[![Version](https://img.shields.io/github/v/tag/virtualspirit/ZLImageEditor.svg?color=blue&sort=semver)](https://github.com/virtualspirit/ZLImageEditor/tags)
[![SwiftPM compatible](https://img.shields.io/badge/SwiftPM-supported-E57141.svg)](https://swift.org/package-manager/)
[![License](https://img.shields.io/badge/license-MIT-black)](https://raw.githubusercontent.com/virtualspirit/ZLImageEditor/master/LICENSE)
[![Platform](https://img.shields.io/badge/Platforms-iOS-blue?style=flat)](https://img.shields.io/badge/Platforms-iOS-blue?style=flat)
![Language](https://img.shields.io/badge/Language-%20Swift%20-E57141.svg)

A powerful iOS image editor framework. Supports drawing, cropping, mosaic, text stickers, image stickers, filters, and image adjustments.

Forked from [longitachi/ZLImageEditor](https://github.com/longitachi/ZLImageEditor) with customizations for use via [rn-photo-editor](https://github.com/virtualspirit/rn-photo-editor).

---

## Features

- [x] Draw (custom line color, width, style)
- [x] Crop (free-style and custom ratios)
- [x] Image sticker (custom sticker container view)
- [x] Text sticker (custom text color and font)
- [x] Mosaic
- [x] Filter (custom filters)
- [x] Adjust (Brightness, Contrast, Saturation)
- [x] Undo / Redo for all operations

---

## Requirements

| Version | iOS |
|---------|-----|
| v >= 2.0.0 | iOS 10.0+ |
| v < 2.0.0 | iOS 9.0+ |

- Swift 5.x
- Xcode 12.x+

---

## Installation

### CocoaPods

```ruby
pod 'ZLImageEditor', :git => 'https://github.com/virtualspirit/ZLImageEditor.git', :tag => '3.0.6'
```

Then run:

```sh
pod install
```

### Swift Package Manager

1. File > Add Package Dependencies
2. Enter: `https://github.com/virtualspirit/ZLImageEditor.git`
3. Set version rule to **Up to Next Major** starting from `3.0.6`

---

## Usage

```swift
ZLImageEditorConfiguration.default()
    .editImageTools([.draw, .clip, .imageSticker, .textSticker, .mosaic, .filter, .adjust])
    .adjustTools([.brightness, .contrast, .saturation])

ZLEditImageViewController.showEditImageVC(
    parentVC: self,
    image: image,
    editModel: editModel
) { [weak self] resImage, editModel in
    // resImage: edited UIImage
    // editModel: ZLEditImageModel for re-editing
}
```

---

## Languages

🇨🇳 Chinese (Simplified/Traditional), 🇺🇸 English, 🇯🇵 Japanese, 🇫🇷 French, 🇩🇪 German, 🇺🇦 Ukrainian, 🇷🇺 Russian, 🇻🇳 Vietnamese, 🇰🇷 Korean, 🇲🇾 Malay, 🇮🇹 Italian, 🇮🇩 Indonesian, 🇪🇸 Spanish, 🇵🇹 Portuguese, 🇹🇷 Turkish, 🇸🇦 Arabic, 🇳🇱 Dutch.

---

## License

MIT
