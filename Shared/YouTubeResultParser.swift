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
    let regex = try? NSRegularExpression(pattern: "\"videoId\":\"*\"")
    guard let matches = regex?.matches(in: string, options: [], range: range) else {
      return .failure(.matchingFailed)
    }
    let ids: [String] = matches.compactMap { match in
      guard let range = Range(match.range(at: 0), in: string) else { return nil }
      // TODO: should be a regular expression
      return String(string[range.upperBound..<string.index(range.upperBound, offsetBy: 11)])
    }

    let uniqueIds = Set(ids)
    return .success(uniqueIds.compactMap { YouTubeItem(id: $0) })
  }
}
