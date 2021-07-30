//
//  MyNeighborsViewController.swift
//  neighbourhood
//
//  Created by Dioksa on 24.04.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces
import GoogleMapsUtils

private let markerWidth: CGFloat = 110.0
private let markerHeight: CGFloat = 80.0
private let clusterSize: CGFloat = 45

final class MyNeighborsViewController: BaseViewController, CLLocationManagerDelegate {
    @IBOutlet private weak var googleMapsView: GMSMapView!
    
    private var profileMarkerView = ProfileMarkerView(frame: CGRect(x: 0, y: 0, width: 110, height: 80))
    private var offlineMarker = GMSMarker()
    
    private var clusterManager: GMUClusterManager?
    private var locationManager = CLLocationManager()
    
    private lazy var authorizationManager: RestAuthorizationManager = RestService.shared.createOperationsManager(from: self)
    private lazy var profileManager: RestProfileManager = RestService.shared.createOperationsManager(from: self)
    private lazy var neighborsManager: RestMyNeighborsManager = RestService.shared.createOperationsManager(from: self)
    private var neighbors: [NeighborModel]?
    private var latitude: Float?
    private var longitude: Float?
    private var profileImageUrl: URL?
    private var profileName: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        initializeClusterItems()
        AnalyticsService.logOpenMapView()
        NotificationCenter.default.addObserver(self, selector: #selector(profileChanged), name: .profileDidChanged, object: nil)
        updateMap()
    }
    
    public func updateMap() {
        guard googleMapsView != nil else { return }
        googleMapsView.clear()
        defineCurrentProfile()
        fetchAllNeighbors()
    }
    
    private func initializeClusterItems() {
        let iconGenerator = GMUDefaultClusterIconGenerator.init(buckets: [99], backgroundImages: [R.image.map_round()!])
        let algorithm = GMUNonHierarchicalDistanceBasedAlgorithm()
        let renderer = GMUDefaultClusterRenderer(mapView: googleMapsView, clusterIconGenerator: iconGenerator)
        renderer.delegate = self
        clusterManager = GMUClusterManager(map: googleMapsView, algorithm: algorithm, renderer: renderer)
        clusterManager?.cluster()
        clusterManager?.setDelegate(self, mapDelegate: self)
    }

    private func generateClusterItems() {
        clusterManager?.clearItems()
        guard let neighbors = neighbors else {
            loadGoogleMapView()
            return
        }
        for neighbor in neighbors {
            let lat = Double(neighbor.latitude)
            let lng = Double(neighbor.longitude)
            let item = POIItem(position: CLLocationCoordinate2DMake(lat, lng),
                               id: neighbor.id,
                               type: neighbor.type,
                               avatar: neighbor.avatar,
                               fullName: neighbor.fullName,
                               isBusiness: neighbor.type == .business)
            
            clusterManager?.add(item)
        }
        
        loadGoogleMapView()
    }

    /// Create marker with circle for current profile
    private func loadGoogleMapView() {
        if let latitude = latitude, let longitude = longitude {
            let lat = CLLocationDegrees(exactly: latitude) ?? 0
            let lon = CLLocationDegrees(exactly: longitude) ?? 0
            offlineMarker = GMSMarker(position: CLLocationCoordinate2D(latitude: lat, longitude: lon))
            offlineMarker.iconView = profileMarkerView
            profileMarkerView.updateView(imageUrl: profileImageUrl, name: R.string.localizable.meMapItem(), profileName: profileName)
            offlineMarker.map = googleMapsView
            googleMapsView.moveCamera(GMSCameraUpdate.setCamera(GMSCameraPosition(latitude: CLLocationDegrees(latitude),
                                                                                  longitude: CLLocationDegrees(longitude),
                                                                                  zoom: 7)))
            
            let circleCenter : CLLocationCoordinate2D  = CLLocationCoordinate2DMake(CLLocationDegrees(latitude), CLLocationDegrees(longitude))
            let circle = GMSCircle(position: circleCenter, radius: GlobalConstants.Common.mapRadiusInMeters)
            circle.fillColor = R.color.accentGreenTransparent()
            circle.strokeColor = R.color.accentGreenTransparent()
            circle.map = googleMapsView
        }
    }
    
    private func defineCurrentProfile() {
        guard let currentProfile = ArchiveService.shared.currentProfile else {
            return
        }
            latitude = currentProfile.latitude
            longitude = currentProfile.longitude
            profileImageUrl = currentProfile.avatar?.formatted?.small
            profileName = currentProfile.fullName
    }
    
    // MARK: - REST requests
    
    private func fetchAllNeighbors() {
        guard ValidationManager().checkInternetConnection() else {
            Toast.show(message: R.string.localizable.internetConnectionError())
            return
        }

        neighborsManager.getNeighbors()
            .onComplete { [weak self] (result) in
                self?.neighbors = result.result
                self?.generateClusterItems()
        } .run()
    }

    @objc func profileChanged() {
        updateMap()
    }
}

// MARK: - GMUClusterManagerDelegate
extension MyNeighborsViewController: GMUClusterManagerDelegate {
    func clusterManager(_ clusterManager: GMUClusterManager, didTap cluster: GMUCluster) -> Bool {
        let newCamera = GMSCameraPosition.camera(withTarget: cluster.position,
                                                 zoom: googleMapsView.camera.zoom + 1)
        let update = GMSCameraUpdate.setCamera(newCamera)
        googleMapsView.moveCamera(update)
        return true
    }
}

// MARK: - GMSMapViewDelegate
extension MyNeighborsViewController: GMSMapViewDelegate {
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        if let poiItem = marker.userData as? POIItem {
            showPublicProfile(by: poiItem.id, accType: poiItem.type)
        }
        
        return true
    }
    
    private func showPublicProfile(by id: Int, accType: ProfileType) {
        if accType == .basic {
            BasicProfileRouter(in: navigationController).openPublicProfileViewController(profileId: id)
        } else {
            BusinessProfileRouter(in: navigationController).openPublicProfileController(id: id)
        }
    }
}

// MARK: - GMUClusterRendererDelegate
extension MyNeighborsViewController: GMUClusterRendererDelegate {

    func renderer(_ renderer: GMUClusterRenderer, willRenderMarker marker: GMSMarker) {
        if let cluster = marker.userData as? GMUCluster {
            let clusterView = UIView(frame: CGRect(x: 0, y: 0, width: clusterSize, height: clusterSize))
            clusterView.backgroundColor = .white
            clusterView.cornerRadius = clusterSize / 2
            let countLabel = UILabel()
            countLabel.text = Int(cluster.count).counter(max: 99)
            countLabel.font = R.font.poppinsSemiBold(size: 15)
            countLabel.textColor = R.color.blueButton()
            clusterView.addSubview(countLabel)
            countLabel.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                countLabel.centerXAnchor.constraint(equalTo: clusterView.centerXAnchor),
                countLabel.centerYAnchor.constraint(equalTo: clusterView.centerYAnchor)
            ])
            marker.iconView = clusterView
        }
    }

    func renderer(_ renderer: GMUClusterRenderer, markerFor object: Any) -> GMSMarker? {
        let marker = GMSMarker()

        if let item = object as? POIItem {
            let view = CustomMarkerView(frame: CGRect(x: 0, y: 0, width: markerWidth, height: markerHeight))
            view.updateView(imageUrl: item.avatar, name: item.fullName, isBusiness: item.isBusiness)
            marker.iconView = view
        }
        
        return marker
    }
}
