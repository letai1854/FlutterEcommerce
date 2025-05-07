import 'dart:io';

import 'package:e_commerce_app/Screens/Admin/AdminReponsicve.dart';
import 'package:e_commerce_app/Screens/Cart/PageCart.dart';
import 'package:e_commerce_app/Screens/Chat/PageChat.dart';
import 'package:e_commerce_app/Screens/ForgotPassword/PageForgotPassword.dart';
import 'package:e_commerce_app/Screens/ListProduct/PageListProduct.dart';
import 'package:e_commerce_app/Screens/Login/PageLogin.dart';
import 'package:e_commerce_app/Screens/Payment/PagePayment.dart';
import 'package:e_commerce_app/Screens/ProductDetail/PageProductDetail.dart';
import 'package:e_commerce_app/Screens/Search/PageSearch.dart';
import 'package:e_commerce_app/Screens/SignUp/PageSignup.dart';
import 'package:e_commerce_app/Screens/SuccessPayment/PageSuccessPayment.dart';
import 'package:e_commerce_app/Screens/UserInfo/ResponsiveUserInfo.dart';
import 'package:e_commerce_app/database/Storage/BrandCategoryService.dart';
import 'package:e_commerce_app/database/Storage/UserInfo.dart';
import 'package:e_commerce_app/database/services/user_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_strategy/url_strategy.dart';
import 'package:e_commerce_app/Screens/Home/home_responsive.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:e_commerce_app/providers/signup_form_provider.dart';
import 'package:e_commerce_app/providers/login_form_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

Future<void> initApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  setPathUrlStrategy();
  // Only attempt auto-login on non-web platforms
  if (!kIsWeb) {
    final userService = UserService();
    await userService.attemptAutoLogin();
    print('Auto-login attempted on ${kIsWeb ? 'web' : 'native'} platform');
  } else {
    print('Auto-login skipped on web platform');
  }
  // // Initialize user session
  // final userProvider = UserProvider();
  // await userProvider.loadUserSession();
  // await AppDataService().loadData();
  print('AppDataService loaded successfully during app init.');
}

void main() async {
  await initApp();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SignupFormProvider()),
        ChangeNotifierProvider(create: (_) => LoginFormProvider()),
      ],
      child: const MyApp(),
    ),
  );
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
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate, // Cần cho Material DatePicker
        GlobalWidgetsLocalizations.delegate, // Cần cho các widget cơ bản
        GlobalCupertinoLocalizations
            .delegate, // Tùy chọn nếu dùng Cupertino design
      ],
      supportedLocales: const [
        Locale('en', ''), // Hỗ trợ Tiếng Anh
        Locale('vi', 'VN'), // <-- HỖ TRỢ TIẾNG VIỆT CHO showDateRangePicker
      ],
      // Tùy chọn: Logic xác định ngôn ngữ mặc định
      localeResolutionCallback: (locale, supportedLocales) {
        for (var supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale?.languageCode &&
              supportedLocale.countryCode == locale?.countryCode) {
            return supportedLocale;
          }
        }
        return supportedLocales.first; // Mặc định là ngôn ngữ đầu tiên hỗ trợ
      },
      initialRoute: '/', // Đảm bảo có route mặc định
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/login':
            if (UserInfo().currentUser == null) {
              return PageRouteBuilder(
                pageBuilder: (context, _, __) => const Pagelogin(),
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
          case '/info':
            return PageRouteBuilder(
              pageBuilder: (context, _, __) => const ResponsiveUserInfo(),
              settings: settings,
            );
          case '/chat':
            return PageRouteBuilder(
              pageBuilder: (context, _, __) => const Pagechat(),
              settings: settings,
            );
          case '/signup':
            return PageRouteBuilder(
              pageBuilder: (context, _, __) => const PageSignup(),
              settings: settings,
            );

          case '/catalog_product':
            return PageRouteBuilder(
              pageBuilder: (context, _, __) => const PageListProduct(),
              settings: settings,
            );
          case '/product_detail':
            return PageRouteBuilder(
              pageBuilder: (context, _, __) => const Pageproductdetail(),
              settings: settings,
            );
          case '/cart':
            return PageRouteBuilder(
              pageBuilder: (context, _, __) => const PageCart(),
              settings: settings,
            );
          case '/payment':
            return PageRouteBuilder(
              pageBuilder: (context, _, __) => const PagePayment(),
              settings: settings,
            );
          case '/payment_success':
            return PageRouteBuilder(
              pageBuilder: (context, _, __) => const Pagesuccesspayment(),
              settings: settings,
            );
          case '/forgot_password':
            return PageRouteBuilder(
              pageBuilder: (context, _, __) => const Pageforgotpassword(),
              settings: settings,
            );
          case '/search':
            return PageRouteBuilder(
              pageBuilder: (context, _, __) => const PageSearch(),
              settings: settings,
            );
          case '/admin':
            return PageRouteBuilder(
              pageBuilder: (context, _, __) => const AdminResponsive(),
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
//commit
