# NaeemSoft-POS

Arabic-first Flutter POS foundation for a single vegetable and fruit shop.

## Run on Android
1. Install Flutter stable and Android SDK.
2. Clone this repository.
3. Run `flutter pub get`.
4. Run `flutter run` or `flutter build apk --release`.

## Current implementation
- Arabic RTL interface and bottom navigation.
- Local SQLite database on the device.
- Product catalog with purchase unit, default package weight, cost and retail price.
- Purchase entry supports multiple products and variable package weights; posting increases shop stock.
- Retail sale cart; posting decreases shop stock and checks available quantity.
- Dashboard and stock view.

## Important scope note
This is the first working foundation, not the complete requested accounting release yet. Supplier/customer profiles, payment allocation and statements, customer-specific prices, invoice PDF/share/printing, expiry tracking, and full reports still need implementation. The app has not yet been built or tested on a physical Android device.

The Android GitHub Actions workflow attempts an APK build on pushes to `main`. Check the Actions tab for its result and downloadable artifact.
