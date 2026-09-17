import 'package:flutter/services.dart';

abstract class ClipboardReader {
  Future<String?> readText();
  Future<void> writeText(String text);
}

class SystemClipboardReader implements ClipboardReader {
  @override
  Future<String?> readText() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  @override
  Future<void> writeText(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }
}
