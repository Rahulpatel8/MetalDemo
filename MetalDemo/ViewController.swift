//
//  ViewController.swift
//  MetalDemo
//
//  Created by Sotsys024 on 01/12/18.
//  Copyright © 2018 Sotsys024. All rights reserved.
//

import UIKit
import Metal
import MetalKit

class ViewController: UIViewController {

    @IBOutlet weak var metalView: MTKView!
    @IBOutlet weak var slider: UISlider!
    let metalDevice : MTLDevice = MTLCreateSystemDefaultDevice()!
    var commandQueue : MTLCommandQueue {
        return metalDevice.makeCommandQueue()!
    }
    let contrastFilter = CIFilter(name: "CIColorControls")
    var context : CIContext!
    var image : UIImage! = UIImage(named: "1.jpg")
    var inputImage : CIImage!
    var isSlideing = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        image = image.resizedImageWithinRect(rectSize: UIScreen.main.bounds.size)
        
        inputImage = CIImage(cgImage: image.cgImage!)
        context = CIContext(mtlDevice: metalDevice)
        metalView.device = metalDevice
        metalView.delegate = self
        metalView.enableSetNeedsDisplay = false
        metalView.framebufferOnly = false
        
        isSlideing = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        metalView.frame.size = image.resizedImageWithinRect(rectSize: UIScreen.main.bounds.size).size
        metalView.center = view.center
        
        if image.size.width > image.size.height {
            let scaleFactor = (image.size.width - UIScreen.main.bounds.width * UIScreen.main.scale)/UIScreen.main.bounds.width
            metalView.contentScaleFactor = UIScreen.main.scale + scaleFactor
        } else {
            let scaleFactor = (image.size.height - UIScreen.main.bounds.height * UIScreen.main.scale)/UIScreen.main.bounds.height
            metalView.contentScaleFactor = UIScreen.main.scale + scaleFactor
        }
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        
    }
    
    @IBAction func sliderChanged(_ sender: UISlider) {
        isSlideing = true
    }
    
}

extension ViewController : MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in view: MTKView) {
        if isSlideing == false {
            return
        }
        isSlideing = false
        guard let currentDrawable = view.currentDrawable else {
            return
        }
        //process ciFilter
        contrastFilter?.setValue(inputImage, forKey: kCIInputImageKey)
        contrastFilter?.setValue(NSNumber(value: slider.value), forKey: kCIInputContrastKey)
        guard let outputImage = contrastFilter?.outputImage! else {
            return
        }
        
        var buffer = commandQueue.makeCommandBuffer()
        context.render(outputImage, to: currentDrawable.texture, commandBuffer: buffer!, bounds: outputImage.extent, colorSpace: CGColorSpaceCreateDeviceRGB())
        buffer?.present(currentDrawable)
        buffer?.commit()
        
        buffer = nil
//        guard let latestImage = context.createCGImage(outputImage, from: outputImage.extent) else {return}
//        UIImageWriteToSavedPhotosAlbum(UIImage(cgImage: latestImage), nil, nil, nil)
    }
}

extension UIImage {
    
    /// Returns a image that fills in newSize
    func resizedImage(newSize: CGSize) -> UIImage {
        // Guard newSize is different
        guard self.size != newSize else { return self }
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0);
        self.draw(in: CGRect(x:0, y:0,width: newSize.width,height: newSize.height))
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
    
    /// Returns a resized image that fits in rectSize, keeping it's aspect ratio
    /// Note that the new image size is not rectSize, but within it.
    func resizedImageWithinRect(rectSize: CGSize) -> UIImage {
        let widthFactor = size.width / rectSize.width
        let heightFactor = size.height / rectSize.height
        
        var resizeFactor = widthFactor
        if heightFactor > widthFactor {
            resizeFactor = heightFactor
        }
        
        let newSize = CGSize(width: size.width/resizeFactor,height: size.height/resizeFactor)
        let resized = resizedImage(newSize: newSize)
        return resized
    }
    
}

