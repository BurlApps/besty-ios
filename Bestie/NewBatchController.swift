//
//  NewBatchController.swift
//  Bestie
//
//  Created by Brian Vallelunga on 9/25/15.
//  Copyright © 2015 Brian Vallelunga. All rights reserved.
//

import UIKit
import SVProgressHUD

class NewBatchController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource,
UICollectionViewDelegateFlowLayout, PlusCollectionCellDelegate, ImageCollectionCellDelegate,
UIImagePickerControllerDelegate, UINavigationControllerDelegate, ShareGeneratorDelegate {
    
    private let reuseIdentifier = "cell"
    private let firstReuseIdentifier = "firstCell"
    private let uploadedImages: NSMutableArray = NSMutableArray()
    private let sectionInsets = UIEdgeInsets(top: 25.0, left: 25.0, bottom: 25.0, right: 25.0)
    private var user: User! = User.current()
    private var config: Config!
    private var hitLimit: Bool = false
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var informationLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Config.sharedInstance { (config) -> Void in
            self.config = config
        }
        
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        self.collectionView?.backgroundColor = UIColor.clearColor()
        
        self.submitButton.tintColor = UIColor.whiteColor()
        self.submitButton.backgroundColor = Colors.batchSubmitButton
        self.submitButton.layer.masksToBounds = true
        self.submitButton.setTitle(Strings.newBatchButton, forState: .Normal)
        
        self.informationLabel.textColor = Colors.batchInfomation
        self.informationLabel.text = Strings.newBatchInformation
        self.informationLabel.numberOfLines = 5
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.submitButton.layer.cornerRadius = Globals.batchSubmitButtonRadius(self.submitButton.frame.width)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        self.collectionView.reloadData()
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let count = self.uploadedImages.count
        let ready = count >= 2
        
        if self.config != nil {
            let limit = self.user.shared == true ?  self.config.uploadShareLimit :  self.config.uploadLimit
            
            self.hitLimit = count >= limit
        }
            
        self.submitButton.hidden = !ready
        self.informationLabel.hidden = ready
        
        return self.uploadedImages.count + 1
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let isFirst = indexPath.row == 0
        let identifier = isFirst ? self.firstReuseIdentifier : self.reuseIdentifier
        let cell: UICollectionViewCell = collectionView.dequeueReusableCellWithReuseIdentifier(identifier, forIndexPath: indexPath)
        
        if isFirst {
            let temp = cell as! PlusCollectionCell
            
            temp.delegate = self
            temp.setup()
            
        } else {
            let temp = cell as! ImageCollectionCell
            let image: Image = self.uploadedImages[indexPath.row - 1] as! Image
            
            temp.delegate = self
            temp.setup(image)
        }
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
            var size = (self.collectionView?.frame.width)!/2 - self.sectionInsets.left - self.sectionInsets.right
        
            size += 10
        
            return CGSize(width: size, height: size)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
            return sectionInsets
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 30
    }
    
    func newImageTapped() {
        if !self.hitLimit {
            let picker = UIImagePickerController()
            
            picker.delegate = self
            picker.sourceType = .PhotoLibrary
            picker.allowsEditing = true
            
            Globals.pageController.presentViewController(picker, animated: true, completion: nil)
        } else if self.user.shared == true {
            NavNotification.show(
                String(format: Strings.newbatchLimitAlertMessage, self.config.uploadShareLimit)
            )
        } else {
            let alert = UIAlertController(title: Strings.newBatchShareAlertTitle, message: String(format: Strings.newBatchShareAlertMessage, self.config.uploadShareLimit), preferredStyle: .Alert)
            
            let shareButton = UIAlertAction(title: Strings.newBatchShareAlertConfirm, style: .Destructive, handler: { (action: UIAlertAction) -> Void in
                let shareController = ShareGenerator(sender: self.view, controller: Globals.pageController)
                
                shareController.delegate = self
                
                shareController.share(self.config.shareMessage, image: nil)
            })
            
            let cancelButton = UIAlertAction(title: Strings.newBatchShareAlertCancel, style: .Cancel, handler: nil)
            
            alert.addAction(shareButton)
            alert.addAction(cancelButton)
            
            Globals.pageController.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    func generatorShared() {
        NavNotification.show(
            String(format: Strings.newBatchShareConfirmed, self.config.uploadShareLimit)
        )
        
        self.user.changeShared(true)
        self.hitLimit = false
    }
    
    func removeTapped(cell: ImageCollectionCell) {
        self.uploadedImages.removeObject(cell.voterImage)
        self.collectionView.reloadData()
        cell.voterImage.remove()
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        picker.dismissViewControllerAnimated(true, completion: nil)
        self.uploadedImages.addObject(Image.create(image, user: self.user))
        self.collectionView.reloadData()
    }
    
    @IBAction func submitBatch(sender: AnyObject) {
        SVProgressHUD.setBackgroundColor(UIColor.blackColor())
        SVProgressHUD.setForegroundColor(UIColor.whiteColor())
        SVProgressHUD.setDefaultMaskType(.Black)
        SVProgressHUD.setFont(UIFont(name: "Bariol-Bold", size: 24))
        SVProgressHUD.showWithStatus("Uploading...")
        
        var images: [Image] = []
        
        for image in self.uploadedImages {
            images.append(image as! Image)
        }
        
        Batch.create(images, user: self.user) { (batch) -> Void in
            SVProgressHUD.dismiss()
            Globals.showVoterBarsTutorial()
            Globals.slideToVotingScreen()
            Globals.batchUpdated()
            
            self.user.mixpanel.timeEvent("Mobile.Batch.Results")
            self.user.mixpanel.track("Mobile.Batch.Create", properties: [
                "images": images.count
            ])
        }
    }
}
