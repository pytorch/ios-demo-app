import AVFoundation
import Foundation

class CameraController: NSObject {
    var videoCaptureCompletionBlock: (([Float32]?, CameraControllerError?) -> Void)?
    private let inputWidth = 224
    private let inputHeight = 224
    private var captureSession = AVCaptureSession()
    private var videoOutput = AVCaptureVideoDataOutput()
    private var sessionQueue = DispatchQueue(label: "session")
    private var bufferQueue = DispatchQueue(label: "buffer")

    func configPreviewLayer(_ previewView: CameraPreviewView) {
        previewView.previewLayer.session = captureSession
        previewView.previewLayer.connection?.videoOrientation = .portrait
        previewView.previewLayer.videoGravity = .resizeAspectFill
    }

    func startSession() {
        func reportError(error: CameraControllerError) {
            DispatchQueue.main.async {
                if let callback = self.videoCaptureCompletionBlock {
                    callback(nil, error)
                }
            }
        }
        sessionQueue.async {
            do {
                self.captureSession.sessionPreset = .high
                self.captureSession.beginConfiguration()
                try self.configCameraInput()
                try self.configCameraOutput()
                self.captureSession.commitConfiguration()
                self.prepare {
                    if $0, !self.captureSession.isRunning {
                        self.addListeners()
                        self.captureSession.startRunning()
                    } else {
                        reportError(error: .cameraAccessDenied)
                    }
                }
            } catch {
                reportError(error: .cameraConfigError)
            }
        }
    }

    func stopSession() {
        removeListeners()
        if captureSession.isRunning {
            sessionQueue.async {
                self.captureSession.stopRunning()
            }
        }
    }

    private func prepare(_ completionHandler: @escaping (Bool) -> Void) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) {
                completionHandler($0)
            }
            return
        }
        completionHandler(status == .authorized)
    }

    private func configCameraInput() throws {
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            throw CameraControllerError.cameraConfigError
        }
        let input = try AVCaptureDeviceInput(device: camera)
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        } else {
            throw CameraControllerError.invalidInput
        }
    }

    private func configCameraOutput() throws {
        videoOutput.setSampleBufferDelegate(self, queue: bufferQueue)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [String(kCVPixelBufferPixelFormatTypeKey): kCMPixelFormat_32BGRA]
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        } else {
            throw CameraControllerError.invalidOutput
        }
    }

    private func addListeners() {
        guard let callback = videoCaptureCompletionBlock else {
            return
        }
        let center = NotificationCenter.default
        let mainQueue = OperationQueue.main
        center.addObserver(forName: .AVCaptureSessionRuntimeError, object: nil, queue: mainQueue) { _ in
            callback(nil, .sessionError)
        }
    }

    private func removeListeners() {
        NotificationCenter.default.removeObserver(self)
    }
}

extension CameraController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        connection.videoOrientation = .portrait
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        guard let normalizedBuffer = pixelBuffer.normalized(inputWidth, inputHeight) else {
            return
        }
        if let callback = videoCaptureCompletionBlock {
            callback(normalizedBuffer, nil)
        }
    }
}

extension CameraController {
    enum CameraControllerError: Swift.Error {
        case cameraAccessDenied
        case cameraConfigError
        case invalidInput
        case invalidOutput
        case sessionError
        case unknown
    }
}
