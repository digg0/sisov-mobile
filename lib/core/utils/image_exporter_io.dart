import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as path;

Future<String> saveImageBytesImpl(Uint8List bytes, String filename, String extension) async {
  final downloadDir = Platform.isAndroid
      ? Directory('/storage/emulated/0/Download')
      : Directory.systemTemp;

  if (!await downloadDir.exists()) {
    await downloadDir.create(recursive: true);
  }

  final downloadFile = File(path.join(downloadDir.path, filename));
  await downloadFile.writeAsBytes(bytes, flush: true);
  
  return 'QR Code exportado com sucesso!\n${downloadFile.path}';
}
