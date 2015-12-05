/*
Abstract: This class contains methods to apply blur and tint effects to an image.
This is the code you’ll want to look out to find out how to use vImage to
efficiently calculate a blur.

Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
Inc. ("Apple") in consideration of your agreement to the following
terms, and your use, installation, modification or redistribution of
this Apple software constitutes acceptance of these terms.  If you do
not agree with these terms, please do not use, install, modify or
redistribute this Apple software.

In consideration of your agreement to abide by the following terms, and
subject to these terms, Apple grants you a personal, non-exclusive
license, under Apple's copyrights in this original Apple software (the
"Apple Software"), to use, reproduce, modify and redistribute the Apple
Software, with or without modifications, in source and/or binary forms;
provided that if you redistribute the Apple Software in its entirety and
without modifications, you must retain this notice and the following
text and disclaimers in all such redistributions of the Apple Software.
Neither the name, trademarks, service marks or logos of Apple Inc. may
be used to endorse or promote products derived from the Apple Software
without specific prior written permission from Apple.  Except as
expressly stated in this notice, no other rights or licenses, express or
implied, are granted by Apple herein, including but not limited to any
patent rights that may be infringed by your derivative works or by other
works in which the Apple Software may be incorporated.

The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.

IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

Copyright (C) 2014 Apple Inc. All Rights Reserved.

*/


/*
UIImageEffects.swift

This extension is based on Apple's UIImage category in sample code "Blurring and Tinting an Image":
https://developer.apple.com/library/ios/samplecode/UIImageEffects/Introduction/Intro.html#//apple_ref/doc/uid/DTS40013396

Created by Xin Hong on 15/12/5.
https://github.com/hongxinhope
*/


import UIKit
import Accelerate

public extension UIImage {
    public func applyLightEffect() -> UIImage? {
        let tintColor = UIColor(white: 1, alpha: 0.3)
        return applyBlur(blurRadius: 60, tintColor: tintColor, saturationDeltaFactor: 1.8)
    }

    public func applyExtraLightEffect() -> UIImage? {
        let tintColor = UIColor(white: 0.97, alpha: 0.82)
        return applyBlur(blurRadius: 40, tintColor: tintColor, saturationDeltaFactor: 1.8)
    }

    public func applyDarkEffect() -> UIImage? {
        let tintColor = UIColor(white: 0.11, alpha: 0.73)
        return applyBlur(blurRadius: 40, tintColor: tintColor, saturationDeltaFactor: 1.8)
    }

    public func applyTintEffect(tintColor tintColor: UIColor) -> UIImage? {
        let effectColorAlpha: CGFloat = 0.6
        var effectColor = tintColor
        let componentCount = CGColorGetNumberOfComponents(tintColor.CGColor)

        if componentCount == 2 {
            var b: CGFloat = 0
            if tintColor.getWhite(&b, alpha: nil) {
                effectColor = UIColor(white: b, alpha: effectColorAlpha)
            }
        } else {
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
            if tintColor.getRed(&r, green: &g, blue: &b, alpha: nil) {
                effectColor = UIColor(red: r, green: g, blue: b, alpha: effectColorAlpha)
            }
        }
        return applyBlur(blurRadius: 20, tintColor: effectColor, saturationDeltaFactor: -1)
    }

    public func applyBlur(blurRadius blurRadius: CGFloat, tintColor: UIColor?, saturationDeltaFactor: CGFloat, maskImage: UIImage? = nil) -> UIImage? {
        func preconditionsValid() -> Bool {
            if size.width < 1 || size.height < 1 {
                print("error: invalid image size: (\(size.width, size.height). Both width and height must >= 1)")
                return false
            }
            if CGImage == nil {
                print("error: image must be backed by a CGImage")
                return false
            }
            if let maskImage = maskImage {
                if maskImage.CGImage == nil {
                    print("error: effectMaskImage must be backed by a CGImage")
                    return false
                }
            }
            return true
        }

        if !preconditionsValid() {
            return nil
        }

        let hasBlur = blurRadius > CGFloat(FLT_EPSILON)
        let hasSaturationChange = fabs(saturationDeltaFactor - 1) > CGFloat(FLT_EPSILON)

        let inputCGImage = CGImage!
        let inputImageScale = scale
        let inputImageBitmapInfo = CGImageGetBitmapInfo(inputCGImage)
        let inputImageAlphaInfo = CGImageAlphaInfo(rawValue: inputImageBitmapInfo.rawValue & CGBitmapInfo.AlphaInfoMask.rawValue)

        let outputImageSizeInPoints = size
        let outputImageRectInPoints = CGRect(origin: CGPointZero, size: outputImageSizeInPoints)

        let useOpaqueContext = inputImageAlphaInfo == .None || inputImageAlphaInfo == .NoneSkipLast || inputImageAlphaInfo == .NoneSkipFirst
        UIGraphicsBeginImageContextWithOptions(outputImageRectInPoints.size, useOpaqueContext, inputImageScale)
        let outputContext = UIGraphicsGetCurrentContext()
        CGContextScaleCTM(outputContext, 1, -1)
        CGContextTranslateCTM(outputContext, 0, -outputImageRectInPoints.height)

        if hasBlur || hasSaturationChange {
            var effectInBuffer = vImage_Buffer()
            var scratchBuffer1 = vImage_Buffer()
            var inputBuffer: UnsafeMutablePointer<vImage_Buffer>
            var outputBuffer: UnsafeMutablePointer<vImage_Buffer>

            let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.PremultipliedFirst.rawValue | CGBitmapInfo.ByteOrder32Little.rawValue)
            var format = vImage_CGImageFormat(bitsPerComponent: 8,
                                                  bitsPerPixel: 32,
                                                    colorSpace: nil,
                                                    bitmapInfo: bitmapInfo,
                                                       version: 0,
                                                        decode: nil,
                                               renderingIntent: .RenderingIntentDefault)

            let error = vImageBuffer_InitWithCGImage(&effectInBuffer, &format, nil, inputCGImage, vImage_Flags(kvImagePrintDiagnosticsToConsole))
            if error != kvImageNoError {
                print("error: vImageBuffer_InitWithCGImage returned error code \(error)")
                UIGraphicsEndImageContext()
                return nil
            }

            vImageBuffer_Init(&scratchBuffer1, effectInBuffer.height, effectInBuffer.width, format.bitsPerPixel, vImage_Flags(kvImageNoFlags))
            inputBuffer = withUnsafeMutablePointer(&effectInBuffer, { (address) -> UnsafeMutablePointer<vImage_Buffer> in
                return address
            })
            outputBuffer = withUnsafeMutablePointer(&scratchBuffer1, { (address) -> UnsafeMutablePointer<vImage_Buffer> in
                return address
            })

            if hasBlur {
                var inputRadius = blurRadius * inputImageScale
                if inputRadius - 2 < CGFloat(FLT_EPSILON) {
                    inputRadius = 2
                }
                var radius = UInt32(floor((inputRadius * CGFloat(3) * CGFloat(sqrt(2 * M_PI)) / 4 + 0.5) / 2))
                radius |= 1

                let flags = vImage_Flags(kvImageGetTempBufferSize) | vImage_Flags(kvImageEdgeExtend)
                let tempBufferSize: Int = vImageBoxConvolve_ARGB8888(inputBuffer, outputBuffer, nil, 0, 0, radius, radius, nil, flags)
                let tempBuffer = malloc(tempBufferSize)

                vImageBoxConvolve_ARGB8888(inputBuffer, outputBuffer, tempBuffer, 0, 0, radius, radius, nil, vImage_Flags(kvImageEdgeExtend))
                vImageBoxConvolve_ARGB8888(outputBuffer, inputBuffer, tempBuffer, 0, 0, radius, radius, nil, vImage_Flags(kvImageEdgeExtend))
                vImageBoxConvolve_ARGB8888(inputBuffer, outputBuffer, tempBuffer, 0, 0, radius, radius, nil, vImage_Flags(kvImageEdgeExtend))

                free(tempBuffer)

                let temp = inputBuffer
                inputBuffer = outputBuffer
                outputBuffer = temp
            }

            if hasSaturationChange {
                let s = saturationDeltaFactor
                let floatingPointSaturationMatrix: [CGFloat] = [
                    0.0722 + 0.9278 * s,  0.0722 - 0.0722 * s,  0.0722 - 0.0722 * s,  0,
                    0.7152 - 0.7152 * s,  0.7152 + 0.2848 * s,  0.7152 - 0.7152 * s,  0,
                    0.2126 - 0.2126 * s,  0.2126 - 0.2126 * s,  0.2126 + 0.7873 * s,  0,
                                      0,                    0,                    0,  1,
                ]

                let divisor: Int32 = 256
                let matrixSize = floatingPointSaturationMatrix.count
                var saturationMatrix = [Int16](count: matrixSize, repeatedValue: 0)
                for i in 0..<matrixSize {
                    saturationMatrix[i] = Int16(round(floatingPointSaturationMatrix[i] * CGFloat(divisor)))
                }
                vImageMatrixMultiply_ARGB8888(inputBuffer, outputBuffer, saturationMatrix, divisor, nil, nil, vImage_Flags(kvImageNoFlags))

                let temp = inputBuffer
                inputBuffer = outputBuffer
                outputBuffer = temp
            }

            let cleanupBuffer: @convention(c) (UnsafeMutablePointer<Void>, UnsafeMutablePointer<Void>) -> Void = {(userData, buf_data) -> Void in
                free(buf_data)
            }
            var effectCGImage = vImageCreateCGImageFromBuffer(inputBuffer, &format, cleanupBuffer, nil, vImage_Flags(kvImageNoAllocate), nil)
            if effectCGImage == nil {
                effectCGImage = vImageCreateCGImageFromBuffer(inputBuffer, &format, nil, nil, vImage_Flags(kvImageNoFlags), nil)
                free(inputBuffer.memory.data)
            }
            if let _ = maskImage {
                CGContextDrawImage(outputContext, outputImageRectInPoints, inputCGImage)
            }

            CGContextSaveGState(outputContext)
            if let maskImage = maskImage {
                CGContextClipToMask(outputContext, outputImageRectInPoints, maskImage.CGImage)
            }
            CGContextDrawImage(outputContext, outputImageRectInPoints, effectCGImage.takeRetainedValue())
            CGContextRestoreGState(outputContext)

            free(outputBuffer.memory.data)
        } else {
            CGContextDrawImage(outputContext, outputImageRectInPoints, inputCGImage)
        }

        if let tintColor = tintColor {
            CGContextSaveGState(outputContext)
            CGContextSetFillColorWithColor(outputContext, tintColor.CGColor)
            CGContextFillRect(outputContext, outputImageRectInPoints)
            CGContextRestoreGState(outputContext)
        }

        let outputImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return outputImage
    }
}
