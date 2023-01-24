#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Foundation
import CryptoKit

public enum OAuthSignatureMethod: String {
    case HMAC_SHA1 = "HMAC-SHA1"
    case PLAINTEXT = "PLAINTEXT"
}

public enum OAuth1Error: Error {
    case noBaseString
    case invalidSignature
}

enum HTTPMethod: String {
    case connect = "CONNECT"
    case delete = "DELETE"
    case get = "GET"
    case head = "HEAD"
    case options = "OPTIONS"
    case patch = "PATCH"
    case post = "POST"
    case put = "PUT"
    case query = "QUERY"
    case trace = "TRACE"
}

class OAuth1 {
    var signatureMethod: OAuthSignatureMethod
    var key: String
    var secret: String
    var token: String
    var tokenSecret: String
    let version: String = "1.0"
    
    init(key: String, secret: String, token: String, tokenSecret: String) {
        self.key = key
        self.secret = secret
        self.token = token
        self.tokenSecret = tokenSecret
        self.signatureMethod = .HMAC_SHA1
    }
    
    func adaptRequest(_ urlRequest: URLRequest) throws -> URLRequest {
        var parameters = generateParameters()
        
        guard let urlString = urlRequest.url?.absoluteString,
              let httpMethodString = urlRequest.httpMethod,
              let accessMethod = HTTPMethod(rawValue: httpMethodString),
              let baseString = constructBaseString(withBaseUrl: urlString, accessMethod: accessMethod, parameters: parameters)
        else {
            throw OAuth1Error.noBaseString
        }
        
        guard let signature = generateSignature(text: baseString).percentEncoding() else {
            throw OAuth1Error.invalidSignature
        }
        
        parameters["oauth_signature"] = signature
        
        let query = parameters.sorted(by: <).map({ $0 + "=" + "\"\($1)\"" }).joined(separator: ", ")
        if let _ = urlRequest.url?.absoluteString {
            var urlRequest = urlRequest
            urlRequest.setValue("OAuth " + query, forHTTPHeaderField: "Authorization")
            urlRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            return urlRequest
        }
        
        return urlRequest
    }
    
    private func generateParameters() -> Dictionary<String, String> {
        var parameters = Dictionary<String, String>()
        parameters["oauth_version"] = version
        parameters["oauth_consumer_key"] = key
        parameters["oauth_token"] = token
        parameters["oauth_signature_method"] = signatureMethod.rawValue
        parameters["oauth_timestamp"] = generateTimestamp()
        parameters["oauth_nonce"] = generateNonce()
        return parameters
    }
    
    private func generateNonce() -> String {
        return UUID().uuidString.replacingOccurrences(of: "-", with: "")
    }
    
    private func generateTimestamp() -> String {
        return String(Int64(Date().timeIntervalSince1970))
    }
    
    private func generateSignature(text: String) -> String {
        var signature: String
        let key = "\(secret)&\(tokenSecret)"
        switch signatureMethod {
        case .HMAC_SHA1:
            // sign with HMAC-SHA1, https://tools.ietf.org/html/rfc5849#section-3.4.2
            signature = text.hmacsha1(with: key)
        case .PLAINTEXT:
            signature = key
        }
        return signature
    }
    
    // construct Base String, see RFC 5849, https://tools.ietf.org/html/rfc5849#section-3.4.1.1
    private func constructBaseString(withBaseUrl baseUrl: String, accessMethod: HTTPMethod, parameters: [String: String]) -> String? {
        guard let encodedBaseUrl = baseUrl.percentEncoding() else { return nil }
        
        print(encodedBaseUrl)
        
        // [k1: v1, k2: v2, ...] => k1 = v1 & k2 = v2 &...
        let query = parameters.sorted(by: <).map({ $0 + "=" + $1 }).joined(separator: "&")
        guard let encodedQuery = query.percentEncoding() else {
            print("Error: cannot encode \(query)")
            return nil
        }
        
        let baseString = "\(accessMethod.rawValue)&\(encodedBaseUrl)&\(encodedQuery)"
        return baseString
    }
}

extension String {
    // percent encoding, see RFC 5849, https://tools.ietf.org/html/rfc5849#section-3.6
    func percentEncoding() -> String? {
        // encoded as UTF-8 octets
        guard let data = self.data(using: .utf8) else {
            print("Error: cannot get utf8 data with \(self)")
            return nil
        }
        guard let utf8String = String(data: data, encoding: .utf8) else {
            print("Error: cannot convert data data to utf8 string")
            return nil
        }
        
        // escaped using the RFC3986 mechanism, https://tools.ietf.org/html/rfc3986#section-2.3
        // create custom character set, https://stackoverflow.com/a/32527940
        var allowedCharacterSet = CharacterSet
            .alphanumerics
            .union(.decimalDigits)
            
        allowedCharacterSet.insert(charactersIn: "-._~")
        
        return utf8String.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet)
    }
    
    // https://stackoverflow.com/a/48406753/9246748
    func hmacsha1(with key: String) -> String {
        let messageData = self.data(using: .utf8)!
        let keyData = key.data(using: .utf8)!
        let data = Data(HMAC<Insecure.SHA1>.authenticationCode(for: messageData, using: SymmetricKey(data: keyData)))
        return data.base64EncodedString(options: Data.Base64EncodingOptions.lineLength76Characters)
    }
}

