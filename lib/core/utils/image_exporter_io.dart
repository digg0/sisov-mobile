import 'dart:io';
import 'dart:typed_data';

Future<String> saveImageBytesImpl(Uint8List bytes, String filename, String extension) async {
  final directory = Directory.systemTemp;
  final file = File('${directory.path}/$filename');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}
