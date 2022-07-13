//
//  YouTubeService.swift
//  YouTubeTest
//
//  Created by Renen Avneri on 21/06/2022.
//

import Foundation
import Combine

protocol YouTubeService {
  func query(_ string: String) -> AnyPublisher<Data, YouTubeViewModelError>
}

class YouTubeServiceImpl: YouTubeService {
  
  private var session: URLSession
  private static let queryUrlComponents = URLComponents(string: "https://www.youtube.com/results")!

  init(urlSession: URLSession = .shared) {
    session = urlSession
  }
  
  func query(_ string: String) -> AnyPublisher<Data, YouTubeViewModelError> {
    let subject = PassthroughSubject<Data, YouTubeViewModelError>()
    var components = Self.queryUrlComponents
    components.queryItems = [URLQueryItem(name: "search_query", value: string)]
    
    guard let url = components.url else {
      return Fail(error: YouTubeViewModelError.couldNotFormURL).eraseToAnyPublisher()
    }
    var request = URLRequest(url: url)
    // reason: https://stackoverflow.com/questions/67032728/urlsession-returns-script-element-still-string-encoded-and-escaped
    request.setValue("Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:60.0) Gecko/20100101 Firefox/60.0", forHTTPHeaderField:"user-agent")
    
    // Note: we may want to specify a queue via URL session configuration
    let task = session.dataTask(with: request) { data, response, error in
      if let error = error {
        subject.send(completion: .failure(.queryReturnedError(error)))
        return
      }
      guard let data = data else {
        subject.send(completion: .failure(.queryReturnedEmpty))
        return
      }
      subject.send(data)
      subject.send(completion: .finished)
    }
    task.resume()
    return subject.eraseToAnyPublisher()
  }
}
