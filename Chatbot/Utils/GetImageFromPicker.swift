//
//  GetImageFromPicker.swift
//  Tookan
//
//  Created by cl-macmini-45 on 25/09/17.
//  Copyright © 2017 Click Labs. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
//import CropViewController

class PickerData {
    var fileName:String?
    var imageUrl: URL?
    var imgUrlStr: String?
    var image: UIImage?
    var index: Int?
    var data: Data?
    var fileSize:Int?
    var id: String?
    
    init(_ fileName:String?,_ imageUrl: URL?,_ image: UIImage?,_ index: Int?) {
        self.fileName = fileName
        self.imageUrl = imageUrl
        self.image = image
        self.index = index
    }
    
//    init(banner: Banner, index:Int) {
//        self.fileName = banner.file_name
//        self.imgUrlStr = banner.url
//        self.fileSize = banner.file_size
//        print("size is ***** \(banner.file_size)")
//        self.id = banner._id
//        self.index = index
//    }
    
    func getJson(isData: Bool) -> [String: Any] {
        var docs = [String: Any]()
        docs["file_name"] = self.fileName
        docs["url"] = self.imgUrlStr
        if isData {
            docs["file_size"] = self.fileSize
        }
        return docs
    }
    
//    func getBanner() -> Banner {
//        let banner = Banner()
//        banner.file_name = self.fileName
//        banner.url = self.imgUrlStr
//        banner.file_size = self.fileSize
//        banner.added_on = Date().toString()
//        return banner
//    }
    
}


class GetImageFromPicker: NSObject {
    enum PickerType {
        case camera
        case gallery
        case both
    }
    
    enum Error:String {
        case REJECTED_CAMERA_SUPPORT
        case REJECTED_GALLERY_ACCESS
        case SOMETHING_WRONG
        case NO_CAMERA_SUPPORT
        case NO_GALLERY_SUPPORT
        
        func message() -> String {
            switch self {
            case .REJECTED_CAMERA_SUPPORT:
                return "Need permission to open camera"
            case .REJECTED_GALLERY_ACCESS:
                return "Need permission to open Gallery"
            case .SOMETHING_WRONG:
                return "Something went wrong. Please try again."
            case .NO_CAMERA_SUPPORT:
                return "This device does not support camera"
            case .NO_GALLERY_SUPPORT:
                return "Photo library not found in this device."
            }
        }
    }

    enum PickerResult {
        case success(PickerData?)
        case error(String)
    }
    
    var imageCallBack: ((_ result: PickerResult) -> Void)?
    private var pickerType: PickerType? = .both
    var imagePicker: UIImagePickerController? = UIImagePickerController()
    private var cameraButtonTitle = "Camera"
    private var galleryButtonTitle = "Gallery"
    private var alertTitle = "Upload image from "
    var index = -1
    private var visibleController: UIViewController?
    
    override init() {}
    
    public func setImagePicker(imagePickerType:PickerType = .both, tag:Int = -1, controller: UIViewController?) {
        self.pickerType = imagePickerType
        self.index = tag
        let scenes = UIApplication.shared.connectedScenes
        let windowScenes = scenes.first as? UIWindowScene
        let window = windowScenes?.windows.first
        if controller == nil {
            guard let rootViewController = window?.rootViewController as? UINavigationController else {
                return
            }
            guard let visibleController = rootViewController.visibleViewController else {
                return
            }
            self.visibleController = visibleController
        } else {
            self.visibleController = controller
        }
        self.showAlert()
    }
    
    private func showAlert() {
        DispatchQueue.main.async {
            switch self.pickerType! {
            case .camera:
                self.cameraAction()
            case .gallery:
                self.galleryAction()
            default:
                let alert = UIAlertController(title: self.alertTitle, message: nil, preferredStyle: UIAlertController.Style.actionSheet)
                self.addCameraAction(alert: alert)
                self.addGalleryAction(alert: alert)
                let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel){
                    UIAlertAction in
                }
                alert.addAction(cancelAction)
//                DispatchQueue.main.async {
                    self.visibleController?.present(alert, animated: true, completion: nil)
//                }
            }
        }
    }
    
    private func addCameraAction(alert:UIAlertController) {
        DispatchQueue.main.async {
            let cameraAction = UIAlertAction(title: self.cameraButtonTitle, style: UIAlertAction.Style.default){
                UIAlertAction in
                self.cameraAction()
            }
            alert.addAction(cameraAction)
        }
    }
    
    private func addGalleryAction(alert:UIAlertController) {
        DispatchQueue.main.async {
            let gallaryAction = UIAlertAction(title: self.galleryButtonTitle, style: UIAlertAction.Style.default){
                UIAlertAction in
                self.galleryAction()
            }
            alert.addAction(gallaryAction)
        }
    }
    
    private func cameraAction() {
        self.checkCameraAutorizationStatus(completion: {(isAuthorized) in
            DispatchQueue.main.async {
                guard isAuthorized == true else {
                    self.imageCallBack!(.error(Error.REJECTED_CAMERA_SUPPORT.message()))
                    return
                }
                self.openCamera()
            }
        })
    }
    
    private func galleryAction() {
        self.checkGalleryAuthorizationStatus(completion: { (isAuthorized) in
            DispatchQueue.main.async {
                guard isAuthorized == true else {
                    self.imageCallBack!(.error(Error.REJECTED_GALLERY_ACCESS.message()))
                    return
                }
                self.openGallery()
            }
        })
    }
    
    private func checkCameraAutorizationStatus(completion: ((Bool) -> Void)?) {
        let authStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        switch authStatus {
        case .authorized:
        completion?(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: AVMediaType.video) { granted in
                if granted {
                    completion?(true)
                } else {
                    completion?(false)
                }
            }
        default:
            return (completion?(false))!
        }
    }
    
    private func checkGalleryAuthorizationStatus(completion: ((Bool) -> Void)?) {
        let authStatus = PHPhotoLibrary.authorizationStatus() //PHPhotoLibrary.authorizationStatus(forMediaType: AVMediaTypeVideo)
        switch authStatus {
        case .authorized:
            completion?(true)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization{ grantedStatus in
                switch grantedStatus {
                case .authorized:
                    completion?(true)
                default:
                    (completion?(false))!
                }
            }
        default:
            return (completion?(false))!
        }
    }
    
    private func openCamera() {
//        self.imagePicker = UIImagePickerController()
        self.imagePicker?.delegate = self
        self.imagePicker?.allowsEditing = false
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            DispatchQueue.main.async {
                //self.imagePicker?.allowsEditing = false
                self.imagePicker?.sourceType = UIImagePickerController.SourceType.camera
                guard let picker = self.imagePicker else {
                    self.imageCallBack!(.error(Error.SOMETHING_WRONG.message()))
                    return
                }
                
                self.visibleController?.present(picker, animated: true, completion: nil)
            }
        } else {
            self.imageCallBack!(.error(Error.NO_CAMERA_SUPPORT.message()))
        }
    }
    
    private func openGallery() {
//        self.imagePicker = UIImagePickerController()
       // self.imagePicker?.delegate = self
        self.imagePicker?.allowsEditing = false
        self.imagePicker?.mediaTypes = ["public.image", "public.movie"]
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            DispatchQueue.main.async {
                self.imagePicker?.sourceType = UIImagePickerController.SourceType.photoLibrary
                guard let picker = self.imagePicker else {
                    self.imageCallBack!(.error(Error.SOMETHING_WRONG.message()))
                    return
                }
                self.visibleController?.present(picker, animated: true, completion: nil)
            }
        } else {
            self.imageCallBack!(.error(Error.NO_GALLERY_SUPPORT.message()))
        }
    }
    
    func resizeImage(image: UIImage) -> UIImage {
        let imageHeight = image.size.height
        let imageWidth = image.size.width
        let scale: CGFloat = 1.0
        let targetOrigin: CGFloat = 0.0
        var newHeight = image.size.width * scale
        var newWidth = image.size.width * scale
        
        if imageWidth == imageHeight {
            return image
        } else if imageHeight > imageWidth {
            newHeight = imageWidth
            newWidth = imageWidth
        } else {
            newHeight = imageHeight
            newWidth = imageHeight
        }
        UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
        image.draw(in: CGRect(x: targetOrigin, y: targetOrigin, width: newWidth, height: newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        if newImage != nil {
            return newImage!
        } else {
            return image
        }
    }
}

//MARK: ImagePickerDelegate Methods
extension GetImageFromPicker : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
//    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
//        let updatedImage = self.resizeImage(image: image)
//        ActivityIndicator.sharedInstance.showActivityIndicator()
//        picker.dismiss(animated: true) {
//            DispatchQueue.main.async {
//                if self.imageCallBack != nil {
//                    self.imageCallBack!(.success(updatedImage, self.index))
//                }
//            }
//        }
//    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {return}
        let imageUrl = info[UIImagePickerController.InfoKey.imageURL] as? URL
        print(imageUrl)
        var fileName:String?
        
        if let asset = info[UIImagePickerController.InfoKey(rawValue: "UIImagePickerControllerPHAsset")] as? PHAsset {
             fileName = asset.value(forKey: "filename") as? String
        }
        if fileName == nil {
            fileName = "IMG_\(Date().timeIntervalSince1970 * 1000).JPG"
        }
        
//        print("url ==== \(info[UIImagePickerController.InfoKey.imageURL] as! URL)")
        
//        let cropViewController = CropViewController(image: image)
//        cropViewController.delegate = self
//        picker.present(cropViewController, animated: true, completion: nil)
        
//        var updatedImage:UIImage?
//        if image != nil {
//            updatedImage = self.resizeImage(image: image!)
//        } else {
//            updatedImage = self.resizeImage(image: (info[UIImagePickerController.InfoKey.originalImage] as? UIImage)!)
//        }
//        guard let newImage = updatedImage else {return}
        //ActivityIndicator.sharedInstance.showActivityIndicator()
        
        
        picker.dismiss(animated: false) {
            DispatchQueue.main.async {
                if self.imageCallBack != nil {
                    let data = PickerData(fileName, imageUrl, image, self.index)
                    data.data = image.jpegData(compressionQuality: 1.0)
                    data.fileSize = data.data?.count
                    data.image = image
                    self.imageCallBack!(.success(data))
                    print(data)
                }
            }
        }
    }
    
    
    func presentCropViewController(image:UIImage) {
        
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}


//extension GetImageFromPicker: CropViewControllerDelegate {
//    func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
//        cropViewController.dismiss(animated: false) {
//            self.imagePicker?.dismiss(animated: false) {
//                DispatchQueue.main.async {
//                    if self.imageCallBack != nil {
//                        self.imageCallBack!(.success(image, self.index))
//                    }
//                }
//            }
//        }
//    }
//}
