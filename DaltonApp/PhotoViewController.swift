//
//  PhotoViewController.swift
//  DaltonApp
//
//  Created by Gianluca Caggiano on 24/01/2017.
//  Copyright © 2017 Gianluca Caggiano. All rights reserved.
//

import UIKit

class PhotoViewController: UIViewController  {

    var takenPhoto:UIImage?
    let viewCont = ViewController()
    
    
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var colorFamily: UILabel!
    
    var size: CGFloat = 50
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.imageView.isUserInteractionEnabled = true

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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
        
        cameraView.backgroundColor = color
        print(toHexString(color: color))
        colorFamily.text = whichColor(color: color)

    }
    
    func whichColor(color: UIColor) -> String{
        var (h,s,b,a) : (CGFloat, CGFloat, CGFloat, CGFloat) = (0,0,0,0)
        _ = color.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        
        // print("HSB range- h: \(h), s: \(s), v: \(b)")
        
        var colorTitle = ""
        
        switch (h, s, b) {
            
        // red
        case (0...0.138, 0.88...1.00, 0.75...1.00):
            colorTitle = "red"
        // yellow
        case (0.139...0.175, 0.30...1.00, 0.80...1.00):
            colorTitle = "yellow"
        // green
        case (0.176...0.422, 0.30...1.00, 0.60...1.00):
            colorTitle = "green"
        // teal
        case (0.423...0.494, 0.30...1.00, 0.54...1.00):
            colorTitle = "teal"
        // blue
        case (0.495...0.667, 0.30...1.00, 0.60...1.00):
            colorTitle = "blue"
        // purple
        case (0.668...0.792, 0.30...1.00, 0.40...1.00):
            colorTitle = "purple"
        // pink
        case (0.793...0.977, 0.30...1.00, 0.80...1.00):
            colorTitle = "pink"
        // brown
        case (0...0.097, 0.50...1.00, 0.25...0.58):
            colorTitle = "brown"
        // white
        case (0...1.00, 0...0.05, 0.95...1.00):
            colorTitle = "white"
        // grey
        case (0...1.00, 0, 0.25...0.94):
            colorTitle = "grey"
        // black
        case (0...1.00, 0...1.00, 0...0.07):
            colorTitle = "black"
        default:
            colorTitle = "Color didn't fit defined ranges..."
        }
        
        return colorTitle
    }

    
    
    //appena inizia il tocco
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first!
        let location = touch.location(in: imageView.self)
        
        //let size = CGSize(width: 50, height: 50)
        size = 50
        label.frame = CGRect(x: location.x - (size / 2), y: location.y + (size / 2), width: size, height: size)
        //label.frame = CGRect(origin: location, size: size)
        
        label.layer.borderColor = UIColor.black.cgColor
        label.layer.borderWidth = 4
        label.layer.cornerRadius = label.frame.size.width / 2
        label.layer.backgroundColor = UIColor(white: 1, alpha: 0.5).cgColor
        
        getPixelColorAtPoint(point: location, sourceView: imageView)
        label.isHidden = false
        
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
 
    

    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
