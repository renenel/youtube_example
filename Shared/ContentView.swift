//
//  ContentView.swift
//  Shared
//
//  Created by Renen Avneri on 21/06/2022.
//

import SwiftUI
import Combine

struct ContentView: View {

  @State private var queryString: String = ""
  @State private var items: [YouTubeItem]?
  @State private var didFetch = false
  static private var cancellable: AnyCancellable?

  var body: some View {
    VStack {
      TextField("Search", text: .init(
        get: { self.queryString },
        set: {
          self.queryString = $0
          guard isQueryStringValid else {
            return
          }
          ContentView.cancellable = YouTubeViewModelImpl.shared.query($0).sink { result in
            self.didFetch = true
            switch result {
            case .failure(let error):
              print("Youtube query failed with \(error)")
            case .finished:
              print("Youtube query finished successfully")
            }
          } receiveValue: { items in
            self.items = items
          }
        })).padding()
      if isQueryStringValid {
        if let items = items, didFetch {
          if items.isEmpty {
            Text("No results")
          } else {
            List(items, id:\.self) {
              //Text("\($0.id)")
              WebView(url: URL(string: $0.iFrameString)!).frame(maxHeight: 400)
            }
          }
        } else {
          Text("Loading...")
        }
      } else {
        Text("Please type a search string...")
      }
    }
  }
  
  var isQueryStringValid: Bool {
    queryString.count > 3 // TODO: better validation
  }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
