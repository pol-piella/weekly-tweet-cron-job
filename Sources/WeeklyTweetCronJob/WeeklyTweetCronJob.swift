import Foundation

@main
public struct WeeklyTweetCronJob {
    public static func main() async {
        guard let fathomEntity = ProcessInfo.processInfo.environment["FATHOM_ENTITY_ID"],
              let fathomToken = ProcessInfo.processInfo.environment["FATHOM_TOKEN"],
              let twitterAPIKey = ProcessInfo.processInfo.environment["TWITTER_API_KEY"],
              let twitterAPISecret = ProcessInfo.processInfo.environment["TWITTER_API_SECRET"],
              let twitterAPIToken = ProcessInfo.processInfo.environment["TWITTER_API_TOKEN"],
              let twitterAPITokenSecret = ProcessInfo.processInfo.environment["TWITTER_API_TOKEN_SECRET"] else {
            print("Missing environment variables...")
            exit(1)
        }
        
        let currentDate = Date()
        let aWeekAgoDate = Calendar(identifier: .iso8601).date(byAdding: .day, value: -7, to: currentDate)!
        
        // Build a URL
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.usefathom.com"
        components.path = "/v1/aggregations"
        components.queryItems = [
            URLQueryItem(name: "entity", value: "pageview"),
            URLQueryItem(name: "entity_id", value: fathomEntity),
            URLQueryItem(name: "aggregates", value: "uniques"),
            URLQueryItem(name: "field_grouping", value: "pathname"),
            URLQueryItem(name: "sort_by", value: "uniques:desc"),
            URLQueryItem(name: "timezone", value: "Europe/London"),
            URLQueryItem(name: "date_from", value: aWeekAgoDate.ISO8601Format()),
            URLQueryItem(name: "date_to", value: currentDate.ISO8601Format()),
            URLQueryItem(name: "filters", value: "[{\"property\":\"pathname\", \"operator\":\"is like\", \"value\":\"/*-*\"}]")
        ]
        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(fathomToken)", forHTTPHeaderField: "Authorization")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let pageViews = try! JSONDecoder().decode([PageView].self, from: data)
            let uniquedPageViews = pageViews.reduce(into: [PageView]()) { partialResult, pageView in
                if let index = partialResult.firstIndex(where: { $0.pathname == pageView.pathname }) {
                    partialResult[index].uniques += pageView.uniques
                } else {
                    partialResult.append(pageView)
                }
            }
                .sorted(by: { lhs, rhs in lhs.uniques > rhs.uniques })
                .prefix(3)
            
            let topArticlesList = uniquedPageViews.enumerated().map { index, pageView in
                let emoji = [
                    UnicodeScalar(0x0031 + index),
                    UnicodeScalar(UInt32(0xfe0f)),
                    UnicodeScalar(UInt32(0x20E3))
                ]
                .compactMap { $0 }
                .map { String($0) }
                .joined()
                
                return "\(emoji) polpiella.dev/\(pageView.pathname)"
            }
            .joined(separator: "\n")

            let tweet = """
            Happy Friday everyone! 👋

            Hope you've all had a great week. Here's a look back at the week's most read articles in my blog:

            \(topArticlesList)

            #iosdev #swiftlang
            """
            
            let url = URL(string: "https://api.twitter.com/2/tweets")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = try JSONEncoder().encode(Tweet(text: tweet))

            // Add oAuth1 key-value pairs to `URLRequest` headers
            let oAuth1 = OAuth1(key: twitterAPIKey, secret: twitterAPISecret, token: twitterAPIToken, tokenSecret: twitterAPITokenSecret)
            let adaptedRequest = try oAuth1.adaptRequest(request)
            _ = try await URLSession.shared.data(for: adaptedRequest)
        } catch {
            print("Something went wrong making the request: \(error.localizedDescription)")
            exit(1)
        }
    }
}
