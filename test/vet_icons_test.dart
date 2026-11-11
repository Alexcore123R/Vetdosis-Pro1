import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vetdosis_pro/vet_ui/vet_icons.dart';

void main() {
  test('cada icono apunta a la fuente VetIcons con un codigo unico', () {
    final codes = <int>{};
    for (final entry in VetIcons.all.entries) {
      expect(entry.value.fontFamily, 'VetIcons', reason: entry.key);
      expect(codes.add(entry.value.codePoint), isTrue, reason: entry.key);
    }
  });

  test('la clase generada coincide con codepoints.json y con svg/', () {
    final json =
        jsonDecode(File('tools/icons/codepoints.json').readAsStringSync())
            as Map<String, dynamic>;
    expect(
      {for (final e in VetIcons.all.entries) e.key: e.value.codePoint},
      json,
      reason: 'Falta volver a correr tools/icons/build_font.py',
    );
    final svgs = Directory('tools/icons/svg')
        .listSync()
        .map((f) => f.uri.pathSegments.last)
        .where((f) => f.endsWith('.svg'))
        .map((f) => f.substring(0, f.length - 4))
        .toSet();
    expect(svgs, json.keys.toSet());
  });

  test('pubspec declara la fuente que usan los iconos', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('family: VetIcons'));
    expect(pubspec, contains('assets/fonts/VetIcons.ttf'));
    expect(File('assets/fonts/VetIcons.ttf').existsSync(), isTrue);
  });

  testWidgets('un Icon de VetIcons se pinta con el color del tema', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: IconTheme(
          data: IconThemeData(color: Color(0xFF7C4DFF), size: 32),
          child: Icon(VetIcons.paw),
        ),
      ),
    );
    final text = tester.widget<RichText>(find.byType(RichText));
    expect(text.text.style?.fontFamily, 'VetIcons');
    expect(text.text.style?.color, const Color(0xFF7C4DFF));
    expect(text.text.style?.fontSize, 32);
  });
}
