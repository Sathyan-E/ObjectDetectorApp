//
//  ObjectDetectorViewController.swift
//  ObjectDetector
//
//  Created by sathyan elangovan on 09/03/24.
//

import UIKit

enum DataModel {
  static let modelInfo: MyFileInfo = (name: "detect", extension: "tflite")
    static let labelInfo: MyFileInfo = (name: "labelmap", extension: "txt")
}

class SecondViewController: UIViewController {

    @IBOutlet weak var ivPreview: UIImageView!
    @IBOutlet weak var ivDetected: UIImageView!
    @IBOutlet weak var overlayView: MyOverlayView!
    @IBOutlet weak var lblDetectedimage: UILabel!
    
    public var selectedImage: UIImage?
    
    // MARK: Constants
    private let displayFont = UIFont.systemFont(ofSize: 12.0, weight: .medium)
    private let edgeOffset: CGFloat = 2.0
    private let labelOffset: CGFloat = 10.0
    private let delayBetweenInferencesMs: Double = 200

    
    private var modelDataHandler: MyModelDataHandler? =
    MyModelDataHandler(modelFileInfo: DataModel.modelInfo, labelFileInfo: DataModel.labelInfo)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        guard let image = selectedImage else {
            showAlert(title: "Sorry😞!!", message: "Couldn't fetch selected image")
            return
        }
        ivPreview.image = image
        processImage()
    }
    
    func processImage() {
        guard let iv = ivPreview.image, let pixelBuffer = iv.pixelBuffer() else {
            showAlert(title: "Sorry😞!!", message: "Couldn't detect the objects in the selected image.")
            return
        }
                
        guard let inferences = self.modelDataHandler?.runModel(onFrame: pixelBuffer) else {
            showAlert(title: "Sorry😞!!", message: "Couldn't detect the objects in selected image.")
            return
        }
         
        guard !inferences.isEmpty else {
            showAlert(title: "Sorry😞!!", message: "Couldn't detect the objects in selected image.")
            return
        }
        
        guard let image = selectedImage else {
            return
        }
        
        lblDetectedimage.isHidden = false
        ivDetected.image = image

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)

        DispatchQueue.main.async {
        // Draws the bounding boxes and displays class names and confidence scores.
            self.drawAfterPerformingCalculations(onInferences: inferences, withImageSize: CGSize(width: CGFloat(width),   height: CGFloat(height)))
        }
    }
    
    
    /**
     This method takes the results, translates the bounding box rects to the current view, draws the bounding boxes, classNames and confidence scores of inferences.
     */
    func drawAfterPerformingCalculations(onInferences inferences: [Inference], withImageSize imageSize:CGSize) {

      self.overlayView.objectOverlays = []
      self.overlayView.setNeedsDisplay()

      var objectOverlays: [ObjectOverlay] = []

      for inference in inferences {

        // Translates bounding box rect to current view.
        var convertedRect = inference.rect.applying(CGAffineTransform(scaleX: self.overlayView.bounds.size.width / imageSize.width, y: self.overlayView.bounds.size.height / imageSize.height))

        if convertedRect.origin.x < 0 {
          convertedRect.origin.x = self.edgeOffset
        }

        if convertedRect.origin.y < 0 {
          convertedRect.origin.y = self.edgeOffset
        }

        if convertedRect.maxY > self.overlayView.bounds.maxY {
          convertedRect.size.height = self.overlayView.bounds.maxY - convertedRect.origin.y - self.edgeOffset
        }

        if convertedRect.maxX > self.overlayView.bounds.maxX {
          convertedRect.size.width = self.overlayView.bounds.maxX - convertedRect.origin.x - self.edgeOffset
        }

        let confidenceValue = Int(inference.confidence * 100.0)
        let string = "\(inference.className)  (\(confidenceValue)%)"

        let size = string.size(usingFont: self.displayFont)

        let objectOverlay = ObjectOverlay(name: string, borderRect: convertedRect, nameStringSize: size, color: inference.displayColor, font: self.displayFont)

        objectOverlays.append(objectOverlay)
      }

      // Hands off drawing to the OverlayView
      self.draw(objectOverlays: objectOverlays)

    }

    /** Calls methods to update overlay view with detected bounding boxes and class names.
     */
    func draw(objectOverlays: [ObjectOverlay]) {
      self.overlayView.objectOverlays = objectOverlays
      self.overlayView.setNeedsDisplay()
    }

}

