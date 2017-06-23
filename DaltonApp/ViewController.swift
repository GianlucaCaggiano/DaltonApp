//
//  ViewController.swift
//  DaltonApp
//
//  Created by Gianluca Caggiano on 24/01/2017.
//  Copyright © 2017 Gianluca Caggiano. All rights reserved.
//

import UIKit
import AVFoundation
import MobileCoreServices
import JavaScriptCore

class ViewController: UIViewController,UIImagePickerControllerDelegate, UINavigationControllerDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var barra: UIView!
    @IBOutlet weak var flashImg: UIButton!
    @IBOutlet weak var label: UILabel!
    
    @IBOutlet weak var hexLabel: UILabel!
    @IBOutlet weak var colorLabel: UILabel!
    
    var photoViewCont: PhotoViewController!
    
    var jsContext: JSContext!
    
    var size: CGFloat = 50
    
    var captureDevice:AVCaptureDevice!
    let captureSession = AVCaptureSession()
    var previewLayer:CALayer!
    var takePhoto = false
    var frontCamera: Bool = false
    var flashEnabled: Bool = false
    let context = CIContext()
    
    
    var timer = Timer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scheduledTimerWithTimeInterval() ////
        self.initializeJS()
        
    }
    
    func scheduledTimerWithTimeInterval(){
        // Scheduling timer to Call the function **Countdown** with the interval of 1 seconds
        timer = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(self.updateFrame), userInfo: nil, repeats: true)
    }
    
    ////
    func updateFrame(){
        //PIXEL CENTRALE
        let point : CGPoint = CGPoint(x: view.center.x - (size / 2 - 20), y: view.center.y - (size / 2 + 50 ))
        //FUNZIONE DA ESEGUIRE
        getPixelColorAtPoint(point: point, sourceView: imageView)
        
    }
    //////
    
    
    private func imageFromSampleBuffer(sampleBuffer: CMSampleBuffer) -> UIImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
    
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
        
        barra.backgroundColor = color
        
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
        
        hexLabel.text = toHexString(color: color)
        colorLabel.text = whichColor(color: color)
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
    
    
    
    /////
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        prepareCamera()
        size = 50
        label.frame = CGRect(x: view.center.x - (size / 2), y: view.center.y - (size / 2) , width: size, height: size)
        
        label.layer.borderColor = UIColor.black.cgColor
        label.layer.borderWidth = 4
        label.layer.cornerRadius = label.frame.size.width / 2
        label.layer.backgroundColor = UIColor(white: 1, alpha: 0.5).cgColor
        
        label.isHidden = false
        
        
    }
    
    //prepara la fotocamera
    func prepareCamera() {
        captureSession.sessionPreset = AVCaptureSessionPreset1280x720
        frontCamera = true
        initCamera()
    }
    
    //cambia camera
    @IBAction func setCamera(_ sender: Any) {
        initCamera()
    }
    
    func initCamera() {
        stopCaptureSession()
        if (frontCamera == false) {
            if let availableDevices = AVCaptureDeviceDiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaTypeVideo, position: .front).devices {
                frontCamera = true;
                flashImg.isHidden = true
                captureDevice = availableDevices.first
                beginSession()
            }
        }
        else {
            if let availableDevices = AVCaptureDeviceDiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaTypeVideo, position: .back).devices {
                flashImg.isHidden = false
                frontCamera = false;
                captureDevice = availableDevices.first
                beginSession()
            }
        }
    }
    
    func beginSession () {
        do {
            let captureDeviceInput = try AVCaptureDeviceInput(device: captureDevice)
            
            captureSession.addInput(captureDeviceInput)
            
        }catch {
            print(error.localizedDescription)
        }
        
        
        if let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession) {
            previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
            self.previewLayer = previewLayer
            self.cameraView.layer.addSublayer(self.previewLayer)
            self.previewLayer.frame = self.cameraView.layer.frame
            captureSession.startRunning()
            
            let dataOutput = AVCaptureVideoDataOutput()
            dataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString):NSNumber(value:kCVPixelFormatType_32BGRA)]
            
            dataOutput.alwaysDiscardsLateVideoFrames = true
            
            if captureSession.canAddOutput(dataOutput) {
                captureSession.addOutput(dataOutput)
            }
            
            captureSession.commitConfiguration()
            
            
            let queue = DispatchQueue(label: "com.brianadvent.captureQueue")
            dataOutput.setSampleBufferDelegate(self, queue: queue)
            
            
        }
        
    }
    
    //fa la foto
    @IBAction func takePhoto(_ sender: Any) {
        takePhoto = true
    }
    
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        if takePhoto {
            takePhoto = false
            
            if let image = self.getImageFromSampleBuffer(buffer: sampleBuffer) {
                
                let photoVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "PhotoVC") as! PhotoViewController
                
                photoVC.takenPhoto = image
                
                DispatchQueue.main.async {
                    self.present(photoVC, animated: true, completion: {
                        self.stopCaptureSession()
                    })
                }
            }
        }
        else {
            if let image = self.getImageFromSampleBuffer(buffer: sampleBuffer) {
                imageView.image = image
            }
        }
        
    }
    
    
    func getImageFromSampleBuffer (buffer:CMSampleBuffer) -> UIImage? {
        if let pixelBuffer = CMSampleBufferGetImageBuffer(buffer) {
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            let context = CIContext()
            
            let imageRect = CGRect(x: 0, y: 0, width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer))
            
            if let image = context.createCGImage(ciImage, from: imageRect) {
                return UIImage(cgImage: image, scale: UIScreen.main.scale, orientation: .right)
            }
        }
        
        return nil
    }
    
    func stopCaptureSession () {
        self.captureSession.stopRunning()
        
        if let inputs = captureSession.inputs as? [AVCaptureDeviceInput] {
            for input in inputs {
                self.captureSession.removeInput(input)
            }
        }
        
    }
    
    //attiva il flash alla fotocamera
    @IBAction func activeFlash(_ sender: Any) {
        if captureDevice!.hasTorch {
            do {
                if (flashEnabled == false) {
                    flashImg.setImage(UIImage(named: "icons8-Flash Off-50 (1).png"), for: .normal)
                    try captureDevice.lockForConfiguration()
                    captureDevice!.torchMode =  AVCaptureTorchMode.on
                    captureDevice!.unlockForConfiguration()
                    flashEnabled = true
                }
                else {
                    flashImg.setImage(nil, for: .normal)
                    flashImg.setImage(UIImage(named: "icons8-Flash On-50 (1).png"), for: .normal)
                    try captureDevice.lockForConfiguration()
                    captureDevice!.torchMode =  AVCaptureTorchMode.off
                    captureDevice!.unlockForConfiguration()
                    flashEnabled = false
                }
            }catch{
                
            }
        }
    }
    
    //Apre la galleria
    @IBAction func ImageCameraRoll(_ sender: Any) {
        self.stopCaptureSession()
        
        let ipc = UIImagePickerController()
        ipc.sourceType = .photoLibrary
        ipc.delegate = self
        
        present(ipc, animated: true, completion: nil)
        
    }
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let photoVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "PhotoVC") as! PhotoViewController
        let selectedImage = info[UIImagePickerControllerOriginalImage] as? UIImage
        
        
        photoVC.takenPhoto = selectedImage
        dismiss(animated: true, completion: nil)
        DispatchQueue.main.async {
            self.present(photoVC, animated: true, completion: {
                self.stopCaptureSession()
            })
        }
    }
    
    
    //blocca la rotazione dello schermo per la fotocamera
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.portrait
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
    
    
    
}






