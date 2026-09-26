import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

/// Abre o diálogo nativo "Salvar como" e grava os bytes no destino escolhido.
///
/// Retorna `false` quando o usuário cancela o diálogo.
Future<bool> saveBytesToFile({
  required Uint8List bytes,
  required String fileName,
  String mimeType = 'application/octet-stream',
}) async {
  final isMobile = Platform.isAndroid || Platform.isIOS;

  // No mobile o file_picker grava os bytes; no desktop ele só retorna o caminho.
  final path = await FilePicker.platform.saveFile(
    dialogTitle: 'Salvar imagem',
    fileName: fileName,
    bytes: isMobile ? bytes : null,
  );
  if (path == null) return false;

  if (!isMobile) {
    await File(path).writeAsBytes(bytes, flush: true);
  }
  return true;
}
