import ImageIO
import UIKit

/// Decodifica GIFs con ImageIO, sin dependencias. Cachea animaciones y miniaturas.
enum GIFDecoder {
    private static let animations = NSCache<NSURL, UIImage>()
    private static let thumbnails = NSCache<NSURL, UIImage>()

    static func animatedImage(at url: URL) -> UIImage? {
        if let cached = animations.object(forKey: url as NSURL) { return cached }
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }

        let count = CGImageSourceGetCount(source)
        var frames: [UIImage] = []
        var duration = 0.0
        for index in 0..<count {
            guard let frame = CGImageSourceCreateImageAtIndex(source, index, nil) else { continue }
            frames.append(UIImage(cgImage: frame))
            duration += frameDelay(source: source, index: index)
        }
        guard let image = frames.count > 1
            ? UIImage.animatedImage(with: frames, duration: duration)
            : frames.first else { return nil }
        animations.setObject(image, forKey: url as NSURL)
        return image
    }

    static func thumbnail(at url: URL, maxPixelSize: Int = 240) -> UIImage? {
        if let cached = thumbnails.object(forKey: url as NSURL) { return cached }
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
        ]
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
        let image = UIImage(cgImage: cgImage)
        thumbnails.setObject(image, forKey: url as NSURL)
        return image
    }

    private static func frameDelay(source: CGImageSource, index: Int) -> Double {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any],
              let gif = properties[kCGImagePropertyGIFDictionary] as? [CFString: Any] else { return 0.1 }
        let delay = (gif[kCGImagePropertyGIFUnclampedDelayTime] as? Double)
            ?? (gif[kCGImagePropertyGIFDelayTime] as? Double)
            ?? 0.1
        return delay < 0.02 ? 0.1 : delay
    }
}
