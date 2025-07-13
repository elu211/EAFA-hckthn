// This is a basic Flutter widget test for the AI Dashcam App.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_car_app/main.dart';

void main() {
  testWidgets('AI Dashcam App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MaterialApp(home: AIDashcamApp()));

    // Verify that the app loads with basic elements
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(SafeArea), findsOneWidget);
    
    // Verify that the status bar is present
    expect(find.text('GPS'), findsOneWidget);
    
    // Verify that camera display area is present
    expect(find.text('Rear Camera'), findsOneWidget);
    expect(find.text('Camera Feed Active'), findsOneWidget);
    expect(find.text('✅ Camera Ready'), findsOneWidget);
  });

  testWidgets('Camera mode switching test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MaterialApp(home: AIDashcamApp()));

    // Find the front camera button
    final frontCameraButton = find.text('Front');
    expect(frontCameraButton, findsOneWidget);

    // Ensure the button is visible before tapping
    await tester.ensureVisible(frontCameraButton);
    await tester.tap(frontCameraButton);
    await tester.pump();

    // Verify that an alert message appears confirming the switch
    expect(find.textContaining('Switched to front camera'), findsOneWidget);
  });

  testWidgets('AI features test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MaterialApp(home: AIDashcamApp()));

    // Verify that AI features section is present
    expect(find.text('AI Features'), findsOneWidget);
    expect(find.text('Lane Detection'), findsOneWidget);
    expect(find.text('Collision Warning'), findsOneWidget);
    expect(find.text('Speed Limit'), findsOneWidget);
    expect(find.text('Parking Mode'), findsOneWidget);
  });

  testWidgets('Quick actions test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MaterialApp(home: AIDashcamApp()));

    // Verify that quick action buttons are present
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Emergency'), findsOneWidget);
  });
}
