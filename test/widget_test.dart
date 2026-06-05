import 'package:flutter_test/flutter_test.dart';
import 'package:freelance_finance_app/main.dart';

void main() {
  testWidgets('renders freelancer finance dashboard', (tester) async {
    await tester.pumpWidget(const FreelanceFinanceApp());

    expect(find.text('Tai chinh Freelancer'), findsOneWidget);
    expect(find.text('Rui ro cao'), findsWidgets);
  });
}
