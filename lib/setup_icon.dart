import 'dart:io';

void main() {
  final sourceFile = File(r'C:\Users\sreej\.gemini\antigravity-ide\brain\33267269-47ed-476f-8704-a9684f9e8a02\app_icon_square_1786508146520.png');
  final destFile = File('assets/images/app_icon.png');

  if (!sourceFile.existsSync()) {
    print('Error: Source image not found at ${sourceFile.path}');
    return;
  }

  // Ensure assets/images directory exists
  Directory('assets/images').createSync(recursive: true);

  sourceFile.copySync(destFile.path);
  print('Successfully copied icon to ${destFile.path}!');
}
