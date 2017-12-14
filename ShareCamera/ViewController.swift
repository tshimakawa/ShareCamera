//
//  ViewController.swift
//  ShareCamera
//
//  Created by 川村航平 on 2017/05/18.
//  Copyright © 2017年 川村航平. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    //UIViewController：カメラ使うのに必要，UINavigationControllerDelegate：階層的な画面遷移を管理

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        label.text = "Tap the [Camera] to take a picture"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    var json:NSData!
    
    @IBOutlet weak var cameraView: UIImageView!
    
    
    @IBOutlet weak var bCameraStart: UIButton!
    @IBOutlet weak var bSavePic: UIButton!
    @IBOutlet weak var bAlbum: UIButton!
    
    @IBOutlet weak var label: UILabel!

    
    // カメラの撮影開始
    @IBAction func cameraStart(_ sender: Any) {
        let sourceType:UIImagePickerControllerSourceType = UIImagePickerControllerSourceType.camera
        // カメラが利用可能かチェック
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera){
            // インスタンスの作成
            let cameraPicker = UIImagePickerController()
            cameraPicker.sourceType = sourceType
            cameraPicker.delegate = self
            self.present(cameraPicker, animated: true, completion: nil)
        }
        else{
            //label.text = "error"
        }
    }
    
    //　撮影が完了時した時に呼ばれる
    func imagePickerController(_ imagePicker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            cameraView.contentMode = .scaleAspectFit
            cameraView.image = pickedImage
        }
        
        let image:UIImage! = cameraView.image
        
        if image != nil {
            UIImageWriteToSavedPhotosAlbum(image, self, #selector(ViewController.image(_:didFinishSavingWithError:contextInfo:)), nil)
        }
        else{
            //label.text = "image Failed !"
        }
        
        //閉じる処理
        imagePicker.dismiss(animated: true, completion: nil)
        //slabel.text = "Tap the [Share] to Share picture"
        
    }
    
    // 撮影がキャンセルされた時に呼ばれる
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
        //label.text = "Canceled"
    }
    
    
    @IBAction func savePic(_ sender: Any) {
        
        myImageUploadRequest()
        
    }
    
    func myImageUploadRequest(){
        //myUrlには自分で用意したphpファイルのアドレスを入れる
        let myUrl = NSURL(string:"http://172.20.11.170/image_trans.php")
        let request = NSMutableURLRequest(url:myUrl! as URL)
        request.httpMethod = "POST"
        //下記のパラメータはあくまでもPOSTの例
        let param = [
            "userId" : "12345"
        ]
        let boundary = generateBoundaryString()
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        let imageData = UIImageJPEGRepresentation(cameraView.image!, 0.75)
        
        if(imageData==nil) { return; }
        request.httpBody = createBodyWithParameters(parameters: param, filePathKey: "file", imageDataKey: imageData! as NSData, boundary: boundary) as Data
        let task = URLSession.shared.dataTask(with: request as URLRequest) {
            data, response, error in
            if error != nil {
                print("error=\(String(describing: error))")
                return
            }
            // レスポンスを出力
            print("******* response = \(String(describing: response))")
            let responseString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
            print("****** response data = \(responseString!)")
            DispatchQueue.main.async(execute: {
                //アップロード完了
                self.label.text = "Share Successed"

            });
        }
        task.resume()
        print("Upload completed")
                
    }
    
    func createBodyWithParameters(parameters: [String: String]?, filePathKey: String?, imageDataKey: NSData, boundary: String) -> NSData {
        let body = NSMutableData()
        if parameters != nil {
            for (key, value) in parameters! {
                body.appendString(string: "--\(boundary)\r\n")
                body.appendString(string: "Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
                body.appendString(string: "\(value)\r\n")
            }
        }
        
        
        let filename = "user-profile.jpg"
        let mimetype = "image/jpg"
        body.appendString(string: "--\(boundary)\r\n")
        body.appendString(string: "Content-Disposition: form-data; name=\"\(filePathKey!)\"; filename=\"\(filename)\"\r\n")
        body.appendString(string: "Content-Type: \(mimetype)\r\n\r\n")
        body.append(imageDataKey as Data)
        body.appendString(string: "\r\n")
        body.appendString(string: "--\(boundary)--\r\n")
        return body
        
    }
    
    func generateBoundaryString() -> String {
        return "Boundary-\(NSUUID().uuidString)"
    }
    
    
    
    // 書き込み完了結果の受け取り
    func image(_ image: UIImage, didFinishSavingWithError error: NSError!, contextInfo: UnsafeMutableRawPointer) {
        print("Write completed")
        
        if error != nil {
            print(error.code)
            label.text = "Save Failed !"
        }
        else{
            label.text = "Selected Picture"
        }
    }
    
    
    // アルバムを表示
    @IBAction func showAlbum(_ sender: Any) {
        let sourceType:UIImagePickerControllerSourceType = UIImagePickerControllerSourceType.photoLibrary
        
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.photoLibrary){
            // インスタンスの作成
            let cameraView = UIImagePickerController()
            cameraView.sourceType = sourceType
            cameraView.delegate = self
            self.present(cameraView, animated: true, completion: nil)
            
            //label.text = "Tap the [Start] to save a picture"
        }
        else{
            //label.text = "error"
            
        }
    }
    
    
}

extension NSMutableData {
    func appendString(string: String) {
        let data = string.data(using: String.Encoding.utf8, allowLossyConversion: true)
        append(data!)
    }
}
