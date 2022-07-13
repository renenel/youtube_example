//
//  WebView.swift
//  YouTubeTest
//
//  Created by Renen Avneri on 21/06/2022.
//

import SwiftUI
import WebKit
 
struct WebView: UIViewRepresentable {
 
    var htmlString: String
 
    func makeUIView(context: Context) -> WKWebView {
      WKWebView()
    }
 
    func updateUIView(_ webView: WKWebView, context: Context) {
      webView.loadHTMLString(htmlString, baseURL: nil)
    }
}
