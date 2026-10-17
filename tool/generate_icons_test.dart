// Renders the Findly logo to the PNGs used by flutter_launcher_icons.
//
// Not part of the normal test suite (it lives outside test/). Regenerate with:
//   flutter test tool/generate_icons_test.dart
//   dart run flutter_launcher_icons
import 'dart:io';
import 'dart:ui' as ui;

import 'package:findly/widgets/findly_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _render(
  String path, {
  required int size,
  required FindlyLogoPainter painter,
  double glyphScale = 1,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final glyph = size * glyphScale;
  final offset = (size - glyph) / 2;
  canvas.translate(offset, offset);
  painter.paint(canvas, Size.square(glyph));
  final image = await recorder.endRecording().toImage(size, size);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File(path)..createSync(recursive: true);
  file.writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  testWidgets('generate launcher icon PNGs', (tester) async {
    await tester.runAsync(() async {
      // Legacy/iOS icon: full tile, edge to edge (iOS rounds the corners
      // itself; Android legacy icons keep the tile's own rounding).
      await _render(
        'assets/icon/icon.png',
        size: 1024,
        painter: const FindlyLogoPainter(),
      );
      // Adaptive foreground: glyph only on transparency. The background
      // colour comes from pubspec and the launcher applies its own mask.
      await _render(
        'assets/icon/icon_foreground.png',
        size: 1024,
        painter: const FindlyLogoPainter(showTile: false),
        glyphScale: 0.82,
      );
      await _render(
        'assets/icon/icon_monochrome.png',
        size: 1024,
        painter: const FindlyLogoPainter(showTile: false, monochrome: true),
        glyphScale: 0.82,
      );
    });
    expect(File('assets/icon/icon.png').existsSync(), isTrue);
  });
}
