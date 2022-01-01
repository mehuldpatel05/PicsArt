//
//  ViewController.swift
//  PicsArt
//
//  Created by FPrimeC on 2021-12-30.
//

import UIKit
import AssetsPickerViewController
import Photos

class ViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, AssetsPickerViewControllerDelegate {

    let picker = AssetsPickerViewController()
    var thumbnailImageArray = [UIImage]()
    @IBOutlet weak var photoCollectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Pics Art"
        picker.pickerDelegate = self
        // Do any additional setup after loading the view.
        photoCollectionView.register(UINib(nibName: "PhotoCell", bundle: nil), forCellWithReuseIdentifier: "PhotoCell")
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
            for i in 0..<thumbnailImageArray.count{
                cell.thumbnailImageView.image = thumbnailImageArray[i]
            }
        }

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item == 0 {
            print("Open Photo gallery")
            present(picker, animated: true, completion: nil)
        }
        else {
            print("Go inside photo editor view")
        }
    }
    
    func assetsPicker(controller: AssetsPickerViewController, selected assets: [PHAsset]) {
        let selectedAssets = controller.selectedAssets
        print("assets Count  \(selectedAssets.count)")
        
        if selectedAssets.count > 0 {
            for i in 0..<selectedAssets.count {
                let thumnailImage = getThumbnail(asset: selectedAssets[i])
                print("thumnailImage \(thumnailImage)")
                thumbnailImageArray.append(thumnailImage!)
            }
            photoCollectionView.reloadData()
        }
    }

    func getThumbnail(asset: PHAsset) -> UIImage? {
        var thumbnail : UIImage?
        
        let manager = PHImageManager.default()
        
        let options = PHImageRequestOptions()
        options.version = .original
        options.isSynchronous = true
        
        manager.requestImage(for: asset, targetSize: CGSize(width: 100, height: 100), contentMode: .aspectFit, options: options, resultHandler: { image, _ in
            thumbnail = image!
        })
        return thumbnail
    }
    
}
