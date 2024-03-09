//
//  UIImage + Extension.swift
//  ObjectDetector
//
//  Created by sathyan elangovan on 09/03/24.
//

import Foundation
import UIKit

extension UIImage {
    
    func pixelBuffer() -> CVPixelBuffer? {
      
      let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
      
      var pixelBuffer : CVPixelBuffer?
      let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(self.size.width), Int(self.size.height), kCVPixelFormatType_32BGRA, attrs, &pixelBuffer)
      guard (status == kCVReturnSuccess) else {
        return nil
      }
      
      CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
      let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
      
      let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
      
      let context = CGContext(data: pixelData, width: Int(self.size.width), height: Int(self.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
      
      // Translates the origin to bottom left before drawing the UIImage to pixel buffer, since Core Graphics expects origin to be at bottom left as opposed to top left expected by UIKit.
      context?.translateBy(x: 0, y: self.size.height)
      context?.scaleBy(x: 1.0, y: -1.0)
      
      // Draws the UIImage in the context to extract the CVPixelBuffer
      UIGraphicsPushContext(context!)
      self.draw(in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
      UIGraphicsPopContext()
      CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
      
      return pixelBuffer
    }
    
}
