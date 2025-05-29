//
//
//

import SwiftUI
import MapboxMaps

struct SearchView: View {
    @Binding var isPresented: Bool
    @State private var searchText = ""
    @State private var searchResults: [SearchResult] = []
    
    var onSelectLocation: (CLLocationCoordinate2D) -> Void
    
    var body: some View {
        VStack {
            HStack {
                TextField("検索", text: $searchText)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal)
                
                Button(action: {
                    isPresented = false
                }) {
                    Text("キャンセル")
                }
                .padding(.trailing)
            }
            .padding(.top)
            
            if !searchText.isEmpty {
                Button(action: {
                    performSearch()
                }) {
                    Text("検索")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding(.horizontal)
                }
            }
            
            List(searchResults) { result in
                Button(action: {
                    onSelectLocation(result.coordinate)
                    isPresented = false
                }) {
                    VStack(alignment: .leading) {
                        Text(result.name)
                            .font(.headline)
                        Text(result.address)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Spacer()
        }
        .background(Color(.systemBackground))
    }
    
    private func performSearch() {
        searchResults = [
            SearchResult(id: "1", name: "東京駅", address: "東京都千代田区", coordinate: CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)),
            SearchResult(id: "2", name: "渋谷駅", address: "東京都渋谷区", coordinate: CLLocationCoordinate2D(latitude: 35.6580, longitude: 139.7016)),
            SearchResult(id: "3", name: "新宿駅", address: "東京都新宿区", coordinate: CLLocationCoordinate2D(latitude: 35.6896, longitude: 139.7006))
        ]
    }
}

struct SearchResult: Identifiable {
    let id: String
    let name: String
    let address: String
    let coordinate: CLLocationCoordinate2D
}
