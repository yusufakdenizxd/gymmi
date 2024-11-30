default:
  @just --list
clean:
  flutter clean
pubget:
  flutter pub get --no-example
podinstall:
  cd ios && pod install && cd ..
run:
  flutter run
buildipa:
  flutter build ipa
buildappbundle:
  flutter build appbundle
buildapk:
  flutter build apk
