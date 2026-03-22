import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final iconFile = File('assets/mainIcon.png');
  final mainIcon = img.decodeImage(iconFile.readAsBytesSync());
  if (mainIcon == null) return;

  // Create a 288x288 empty (transparent) image
  final canvas = img.Image(width: 288, height: 288);
  
  // 130x130 white square offset by 79
  final int squareSize = 130;
  final int offset = (288 - squareSize) ~/ 2;
  
  // draw rounded rect
  for (int y = 0; y < squareSize; y++) {
    for (int x = 0; x < squareSize; x++) {
      double r = 28.0;
      double dx = 0, dy = 0;
      if (x < r && y < r) { dx = r - x; dy = r - y; }
      else if (x > squareSize - r && y < r) { dx = x - (squareSize - r); dy = r - y; }
      else if (x < r && y > squareSize - r) { dx = r - x; dy = y - (squareSize - r); }
      else if (x > squareSize - r && y > squareSize - r) { dx = x - (squareSize - r); dy = y - (squareSize - r); }
      
      if (dx > 0 || dy > 0) {
        if (dx*dx + dy*dy > r*r) continue;
      }
      
      canvas.setPixelRgba(offset + x, offset + y, 240, 242, 245, 255);
    }
  }
  
  // Resize mainIcon to fit inside the square (84x84)
  final iconResized = img.copyResize(mainIcon, width: 84, height: 84);
  img.compositeImage(canvas, iconResized, dstX: 288~/2 - 42, dstY: 288~/2 - 42);
  
  File('assets/ka3ba.png').writeAsBytesSync(img.encodePng(canvas));
  print('Created transparent.png');
}
