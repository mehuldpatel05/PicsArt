//
//  PhotoEditorViewController.swift
//  PicsArt
//
//  Created by FPrimeC on 2022-01-01.
//

import UIKit

class PhotoEditorViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {

    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var effectsCollectionView: UICollectionView!
    
    var previewImage : UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.previewImageView.image = previewImage
        // Do any additional setup after loading the view.
        effectsCollectionView.delegate = self
        effectsCollectionView.dataSource = self
        
        effectsCollectionView.register(UINib(nibName: "PhotoCell", bundle: nil), forCellWithReuseIdentifier: "PhotoCell")
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 10
    }
   
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let collectionviewCell = effectsCollectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCell
        collectionviewCell.backgroundColor = .brown
        return collectionviewCell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    }


}
