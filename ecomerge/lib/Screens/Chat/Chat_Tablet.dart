// import 'package:e_commerce_app/Models/User_model.dart';
// import 'package:e_commerce_app/Provider/UserProvider.dart';
// import 'package:e_commerce_app/widgets/navbar.dart';
// import 'package:e_commerce_app/widgets/navbarAdmin.dart';
// import 'package:flutter/material.dart';
// import '../../widgets/Chat/message_list.dart';
// import '../../widgets/Chat/chat_content.dart';

// class ChatTablet extends StatelessWidget {
//   const ChatTablet({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     final isAdmin = UserProvider().currentUser?.role == UserRole.admin;
//     return Scaffold(
//       appBar: PreferredSize(
//         preferredSize: const Size.fromHeight(80),
//         child: const NavbarAdmin(),
//       ),
//       body: Row(
//         children: [
//           if (isAdmin)
//             Expanded(
//               flex: 3,
//               child: Container(
//                 decoration: BoxDecoration(
//                     border: Border(
//                         right: BorderSide(
//                             width: 1, color: Colors.grey.shade300))),
//                 child: MessageList(),
//               ),
//             ),
//           Expanded(
//             flex: 5,
//             child: ChatContent(),
//           ),
//         ],
//       ),
//     );
//   }
// }
