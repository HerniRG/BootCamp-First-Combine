import Foundation
import Combine

final class BootcampsViewModel: ObservableObject {
    @Published var boots: [Bootcamp] = Array<Bootcamp>()
    @Published var estado: Estado
    
    private var cancellables: Set<AnyCancellable> = []
    
    init() {
        estado = .none
        cargarBootcamps()
    }
    
    func cargarBootcamps(useMockData: Bool = false) {
        self.estado = .loading
        if useMockData {
            // Retraso de 2 segundos solo para los datos mock
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                self?.boots = self?.getMockBootcamps() ?? []
                self?.estado = .loaded
            }
        } else {
            // Carga los datos de la API sin retraso
            getReactiveBootcamps()
        }
    }
    
    func getMockBootcamps() -> [Bootcamp] {
        return [
            Bootcamp(id: UUID().uuidString, name: "Bootcamp 1"),
            Bootcamp(id: UUID().uuidString, name: "Bootcamp 2"),
            Bootcamp(id: UUID().uuidString, name: "Bootcamp 3"),
            Bootcamp(id: UUID().uuidString, name: "Bootcamp 4")
        ]
    }
    
    func getReactiveBootcamps() {
        let url = URL(string: "https://dragonball.keepcoding.education/api/data/bootcamps")!
        
        URLSession.shared
            .dataTaskPublisher(for: url)
            .retry(3)
            .tryMap { element -> Data in
                guard let httpResponse = element.response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                return element.data
            }
            .decode(type: [Bootcamp].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                case .finished:
                    self?.estado = .loaded
                case .failure:
                    self?.estado = .error
                }
            }, receiveValue: { [weak self] bootcamps in
                self?.boots = bootcamps
            })
            .store(in: &cancellables)
    }
}

enum Estado {
    case none
    case loading
    case loaded
    case error
}
