import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void main() {
  test('LucideIcons and fallback Icons should resolve valid IconData', () {
    expect(LucideIcons.utensils, isA<IconData>());
    expect(LucideIcons.car, isA<IconData>());
    expect(LucideIcons.shoppingBag, isA<IconData>());
    expect(LucideIcons.wallet, isA<IconData>());
    expect(Icons.category, isA<IconData>());
  });
}
