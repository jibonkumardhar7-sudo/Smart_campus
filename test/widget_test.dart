import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_campus/core/app_theme.dart';
import 'package:smart_campus/core/validators.dart';
import 'package:smart_campus/core/widgets.dart';

Widget wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    home: Scaffold(body: child),
  );
}

void main() {
  group('Email validation', () {
    test('accepts a valid email', () {
      expect(Validators.email('student@gmail.com'), isNull);
    });

    test('rejects an invalid email', () {
      expect(Validators.email('student@'), isNotNull);
      expect(Validators.email('studentgmail.com'), isNotNull);
    });

    test('rejects an empty email', () {
      expect(Validators.email(''), isNotNull);
    });
  });

  group('Password validation', () {
    test('accepts a strong password', () {
      expect(Validators.password('Smart1234'), isNull);
    });

    test('rejects a short password', () {
      expect(Validators.password('Ab1'), isNotNull);
    });

    test('rejects a password without an uppercase letter', () {
      expect(Validators.password('smart1234'), isNotNull);
    });

    test('rejects a password without a lowercase letter', () {
      expect(Validators.password('SMART1234'), isNotNull);
    });

    test('rejects a password without a number', () {
      expect(Validators.password('SmartCampus'), isNotNull);
    });
  });

  group('Confirm password validation', () {
    test('accepts matching passwords', () {
      expect(Validators.confirmPassword('Smart1234', 'Smart1234'), isNull);
    });

    test('rejects different passwords', () {
      expect(Validators.confirmPassword('Smart1234', 'Smart5678'), isNotNull);
    });
  });

  group('Phone validation', () {
    test('accepts a valid phone number', () {
      expect(Validators.phone('01799449370'), isNull);
    });

    test('rejects a short phone number', () {
      expect(Validators.phone('0179'), isNotNull);
    });

    test('rejects letters in a phone number', () {
      expect(Validators.phone('01799abc370'), isNotNull);
    });
  });

  group('Student ID validation', () {
    test('accepts a valid student ID', () {
      expect(Validators.studentId('0182420012101050'), isNull);
    });

    test('rejects an empty student ID', () {
      expect(Validators.studentId(''), isNotNull);
    });

    test('rejects a student ID with spaces', () {
      expect(Validators.studentId('01 82 42'), isNotNull);
    });
  });

  group('Required and price validation', () {
    test('required field cannot be empty', () {
      expect(Validators.required('   ', 'Title'), isNotNull);
      expect(Validators.required('Laptop', 'Title'), isNull);
    });

    test('price accepts numbers only', () {
      expect(Validators.price('1200'), isNull);
      expect(Validators.price('99.50'), isNull);
      expect(Validators.price('abc'), isNotNull);
    });
  });

  group('Reusable widgets', () {
    testWidgets('AppButton shows its label and reacts to taps', (WidgetTester tester) async {
      var tapped = false;

      await tester.pumpWidget(
        wrap(AppButton(label: 'Login', onPressed: () => tapped = true)),
      );

      expect(find.text('Login'), findsOneWidget);
      await tester.tap(find.text('Login'));
      expect(tapped, isTrue);
    });

    testWidgets('AppButton shows a spinner while loading', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrap(AppButton(label: 'Login', loading: true, onPressed: () {})),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Login'), findsNothing);
    });

    testWidgets('EmptyView shows its message', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(const EmptyView(message: 'No notices found')));

      expect(find.text('No notices found'), findsOneWidget);
    });

    testWidgets('EmptyView shows a retry button when onRetry is given', (WidgetTester tester) async {
      var retried = false;

      await tester.pumpWidget(
        wrap(EmptyView(message: 'Could not load', onRetry: () => retried = true)),
      );

      await tester.tap(find.text('Try again'));
      expect(retried, isTrue);
    });

    testWidgets('AppTextField toggles password visibility', (WidgetTester tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        wrap(AppTextField(controller: controller, label: 'Password', obscure: true)),
      );

      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pump();
      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });
  });

  group('Themes', () {
    test('light and dark themes use different brightness', () {
      expect(AppTheme.light.brightness, Brightness.light);
      expect(AppTheme.dark.brightness, Brightness.dark);
    });
  });
}