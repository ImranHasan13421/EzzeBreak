// ignore_for_file: avoid_print
import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final logoFile = File('assets/logo/applogo.png');
  if (!logoFile.existsSync()) {
    print('Error: assets/logo/applogo.png not found!');
    exit(1);
  }

  final bytes = logoFile.readAsBytesSync();
  final image = img.decodeImage(bytes);
  if (image == null) {
    print('Error: Failed to decode image!');
    exit(1);
  }

  final targets = {
    'android/app/src/main/res/mipmap-mdpi/ic_launcher.png': 48,
    'android/app/src/main/res/mipmap-hdpi/ic_launcher.png': 72,
    'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png': 96,
    'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png': 144,
    'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png': 192,
  };

  for (final entry in targets.entries) {
    final size = entry.value;
    final resized = img.copyResize(image, width: size, height: size, interpolation: img.Interpolation.cubic);
    final targetFile = File(entry.key);
    targetFile.parent.createSync(recursive: true);
    targetFile.writeAsBytesSync(img.encodePng(resized));
    print('Generated ${entry.key} ($size x $size)');
  }

  print('All Android launcher icons generated successfully!');
}
