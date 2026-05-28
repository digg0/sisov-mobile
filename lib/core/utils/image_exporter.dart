import 'dart:typed_data';

import 'image_exporter_io.dart'
    if (dart.library.html) 'image_exporter_web.dart';

Future<String> saveImageBytes(Uint8List bytes, String filename, String extension) async {
  return saveImageBytesImpl(bytes, filename, extension);
}
