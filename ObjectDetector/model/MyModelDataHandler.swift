//
//  MyModelDataHandler.swift
//  ObjectDetector
//
//  Created by sathyan elangovan on 09/03/24.
//

import Foundation
import UIKit
import TensorFlowLite
import CoreImage

typealias MyFileInfo = (name: String, extension: String)

struct Inference {
  let confidence: Float
  let className: String
  let rect: CGRect
  let displayColor: UIColor
}


class MyModelDataHandler {
    
    // MARK: - Model Parameters
    let batchSize = 1
    let inputChannels = 3
    let inputWidth = 300
    let inputHeight = 300
    let threadCount: Int
    let threshold: Float = 0.5
    
    
    // MARK: Private properties
    private var labels: [String] = []
    /// TensorFlow Lite `Interpreter` object for performing inference on a given model.
    private var interpreter: Interpreter
    private let bgraPixel = (channels: 4, alphaComponent: 3, lastBgrComponent: 2)
    private let rgbPixelChannels = 3
    private let colorStrideValue = 10
    
    /// Information about the alpha component in RGBA data.
    private let alphaComponent = (baseOffset: 4, moduloRemainder: 3)
    
    private let colors = [
      UIColor.red,
      UIColor(displayP3Red: 90.0/255.0, green: 200.0/255.0, blue: 250.0/255.0, alpha: 1.0),
      UIColor.green,
      UIColor.orange,
      UIColor.blue,
      UIColor.purple,
      UIColor.magenta,
      UIColor.yellow,
      UIColor.cyan,
      UIColor.brown
    ]
    
    init?(modelFileInfo: MyFileInfo, labelFileInfo: MyFileInfo, threadCount: Int = 1) {
      let modelFilename = modelFileInfo.name
      
      // Construct the path to the model file.
      guard let modelPath = Bundle.main.path(
        forResource: modelFilename,
        ofType: modelFileInfo.extension
        ) else {
          print("Failed to load the model file with name: \(modelFilename).")
          return nil
      }
      
      // Specify the options for the `Interpreter`.
      self.threadCount = threadCount
        var options = Interpreter.Options()
      options.threadCount = threadCount
      do {
        // Create the `Interpreter`.
        interpreter = try Interpreter(modelPath: modelPath, options: options)
      } catch let error {
        print("Failed to create the interpreter with error: \(error.localizedDescription)")
        return nil
      }
     loadLabels(fileInfo: labelFileInfo)
    }
    
    /// Filters out all the results with confidence score < threshold and returns the top N results
    /// sorted in descending order.
    func formatResults(boundingBox: [Float], outputClasses: [Float], outputScores: [Float], outputCount: Int, width: CGFloat, height: CGFloat) -> [Inference]{
      var resultsArray: [Inference] = []
      
      for i in 0..<outputCount {

        let score = outputScores[i]

        // Filters results with confidence < threshold.
        guard score >= threshold else {
          continue
        }

        // Gets the output class names for detected classes from labels list.
        let outputClassIndex = Int(outputClasses[i])
        let outputClass = labels[outputClassIndex + 1]

        var rect: CGRect = CGRect.zero

        // Translates the detected bounding box to CGRect.
        rect.origin.y = CGFloat(boundingBox[4*i])
        rect.origin.x = CGFloat(boundingBox[4*i+1])
        rect.size.height = CGFloat(boundingBox[4*i+2]) - rect.origin.y
        rect.size.width = CGFloat(boundingBox[4*i+3]) - rect.origin.x

        // The detected corners are for model dimensions. So we scale the rect with respect to the
        // actual image dimensions.
        let newRect = rect.applying(CGAffineTransform(scaleX: width, y: height))

        // Gets the color assigned for the class
        let colorToAssign = colorForClass(withIndex: outputClassIndex + 1)
        let inference = Inference(confidence: score,
                                  className: outputClass,
                                  rect: newRect,
                                  displayColor: colorToAssign)
        resultsArray.append(inference)
      }

      // Sort results in descending order of confidence.
      resultsArray.sort { (first, second) -> Bool in
        return first.confidence  > second.confidence
      }

      return resultsArray
    }
    
    
    
    /// This class handles all data preprocessing and makes calls to run inference on a given frame
    /// through the `Interpeter`. It then formats the inferences obtained and returns the top N
    /// results for a successful inference.
    func runModel(onFrame pixelBuffer: CVPixelBuffer) -> [Inference]? {
      let imageWidth = CVPixelBufferGetWidth(pixelBuffer)
      let imageHeight = CVPixelBufferGetHeight(pixelBuffer)
      let sourcePixelFormat = CVPixelBufferGetPixelFormatType(pixelBuffer)
      assert(sourcePixelFormat == kCVPixelFormatType_32ARGB ||
               sourcePixelFormat == kCVPixelFormatType_32BGRA ||
                 sourcePixelFormat == kCVPixelFormatType_32RGBA)


      let imageChannels = 4
      assert(imageChannels >= inputChannels)

      // Crops the image to the biggest square in the center and scales it down to model dimensions.
      let scaledSize = CGSize(width: inputWidth, height: inputHeight)
      guard let scaledPixelBuffer = pixelBuffer.resized(to: scaledSize) else {
        return nil
      }

      let outputBoundingBox: Tensor
      let outputClasses: Tensor
      let outputScores: Tensor
      let outputCount: Tensor
      do {
          
          // Allocate memory for the model's input `Tensor`s.
          try interpreter.allocateTensors()
          
        let inputTensor = try interpreter.input(at: 0)

        // Remove the alpha component from the image buffer to get the RGB data.
        guard let rgbData = rgbDataFromBuffer(
          scaledPixelBuffer,
          byteCount: batchSize * inputWidth * inputHeight * inputChannels,
          isModelQuantized: inputTensor.dataType == .uInt8
        ) else {
          print("Failed to convert the image buffer to RGB data.")
          return nil
        }

        // Copy the RGB data to the input `Tensor`.
        try interpreter.copy(rgbData, toInputAt: 0)

        // Run inference by invoking the `Interpreter`.
        let startDate = Date()
        try interpreter.invoke()

        outputBoundingBox = try interpreter.output(at: 0)
        outputClasses = try interpreter.output(at: 1)
        outputScores = try interpreter.output(at: 2)
        outputCount = try interpreter.output(at: 3)
      } catch let error {
        print("Failed to invoke the interpreter with error: \(error.localizedDescription)")
        return nil
      }

      // Formats the results
      let resultArray = formatResults(
        boundingBox: [Float](unsafeData: outputBoundingBox.data) ?? [],
        outputClasses: [Float](unsafeData: outputClasses.data) ?? [],
        outputScores: [Float](unsafeData: outputScores.data) ?? [],
        outputCount: Int(([Float](unsafeData: outputCount.data) ?? [0])[0]),
        width: CGFloat(imageWidth),
        height: CGFloat(imageHeight)
      )

      return resultArray
    }

    
    /// Loads the labels from the labels file and stores them in the `labels` property.
    private func loadLabels(fileInfo: MyFileInfo) {
      let filename = fileInfo.name
      let fileExtension = fileInfo.extension
      guard let fileURL = Bundle.main.url(forResource: filename, withExtension: fileExtension) else {
        fatalError("Labels file not found in bundle. Please add a labels file with name " +
                     "\(filename).\(fileExtension) and try again.")
      }
      do {
        let contents = try String(contentsOf: fileURL, encoding: .utf8)
        labels = contents.components(separatedBy: .newlines)
      } catch {
        fatalError("Labels file named \(filename).\(fileExtension) cannot be read. Please add a " +
                     "valid labels file and try again.")
      }
    }
    
    
    /// This assigns color for a particular class.
    private func colorForClass(withIndex index: Int) -> UIColor {

      // We have a set of colors and the depending upon a stride, it assigns variations to of the base
      // colors to each object based on its index.
      let baseColor = colors[index % colors.count]

      var colorToAssign = baseColor

      let percentage = CGFloat((colorStrideValue / 2 - index / colors.count) * colorStrideValue)

      if let modifiedColor = baseColor.getModified(byPercentage: percentage) {
        colorToAssign = modifiedColor
      }

      return colorToAssign
    }
    
    private func rgbDataFromBuffer(
      _ buffer: CVPixelBuffer,
      byteCount: Int,
      isModelQuantized: Bool
    ) -> Data? {
      CVPixelBufferLockBaseAddress(buffer, .readOnly)
      defer { CVPixelBufferUnlockBaseAddress(buffer, .readOnly) }
      guard let mutableRawPointer = CVPixelBufferGetBaseAddress(buffer) else {
        return nil
      }
      assert(CVPixelBufferGetPixelFormatType(buffer) == kCVPixelFormatType_32BGRA)
      let count = CVPixelBufferGetDataSize(buffer)
      let bufferData = Data(bytesNoCopy: mutableRawPointer, count: count, deallocator: .none)
      var rgbBytes = [UInt8](repeating: 0, count: byteCount)
      var pixelIndex = 0
      for component in bufferData.enumerated() {
        let bgraComponent = component.offset % bgraPixel.channels;
        let isAlphaComponent = bgraComponent == bgraPixel.alphaComponent;
        guard !isAlphaComponent else {
          pixelIndex += 1
          continue
        }
        // Swizzle BGR -> RGB.
        let rgbIndex = pixelIndex * rgbPixelChannels + (bgraPixel.lastBgrComponent - bgraComponent)
        rgbBytes[rgbIndex] = component.element
      }
      if isModelQuantized { return Data(rgbBytes) }
      return Data(copyingBufferOf: rgbBytes.map { Float($0) / 255.0 })
    }

    
}


extension Data {
  /// Creates a new buffer by copying the buffer pointer of the given array.
  ///
  /// - Warning: The given array's element type `T` must be trivial in that it can be copied bit
  ///     for bit with no indirection or reference-counting operations; otherwise, reinterpreting
  ///     data from the resulting buffer has undefined behavior.
  /// - Parameter array: An array with elements of type `T`.
  init<T>(copyingBufferOf array: [T]) {
    self = array.withUnsafeBufferPointer(Data.init)
  }
}


extension Array {
  /// Creates a new array from the bytes of the given unsafe data.
  ///
  /// - Warning: The array's `Element` type must be trivial in that it can be copied bit for bit
  ///     with no indirection or reference-counting operations; otherwise, copying the raw bytes in
  ///     the `unsafeData`'s buffer to a new array returns an unsafe copy.
  /// - Note: Returns `nil` if `unsafeData.count` is not a multiple of
  ///     `MemoryLayout<Element>.stride`.
  /// - Parameter unsafeData: The data containing the bytes to turn into an array.
  init?(unsafeData: Data) {
    guard unsafeData.count % MemoryLayout<Element>.stride == 0 else { return nil }
    #if swift(>=5.0)
    self = unsafeData.withUnsafeBytes { .init($0.bindMemory(to: Element.self)) }
    #else
    self = unsafeData.withUnsafeBytes {
      .init(UnsafeBufferPointer<Element>(
        start: $0,
        count: unsafeData.count / MemoryLayout<Element>.stride
      ))
    }
    #endif  // swift(>=5.0)
  }
}
