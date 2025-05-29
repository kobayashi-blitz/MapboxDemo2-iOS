//
//
//

import UIKit
import MapboxMaps
import CoreLocation

class MainViewController: UIViewController {
    
    private let DEFAULT_ZOOM: Double = 17.0
    private let ZOOM_INCREMENT: Double = 1.0
    private let LOCATION_PERMISSION_REQUEST_CODE = 1
    
    private var mapView: MapView!
    private var zoomInButton: UIButton!
    private var zoomOutButton: UIButton!
    private var myLocationButton: UIButton!
    private var searchButton: UIButton!
    private var splashImageView: UIImageView?
    private var splashShownTime: Date?
    
    private var currentLocation: CLLocationCoordinate2D?
    private var locationManager: CLLocationManager?
    private var isNavigating = false
    private var highlightedGridPolygon: Polygon?
    private var gridOrigin: Point?
    private var lastSearchResults: [SearchResult] = []
    private var navigationSteps: [(point: Point, instruction: String)] = []
    private var gridSizeLabel: UILabel?
    private var navigationPanel: UIView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupMapView()
        setupControls()
        initializeMap()
    }
    
    private func setupMapView() {
        let options = MapInitOptions(
            cameraOptions: CameraOptions(
                center: CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671),
                zoom: DEFAULT_ZOOM
            )
        )
        
        mapView = MapView(frame: view.bounds, mapInitOptions: options)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(mapView)
    }
    
    private func setupControls() {
        let controlsLayout = UIStackView()
        controlsLayout.axis = .vertical
        controlsLayout.spacing = 16
        controlsLayout.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(controlsLayout)
        
        zoomInButton = createFloatingButton(imageName: "plus")
        zoomInButton.addTarget(self, action: #selector(zoomIn), for: .touchUpInside)
        controlsLayout.addArrangedSubview(zoomInButton)
        
        zoomOutButton = createFloatingButton(imageName: "minus")
        zoomOutButton.addTarget(self, action: #selector(zoomOut), for: .touchUpInside)
        controlsLayout.addArrangedSubview(zoomOutButton)
        
        myLocationButton = createFloatingButton(imageName: "location")
        myLocationButton.addTarget(self, action: #selector(moveToCurrentLocation), for: .touchUpInside)
        controlsLayout.addArrangedSubview(myLocationButton)
        
        searchButton = UIButton(type: .system)
        searchButton.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
        searchButton.backgroundColor = .white
        searchButton.tintColor = .systemBlue
        searchButton.layer.cornerRadius = 28
        searchButton.layer.shadowColor = UIColor.black.cgColor
        searchButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        searchButton.layer.shadowRadius = 2
        searchButton.layer.shadowOpacity = 0.3
        searchButton.translatesAutoresizingMaskIntoConstraints = false
        searchButton.addTarget(self, action: #selector(showSearchMenuDialog), for: .touchUpInside)
        view.addSubview(searchButton)
        
        NSLayoutConstraint.activate([
            controlsLayout.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            controlsLayout.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            
            searchButton.widthAnchor.constraint(equalToConstant: 56),
            searchButton.heightAnchor.constraint(equalToConstant: 56),
            searchButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            searchButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -220)
        ])
    }
    
    private func createFloatingButton(imageName: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: imageName), for: .normal)
        button.backgroundColor = .white
        button.tintColor = .systemBlue
        button.layer.cornerRadius = 20
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 2
        button.layer.shadowOpacity = 0.3
        button.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 40),
            button.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        return button
    }
    
    private func initializeMap() {
        mapView.mapboxMap.loadStyleURI(.streets) { [weak self] _ in
            guard let self = self else { return }
            
            self.mapView.gestures.options.rotateEnabled = false
            
            self.drawGridOverlay()
            
            self.mapView.mapboxMap.onCameraChanged.add { [weak self] _ in
                self?.drawGridOverlay()
            }
            
            self.showSplashScreen()
            
            if self.checkLocationPermission() {
                self.enableLocationComponent()
                self.moveToCurrentLocationOnce()
            }
        }
    }
    
    private func showSplashScreen() {
        splashImageView = UIImageView(frame: view.bounds)
        splashImageView?.image = UIImage(named: "splash")
        splashImageView?.contentMode = .scaleAspectFill
        splashImageView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        if let splashImageView = splashImageView {
            view.addSubview(splashImageView)
            splashShownTime = Date()
        }
    }
    
    private func removeSplashScreen() {
        guard let splashImageView = splashImageView,
              let splashShownTime = splashShownTime else { return }
        
        let elapsed = Date().timeIntervalSince(splashShownTime)
        let remaining = 1.5 - elapsed
        
        if remaining > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + remaining) {
                UIView.animate(withDuration: 0.3, animations: {
                    splashImageView.alpha = 0
                }, completion: { _ in
                    splashImageView.removeFromSuperview()
                    self.splashImageView = nil
                })
            }
        } else {
            UIView.animate(withDuration: 0.3, animations: {
                splashImageView.alpha = 0
            }, completion: { _ in
                splashImageView.removeFromSuperview()
                self.splashImageView = nil
            })
        }
    }
    
    private func checkLocationPermission() -> Bool {
        let manager = CLLocationManager()
        
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return true
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
            return false
        case .denied, .restricted:
            showLocationPermissionAlert()
            return false
        @unknown default:
            return false
        }
    }
    
    private func showLocationPermissionAlert() {
        let alert = UIAlertController(
            title: "位置情報の許可が必要です",
            message: "現在地を表示するには位置情報へのアクセスを許可してください。",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "設定", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        
        alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func enableLocationComponent() {
        if locationManager == nil {
            locationManager = CLLocationManager()
        }
        
        var configuration = Puck2DConfiguration()
        configuration.showsAccuracyRing = true
        configuration.pulsing = LocationPulsingConfiguration(isEnabled: true)
        configuration.bearingImage = UIImage(systemName: "location.north.fill")
        
        mapView.location.options.puckType = .puck2D(configuration)
        mapView.location.options.puckBearingSource = .heading
    }
    
    private func moveToCurrentLocationOnce() {
        mapView.location.addOnLocationUpdateListener { [weak self] location in
            guard let self = self,
                  let location = location,
                  let coordinate = location.coordinate else { return }
            
            self.currentLocation = coordinate
            
            self.mapView.camera.fly(to: CameraOptions(center: coordinate, zoom: self.DEFAULT_ZOOM), duration: 1.0)
            
            self.mapView.location.removeOnLocationUpdateListeners()
            
            self.removeSplashScreen()
        }
    }
    
    @objc private func zoomIn() {
        let currentZoom = mapView.cameraState.zoom
        mapView.camera.ease(to: CameraOptions(zoom: currentZoom + ZOOM_INCREMENT), duration: 0.3)
    }
    
    @objc private func zoomOut() {
        let currentZoom = mapView.cameraState.zoom
        mapView.camera.ease(to: CameraOptions(zoom: currentZoom - ZOOM_INCREMENT), duration: 0.3)
    }
    
    @objc private func moveToCurrentLocation() {
        guard let currentLocation = currentLocation else {
            if !checkLocationPermission() {
                return
            }
            return
        }
        
        mapView.camera.fly(to: CameraOptions(center: currentLocation, zoom: DEFAULT_ZOOM), duration: 0.5)
    }
    
    @objc private func showSearchMenuDialog() {
        let alertController = UIAlertController(title: "検索メニュー", message: nil, preferredStyle: .actionSheet)
        
        alertController.addAction(UIAlertAction(title: "キーワード検索", style: .default) { [weak self] _ in
            self?.showKeywordSearchDialog()
        })
        
        alertController.addAction(UIAlertAction(title: "写真検索", style: .default) { [weak self] _ in
            self?.showPhotoSearchDialog()
        })
        
        alertController.addAction(UIAlertAction(title: "キャンセル", style: .cancel))
        
        present(alertController, animated: true)
    }
    
    private func showKeywordSearchDialog() {
        let alertController = UIAlertController(title: "キーワード検索", message: nil, preferredStyle: .alert)
        
        alertController.addTextField { textField in
            textField.placeholder = "検索キーワード"
            textField.returnKeyType = .search
        }
        
        let searchAction = UIAlertAction(title: "検索", style: .default) { [weak self] _ in
            guard let self = self,
                  let textField = alertController.textFields?.first,
                  let keyword = textField.text,
                  !keyword.isEmpty else { return }
            
            self.performSearch(keyword: keyword)
        }
        
        let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel)
        
        alertController.addAction(searchAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true)
    }
    
    private func showPhotoSearchDialog() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        
        present(imagePicker, animated: true)
    }
    
    private func performSearch(keyword: String) {
        let loadingAlert = UIAlertController(title: "検索中...", message: nil, preferredStyle: .alert)
        present(loadingAlert, animated: true)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            
            loadingAlert.dismiss(animated: true) {
                let results = [
                    SearchResult(id: "1", name: "東京駅", address: "東京都千代田区丸の内1丁目", coordinate: CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)),
                    SearchResult(id: "2", name: "渋谷駅", address: "東京都渋谷区道玄坂1丁目", coordinate: CLLocationCoordinate2D(latitude: 35.6580, longitude: 139.7016)),
                    SearchResult(id: "3", name: "新宿駅", address: "東京都新宿区新宿3丁目", coordinate: CLLocationCoordinate2D(latitude: 35.6896, longitude: 139.7006)),
                    SearchResult(id: "4", name: "\(keyword)", address: "検索結果", coordinate: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503))
                ]
                
                self.lastSearchResults = results
                self.showSearchResults(results)
            }
        }
    }
    
    private func showSearchResults(_ results: [SearchResult]) {
        let tableViewController = UITableViewController(style: .plain)
        tableViewController.title = "検索結果"
        
        tableViewController.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        tableViewController.tableView.dataSource = self
        tableViewController.tableView.delegate = self
        
        let navigationController = UINavigationController(rootViewController: tableViewController)
        
        tableViewController.navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(dismissSearchResults)
        )
        
        present(navigationController, animated: true)
    }
    
    @objc private func dismissSearchResults() {
        dismiss(animated: true)
    }
    
    private func processSelectedPhoto(_ image: UIImage) {
        let loadingAlert = UIAlertController(title: "写真を解析中...", message: nil, preferredStyle: .alert)
        present(loadingAlert, animated: true)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self = self else { return }
            
            loadingAlert.dismiss(animated: true) {
                let results = [
                    SearchResult(id: "1", name: "写真の場所", address: "写真から検出された位置", coordinate: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503))
                ]
                
                self.lastSearchResults = results
                self.showSearchResults(results)
            }
        }
    }
    
    private func drawGridOverlay() {
        guard let style = mapView.mapboxMap.style else { return }
        
        let zoom = mapView.cameraState.zoom
        
        let gridSizeMeters: Double
        switch zoom {
        case 19.0...:
            gridSizeMeters = 5.0
        case 16.0..<19.0:
            gridSizeMeters = 50.0
        case 13.0..<16.0:
            gridSizeMeters = 500.0
        default:
            gridSizeMeters = 5000.0
        }
        
        showOrUpdateGridSizeLabel(gridSizeMeters)
        
        let sourceId = "grid-source"
        let layerId = "grid-layer"
        
        try? style.removeLayer(withId: layerId)
        try? style.removeSource(withId: sourceId)
        
        if zoom < 11.0 {
            hideGridSizeLabel()
            return
        }
        
        let center = mapView.cameraState.center
        let latCenter = center.latitude
        
        let camera = mapView.mapboxMap.camera(for: mapView.cameraState)
        let bounds = mapView.mapboxMap.coordinateBounds(for: camera)
        
        let minLat = bounds.southwest.latitude
        let maxLat = bounds.northeast.latitude
        let minLng = bounds.southwest.longitude
        let maxLng = bounds.northeast.longitude
        
        let lat0 = 20.0
        let lng0 = 122.0
        let metersPerDegreeLat = 111132.0
        let metersPerDegreeLng = 111320.0 * cos(lat0 * .pi / 180.0)
        let dLat = gridSizeMeters / metersPerDegreeLat
        let dLng = gridSizeMeters / metersPerDegreeLng
        
        var features: [Feature] = []
        
        let minGridX = Int(ceil((minLng - lng0) / dLng))
        let maxGridX = Int(floor((maxLng - lng0) / dLng))
        
        for n in minGridX...maxGridX {
            let lng = lng0 + Double(n) * dLng
            let line = LineString(coordinates: [
                Point(CLLocationCoordinate2D(latitude: minLat, longitude: lng)),
                Point(CLLocationCoordinate2D(latitude: maxLat, longitude: lng))
            ])
            features.append(Feature(geometry: .lineString(line)))
        }
        
        let minGridY = Int(ceil((minLat - lat0) / dLat))
        let maxGridY = Int(floor((maxLat - lat0) / dLat))
        
        for m in minGridY...maxGridY {
            let lat = lat0 + Double(m) * dLat
            let line = LineString(coordinates: [
                Point(CLLocationCoordinate2D(latitude: lat, longitude: minLng)),
                Point(CLLocationCoordinate2D(latitude: lat, longitude: maxLng))
            ])
            features.append(Feature(geometry: .lineString(line)))
        }
        
        let featureCollection = FeatureCollection(features: features)
        
        let source = GeoJSONSource(id: sourceId)
        source.data = .featureCollection(featureCollection)
        try? style.addSource(source)
        
        let gridLineColor = gridSizeMeters == 5.0 ? 
            UIColor(red: 1.0, green: 0.55, blue: 0.0, alpha: 0.18) : // Orange
            UIColor(red: 0.12, green: 0.31, blue: 0.78, alpha: 0.18) // Blue
        
        var lineLayer = LineLayer(id: layerId)
        lineLayer.source = sourceId
        lineLayer.lineColor = .constant(.color(gridLineColor))
        lineLayer.lineWidth = .constant(1.0)
        
        try? style.addLayer(lineLayer)
        
        if let highlightedGridPolygon = highlightedGridPolygon {
            addHighlightedGrid(highlightedGridPolygon)
        }
    }
    
    private func showOrUpdateGridSizeLabel(_ gridSizeMeters: Double) {
        if gridSizeLabel == nil {
            gridSizeLabel = UILabel()
            gridSizeLabel?.backgroundColor = UIColor(white: 0.0, alpha: 0.6)
            gridSizeLabel?.textColor = .white
            gridSizeLabel?.font = UIFont.systemFont(ofSize: 12)
            gridSizeLabel?.textAlignment = .center
            gridSizeLabel?.layer.cornerRadius = 4
            gridSizeLabel?.clipsToBounds = true
            gridSizeLabel?.translatesAutoresizingMaskIntoConstraints = false
            
            if let gridSizeLabel = gridSizeLabel {
                view.addSubview(gridSizeLabel)
                
                NSLayoutConstraint.activate([
                    gridSizeLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
                    gridSizeLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
                    gridSizeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 80),
                    gridSizeLabel.heightAnchor.constraint(equalToConstant: 24)
                ])
            }
        }
        
        let sizeText: String
        if gridSizeMeters >= 1000 {
            sizeText = String(format: "%.1fkm", gridSizeMeters / 1000)
        } else {
            sizeText = String(format: "%.0fm", gridSizeMeters)
        }
        
        gridSizeLabel?.text = "グリッド: \(sizeText)"
        gridSizeLabel?.isHidden = false
    }
    
    private func hideGridSizeLabel() {
        gridSizeLabel?.isHidden = true
    }
    
    private func addHighlightedGrid(_ polygon: Polygon) {
        guard let style = mapView.mapboxMap.style else { return }
        
        let highlightLayerId = "highlight-layer"
        let highlightSourceId = "highlight-source"
        
        try? style.removeLayer(withId: highlightLayerId)
        try? style.removeSource(withId: highlightSourceId)
        
        let feature = Feature(geometry: .polygon(polygon))
        let featureCollection = FeatureCollection(features: [feature])
        
        let source = GeoJSONSource(id: highlightSourceId)
        source.data = .featureCollection(featureCollection)
        try? style.addSource(source)
        
        var fillLayer = FillLayer(id: highlightLayerId)
        fillLayer.source = highlightSourceId
        fillLayer.fillColor = .constant(.color(UIColor(red: 1.0, green: 0.55, blue: 0.0, alpha: 0.3)))
        fillLayer.fillOutlineColor = .constant(.color(UIColor(red: 1.0, green: 0.55, blue: 0.0, alpha: 0.8)))
        
        try? style.addLayer(fillLayer)
    }
}

extension MainViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return lastSearchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let result = lastSearchResults[indexPath.row]
        
        var content = cell.defaultContentConfiguration()
        content.text = result.name
        content.secondaryText = result.address
        cell.contentConfiguration = content
        
        return cell
    }
}

extension MainViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let result = lastSearchResults[indexPath.row]
        
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            
            self.mapView.camera.fly(to: CameraOptions(center: result.coordinate, zoom: self.DEFAULT_ZOOM), duration: 0.5)
            
            if let currentLocation = self.currentLocation {
                self.drawRouteLine(from: currentLocation, to: result.coordinate)
            }
        }
    }
}

extension MainViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true) { [weak self] in
            if let image = info[.originalImage] as? UIImage {
                self?.processSelectedPhoto(image)
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

extension MainViewController {
    private func drawRouteLine(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) {
        guard let style = mapView.mapboxMap.style else { return }
        
        try? style.removeLayer(withId: "route-layer")
        try? style.removeSource(withId: "route-source")
        
        let routeCoordinates = [
            Point(origin),
            Point(destination)
        ]
        
        let routeLine = LineString(coordinates: routeCoordinates)
        let routeFeature = Feature(geometry: .lineString(routeLine))
        let featureCollection = FeatureCollection(features: [routeFeature])
        
        let source = GeoJSONSource(id: "route-source")
        source.data = .featureCollection(featureCollection)
        try? style.addSource(source)
        
        var lineLayer = LineLayer(id: "route-layer")
        lineLayer.source = "route-source"
        lineLayer.lineColor = .constant(.color(.systemBlue))
        lineLayer.lineWidth = .constant(4.0)
        lineLayer.lineCap = .constant(.round)
        lineLayer.lineJoin = .constant(.round)
        
        try? style.addLayer(lineLayer)
        
        showNavigationUI(destination: destination)
    }
    
    private func showNavigationUI(destination: CLLocationCoordinate2D) {
        let navigationPanel = UIView()
        navigationPanel.backgroundColor = UIColor(white: 0.0, alpha: 0.7)
        navigationPanel.layer.cornerRadius = 8
        navigationPanel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(navigationPanel)
        
        let destinationLabel = UILabel()
        destinationLabel.text = "目的地: \(getAddressForCoordinate(destination))"
        destinationLabel.textColor = .white
        destinationLabel.font = UIFont.systemFont(ofSize: 14)
        destinationLabel.translatesAutoresizingMaskIntoConstraints = false
        navigationPanel.addSubview(destinationLabel)
        
        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle("ナビゲーションを終了", for: .normal)
        cancelButton.setTitleColor(.white, for: .normal)
        cancelButton.backgroundColor = .systemRed
        cancelButton.layer.cornerRadius = 4
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.addTarget(self, action: #selector(cancelNavigation), for: .touchUpInside)
        navigationPanel.addSubview(cancelButton)
        
        NSLayoutConstraint.activate([
            navigationPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            navigationPanel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            navigationPanel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            
            destinationLabel.topAnchor.constraint(equalTo: navigationPanel.topAnchor, constant: 12),
            destinationLabel.leadingAnchor.constraint(equalTo: navigationPanel.leadingAnchor, constant: 12),
            destinationLabel.trailingAnchor.constraint(equalTo: navigationPanel.trailingAnchor, constant: -12),
            
            cancelButton.topAnchor.constraint(equalTo: destinationLabel.bottomAnchor, constant: 12),
            cancelButton.leadingAnchor.constraint(equalTo: navigationPanel.leadingAnchor, constant: 12),
            cancelButton.trailingAnchor.constraint(equalTo: navigationPanel.trailingAnchor, constant: -12),
            cancelButton.bottomAnchor.constraint(equalTo: navigationPanel.bottomAnchor, constant: -12),
            cancelButton.heightAnchor.constraint(equalToConstant: 36)
        ])
        
        self.navigationPanel = navigationPanel
        
        isNavigating = true
    }
    
    @objc private func cancelNavigation() {
        navigationPanel?.removeFromSuperview()
        navigationPanel = nil
        
        if let style = mapView.mapboxMap.style {
            try? style.removeLayer(withId: "route-layer")
            try? style.removeSource(withId: "route-source")
        }
        
        isNavigating = false
    }
    
    private func getAddressForCoordinate(_ coordinate: CLLocationCoordinate2D) -> String {
        return "目的地"
    }
}

struct SearchResult {
    let id: String
    let name: String
    let address: String
    let coordinate: CLLocationCoordinate2D
}
