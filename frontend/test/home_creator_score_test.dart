import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:creator_os/widgets/home/home_creator_score.dart';
import 'package:creator_os/utils/app_colors.dart';

void main() {
  testWidgets('HomeCreatorScore parses safely and renders fallback on network error', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: const [
            AppColors.light, // Provides all required color tokens for tests
          ],
        ),
        home: const Scaffold(
          body: HomeCreatorScore(),
        ),
      ),
    );

    // Initial state should be loading (since we aren't mocking the API here, it will throw an exception and catch it)
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Wait for the async API call to throw and the catch block to set the fallback state
    await tester.pumpAndSettle();

    // Verify it rendered the fallback successfully without crashing
    expect(find.text('Creator Score'), findsOneWidget);
    // Since we caught the exception, it defaults to the 82 score fallback
    expect(find.text('82'), findsOneWidget);
  });
}
