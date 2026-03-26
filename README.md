# GallerySwiper 📸✨

**GallerySwiper** is a stylish, minimalist Android application designed to help you declutter your photo gallery quickly and efficiently using intuitive swipe gestures. Inspired by dating app mechanics, it turns the tedious task of cleaning up your photos into a fast and satisfying experience.

## ✨ Features

- **Intuitive Swiping:**
  - ⬅️ **Swipe Left:** Mark photo for deletion (Red indicator).
  - ➡️ **Swipe Right:** Keep the photo (Green indicator).
- **Two Ways to Load:**
  - **Scan All Photos:** Instantly load your entire gallery to start a deep clean.
  - **Pick Photos:** Select specific albums or a handful of photos to review.
- **Smart Deletion:** Uses modern Android `MediaStore` APIs to safely request deletion of multiple photos at once.
- **Undo Support:** Made a mistake? Quickly undo your last swipe.
- **Modern Dark UI:** A sleek, Material 3 dark-themed interface with smooth animations and rounded corners.
- **Progress Tracking:** Real-time progress bar and counter to show how many photos you've reviewed.
- **Instructions Overlay:** A helpful first-time guide to get you swiping immediately.

## 🛠️ Built With

- **Java** - Core logic.
- **Material Design 3** - Modern UI components and styling.
- **ConstraintLayout** - Flexible and responsive layouts.
- **MediaStore API** - For efficient and secure photo management.
- **Android Photo Picker** - For privacy-focused photo selection.

## 🚀 How to Use

1. **Launch the App:** Review the quick instruction popup.
2. **Load Photos:** Use "Scan All" or "Pick Photos" to populate the swiper.
3. **Swipe Away:** Drag photos left or right based on your choice.
4. **Finalize:** Once finished, tap "Delete Marked Photos" to confirm the removal of unwanted images from your device.

## 📱 Compatibility

- **Minimum SDK:** API 24 (Android 7.0)
- **Target SDK:** API 34
- **Optimized for:** Android 11+ (API 30+) for seamless bulk deletion.

## 📜 License

This project is open-source and available under the [MIT License](LICENSE).
