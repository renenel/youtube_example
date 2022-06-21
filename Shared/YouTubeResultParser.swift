//
//  YouTubeResultParser.swift
//  YouTubeTest
//
//  Created by Renen Avneri on 21/06/2022.
//

import Foundation

enum YouTubeResultParserError: Error {
  case couldNotCastDataToString
  case matchingFailed
}

protocol YouTubeResultParser {
  func parse(_ results: Data) -> Result<[YouTubeItem], YouTubeResultParserError>
}

class YouTubeResultsParserImpl: YouTubeResultParser {
  func parse(_ results: Data) -> Result<[YouTubeItem], YouTubeResultParserError> {
    guard let string = String(data: results, encoding: .utf8) else {
      return .failure(.couldNotCastDataToString)
    }
    let range = NSRange(location: 0, length: string.utf16.count)
    let regex = try? NSRegularExpression(pattern: "\"videoId\": \"(.*)\"")
    guard let matches = regex?.matches(in: string, options: [], range: range) else {
      return .failure(.matchingFailed)
    }
    let ids: [String] = matches.compactMap {
      let fullString = String(string[Range($0.range, in: string)!])
      // should replace with regex given time:
      return fullString
        .replacingOccurrences(of: "\"videoId\": \"", with: "")
        .replacingOccurrences(of: "\"", with: "")
    }
    let uniqueIds = Set(ids)
    return .success(uniqueIds.compactMap { YouTubeItem(id: $0) })
  }
}
