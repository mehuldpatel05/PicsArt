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

    @IBOutlet weak var photoCollectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Pics Art"
        // Do any additional setup after loading the view.
        photoCollectionView.register(UINib(nibName: "PhotoCell", bundle: nil), forCellWithReuseIdentifier: "PhotoCell")
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
                    self.thumbnailImageArray.append(currentImage!)
                    self.imagePicker.deselect(asset: assets[i])
                }
                self.photoCollectionView.reloadData()
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
            print("Open Photo gallery")
            imagePickerSetup()
        }
        else {
            print("Go inside photo editor view")
            let photoeditorViewCtrl = PhotoEditorViewController()
            photoeditorViewCtrl.previewImage = thumbnailImageArray[indexPath.item - 1]
            self.navigationController?.pushViewController(photoeditorViewCtrl, animated: true)
        }
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
    
}
