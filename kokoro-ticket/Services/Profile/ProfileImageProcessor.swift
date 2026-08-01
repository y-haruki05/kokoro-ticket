import Foundation
import UIKit

/// 選択画像をアップロード可能なJPEGへ縮小・圧縮する処理の契約
protocol ProfileImageProcessing: Sendable {
    func prepareJPEG(from sourceData: Data) throws -> Data
}

struct ProfileImageProcessor: ProfileImageProcessing {
    static let maximumSourceBytes = 20 * 1_024 * 1_024
    static let maximumUploadBytes = 5 * 1_024 * 1_024
    static let maximumDimension: CGFloat = 1_024

    func prepareJPEG(from sourceData: Data) throws -> Data {
        guard !sourceData.isEmpty, sourceData.count <= Self.maximumSourceBytes else {
            throw AppError.profileAvatarTooLarge
        }
        guard let sourceImage = UIImage(data: sourceData) else {
            throw AppError.profileAvatarInvalid
        }

        let sourceSize = sourceImage.size
        guard sourceSize.width > 0, sourceSize.height > 0 else {
            throw AppError.profileAvatarInvalid
        }

        let squareSide = min(sourceSize.width, sourceSize.height)
        let cropOrigin = CGPoint(
            x: (sourceSize.width - squareSide) / 2,
            y: (sourceSize.height - squareSide) / 2
        )
        let targetSide = min(squareSide, Self.maximumDimension)
        let renderer = UIGraphicsImageRenderer(
            size: CGSize(width: targetSide, height: targetSide),
            format: rendererFormat
        )
        let preparedImage = renderer.image { _ in
            sourceImage.draw(
                in: CGRect(
                    x: -cropOrigin.x * targetSide / squareSide,
                    y: -cropOrigin.y * targetSide / squareSide,
                    width: sourceSize.width * targetSide / squareSide,
                    height: sourceSize.height * targetSide / squareSide
                )
            )
        }

        guard let jpeg = preparedImage.jpegData(compressionQuality: 0.8),
              jpeg.count <= Self.maximumUploadBytes else {
            throw AppError.profileAvatarTooLarge
        }
        return jpeg
    }

    private var rendererFormat: UIGraphicsImageRendererFormat {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        format.preferredRange = .standard
        return format
    }
}
