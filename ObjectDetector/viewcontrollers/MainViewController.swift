//
//  MainViewController.swift
//  ObjectDetector
//
//  Created by sathyan elangovan on 09/03/24.
//

import UIKit

class MainViewController: UIViewController {
    
    @IBOutlet weak var btnOpenPhotos: UIButton!
    let imageInfoKey = UIImagePickerController.InfoKey(rawValue: "UIImagePickerControllerOriginalImage")
    let activityIndicator = UIActivityIndicatorView(style: .large)

    override func viewDidLoad() {
        super.viewDidLoad()
        btnOpenPhotos.addTarget(self, action: #selector(openPhotos), for: .touchUpInside)
        activityIndicator.center = CGPoint(x: view.bounds.size.width/2, y: view.bounds.size.height/2)
        activityIndicator.color = UIColor.darkGray
        view.addSubview(activityIndicator)

    }
    
    func showActivityIndicator() {
        activityIndicator.startAnimating()
    }
    
    func hideActivityIndicator() {
        activityIndicator.stopAnimating()
    }
    

    @objc func openPhotos(sender: UIButton) {
        showActivityIndicator()
        let photosPickerVC = UIImagePickerController()
        photosPickerVC.sourceType = .photoLibrary
        photosPickerVC.delegate = self
        present(photosPickerVC, animated: true)
    }
}

extension MainViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        hideActivityIndicator()
        guard let image = info[imageInfoKey] as? UIImage else {
            showAlert(title: "Failure", message: "Failed to extract the selected image!!.")
            return
        }
        navigateToDetectorVC(image: image)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        hideActivityIndicator()
        picker.dismiss(animated: true)
    }
    
    func navigateToDetectorVC(image: UIImage) {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        
        guard let vc : SecondViewController = mainStoryboard.instantiateViewController(withIdentifier: "secondviewcontroller") as? SecondViewController else {
            showAlert(title: "Navigation Failure", message: "Couldn't navigate to next screen!!.")
            return
        }
        vc.selectedImage = image
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

extension UIViewController {
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}
