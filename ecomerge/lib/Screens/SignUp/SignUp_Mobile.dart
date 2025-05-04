// import 'package:e_commerce_app/widgets/footer.dart';
// import 'package:e_commerce_app/widgets/signup_form.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';

// class SignupMobile extends StatelessWidget {
//   const SignupMobile({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         children: [
//           // Background gradient covering entire screen
//           Container(
//             decoration: const BoxDecoration(
//               gradient: LinearGradient(
//                 begin: Alignment.topCenter,
//                 end: Alignment.bottomCenter,
//                 colors: [
//                   Color.fromARGB(255, 234, 29, 7),
//                   Color.fromARGB(255, 255, 85, 0),
//                 ],
//               ),
//             ),
//           ),
//           // Content
//           SingleChildScrollView(
//             child: Column(
//               children: [
//                 // Logo section with white background
//                 Container(
//                   width: double.infinity,
//                   color: Colors.white,
//                   child: Padding(
//                     padding: const EdgeInsets.all(16.0),
//                     child: GestureDetector(
//                       onTap: () {
//                         Navigator.pushNamed(context, '/');
//                       },
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Image.asset(
//                             'assets/logoS.jpg',
//                             height: 80,
//                             width: 80,
//                             fit: BoxFit.contain,
//                           ),
//                           const SizedBox(width: 8),
//                           const Text(
//                             'Shopii',
//                             style: TextStyle(
//                               fontSize: 30,
//                               fontWeight: FontWeight.bold,
//                               color: Color.fromARGB(255, 255, 85, 0),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//                 // Login form section
//                 Padding(
//                   padding: const EdgeInsets.symmetric(
//                       horizontal: 24.0, vertical: 30.0),
//                   child: Container(
//                     color: Colors.white
//                         .withOpacity(0.9), // Changed from decoration to color
//                     child: const SignForm(),
//                   ),
//                 ),
//                 if (kIsWeb) const Footer(),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
// //test
