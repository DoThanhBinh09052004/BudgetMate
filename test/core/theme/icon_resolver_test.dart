import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bugdetmate/core/theme/icon_resolver.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void main() {
  test('IconResolver maps string names to valid IconData with fallback', () {
    expect(IconResolver.resolve('utensils'), LucideIcons.utensils);
    expect(IconResolver.resolve('coffee'), LucideIcons.coffee);
    expect(IconResolver.resolve('car'), LucideIcons.car);
    expect(IconResolver.resolve('fuel'), LucideIcons.fuel);
    expect(IconResolver.resolve('shopping_bag'), LucideIcons.shoppingBag);
    expect(IconResolver.resolve('receipt'), LucideIcons.receipt);
    expect(IconResolver.resolve('home'), LucideIcons.home);
    expect(IconResolver.resolve('wallet'), LucideIcons.wallet);

    // Fallback test
    expect(IconResolver.resolve('unknown_icon_xyz'), Icons.category_rounded);
  });
}
