import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freelance_finance_app/main.dart';

void main() {
  testWidgets('renders freelancer finance dashboard', (tester) async {
    await tester.pumpWidget(const FreelanceFinanceApp());

    expect(find.text('Đăng nhập'), findsWidgets);

    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.pumpAndSettle();

    expect(find.text('Tài chính Freelancer'), findsOneWidget);
    expect(find.text('Rủi ro cao'), findsWidgets);
  });
}
