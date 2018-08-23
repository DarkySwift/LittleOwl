//
//  PhotoViewController.swift
//  Owl
//
//  Created by Carlos Duclos on 8/17/18.
//

import Foundation
import UIKit

class PhotoViewController: UIViewController {
    
    // MARK: - Properties
    
    @IBOutlet weak var photoView: UIImageView!
    
    var didSelectPhoto: ((UIImage?) -> Void)?
    
    var image: UIImage?
    
    // MARK: - Override
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    // MARK: - Actions
    
    @IBAction func cancelTapped(_ sender: Any) {
        didSelectPhoto?(nil)
    }
    
    @IBAction func selectTapped(_ sender: Any) {
        didSelectPhoto?(image)
    }
    
    // MARK: - Methods
    
    func setupView() {
        photoView.contentMode = .scaleAspectFit
        photoView.image = image
    }
    
    public static func `init`(image: UIImage) -> PhotoViewController {
        let identifier = String(describing: PhotoViewController.self)
        let bundle = Bundle(for: PhotoViewController.self)
        let storyboard = UIStoryboard(name: "LittleOwl", bundle: bundle)
        let photoController = storyboard.instantiateViewController(withIdentifier: identifier) as! PhotoViewController
        photoController.image = image
        return photoController
    }
}
