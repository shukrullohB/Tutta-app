import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tutta/app/app.dart';

void main() {
  testWidgets('App boots with splash', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: TuttaApp()));
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
