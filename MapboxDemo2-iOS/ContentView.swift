//
//  ContentView.swift
//  MapboxDemo2-iOS
//
//  Created by Shinya Kobayashi on 2025/05/29.
//

import SwiftUI
import MapboxMaps

struct ContentView: View {
    @State private var showUserLocation = false
    @State private var showSearch = false
    @State private var mapView: MapView?
    
    var body: some View {
        ZStack {
            MapViewRepresentable(showUserLocation: $showUserLocation, mapViewCallback: { view in
                self.mapView = view
            })
            .edgesIgnoringSafeArea(.all)
            
            VStack {
                HStack {
                    Button(action: {
                        showSearch = true
                    }) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                            Text("場所を検索")
                                .foregroundColor(.gray)
                            Spacer()
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)
                        .shadow(radius: 2)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                
                Spacer()
                
                HStack {
                    VStack(spacing: 16) {
                        Button(action: {
                            zoomIn()
                        }) {
                            Image(systemName: "plus")
                                .padding()
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(radius: 2)
                        }
                        
                        Button(action: {
                            zoomOut()
                        }) {
                            Image(systemName: "minus")
                                .padding()
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(radius: 2)
                        }
                        
                        Button(action: {
                            showUserLocation.toggle()
                        }) {
                            Image(systemName: "location")
                                .padding()
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(radius: 2)
                        }
                    }
                    .padding(.leading, 16)
                    
                    Spacer()
                }
                .padding(.bottom, 32)
            }
        }
        .sheet(isPresented: $showSearch) {
            SearchView(isPresented: $showSearch, onSelectLocation: { coordinate in
                moveToLocation(coordinate: coordinate)
            })
        }
    }
    
    private func zoomIn() {
        guard let mapView = mapView else { return }
        let currentZoom = mapView.cameraState.zoom
        mapView.camera.ease(to: CameraOptions(zoom: currentZoom + 1), duration: 0.3)
    }
    
    private func zoomOut() {
        guard let mapView = mapView else { return }
        let currentZoom = mapView.cameraState.zoom
        mapView.camera.ease(to: CameraOptions(zoom: currentZoom - 1), duration: 0.3)
    }
    
    private func moveToLocation(coordinate: CLLocationCoordinate2D) {
        guard let mapView = mapView else { return }
        mapView.camera.ease(to: CameraOptions(center: coordinate, zoom: 15), duration: 0.5)
    }
}

struct MapViewRepresentable: UIViewRepresentable {
    @Binding var showUserLocation: Bool
    var mapViewCallback: (MapView) -> Void
    
    func makeUIView(context: Context) -> MapView {
        let accessToken = Bundle.main.object(forInfoDictionaryKey: "MBXAccessToken") as! String
        let resourceOptions = ResourceOptions(accessToken: accessToken)
        let mapInitOptions = MapInitOptions(resourceOptions: resourceOptions)
        
        mapInitOptions.cameraOptions = CameraOptions(center: CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671), zoom: 14.0)
        
        let mapView = MapView(frame: .zero, mapInitOptions: mapInitOptions)
        
        mapView.location.options.puckType = .puck2D()
        
        mapView.mapboxMap.style.localizeLabels(into: "ja")
        
        mapViewCallback(mapView)
        
        return mapView
    }
    
    func updateUIView(_ mapView: MapView, context: Context) {
        if showUserLocation {
            mapView.location.options.puckType = .puck2D()
            mapView.location.locationProvider.requestAlwaysAuthorization()
        }
    }
}

#Preview {
    ContentView()
}
