//
//  PhotoViewController.swift
//  DaltonApp
//
//  Created by Gianluca Caggiano on 24/01/2017.
//  Copyright © 2017 Gianluca Caggiano. All rights reserved.
//

import UIKit
import JavaScriptCore

class PhotoViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate  {
    
    var takenPhoto:UIImage?
    let viewCont = ViewController()
    
    var imagePicker: UIImagePickerController!
    
    
    @IBOutlet weak var colorLabel: UILabel!
    @IBOutlet weak var hexLabel: UILabel!
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var colorFamily: UILabel!
    
    
    var size: CGFloat = 50
    var jsContext: JSContext!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.imageView.isUserInteractionEnabled = true
        self.initializeJS()
        
        if let availableImage = takenPhoto {
            imageView.image = availableImage
            imageView.contentMode = .scaleToFill
        }
        label.isHidden = true
        // You can also manually set it through IB
        // selecting the UIImageView in the storyboard
        // and checking "User Interaction Enabled" checkbox
        // in the Attributes Inspector panel.
    }
    
    
    
    @IBAction func goBack(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    // Restituire il colore del pixel che viene toccato
    func getPixelColorAtPoint(point:CGPoint, sourceView: UIView) {
        let pixel = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: 4)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        let context = CGContext(data: pixel, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)
        
        context!.translateBy(x: -point.x, y: -point.y)
        sourceView.layer.render(in: context!)
        let color:UIColor = UIColor(red: CGFloat(pixel[0])/255.0,
                                    green: CGFloat(pixel[1])/255.0,
                                    blue: CGFloat(pixel[2])/255.0,
                                    alpha: CGFloat(pixel[3])/255.0)
        pixel.deallocate(capacity: 4)
        
        //calcola colore label
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        let rgb:Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0
        if(rgb < 8421504)
        {
            hexLabel.textColor = UIColor.white
            colorLabel.textColor = UIColor.white
        }
        else{
            hexLabel.textColor = UIColor.black
            colorLabel.textColor = UIColor.black
        }
        
        cameraView.backgroundColor = color
        hexLabel.text = toHexString(color: color)
        colorLabel.text = whichColor(color: color)
    }
    
    
    func whichColor(color: UIColor) -> String{
        
        let colori = toHexString(color: color)
        var nome: String = "Bello"
        
        if let functionFullname = self.jsContext.objectForKeyedSubscript("nomi") {
            // Call the function that composes the fullname.
            if let fullname = functionFullname.call(withArguments: [colori]) {
                nome=fullname.toString()
                
            }
        }
        return nome
    }
    
    
    
    
    
    // inizia il tocco
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first!
        let location = touch.location(in: imageView.self)
        
        //let size = CGSize(width: 50, height: 50)
        size = 50
        if(location.y > 20){
        label.frame = CGRect(x: location.x - (size / 2), y: location.y + (size / 2), width: size, height: size)
        //label.frame = CGRect(origin: location, size: size)
        
        label.layer.borderColor = UIColor.black.cgColor
        label.layer.borderWidth = 4
        label.layer.cornerRadius = label.frame.size.width / 2
        label.layer.backgroundColor = UIColor(white: 1, alpha: 0.5).cgColor
        
        getPixelColorAtPoint(point: location, sourceView: imageView)
        label.isHidden = false
        }
    }
    
    
    
    func toHexString(color: UIColor) -> String {
        var r:CGFloat = 0
        var g:CGFloat = 0
        var b:CGFloat = 0
        var a:CGFloat = 0
        
        //getRed()
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let rgb:Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0
        
        return NSString(format:"#%06x", rgb) as String
    }
    
    
    @IBAction func save(_ sender: UIButton) {
        
        
        UIImageWriteToSavedPhotosAlbum(imageView.image!, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
        
    }
    
    func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            // we got back an error!
            let ac = UIAlertController(title: "Save error", message: error.localizedDescription, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        } else {
            let ac = UIAlertController(title: "Saved!", message: "Your image has been saved to your photos.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            dismiss(animated: true, completion: nil)
        }
    }
    
    //MARK: - Done image capture here
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        imagePicker.dismiss(animated: true, completion: nil)
        imageView.image = info[UIImagePickerControllerOriginalImage] as? UIImage
    }
    func initializeJS() {
        self.jsContext = JSContext()
        
        if let jsSourcePath = Bundle.main.path(forResource: "ntc", ofType: "js") {
            do {
                // Load its contents to a String variable.
                let jsSourceContents = try String(contentsOfFile: jsSourcePath)
                
                // Add the Javascript code that currently exists in the jsSourceContents to the Javascript Runtime through the jsContext object.
                self.jsContext.evaluateScript(jsSourceContents)
            }
            catch {
                print(error.localizedDescription)
            }
        }
        
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
