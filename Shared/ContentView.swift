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

  var body: some View {
    VStack {
      TextField("Search", text: .init(
        get: { self.queryString },
        set: {
          self.queryString = $0
          guard isQueryStringValid else {
            return
          }
          YouTubeViewModelImpl.shared.query($0) { result in
            self.didFetch = true
            switch result {
            case .failure(let error):
              print("Youtube query failed with \(error)")
            case .success(let items):
              self.items = items
              print("Youtube query finished successfully: \(items)")
            }
          }
        })).padding()
      if isQueryStringValid {
        if let items = items, didFetch {
          if items.isEmpty {
            Text("No results")
          } else {
            List(items, id:\.self) {
              WebView(htmlString: $0.iFrameString).frame(minHeight: 120)
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
