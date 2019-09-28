//
//  PhotoC.swift
//  VirtualTourist
//
//  Created by Mahreen Azam on 9/26/19.
//  Copyright © 2019 Mahreen Azam. All rights reserved.
//

import Foundation

struct PhotoC: Codable {
    let id: String
    let owner: String
    let secret: String
    let server: String
    let farm: Int
    let title: String
    let ispublic: Int
    let isfriend: Int
    let isfamily: Int
}
