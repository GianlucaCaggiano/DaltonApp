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

class ViewController: UIViewController,UIImagePickerControllerDelegate, UINavigationControllerDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var barra: UIView!
    @IBOutlet weak var flashImg: UIButton!
    
    
    
    var captureDevice:AVCaptureDevice!
    let captureSession = AVCaptureSession()
    var previewLayer:CALayer!
    var takePhoto = false
    var frontCamera: Bool = false
    var flashEnabled: Bool = false

    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        prepareCamera()
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
    
}

