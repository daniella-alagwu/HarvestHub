import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harvesthub/data/models/user_role.dart';
import 'package:harvesthub/firebase_options.dart';
import 'package:harvesthub/presentation/screens/auth/register_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('farmer registration requires farm description and photo uploads',
      (tester) async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: RegisterScreen(role: UserRole.farmer),
      ),
    );

    expect(find.text('Farm Description'), findsOneWidget);
    expect(find.text('Profile Photo'), findsOneWidget);
    expect(find.text('Farm Photo'), findsOneWidget);
  });
}
