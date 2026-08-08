import 'package:flutter_test/flutter_test.dart';
import 'package:seraphx/main.dart';

void main() {
  testWidgets('SeraphXApp builds without throwing', (WidgetTester tester) async {
    await tester.pumpWidget(const SeraphXApp());
    // Cukup pastikan widget root ke-render tanpa exception,
    // gak perlu assert isi UI detail di sini.
    expect(find.byType(SeraphXApp), findsOneWidget);
  });
}
