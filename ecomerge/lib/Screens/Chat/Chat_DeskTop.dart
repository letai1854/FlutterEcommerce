import 'package:e_commerce_app/Models/User_model.dart';
import 'package:e_commerce_app/Provider/UserProvider.dart';
import 'package:e_commerce_app/widgets/navbarAdmin.dart';
import 'package:flutter/material.dart';
import '../../widgets/navbar.dart';
import '../../widgets/message_list.dart';
import '../../widgets/chat_content.dart';

class ChatDesktop extends StatelessWidget {
  const ChatDesktop({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userProvider = UserProvider();
    final isAdmin = userProvider.currentUser?.role == UserRole.admin;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child:const NavbarAdmin(),
      ),
      body: isAdmin 
        ? Row(
            children: [
              const Expanded(
                flex: 2,
                child: MessageList(),
              ),
              const Expanded(
                flex: 5,
                child: ChatContent(),
              ),
            ],
          )
        : Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1100),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const ChatContent(),
            ),
          ),
    );
  }
}
