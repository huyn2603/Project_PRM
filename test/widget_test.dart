import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freelance_finance_app/main.dart';

void main() {
  testWidgets(
      'freelancer logs in, creates project, records payment, and logs out',
      (tester) async {
    await tester.pumpWidget(const FreelanceFinanceApp());

    expect(find.text('Đăng nhập'), findsWidgets);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'freelancer@test.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Mật khẩu'),
      '123456',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.pumpAndSettle();

    expect(find.text('Tài chính Freelancer'), findsOneWidget);

    await tester.tap(find.text('Dự án'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Mới'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Tên dự án'),
      'Website portfolio',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Khách hàng'),
      'Nova Client',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Giá trị hợp đồng'),
      '10000000',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Hạn thanh toán'),
      '30/06',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Thêm'));
    await tester.pumpAndSettle();

    expect(find.text('Website portfolio'), findsOneWidget);

    await tester.tap(find.text('Thu nợ'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Ghi thu').first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Số tiền nhận'),
      '1000000',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Ghi nhận'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Tài khoản'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đăng xuất'));
    await tester.pumpAndSettle();

    expect(find.text('Đăng nhập'), findsWidgets);
  });
}
