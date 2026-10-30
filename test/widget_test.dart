import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:testflutter/app/app.dart';

void main() {
  testWidgets('displays the home screen', (WidgetTester tester) async {
    await initializeDateFormatting('ja');
    await tester.pumpWidget(const ProviderScope(child: App()));
    await tester.pumpAndSettle();

    expect(find.text('試験まで あと'), findsOneWidget);
    expect(find.text('今日の目標'), findsOneWidget);
  });
}
