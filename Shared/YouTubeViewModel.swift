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
  func query(_ string: String, completion: @escaping (Result<[YouTubeItem], YouTubeViewModelError>) -> (Void))
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
  private var service: YouTubeService
  private var cancellable: AnyCancellable?
  private var debounceTimer: Timer?
  private static let debounceInterval: TimeInterval = 1.0
  
  init(service: YouTubeService = YouTubeServiceImpl(urlSession: .shared),
       parser: YouTubeResultParser = YouTubeResultsParserImpl()) {
    self.parser = parser
    self.service = service
  }
  
  func query(_ string: String, completion: @escaping (Result<[YouTubeItem], YouTubeViewModelError>) -> (Void)) {
    debounceTimer?.invalidate()
    debounceTimer = Timer.scheduledTimer(
      withTimeInterval: Self.debounceInterval,
      repeats: false,
      block: { [weak self] _ in
        self?.applyQuery(string, completion: completion)
      })
  }
  
  func applyQuery(_ string: String, completion: @escaping (Result<[YouTubeItem], YouTubeViewModelError>) -> (Void)) {
    cancellable = service.query(string).sink(receiveCompletion: {
      switch $0 {
      case .finished:
        break
      case .failure(let error):
        completion(.failure(error))
      }
    }, receiveValue: {
      switch self.parser.parse($0) {
      case .failure(let error):
        completion(.failure(.queryResultCouldNotBeParsed(error)))
      case .success(let results):
        completion(.success(results))
      }
    })
  }
}
