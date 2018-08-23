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
    
    @IBOutlet private weak var cameraButton: CameraButton!
    @IBOutlet private weak var toggleCameraButton: UIButton!
    @IBOutlet private weak var toggleFlashButton: UIButton!
    @IBOutlet private weak var closeButton: UIButton!
    @IBOutlet private weak var instructionsLabel: UILabel!
    @IBOutlet private weak var tappableView: UIView!
    @IBOutlet private weak var previewView: PreviewView!
    @IBOutlet private weak var counterView: CounterView!
    
    private var videoDevice: AVCaptureDevice?
    private var videoInputDevice: AVCaptureDeviceInput?
    private var audioInputDevice: AVCaptureDeviceInput?
    private var movieFileOutput: AVCaptureMovieFileOutput?
    private var photoFileOutput: AVCaptureStillImageOutput?
    private var sessionQueue = DispatchQueue(label: "com.carlosduclos.videotest", qos: .background, attributes: .concurrent)
    private var useFrontCamera = false
    private var useFlash = false {
        didSet {
            let imageName = useFlash ? "flash" : "flashOutline"
            toggleFlashButton.setImage(imageNamed(imageName), for: .normal)
        }
    }
    private var statusBarWasHidden = false
    private var zoomScale: CGFloat = 0.0
    
    var maxDuration: Int = 0
    var type: CameraType = .photo
    
    public var didSelectPhoto: ((UIImage?) -> Void)?
    public var didSelectVideo: ((URL?) -> Void)?
    public var didClose: (() -> Void)?
    
    private var deviceOrientation: UIDeviceOrientation {
        get {
            let statusBarOrientation: UIInterfaceOrientation = UIApplication.shared.statusBarOrientation
            switch statusBarOrientation {
            case .landscapeRight: return .landscapeLeft
            case .landscapeLeft: return .landscapeRight
            case .portraitUpsideDown: return .portraitUpsideDown
            default: return .portrait
            }
        }
        set { }
    }
    
    private var videoOrientation: AVCaptureVideoOrientation {
        switch deviceOrientation {
        case UIDeviceOrientation.landscapeLeft: return .landscapeRight
        case UIDeviceOrientation.landscapeRight: return .landscapeLeft
        case UIDeviceOrientation.portraitUpsideDown: return .portraitUpsideDown
        default: return .portrait
        }
    }
    
    private var imageOrientation: UIImageOrientation {
        switch deviceOrientation {
        case UIDeviceOrientation.landscapeLeft: return !useFrontCamera ? .up : .downMirrored
        case UIDeviceOrientation.landscapeRight: return !useFrontCamera ? .down : .upMirrored
        case UIDeviceOrientation.portraitUpsideDown: return !useFrontCamera ? .left : .rightMirrored
        default: return !useFrontCamera ? .right : .leftMirrored
        }
    }
    
    private lazy var session: AVCaptureSession = {
        let session = AVCaptureSession()
        session.sessionPreset = .photo
        return session
    }()
    
    // MARK: - Override
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        guard status == .authorized else {
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async { [weak self] in
                    guard granted == true else { self?.alert(message: "Permissions were not granted to use the camera."); return }
                    self?.setup()
                }
            }; return
        }
        
        setup()
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
    
    // MARK: - Methods
    
    private func checkPermission() {
        
    }
    
    private func setup() {
        setupView()
        setupSession()
        setupCameraButton()
        setupGestures()
    }
    
    private func setupView() {
        let imageDisabled = imageNamed("flashOutlineDisabled")
        
        toggleFlashButton.setImage(imageDisabled, for: .disabled)
        view.backgroundColor = UIColor.red
        previewView.session = session
        previewView.videoPreviewLayer?.videoGravity = .resizeAspectFill
        counterView.alpha = 0.0
        zoomScale = 1.0
        
        if UIDevice.current.orientation != .faceUp && UIDevice.current.orientation != .faceDown {
            deviceOrientation = UIDevice.current.orientation
        }
    
        switch type {
        case .photo: instructionsLabel.text = localizedString("camera.instructions.tap")
        case .video: instructionsLabel.text = localizedString("camera.instructions.pressandhold")
        }
    }

    private func setupGestures() {
        let zoomGesture = UIPinchGestureRecognizer()
        zoomGesture.addTarget(self, action: #selector(zoomGestureEvent(_:)))
        tappableView.addGestureRecognizer(zoomGesture)
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleCameraTapped(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        tappableView.addGestureRecognizer(doubleTapGesture)
    }
    
    private func setupSession() {
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
    
    private func setupCameraButton() {
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
        case .photo: addPhotoOutput()
        case .video: addVideoOutput()
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
    
    private func addAudioInput() {
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
    
    private func removeAudioInput() {
        if let audioInputDevice = self.audioInputDevice {
            session.removeInput(audioInputDevice)
            self.audioInputDevice = nil
        }
    }
    
    private func addVideoInput() {
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

    private func addVideoOutput() {
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
    
    private func addPhotoOutput() {
        let photoFileOutput = AVCaptureStillImageOutput()
        let captureOutput = photoFileOutput as AVCaptureOutput
        if session.canAddOutput(captureOutput) {
            photoFileOutput.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
            session.addOutput(captureOutput)
            self.photoFileOutput = photoFileOutput
        }
    }
    
    private func changeFlashSettings(_ device: AVCaptureDevice, with mode: AVCaptureDevice.FlashMode) {
        do {
            try device.lockForConfiguration()
            device.flashMode = mode
            device.unlockForConfiguration()
            
        } catch let error {
            print("error: \(error.localizedDescription)")
        }
    }
    
    private func processPhoto(with data: Data) -> UIImage? {
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
    
    private func showPhotoController(_ image: UIImage) {
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
    
    private func showVideoController(_ videoURL: URL) {
        let videoController = VideoViewController(videoURL: videoURL)
        videoController.didSelectVideo = { [unowned self] videoURL in
            videoController.removeFromParentViewController()
            videoController.view.removeFromSuperview()
            self.cameraButton.reset()
            self.showUIElements(true)
            self.didSelectVideo?(videoURL)
        }
        
        videoController.willMove(toParentViewController: self)
        addChildViewController(videoController)
        view.addSubview(videoController.view)
        videoController.didMove(toParentViewController: self)
    }

    private func showUIElements(_ flag: Bool) {
        let newAlpha: CGFloat = flag ? 1.0 : 0.0
        UIView.animate(withDuration: 0.2, animations: {
            self.closeButton.alpha = newAlpha
            self.instructionsLabel.alpha = newAlpha
            self.toggleCameraButton.alpha = newAlpha
            self.toggleFlashButton.alpha = newAlpha
            if !flag && self.type.isVideo {
                self.counterView.alpha = 0.65
            }
        })
    }
    
    private func capturePhotoAsynchronously(completionHandler: ((_ success: Bool) -> Void)?) {
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

    private func enableFlash(_ flag: Bool) {
        guard useFrontCamera == false, let videoDevice = self.videoDevice else { return }
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
    
    private func startRecording() {
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

    private func stopRecording() {
        guard let movieFileOutput = self.movieFileOutput else { return }
        sessionQueue.async(execute: {
            guard movieFileOutput.isRecording else { return }
            movieFileOutput.stopRecording()
        })
        counterView.alpha = 0.0
    }
    
    private func takePhoto() {
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

    private func addInputs() {
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
        toggleFlashButton.isEnabled = !(type.isVideo && useFrontCamera)
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
    
    // MARK: - Initialize
    
    public static func `init`(type: CameraType) -> CameraViewController {
        let identifier = String(describing: CameraViewController.self)
        let storyboard = UIStoryboard(name: "LittleOwl", bundle: Bundle(for: CameraViewController.self))
        let cameraController = storyboard.instantiateViewController(withIdentifier: identifier) as! CameraViewController
        cameraController.type = type
        cameraController.maxDuration = type.maxDuration
        return cameraController
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
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
        print("error", error?.localizedDescription ?? "")
        enableFlash(false)
        OperationQueue.main.addOperation {
            self.showVideoController(outputFileURL)
        }
    }
}
