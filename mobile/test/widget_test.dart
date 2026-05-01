import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ros/main.dart';

void main() {
  testWidgets('landing screen starts with residence loading state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
