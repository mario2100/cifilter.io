//
//  FilterExampleProvider.swift
//  CIFilter.io
//
//  Created by Noah Gilmore on 12/8/18.
//  Copyright © 2018 Noah Gilmore. All rights reserved.
//

import Foundation

enum FilterExampleState {
    case available
    case notAvailable(reason: String)

    var isAvailable: Bool {
        switch self {
        case .available: return true
        default: return false
        }
    }
}

// TODO: Rename this class, it doesn't provide examples of filters
final class FilterExampleProvider {
    func state(forFilterName filterName: String) -> FilterExampleState {
        switch filterName {
        case "CIDepthBlurEffect":
            return .notAvailable(reason: "CIFilter.io does not currently support capturing depth and camera calibration data.")
        default:
            return .available
        }
    }
}
