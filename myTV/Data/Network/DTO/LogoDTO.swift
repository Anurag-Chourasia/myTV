//
//  LogoDTO.swift
//  myTV
//
//  Created by Anurag Chourasia on 23/01/26.
//

enum LogoFormat: Codable, Equatable {
    case png
    case jpeg
    case svg
    case unknown(String)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self).uppercased()

        switch value {
        case "PNG": self = .png
        case "JPEG", "JPG": self = .jpeg
        case "SVG": self = .svg
        default: self = .unknown(value)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .png: try container.encode("PNG")
        case .jpeg: try container.encode("JPEG")
        case .svg: try container.encode("SVG")
        case .unknown(let value): try container.encode(value)
        }
    }
}

struct LogoDTO: Codable {
    let channel: String
    let feed: String?
    let tags: [String]
    let width: Double
    let height: Double
    let format: LogoFormat?
    let url: String?
}
