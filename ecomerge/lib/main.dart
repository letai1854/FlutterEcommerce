import 'package:e_commerce_app/Provider/UserProvider.dart';
import 'package:e_commerce_app/Screens/ListProduct/ListProduct_responsive.dart';
import 'package:e_commerce_app/Screens/ProductDetail/ProductDeitalResponsive.dart';
import 'package:flutter/material.dart';
import 'package:url_strategy/url_strategy.dart';
import 'package:e_commerce_app/Screens/Chat/ResponsiveChat.dart';
import 'package:e_commerce_app/Screens/Home/home_responsive.dart';
import 'package:e_commerce_app/Screens/Login/login_responsive.dart';
import 'package:e_commerce_app/Screens/SignUp/SignUp_Reponsive.dart';
import 'package:flutter/material.dart';

Future<void> initApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  setPathUrlStrategy();

  // Initialize user session
  final userProvider = UserProvider();
  await userProvider.loadUserSession();
}

void main() async {
  await initApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Shopii',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/', // Đảm bảo có route mặc định
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/login':
            if (UserProvider().currentUser == null) {
              return PageRouteBuilder(
                pageBuilder: (context, _, __) => const ResponsiveLogin(),
                settings: settings,
              );
            } else {
              return PageRouteBuilder(
                pageBuilder: (context, _, __) => const ResponsiveHome(),
                settings: const RouteSettings(name: '/home'),
              );
            }
          case '/home':
            return PageRouteBuilder(
              pageBuilder: (context, _, __) => const ResponsiveHome(),
              settings: settings,
            );
          case '/chat':
            return PageRouteBuilder(
              pageBuilder: (context, _, __) => const Responsivechat(),
              settings: settings,
            );
          case '/signup':
            return PageRouteBuilder(
              pageBuilder: (context, _, __) => const ReponsiveSignUp(),
              settings: settings,
            );
            case '/catalog_product':
            return PageRouteBuilder(
              pageBuilder: (context, _, __) => const ResponsiveListProduct(),
              settings: settings,
            );
          case '/product_detail':
            return PageRouteBuilder(
              pageBuilder: (context, _, __) => const ResponsiveProductDetail(),
              settings: settings,
            );
          default:
            return PageRouteBuilder(
              pageBuilder: (context, _, __) => const ResponsiveHome(),
              settings: settings,
            );
        }
      },
    );
  }
}
