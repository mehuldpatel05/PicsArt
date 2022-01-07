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
    var currentImgNameArray = [String]()
    let imagePicker = ImagePickerController()
    var dbMGR : DBManager!
    var imageIdCounter : Int = 0
    var isSelectEnabled = true
    var imageSelectBarBtn = UIBarButtonItem()
    var deleteBarBtn = UIBarButtonItem()
    @IBOutlet weak var photoCollectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Pics Art"
        
        dbMGR = DBManager.init(databaseFilename: "Picsart.db")
        
        imageSelectBarBtn = UIBarButtonItem(title: "Select", style: .done, target: self, action: #selector(selectImageForDelete))
        self.navigationItem.rightBarButtonItem = imageSelectBarBtn
        
        
        
        // Do any additional setup after loading the view.
        photoCollectionView.register(UINib(nibName: "PhotoCell", bundle: nil), forCellWithReuseIdentifier: "PhotoCell")
        photoCollectionView.allowsMultipleSelection = true
        fetchLastIDFromDB()
        
        self.fetchImagesFromDatabase()
    }
    
    @objc func selectImageForDelete() {
        print("Select Image")
        if isSelectEnabled == true {
            imageSelectBarBtn.title = "Cancel"
            deleteBarBtn = UIBarButtonItem(title: "Delete", style: .done, target: self, action: #selector(deleteBtnAction))
            self.navigationItem.leftBarButtonItem = deleteBarBtn
            isSelectEnabled = false
        }
        else {
            imageSelectBarBtn.title = "Select"
            self.navigationItem.leftBarButtonItem  = nil
            isSelectEnabled = true
        }
    }
    
    @objc func deleteBtnAction() {
        print("deleteBtnAction")
        let items = photoCollectionView.indexPathsForSelectedItems
        if items!.count > 0 {
            for item in 0..<items!.count {
                print("item \(items![item])")
                let currentItem = (items![item])
                let currentIndex = currentItem[1]
                print("currentIndex \(currentIndex)")
                let imageName = currentImgNameArray[currentIndex-1]
                deleteImageFromDisk(fileName: "\(imageName)")
                let deleteImgQuery = "DELETE FROM Images WHERE id IS \(imageName)"
                dbMGR.executeQuery(deleteImgQuery)
                
                photoCollectionView.deselectItem(at: currentItem, animated:true)
                if let cell = photoCollectionView.cellForItem(at: currentItem) as? PhotoCell {
                    cell.backgroundColor = .clear
                }
            }
            fetchImagesFromDatabase()
        }
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
        currentImgNameArray.removeAll()
        let selectImagesQuery = "Select * from Images"
        let imagesTblArray : NSArray = self.dbMGR.loadData(fromDB: selectImagesQuery)! as NSArray
        if imagesTblArray.count > 0 {
            for i in 0..<imagesTblArray.count{
                let currentImageArray = imagesTblArray[i] as! NSArray
                let currentImgName = currentImageArray[1] as! String
                let curerntImage = loadImageFromDiskWith(fileName: "\(currentImgName).png")
                currentImgNameArray.append(currentImgName)
                thumbnailImageArray.append(curerntImage!)
            }
        }
        self.photoCollectionView.reloadData()
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
            if isSelectEnabled == true {
                self.navigationController?.pushViewController(photoeditorViewCtrl, animated: true)
            }
            else {
                var cell = collectionView.cellForItem(at: indexPath)
                if cell?.isSelected == true {
                    cell?.backgroundColor = .orange
                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        var cell = collectionView.cellForItem(at: indexPath)
        cell?.backgroundColor = .clear
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
    
    func deleteImageFromDisk(fileName: String) {

        let fileNameToDelete = "\(fileName)" + ".png"
        var filePath = ""
        
        // Find documents directory on device
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentDirectory = paths[0]
        filePath = documentDirectory.appendingFormat("/" + fileNameToDelete)
        
        do {
            let fileManager = FileManager.default
            // Check if file exists
            if fileManager.fileExists(atPath: filePath) {
                // Delete file
                try fileManager.removeItem(atPath: filePath)
            } else {
                print("File does not exist")
            }
        }
        catch let error as NSError {
            print("An error took place: \(error)")
        }
    }
    
}
