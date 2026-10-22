# iOS launch screen artwork

`Contents.json` maps `LaunchImage.png`, `LaunchImage@2x.png`, and
`LaunchImage@3x.png` to the asset used by `ios/Runner/Base.lproj/LaunchScreen.storyboard`.

When updating branding, keep these images consistent with the source logo in
`assets/images/logo.png` and the Flutter/web splash. Changing the Flutter source
asset does not automatically regenerate these native files. Preserve the filenames
and scale mappings, or update the asset catalog and storyboard together.

From the Flutter project root, open `ios/Runner.xcworkspace` in Xcode to preview
the native launch screen. App launcher icons live in the separate `AppIcon.appiconset`.
