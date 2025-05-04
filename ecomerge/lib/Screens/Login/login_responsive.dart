// import 'package:e_commerce_app/Responsive/ResponsiveLayout.dart';
// import 'package:e_commerce_app/Screens/Login/Login_DeskTop.dart';
// import 'package:e_commerce_app/Screens/Login/Login_Mobile.dart';
// import 'package:e_commerce_app/Screens/Login/Login_tablet.dart';
// import 'package:e_commerce_app/providers/login_form_provider.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

// class ResponsiveLogin extends StatefulWidget {
//   const ResponsiveLogin({super.key});

//   @override
//   State<ResponsiveLogin> createState() => _ResponsiveLoginState();
// }

// class _ResponsiveLoginState extends State<ResponsiveLogin> {
//   @override
//   Widget build(BuildContext context) {
//     // Create a local provider instance just for this login flow
//     return ChangeNotifierProvider(
//       create: (_) => LoginFormProvider(),
//       child: ResponsiveLayout(
//         mobileScaffold: const LoginMobile(),
//         tableScaffold: const LoginTablet(),
//         destopScaffold: const LoginDesktop(),
//       ),
//     );
//   }
// }
