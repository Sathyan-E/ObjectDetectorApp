//
//  MyOverlayView.swift
//  ObjectDetector
//
//  Created by sathyan elangovan on 09/03/24.
//

import Foundation
import UIKit

struct ObjectOverlay {
  let name: String
  let borderRect: CGRect
  let nameStringSize: CGSize
  let color: UIColor
  let font: UIFont
}

class MyOverlayView: UIView {

  var objectOverlays: [ObjectOverlay] = []
  private let cornerRadius: CGFloat = 10.0
  private let stringBgAlpha: CGFloat
    = 0.7
  private let lineWidth: CGFloat = 1
  private let stringFontColor = UIColor.white
 
  override func draw(_ rect: CGRect) {
    for objectOverlay in objectOverlays {
      drawBorders(of: objectOverlay)
      drawName(of: objectOverlay)
    }
  }

  func drawBorders(of objectOverlay: ObjectOverlay) {
    let path = UIBezierPath(rect: objectOverlay.borderRect)
    path.lineWidth = lineWidth
    objectOverlay.color.setStroke()
    path.stroke()
  }

  func drawName(of objectOverlay: ObjectOverlay) {

    // Draws the string.
      let stringRect = CGRect(x: objectOverlay.borderRect.origin.x + 5.0, y: objectOverlay.borderRect.origin.y - 15.0, width: objectOverlay.nameStringSize.width, height: objectOverlay.nameStringSize.height)

    let attributedString = NSAttributedString(string: objectOverlay.name, attributes: [NSAttributedString.Key.foregroundColor : stringFontColor, NSAttributedString.Key.font : objectOverlay.font])
    attributedString.draw(in: stringRect)
  }

}
