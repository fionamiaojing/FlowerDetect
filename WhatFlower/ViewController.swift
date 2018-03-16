//
//  ViewController.swift
//  WhatFlower
//
//  Created by Fiona Miao on 3/16/18.
//  Copyright © 2018 Fiona Miao. All rights reserved.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage


class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textLabel: UILabel!
    
    var imagePicker = UIImagePickerController()
    
    let wikipediaURl = "https://en.wikipedia.org/w/api.php"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = true
        textLabel.lineBreakMode = .byWordWrapping
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let userPickedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            
            guard let ciimage = CIImage(image: userPickedImage) else {
                fatalError("Error converting userPickedImage into CIImage")
            }
            
            detect(image: ciimage)
        }
        
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    func detect(image: CIImage) {
        
        //For:xxx - refer to FlowerClassifier.mlmodel line 71&71, class FlowerClassifier var model
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {
            fatalError("import coreML Model failed")
        }
        
        let request = VNCoreMLRequest(model: model, completionHandler: { (request, error) in
            
            guard let result = request.results?.first as? VNClassificationObservation else {
                fatalError("can not get classification")
            }
            self.navigationItem.title = result.identifier.capitalized
            
            self.getWikiData(result.identifier)
        })
        
        let handler = VNImageRequestHandler(ciImage: image)
        do {
            try handler.perform([request])
        } catch {
            print("error classify image")
        }
        
    }
    
    func getWikiData(_ flowerName: String) {
        
        let parameters : [String:String] = [
            "format" : "json",
            "action" : "query",
            "prop" : "extracts|pageimages",
            "exintro" : "",
            "explaintext" : "",
            "titles" : flowerName,
            "indexpageids" : "",
            "redirects" : "1",
            "pithumbsize" : "500"
            ]
        
        Alamofire.request(wikipediaURl, method: .get, parameters: parameters).responseJSON { (response) in
            if response.result.isSuccess {
                
                print(JSON(response.result.value))
                let resultJSON = JSON(response.result.value!)
                
                let pageid = resultJSON["query"]["pageids"][0].stringValue
                
                let description = resultJSON["query"]["pages"][pageid]["extract"]
                
                let flowerImageURL = resultJSON["query"]["pages"][pageid]["thumbnail"]["source"].stringValue
                
                self.textLabel.text = description.stringValue
                self.imageView.sd_setImage(with: URL(string: flowerImageURL))
                
            } else {
                print("Error \(String(describing: response.result.error))")
            }
        }
        
    }
    
    
    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    
}

