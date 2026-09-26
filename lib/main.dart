import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'data/models/user_role.dart';
import 'application/products/product_provider.dart';
import 'application/cart/cart_provider.dart';
import 'application/wishlist/wishlist_provider.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/screens/splash/splash_screen.dart';
import 'presentation/screens/welcome/welcome_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/role_selection_screen.dart';
import 'presentation/screens/auth/register_screen.dart';
import 'presentation/screens/customer/shell/customer_shell.dart';
import 'application/orders/order_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('.env file not found or failed to load: $e');
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase not configured yet: $e');
  }

  runApp(const HarvestHubApp());
}

class HarvestHubApp extends StatelessWidget {
  const HarvestHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
      ],
      child: MaterialApp(
        title: 'HarvestHub',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        initialRoute: SplashScreen.routeName,
        routes: {
          SplashScreen.routeName: (context) => const SplashScreen(),
          WelcomeScreen.routeName: (context) => const WelcomeScreen(),
          RoleSelectionScreen.routeName: (context) => const RoleSelectionScreen(),
          LoginScreen.routeName: (context) => const LoginScreen(),
          CustomerShell.routeName: (context) => const CustomerShell(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == RegisterScreen.routeName) {
            final role = settings.arguments as UserRole? ?? UserRole.customer;
            return MaterialPageRoute(
              builder: (context) => RegisterScreen(role: role),
              settings: settings,
            );
          }
          return null;
        },
      ),
    );
  }
}