//
//  CameraViewController.swift
//  Owl
//
//  Created by Carlos Duclos on 8/17/18.
//

import Foundation
import UIKit
import AVFoundation
import CoreGraphics

public class CameraViewController: UIViewController {
    
    // MARK: - Properties
    
    @IBOutlet weak var cameraButton: CameraButton!
    @IBOutlet weak var toggleCameraButton: UIButton!
    @IBOutlet weak var toggleFlashButton: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var instructionsLabel: UILabel!
    @IBOutlet weak var tappableView: UIView!
    @IBOutlet weak var previewView: PreviewView!
    @IBOutlet weak var counterView: CounterView!
    
    var videoDevice: AVCaptureDevice?
    var videoInputDevice: AVCaptureDeviceInput?
    var audioInputDevice: AVCaptureDeviceInput?
    var movieFileOutput: AVCaptureMovieFileOutput?
    var photoFileOutput: AVCaptureStillImageOutput?
    var sessionQueue = DispatchQueue(label: "com.carlosduclos.videotest", qos: .background, attributes: .concurrent)
    var useFrontCamera = false
    var useFlash = false
    var statusBarWasHidden = false
    var maxDuration: Int = 0
    var type: CameraType = .photo
    var zoomScale: CGFloat = 0.0
    
    public var didSelectPhoto: ((UIImage?) -> Void)?
    public var didSelectVideo: ((URL?) -> Void)?
    public var didClose: (() -> Void)?
    
    private var deviceOrientation: UIDeviceOrientation {
        get {
            let statusBarOrientation: UIInterfaceOrientation = UIApplication.shared.statusBarOrientation
            
            switch statusBarOrientation {
            case .landscapeRight:
                return .landscapeLeft
                
            case .landscapeLeft:
                return .landscapeRight
                
            case .portraitUpsideDown:
                return .portraitUpsideDown
                
            default:
                return .portrait
            }
        }
        set { }
    }
    
    private var videoOrientation: AVCaptureVideoOrientation {
        switch deviceOrientation {
        case UIDeviceOrientation.landscapeLeft:
            return .landscapeRight
            
        case UIDeviceOrientation.landscapeRight:
            return .landscapeLeft
            
        case UIDeviceOrientation.portraitUpsideDown:
            return .portraitUpsideDown
            
        default:
            return .portrait
        }
    }
    
    private var imageOrientation: UIImageOrientation {
        switch deviceOrientation {
        case UIDeviceOrientation.landscapeLeft:
            return !useFrontCamera ? .up : .downMirrored
            
        case UIDeviceOrientation.landscapeRight:
            return !useFrontCamera ? .down : .upMirrored
            
        case UIDeviceOrientation.portraitUpsideDown:
            return !useFrontCamera ? .left : .rightMirrored
            
        default:
            return !useFrontCamera ? .right : .leftMirrored
        }
    }
    
    private lazy var session: AVCaptureSession = {
        let session = AVCaptureSession()
        session.sessionPreset = .photo
        return session
    }()
    
    func setUseFlash(_ useFlash: Bool) {
        self.useFlash = useFlash
        let imageName = self.useFlash ? "flash" : "flashOutline"
        let bundle = Bundle(for: CameraViewController.self)
        let image = UIImage(named: imageName, in: bundle, compatibleWith: nil)
        toggleFlashButton.setImage(image, for: .normal)
    }
    
    // MARK: = Properties
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupView()
        setupSession()
        setupCameraButton()
        setupGestures()
    }

    override public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        let deviceOrientation: UIDeviceOrientation = UIDevice.current.orientation
        if UIDeviceOrientationIsPortrait(deviceOrientation) || UIDeviceOrientationIsLandscape(deviceOrientation) {
            if let anOrientation = AVCaptureVideoOrientation(rawValue: deviceOrientation.rawValue) {
                previewView.videoPreviewLayer?.connection?.videoOrientation = anOrientation
            }
        }
        stopRecording()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func setupView() {
        let bundle = Bundle(for: CameraViewController.self)
        let imageDisabled = UIImage(named: "flashOutlineDisabled", in: bundle, compatibleWith: nil)
        
        toggleFlashButton.setImage(imageDisabled, for: .disabled)
        view.backgroundColor = UIColor.red
        previewView.session = session
        previewView.videoPreviewLayer?.videoGravity = .resizeAspectFill
        counterView.alpha = 0.0
        zoomScale = 1.0
        
        if UIDevice.current.orientation != .faceUp && UIDevice.current.orientation != .faceDown {
            deviceOrientation = UIDevice.current.orientation
        }
        
        let languages = ["en", "es"]
        var lang = NSLocale.current.languageCode
        if !(languages.contains(lang ?? "")) {
            lang = "en"
        }
        
        let table = "Owl_\(lang ?? "")"
        switch type {
        case .photo:
            instructionsLabel.text = NSLocalizedString("camera_instructions_tap", tableName: table, bundle: bundle, comment: "")
            
        case .video:
            instructionsLabel.text = NSLocalizedString("camera_instructions_press_and_hold", tableName: table, bundle: bundle, comment: "")
        }
    }

    func setupGestures() {
        let zoomGesture = UIPinchGestureRecognizer()
        zoomGesture.addTarget(self, action: #selector(zoomGestureEvent(_:)))
        tappableView.addGestureRecognizer(zoomGesture)
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleCameraTapped(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        tappableView.addGestureRecognizer(doubleTapGesture)
    }
    
    func setupSession() {
        sessionQueue.async {
            self.configureSession()
            self.session.startRunning()
            
            DispatchQueue.main.async {
                let statusBarOrientation: UIInterfaceOrientation = UIApplication.shared.statusBarOrientation
                var initialVideoOrientation: AVCaptureVideoOrientation = .portrait
                
                if statusBarOrientation != .unknown {
                    if let anOrientation = AVCaptureVideoOrientation(rawValue: statusBarOrientation.rawValue) {
                        initialVideoOrientation = anOrientation
                    }
                }
                
                self.previewView.videoPreviewLayer?.connection?.videoOrientation = initialVideoOrientation
            }
        }
    }
    
    func setupCameraButton() {
        cameraButton.didReachMaximumDuration = {
            self.stopRecording()
        }
        
        cameraButton.didBeginLongPress = {
            self.startRecording()
            self.showUIElements(false)
            self.counterView.startCounter(with: self.maxDuration)
        }
        
        cameraButton.didEndLongPress = {
            self.stopRecording()
        }
        
        cameraButton.didTap = {
            self.takePhoto()
            self.showUIElements(false)
        }

        cameraButton.maxDuration = maxDuration
        cameraButton.type = type
    }
    
    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .high
        addVideoInput()
        addAudioInput()
        
        switch type {
        case .photo:
            addPhotoOutput()
            
        case .video:
            addVideoOutput()
        }
        
        session.commitConfiguration()
    }
    
    private func device(from mediaType: AVMediaType,
                        position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let devices = AVCaptureDevice.devices(for: mediaType)
        for device: AVCaptureDevice in devices {
            if device.position == position {
                return device
            }
        }
        return nil
    }
    
    func addAudioInput() {
        guard audioInputDevice == nil else { return }
        
        if let audioDevice = AVCaptureDevice.default(for: .audio) {
            audioInputDevice = try? AVCaptureDeviceInput(device: audioDevice)
        }
        
        guard let audioInputDevice = self.audioInputDevice else { return }
        let captureInput = audioInputDevice as AVCaptureInput
        if session.canAddInput(captureInput) {
            session.addInput(captureInput)
        }
    }
    
    func removeAudioInput() {
        if let audioInputDevice = self.audioInputDevice {
            session.removeInput(audioInputDevice)
            self.audioInputDevice = nil
        }
    }
    
    func addVideoInput() {
        let position: AVCaptureDevice.Position = useFrontCamera ? .front : .back
        
        guard let device = self.device(from: .video, position: position) else { return }
        
        do {
            try device.lockForConfiguration()
            
            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
                if device.isSmoothAutoFocusSupported {
                    device.isSmoothAutoFocusEnabled = true
                }
            }
            
            if device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposureMode = .continuousAutoExposure
            }
            
            if device.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
                device.whiteBalanceMode = .continuousAutoWhiteBalance
            }
            
            if device.isLowLightBoostSupported {
                device.automaticallyEnablesLowLightBoostWhenAvailable = true
            }
            
            device.unlockForConfiguration()
            
            videoDevice = device
            
            guard let inputDevice = try? AVCaptureDeviceInput(device: device) else { return }
            let captureInput = inputDevice as AVCaptureInput
            if session.canAddInput(captureInput) {
                session.addInput(captureInput)
                videoInputDevice = inputDevice
            }
            
        } catch let error {
            print("error: \(error.localizedDescription)")
        }
    }

    func addVideoOutput() {
        let movieFileOutput = AVCaptureMovieFileOutput()
        let captureOutput = movieFileOutput as AVCaptureOutput
        if session.canAddOutput(captureOutput) {
            session.addOutput(captureOutput)
            let connection: AVCaptureConnection? = movieFileOutput.connection(with: .video)
            if connection?.isVideoStabilizationSupported != nil {
                connection?.preferredVideoStabilizationMode = .auto
            }
            self.movieFileOutput = movieFileOutput
        }
    }
    
    func addPhotoOutput() {
        let photoFileOutput = AVCaptureStillImageOutput()
        let captureOutput = photoFileOutput as AVCaptureOutput
        if session.canAddOutput(captureOutput) {
            photoFileOutput.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
            session.addOutput(captureOutput)
            self.photoFileOutput = photoFileOutput
        }
    }
    
    func changeFlashSettings(_ device: AVCaptureDevice, with mode: AVCaptureDevice.FlashMode) {
        do {
            try device.lockForConfiguration()
            device.flashMode = mode
            device.unlockForConfiguration()
            
        } catch let error {
            print("error: \(error.localizedDescription)")
        }
    }
    
    func processPhoto(with data: Data) -> UIImage? {
        var image: UIImage? = nil
        data.withUnsafeBytes { (bytes: UnsafePointer<UInt8>) -> Void in
            guard let cfData = CFDataCreate(nil, bytes, data.count) else { return }
            guard let dataProvider = CGDataProvider(data: cfData) else { return }
            guard let cgImage = CGImage(jpegDataProviderSource: dataProvider,
                                        decode: nil,
                                        shouldInterpolate: true,
                                        intent: CGColorRenderingIntent.defaultIntent) else { return }
            image = UIImage(cgImage: cgImage, scale: 1.0, orientation: imageOrientation)
        }
        return image
    }
    
    func showPhotoController(_ image: UIImage) {
        
        let photoController = PhotoViewController(image: image)
        photoController.didSelectPhoto = { [unowned self] image in
            photoController.removeFromParentViewController()
            photoController.view.removeFromSuperview()
            self.cameraButton.reset()
            self.showUIElements(true)
            self.didSelectPhoto?(image)
        }
        
        photoController.image = image
        photoController.willMove(toParentViewController: self)
        addChildViewController(photoController)
        view.addSubview(photoController.view)
        photoController.didMove(toParentViewController: self)
    }
    
    func showVideoController(_ videoURL: URL?) {
        let identifier = String(describing: VideoViewController.self)
        let videoController = storyboard?.instantiateViewController(withIdentifier: identifier) as! VideoViewController
        videoController.videoURL = videoURL
        videoController.didSelectVideo = { [unowned self] videoURL in
            videoController.removeFromParentViewController()
            videoController.view.removeFromSuperview()
            self.cameraButton.reset()
            self.showUIElements(true)
            self.didSelectVideo?(videoURL)
        }
        
        videoController.videoURL = videoURL
        videoController.willMove(toParentViewController: self)
        addChildViewController(videoController)
        view.addSubview(videoController.view)
        videoController.didMove(toParentViewController: self)
    }

    func showUIElements(_ flag: Bool) {
        let newAlpha: CGFloat = flag ? 1.0 : 0.0
        UIView.animate(withDuration: 0.2, animations: {
            self.closeButton.alpha = newAlpha
            self.instructionsLabel.alpha = newAlpha
            self.toggleCameraButton.alpha = newAlpha
            self.toggleFlashButton.alpha = newAlpha
            if !flag && self.type == .video {
                self.counterView.alpha = 0.65
            }
        })
    }
    
    func capturePhotoAsynchronously(completionHandler: ((_ success: Bool) -> Void)?) {
        guard let photoFileOutput = self.photoFileOutput else { return }
        
        let connection = photoFileOutput.connection(with: .video)
        if let aConnection = connection {
            photoFileOutput.captureStillImageAsynchronously(from: aConnection, completionHandler: { imageDataSampleBuffer, error in
                
                guard let imageDataBuffer = imageDataSampleBuffer else {
                    completionHandler?(false);
                    return
                }
                
                guard let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataBuffer) else {
                    completionHandler?(false);
                    return
                }
                
                var image = self.processPhoto(with: imageData)
                image = image?.applyAspectFill(in: self.previewView.frame)
                
                OperationQueue.main.addOperation {
                    guard let img = image else { return }
                    self.showPhotoController(img)
                }
                
                completionHandler?(true)
            })
        }
    }

    func enableFlash(_ flag: Bool) {
        guard useFrontCamera == true, let videoDevice = self.videoDevice else { return }
        guard videoDevice.hasTorch else { return }
            
        do {
            try videoDevice.lockForConfiguration()
            if flag {
                videoDevice.torchMode = .on
                try videoDevice.setTorchModeOn(level: 1.0)
            } else {
                videoDevice.torchMode = .off
            }
            videoDevice.unlockForConfiguration()
            
        } catch let error {
            print("error: \(error.localizedDescription)")
        }
    }
    
    func startRecording() {
        guard let movieFileOutput = self.movieFileOutput else { return }
        
        let videoOrientation = self.videoOrientation
        sessionQueue.async(execute: {
            if movieFileOutput.isRecording {
                movieFileOutput.stopRecording()
                return
            }
            
            let movieFileOutputConnection = movieFileOutput.connection(with: .video)
            if self.useFrontCamera {
                movieFileOutputConnection?.isVideoMirrored = true
            }
            movieFileOutputConnection?.videoOrientation = videoOrientation
            
            let outputFilename = UUID().uuidString
            let outputURL = URL(fileURLWithPath: NSTemporaryDirectory() + "/" + outputFilename + ".mov")
            movieFileOutput.startRecording(to: outputURL, recordingDelegate: self)
            self.enableFlash(self.useFlash)
        })
    }

    func stopRecording() {
        guard let movieFileOutput = self.movieFileOutput else { return }
        sessionQueue.async(execute: {
            guard movieFileOutput.isRecording else { return }
            movieFileOutput.stopRecording()
        })
        counterView.alpha = 0.0
    }
    
    func takePhoto() {
        guard let videoDevice = self.videoDevice else { return }
        if !videoDevice.hasFlash && useFlash && useFrontCamera {
            
            let flashView = UIView(frame: view.frame)
            flashView.alpha = 0.0
            flashView.backgroundColor = UIColor.white
            view.addSubview(flashView)
            
            let previousBrightness: CGFloat = UIScreen.main.brightness
            UIScreen.main.brightness = 1.0
            UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseInOut, animations: {
                flashView.alpha = 1.0
            }) { finished in
                self.capturePhotoAsynchronously { success in
                    UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseInOut, animations: {
                        flashView.alpha = 0.0
                    }) { finished in
                        flashView.removeFromSuperview()
                        UIScreen.main.brightness = previousBrightness
                    }
                }
            }
            return
        }
        
        if videoDevice.hasFlash && useFlash {
            changeFlashSettings(videoDevice, with: AVCaptureDevice.FlashMode.on)
            capturePhotoAsynchronously(completionHandler: nil)
            return
        }
        
        if videoDevice.isFlashActive {
            changeFlashSettings(videoDevice, with: AVCaptureDevice.FlashMode.off)
        }
        
        capturePhotoAsynchronously(completionHandler: nil)
    }

    func addInputs() {
        session.beginConfiguration()
        session.sessionPreset = .high
        addVideoInput()
        addAudioInput()
        session.commitConfiguration()
    }
    
    // MARK: - Actions
    
    @IBAction func closeTapped(_ sender: Any) {
        didClose?()
    }
    
    @objc @IBAction func toggleCameraTapped(_ sender: Any) {
        useFrontCamera = !useFrontCamera
        toggleFlashButton.isEnabled = !(type == .video && useFrontCamera)
        session.stopRunning()
        sessionQueue.async {
            for input in self.session.inputs {
                self.session.removeInput(input)
            }
            self.addInputs()
            self.session.startRunning()
        }
    }
    
    @IBAction func toggleFlashTapped(_ sender: Any) {
        useFlash = !useFlash
    }
    
    @objc func zoomGestureEvent(_ gesture: UIPinchGestureRecognizer) {
        
        guard let videoDevice = self.videoDevice else { return }
        
        if useFrontCamera { return }
        
        do {
            try videoDevice.lockForConfiguration()
            switch gesture.state {
            case .began:
                zoomScale = videoDevice.videoZoomFactor
                
            case .changed:
                var factor: CGFloat = zoomScale * gesture.scale
                factor = max(1.0, min(factor, videoDevice.activeFormat.videoMaxZoomFactor))
                videoDevice.videoZoomFactor = factor
                
            default:
                break
            }
            
            videoDevice.unlockForConfiguration()
        } catch let error {
            print("error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Public
    
    public static func `init`(type: CameraType, maxDuration: Int) -> CameraViewController {
        let identifier = String(describing: CameraViewController.self)
        let storyboard = UIStoryboard(name: "Owl",
                                      bundle: Bundle(for: CameraViewController.self))
        let cameraController = storyboard.instantiateViewController(withIdentifier: identifier) as! CameraViewController
        cameraController.type = type
        cameraController.maxDuration = maxDuration
        return cameraController
    }
    
}

extension CameraViewController: AVCaptureFileOutputRecordingDelegate {
    
    public func fileOutput(_ output: AVCaptureFileOutput,
                           didStartRecordingTo fileURL: URL,
                           from connections: [AVCaptureConnection]) {
        
    }
    
    public func fileOutput(_ output: AVCaptureFileOutput,
                           didFinishRecordingTo outputFileURL: URL,
                           from connections: [AVCaptureConnection],
                           error: Error?) {
        print("error", error)
        enableFlash(false)
        OperationQueue.main.addOperation {
            self.showVideoController(outputFileURL)
        }
    }
}
