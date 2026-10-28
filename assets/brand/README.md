# Hyprwise logo pack (SVG)

Colors: ink #1F2726 · green #28A050 · dark-mode ink #F2F7F4 · dark-mode green #3DD474
Background: #F6FBF8 → #DFF3E5 (light) · #17211D → #0C1210 (dark)

logo/      primary (with tagline), wordmark, dark, dark-transparent, mono black/white, mark-only
app-icon/  full-bleed square 1024 (no rounded corners — iOS/Android apply their own mask), iOS 1024, iOS dark 1024
android/   adaptive foreground/background/monochrome (108dp), Play Store 512, splash light/dark
web/       favicon.svg (square, auto dark mode)

Flutter: export PNGs from the SVGs, then use flutter_launcher_icons
(adaptive_icon_foreground / _background / _monochrome) and flutter_native_splash.
