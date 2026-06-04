import 'package:flutter_test/flutter_test.dart';
import 'package:reeliq/main.dart';

void main() {
  testWidgets('App smoke compile test', (WidgetTester tester) async {
    // Basic test to verify the app compiles and is instantiable
    const app = ReelIQApp();
    expect(app, isNotNull);
  });
}
