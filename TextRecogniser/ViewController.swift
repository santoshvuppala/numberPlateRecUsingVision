//
//  ViewController.swift
//  TextRecogniser
//
//  Created by santosh vuppala on 02/04/20.
//  Copyright © 2020 santosh vuppala. All rights reserved.
//

import UIKit
import Vision
import MobileCoreServices

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var resultLabel: UILabel!
    let imagePickerController = UIImagePickerController()
    var objectBounds = CGRect()
    
    @IBAction func takePhotBtn(_ sender: UIButton) {
               imagePickerController.mediaTypes = [kUTTypeImage as String]
               imagePickerController.sourceType = .photoLibrary
               imagePickerController.allowsEditing = false
        present(imagePickerController, animated: true, completion: nil)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        imagePickerController.delegate = self

    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let capturedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage{
        // Set image on ImageView
            imageView.contentMode = .scaleAspectFit
            imageView.image = capturedImage
            // Start vision task
            self.textRecognition(image:(imageView.image?.cgImage)!)
        }
        
        dismiss(animated: true, completion: nil)
    }
    func textRecognition(image:CGImage){
        // 1. Request
        let textRecognitionRequest = VNRecognizeTextRequest(completionHandler: self.handleDetectedText)
        textRecognitionRequest.recognitionLevel = .accurate
        textRecognitionRequest.recognitionLanguages = ["en_US"]
        textRecognitionRequest.usesLanguageCorrection = false
        textRecognitionRequest.customWords = ["HR26DK8337", "TN09EF8790", "MH12FE8999", "TS07EW9812"]

        // 2. Request Handler
        let textRequest = [textRecognitionRequest]
        let imageRequestHandler = VNImageRequestHandler(cgImage: image, orientation: .up, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // 3. Perform request
                try imageRequestHandler.perform(textRequest)
            } catch let error {
                print("Error: \(error)")
            }
        }
        
    }

    func handleDetectedText(request: VNRequest?, error:Error?){
        if let error = error {
            print("ERROR: \(error)")
            return
        }
        guard let results = request?.results, results.count > 0 else {
            print("No Text recognized in the given Image")
            return
        }
        for result in results {
            if let observation = result as? VNRecognizedTextObservation {
                for text in observation.topCandidates(1){
                    // Draw bounding box on the image
                   // print(observation.boundingBox)
                    DispatchQueue.main.async {
                        do {
                            var t:CGAffineTransform = CGAffineTransform.identity;
                            t = t.scaledBy( x: self.imageView.image!.size.width, y: -self.imageView.image!.size.height);
                            t = t.translatedBy(x: 0, y: -1 );
                            self.objectBounds = observation.boundingBox.applying(t)
                            let newString = text.string.replacingOccurrences(of: " ", with: "")
                            // print(newString)
                            let pattern = "[A-Z]{2}[A-Za-z0-9_]{2}[A-Z]{2}[0-9]{4}"
                            let resultOfRegEx = newString.range(of: pattern, options: .regularExpression)
                            if((resultOfRegEx) != nil){
                            let imageWithBoundingBox =  self.drawRectangleOnImage(image: self.imageView.image!, x: Double(self.objectBounds.minX), y: Double(self.objectBounds.minY), width: Double(self.objectBounds.width), height: Double(self.objectBounds.height))
                            self.imageView.image = imageWithBoundingBox
                                self.resultLabel.text = text.string
                            }
                        }
                    
                    }
                   
                }
            }
        }
        
    }
    
    func drawRectangleOnImage(image: UIImage, x:Double, y:Double, width:Double, height:Double) -> UIImage{
        let imageSize = image.size
        let scale:CGFloat = 0
        UIGraphicsBeginImageContextWithOptions(imageSize, false, scale)
        let context = UIGraphicsGetCurrentContext()
        image.draw(at: CGPoint.zero)
        let rectangelTodraw = CGRect(x:x, y:y, width:width, height:height)
        
        context?.setStrokeColor(UIColor.red.cgColor)
        context?.setLineWidth(5.0)
        context?.addRect(rectangelTodraw)
        context?.drawPath(using: .stroke)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
    
    

}

