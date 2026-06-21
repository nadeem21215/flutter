import 'package:flutter_test/flutter_test.dart';
import 'package:smart_institute_app/main.dart';

void main() {
  testWidgets('App starts successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartInstituteApp());

    expect(find.byType(SmartInstituteApp), findsOneWidget);
  });
}
