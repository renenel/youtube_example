//
//  YouTubeViewModel.swift
//  YouTubeTest
//
//  Created by Renen Avneri on 21/06/2022.
//

import Foundation
import Combine

struct YouTubeItem: Hashable {
  var id: String
}

extension YouTubeItem {
  var iFrameString: String {
    "<iframe width=\"560\" height=\"315\" src=\"https://www.youtube.com/embed/\(id)\" title=\"Youtube Video\" frameborder=\"0\" allow=\"accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture\" allowfullscreen></iframe>"
  }
}

protocol YouTubeViewModel {
  func query(_ string: String) -> AnyPublisher<[YouTubeItem], YouTubeViewModelError>
}

enum YouTubeViewModelError: Error {
  case couldNotFormURL
  case queryReturnedEmpty
  case queryReturnedError(_ error: Error)
  case queryResultCouldNotBeParsed(_ error: Error)
}

class YouTubeViewModelImpl: YouTubeViewModel {
  
  public static var shared: YouTubeViewModel = YouTubeViewModelImpl()
  
  private var parser: YouTubeResultParser
  private var session: URLSession
  private var subject = CurrentValueSubject<[YouTubeItem], YouTubeViewModelError>([])
  private static let queryUrlComponents = URLComponents(string: "https://www.youtube.com/results")!

  init(urlSession: URLSession = .shared, parser: YouTubeResultParser = YouTubeResultsParserImpl()) {
    session = urlSession
    self.parser = parser
  }
  
  func query(_ string: String) -> AnyPublisher<[YouTubeItem], YouTubeViewModelError> {
    // TODO: throttle
    
    var components = Self.queryUrlComponents
    components.queryItems = [URLQueryItem(name: "search_query", value: string)]
    
    guard let url = components.url else {
      return Fail(error: YouTubeViewModelError.couldNotFormURL).eraseToAnyPublisher()
    }

    // Note: we may want to specify a queue via URL session configuration
    let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
      guard let self = self else { return }
      if let error = error {
        self.subject.send(completion: .failure(.queryReturnedError(error)))
        return
      }
      guard let data = data else {
        self.subject.send(completion: .failure(.queryReturnedEmpty))
        return
      }
      // Note: parsing may be better done off the URLSession queue
      switch self.parser.parse(data) {
      case .failure(let error):
        self.subject.send(completion: .failure(.queryResultCouldNotBeParsed(error)))
      case .success(let results):
        self.subject.send(results)
        self.subject.send(completion: .finished)
      }
    }
    task.resume()
    return subject.eraseToAnyPublisher()
  }
}
