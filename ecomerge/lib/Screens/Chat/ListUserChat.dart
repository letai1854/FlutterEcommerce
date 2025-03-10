import 'package:e_commerce_app/widgets/navbarAdmin.dart';
import 'package:flutter/material.dart';
import '../../widgets/navbar.dart';
import '../../widgets/message_list.dart';
import '../../widgets/chat_content.dart';

class Listuserchat extends StatelessWidget {
  const Listuserchat({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Expanded(
            flex: 5,
            child: MessageList(),
          )
        ],
      ),
    );
  }
}
