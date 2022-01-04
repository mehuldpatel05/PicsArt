//
//  ViewController.swift
//  PicsArt
//
//  Created by FPrimeC on 2021-12-30.
//

import UIKit
import Photos
import BSImagePicker

class ViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    var thumbnailImageArray = [UIImage]()
    let imagePicker = ImagePickerController()
    var dbMGR : DBManager!
    var imageIdCounter : Int = 0
    
    @IBOutlet weak var photoCollectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Pics Art"
      
        dbMGR = DBManager.init(databaseFilename: "Picsart.db")
        
        // Do any additional setup after loading the view.
        photoCollectionView.register(UINib(nibName: "PhotoCell", bundle: nil), forCellWithReuseIdentifier: "PhotoCell")
        fetchLastIDFromDB()
        
        self.fetchImagesFromDatabase()
    }
    
    func fetchLastIDFromDB() {
        let selectImageLastIDQuery = "SELECT * FROM SQLITE_SEQUENCE WHERE name='Images'"
        
        let imagesTblArray : NSArray = self.dbMGR.loadData(fromDB: selectImageLastIDQuery)! as NSArray
        
        if imagesTblArray.count > 0 {
            let lastImageArray : NSArray = imagesTblArray[0] as! NSArray
            let lastID = lastImageArray[1] as! String
            imageIdCounter = Int(lastID)!
        }
    }
    
    func fetchImagesFromDatabase(){
        thumbnailImageArray.removeAll()
        let selectImagesQuery = "Select * from Images"
        let imagesTblArray : NSArray = self.dbMGR.loadData(fromDB: selectImagesQuery)! as NSArray
        if imagesTblArray.count > 0 {
            for i in 0..<imagesTblArray.count{
                let currentImageArray = imagesTblArray[i] as! NSArray
                let currentImgName = currentImageArray[1] as! String
                let curerntImage = loadImageFromDiskWith(fileName: "\(currentImgName).png")
                thumbnailImageArray.append(curerntImage!)
            }
            self.photoCollectionView.reloadData()
        }
    }

    func insertImagePathInDB(currentImgCounter: Int) {
        let imageInsertQuery = "insert into Images(imagepath) VALUES ('\(currentImgCounter)')"
        self.dbMGR.executeQuery(imageInsertQuery)
    }
    
    func getThumbnail(asset: PHAsset) -> UIImage? {
        var thumbnail : UIImage?
        
        let manager = PHImageManager.default()
        
        let options = PHImageRequestOptions()
        options.version = .original
        options.isSynchronous = true
        
        manager.requestImage(for: asset, targetSize: CGSize(width: asset.pixelWidth, height: asset.pixelHeight), contentMode: .aspectFit, options: options, resultHandler: { image, _ in
            thumbnail = image!
        })
        return thumbnail
    }

    func imagePickerSetup() {
        imagePicker.settings.theme.selectionStyle = .checked
        imagePicker.settings.fetch.assets.supportedMediaTypes = [.image]
        
        self.presentImagePicker(imagePicker, select: { (asset) in
            print("Selected: \(asset)")
        }, deselect: { (asset) in
            print("Deselected: \(asset)")
        }, cancel: { (assets) in
            print("Canceled with selections: \(assets)")
            if assets.count > 0 {
                for i in 0..<assets.count{
                    self.imagePicker.deselect(asset: assets[i])
                }
            }
        }, finish: { (assets) in
            print("Finished with selections: \(assets)")
            if assets.count > 0 {
                for i in 0..<assets.count{
                    let currentImage = self.getThumbnail(asset: assets[i])
                    self.imageIdCounter = self.imageIdCounter + 1
                    self.insertImagePathInDB(currentImgCounter: self.imageIdCounter)
                    self.saveImageInFilemanager(imageName: "\(self.imageIdCounter).png", image: currentImage!)
                    
                    self.imagePicker.deselect(asset: assets[i])
                }
                self.fetchImagesFromDatabase()
            }
        }, completion: {
            let finish = Date()
        })
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // Set the number of items in your collection view.
        if thumbnailImageArray.count == 0 {
            return 1
        }
        else{
            return thumbnailImageArray.count + 1
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // Access
        let cell = photoCollectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCell
        // Do any custom modifications you your cell, referencing the outlets you defined in the Custom cell file.
        if indexPath.item == 0 {
            cell.thumbnailImageView.image = UIImage(named: "plusimage.png")
        }else{
            cell.thumbnailImageView.image = thumbnailImageArray[indexPath.item - 1]
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item == 0 {
            imagePickerSetup()
        }
        else {
            let photoeditorViewCtrl = PhotoEditorViewController()
            photoeditorViewCtrl.previewImage = thumbnailImageArray[indexPath.item - 1]
            self.navigationController?.pushViewController(photoeditorViewCtrl, animated: true)
        }
    }
        
    func saveImageInFilemanager(imageName: String, image: UIImage) {
        
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        let fileName = imageName
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        guard let data = image.jpegData(compressionQuality: 1) else { return }
        
        //Checks if file exists, removes it if so.
        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                try FileManager.default.removeItem(atPath: fileURL.path)
            } catch let removeError {
                print("couldn't remove file at path", removeError)
            }
        }
        
        do {
            try data.write(to: fileURL)
        } catch let error {
            print("error saving file with error", error)
        }
    }
    
    func loadImageFromDiskWith(fileName: String) -> UIImage? {
        let documentDirectory = FileManager.SearchPathDirectory.documentDirectory
        let userDomainMask = FileManager.SearchPathDomainMask.userDomainMask
        let paths = NSSearchPathForDirectoriesInDomains(documentDirectory, userDomainMask, true)
        
        if let dirPath = paths.first {
            let imageUrl = URL(fileURLWithPath: dirPath).appendingPathComponent(fileName)
            let image = UIImage(contentsOfFile: imageUrl.path)
            return image
        }
        return nil
    }
    
}
