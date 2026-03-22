import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final image = img.Image(width: 1, height: 1);
  // Transparent pixel
  image.setPixelRgba(0, 0, 0, 0, 0, 0);
  File('assets/test_square.png').writeAsBytesSync(img.encodePng(image));
  print('Created test_square.png');
}
