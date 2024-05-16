//
//  MapWithUsersView.swift
//  Chatbot
//
//  Created by Inderpreet Singh on 16/05/24.
//

import UIKit
import MapKit
import Kingfisher
import JPSThumbnailAnnotation

protocol MapWithUsersDelegate: AnyObject {
    func triggerButtonAction(lastLocation location:CLLocationCoordinate2D)
    
    func broadcastAlert(title:String, message:String)
}

class MapWithUsersView: UIView {
    
    var mapView = MKMapView()
    var updateLocationButton = UIButton(type: .system)
    var locationManager = CLLocationManager()
    var authUserLocation: CLLocationCoordinate2D?
    var otherUserLocations: [CLLocationCoordinate2D] = []
    
    /**
     Get currentAuthUser
     */
    var authUser:AuthenticatedUser?
    
    weak var delegate: MapWithUsersDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupMapView()
        setupUpdateLocationButton()
        setupLocationManager()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupMapView()
        setupUpdateLocationButton()
        setupLocationManager()
    }
    
    private func setupMapView() {
        mapView.frame = bounds
        mapView.delegate = self
        mapView.mapType = .standard
        mapView.showsUserLocation = true
        addSubview(mapView)
        
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
    }
    
    private func setupUpdateLocationButton() {
        updateLocationButton.frame = CGRect(x: mapView.frame.maxX - 80, y: mapView.frame.maxY - 280 , width: 40, height: 40)
        updateLocationButton.setImage(UIImage(systemName: "location.fill"), for: .normal)
        updateLocationButton.backgroundColor = UIColorHex().hexStringToUIColor(hex: "#a6a6a6")
        updateLocationButton.layer.cornerRadius = updateLocationButton.frame.width / 2
        updateLocationButton.tintColor = .white
        updateLocationButton.addTarget(self, action: #selector(updateLocationButtonTapped), for: .touchUpInside)

        addSubview(updateLocationButton)
    }

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
    }

    @objc private func updateLocationButtonTapped() {
        locationManager.requestLocation()
        guard let authUserLocation = authUserLocation else {
            delegate?.broadcastAlert(title: "Error", message: "Error occured while fetching user location")
            return
        }
        delegate?.triggerButtonAction(lastLocation: authUserLocation)
    }
    
    func addOtherUserLocations(locations: [CLLocationCoordinate2D]) {
        for location in locations {
            let thumbnail = JPSThumbnail()
            thumbnail.image = UIImage(named: "empire.jpg")
            thumbnail.title = "Empire State Building"
            thumbnail.coordinate = location
    
            let annotation = JPSThumbnailAnnotation(thumbnail: thumbnail)
            guard let annotation = annotation else {return}
            mapView.addAnnotation(annotation)
        }
    }
}

extension MapWithUsersView: MKMapViewDelegate, CLLocationManagerDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            /**
             AuthUser Location
             */
            let userAnnotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "userAnnotation")
            if let authUser = authUser, let url = URL(string: authUser.photoURL ?? ""), let authUserLocation = authUserLocation {
                var userAvatar = UIImageView()
                userAvatar.kf.setImage(with: url)
                let thumbnail = JPSThumbnail()
                thumbnail.image = userAvatar.image
                thumbnail.title = authUser.displayName
                thumbnail.coordinate = authUserLocation
                
                let annotation = JPSThumbnailAnnotation(thumbnail: thumbnail)
                if let annotation = annotation {
                    mapView.addAnnotation(annotation)
                }
            }
            return userAnnotationView
        } else if let thumbnailAnnotation = annotation as? JPSThumbnailAnnotation {
            let identifier = "JPSThumbnailAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)

            if annotationView == nil {
                annotationView = thumbnailAnnotation.annotationView(inMap: mapView)
            } else {
                annotationView!.annotation = thumbnailAnnotation
            }

            return annotationView
        }

        return nil
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        authUserLocation = location.coordinate
        centerMapOnLocation(location.coordinate)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        delegate?.broadcastAlert(title: "Location Manager", message: "Location manager failed with error: \(error.localizedDescription)")
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            updateLocationButton.isEnabled = true
        } else {
            updateLocationButton.isEnabled = false
        }
    }
    
    func centerMapOnLocation(_ location: CLLocationCoordinate2D) {
        let regionRadius: CLLocationDistance = 1000
        let coordinateRegion = MKCoordinateRegion(center: location, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
        mapView.setRegion(coordinateRegion, animated: true)
    }
}
