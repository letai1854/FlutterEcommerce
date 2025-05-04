// import 'package:e_commerce_app/widgets/login_form.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/foundation.dart';
// import '../../widgets/footer.dart';
// import 'package:e_commerce_app/widgets/navbar.dart';

// class LoginTablet extends StatefulWidget {
//   const LoginTablet({super.key});

//   @override
//   State<LoginTablet> createState() => _LoginTabletState();
// }

// class _LoginTabletState extends State<LoginTablet> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color.fromARGB(255, 234, 29, 7),
//       appBar: PreferredSize(
//         preferredSize: Size.fromHeight(80),
//         child: Navbar(),
//       ),
//       body: SizedBox(
//         // Change to SizedBox to take full screen height
//         height: MediaQuery.of(context).size.height,
//         child: SingleChildScrollView(
//           child: LayoutBuilder(
//             builder: (context, constraints) {
//               final isTablet =
//                   constraints.maxWidth > 600; // Define tablet breakpoint

//               return Column(
//                 children: [
//                   SizedBox(height: 20),
//                   Center(
//                     // Center the login form
//                     child: ConstrainedBox(
//                       // Limit the width on larger screens
//                       constraints: BoxConstraints(
//                         maxWidth: isTablet
//                             ? 400
//                             : double
//                                 .infinity, // Max width for tablet, full width otherwise
//                       ),
//                       child: const LoginForm(),
//                     ),
//                   ),
//                   SizedBox(height: 20),
//                   if (kIsWeb) const Footer(),
//                 ],
//               );
//             },
//           ),
//         ),
//       ),
//     );
//   }
// }
