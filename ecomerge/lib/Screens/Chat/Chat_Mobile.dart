import 'package:e_commerce_app/Models/User_model.dart';
import 'package:e_commerce_app/Provider/UserProvider.dart';
import 'package:e_commerce_app/widgets/navbarAdmin.dart';
import 'package:flutter/material.dart';
import '../../widgets/navbar.dart';
import '../../widgets/message_list.dart';
import '../../widgets/chat_content.dart';

class ChatMobile extends StatelessWidget {
  const ChatMobile({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userProvider = UserProvider();
    final isAdmin = userProvider.currentUser?.role == UserRole.admin;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: const NavbarAdmin(),
      ),
      body: isAdmin 
          ? const MessageList()
          : const ChatContent(),
    );
  }
}
