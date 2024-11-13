import UIKit
import Combine

class ViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var infoLabel: UILabel! // Para mostrar mensajes de estado y error
    
    private var viewModel = BootcampsViewModel()
    private var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configUI()
        bindViewmodel()
    }
    
    private func configUI() {
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }
    
    private func bindViewmodel() {
        bindBoots()
        bindEstado()
    }
    
    private func bindBoots() {
        // Observa el cambio en boots y recarga la tabla
        viewModel.$boots
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)
    }
    
    private func bindEstado() {
        // Observa el cambio en estado y actualiza la interfaz según el valor
        viewModel.$estado
            .receive(on: DispatchQueue.main)
            .sink { [weak self] estado in
                self?.updateUI(for: estado)
            }
            .store(in: &cancellables)
    }
    
    
    private func updateUI(for estado: Estado) {
        switch estado {
        case .loading:
            loadingIndicator.startAnimating()
            tableView.isHidden = true
            infoLabel.isHidden = true
        case .loaded:
            loadingIndicator.stopAnimating()
            tableView.isHidden = viewModel.boots.isEmpty
            infoLabel.isHidden = !viewModel.boots.isEmpty
            if viewModel.boots.isEmpty {
                showEmptyStateMessage()
            }
        case .error:
            loadingIndicator.stopAnimating()
            tableView.isHidden = true
            showErrorStateMessage()
        case .none:
            loadingIndicator.stopAnimating()
            tableView.isHidden = true
            infoLabel.isHidden = true
        }
    }
    
    private func showEmptyStateMessage() {
        infoLabel.text = "No hay datos disponibles."
        infoLabel.isHidden = false
    }
    
    private func showErrorStateMessage() {
        infoLabel.text = "Ocurrió un error al cargar los datos."
        infoLabel.isHidden = false
    }
}

// MARK: - UITableViewDataSource
extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.boots.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let bootcamp = viewModel.boots[indexPath.row]
        cell.textLabel?.text = bootcamp.name
        return cell
    }
}
