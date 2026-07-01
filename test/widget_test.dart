import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:agricore/services/auth_service.dart';
import 'package:agricore/services/database_service.dart';
import 'package:agricore/main.dart';
import 'package:agricore/ui/views/login_view.dart';

void main() {
  testWidgets('App boots up securely and renders login view by default', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthService()),
          ChangeNotifierProvider(create: (_) => DatabaseService()),
        ],
        child: const AgriCoreApp(),
      ),
    );

    // Verify that the login view elements are rendered.
    expect(find.byType(LoginView), findsOneWidget);
    expect(find.text('Operations Console'), findsOneWidget);
    expect(find.text('Access Platform'), findsOneWidget);
    
    // Verify that the dashboard is NOT rendered by default (guarded by authentication)
    expect(find.text('Operational Dashboard'), findsNothing);
  });
}
