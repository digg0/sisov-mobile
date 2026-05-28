import 'dart:typed_data';
import 'dart:html' as html;

Future<String> saveImageBytesImpl(Uint8List bytes, String filename, String extension) async {
  final blob = html.Blob([bytes], 'image/$extension');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..style.display = 'none';

  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);

  return 'Download iniciado para $filename';
}
