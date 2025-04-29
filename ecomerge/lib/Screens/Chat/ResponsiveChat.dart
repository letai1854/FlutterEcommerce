import 'package:e_commerce_app/Responsive/ResponsiveLayout.dart';
import 'package:e_commerce_app/Screens/Chat/Chat_DeskTop.dart';
import 'package:e_commerce_app/Screens/Chat/Chat_Mobile.dart';
import 'package:e_commerce_app/Screens/Chat/Chat_Tablet.dart';
import 'package:e_commerce_app/Screens/Chat/ListUserChat.dart';
import 'package:flutter/material.dart';

class Responsivechat extends StatelessWidget {
  const Responsivechat({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobileScaffold: const ChatMobile(),
      tableScaffold: const ChatTablet(),
      destopScaffold: const ChatDesktop(),
    );
  }
}
