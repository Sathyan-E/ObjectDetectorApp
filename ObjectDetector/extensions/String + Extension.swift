//
//  String + Extension.swift
//  ObjectDetector
//
//  Created by sathyan elangovan on 09/03/24.
//

import Foundation

import UIKit

extension String {

  func size(usingFont font: UIFont) -> CGSize {
    let attributedString = NSAttributedString(string: self, attributes: [NSAttributedString.Key.font : font])
    return attributedString.size()
  }

}

