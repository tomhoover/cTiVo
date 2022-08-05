//
//  MTTVDBMovieService.swift
//  cTiVo
//
//  Created by Steve Schmadeke on 7/31/22.
//  Copyright © 2022 cTiVo. All rights reserved.
//

import Foundation

public protocol MTTVDBMovie {
    var title: String? { get }
    var releaseDate: String? { get }
    var posterPath: String? { get }
}

public protocol MTTVDBMovieService {
    func queryMovie(name: String) async -> [MTTVDBMovie]
}

extension MTTVDBMovieService {
    private func baseURL(_ name:String) -> String {
        let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return "https://api.themoviedb.org/3/search/movie?query=\(encodedName)"
    }
    public func queryURL(name: String, apiKey: String) -> String {
        "\(baseURL(name))&api_key=\(apiKey)"
    }
    public func reportURL(name: String) -> String {
        "\(baseURL(name))&api_key=APIKEY"
    }
    public func lookupURL(name: String) -> String {
        let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return "https://www.themoviedb.org/search/movie?query=\(encodedName)"
    }
}

public typealias MTTVDBMovieKeyProvider = () -> String

//
// Next two functions only used with #available fallback prior to macOS 12.0
//

fileprivate func fetchTMDBData(from url: URL, completionHandler: @escaping (Data?, URLResponse?) -> Void) {
    URLSession.shared.dataTask(with: url) { data, response, error in
                if let error = error {
                    DDLogReport("TMDB HTTP Request Error \(error): for \(String(describing: url))")
                    completionHandler(nil, nil)
                }
                completionHandler(data, response)
            }.resume()
}

fileprivate func fetchTMDBData(from url: URL) async -> (Data?, URLResponse?) {
    await withCheckedContinuation { continuation in
        fetchTMDBData(from: url) { data, response in
            continuation.resume(returning: (data, response))
        }
    }
}

//
// Implementation of MTTVDBService
//

public struct MTTVDBMovieServiceV3: MTTVDBMovieService {
    let keyProvider: MTTVDBMovieKeyProvider
//    let rateLimiter = MTTVDBRateLimiter(limit: 38, limitInterval: 11)

    public func queryMovie(name: String) async -> [MTTVDBMovie] {
        // Enforce rate limiting
//        await rateLimiter.wait(name)

        let url = URL(string: queryURL(name: name, apiKey: keyProvider()))!

        let data: Data?, response: URLResponse?
        if #available(macOS 12.0, *) {
            do {
                (data, response) = try await URLSession.shared.data(from: url)
            } catch {
                DDLogReport("TMDB HTTP Request Error \(error): for \(reportURL(name: name))")
                return []
            }
        } else {
            // Fallback on earlier versions
            (data, response) = await fetchTMDBData(from: url)
        }

        guard let data = data else { return [] }

        let statusCode = (response as? HTTPURLResponse)?.statusCode
        if statusCode != 200 {
            DDLogReport("TMDB HTTP Response Status Code Error \(statusCode ?? 0): for \(reportURL(name: name))")
            return []
        }

        let decodedData: ResponseJSON
        do {
            decodedData = try JSONDecoder().decode(ResponseJSON.self, from: data)
        } catch {
            DDLogMajor("TMDB JSON Decoding Error \(error): parsing JSON data (\(String(data: data, encoding: String.Encoding.utf8) ?? "")) for \(reportURL(name: name))")
            return []
        }

        return decodedData.results ?? []
    }

    init(keyProvider: @escaping MTTVDBMovieKeyProvider = movieKeyProvider) {
        self.keyProvider =  keyProvider
    }

    struct ResponseJSON: Decodable {
        struct MovieJSON: Decodable, MTTVDBMovie {
            enum CodingKeys: String, CodingKey {
                case title
                case releaseDate = "release_date"
                case posterPath = "poster_path"
            }
            let title: String?
            let releaseDate: String?
            let posterPath: String?
        }
        let results: [MovieJSON]?
    }
}

fileprivate func movieKeyProvider() -> String {
    let base = "be3784463a56eaa78a5426db8c179905e90127ef"
    return String(base.suffix(36).prefix(32))
}