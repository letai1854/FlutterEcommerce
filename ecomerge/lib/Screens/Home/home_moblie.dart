import 'package:e_commerce_app/constants.dart';
import 'package:e_commerce_app/utils/my_box.dart';
import 'package:e_commerce_app/utils/my_tile.dart';
import 'package:e_commerce_app/widgets/BottomNavigation.dart';
import 'package:e_commerce_app/widgets/Home/bodyHomeMobile.dart';
import 'package:e_commerce_app/widgets/NavbarMobile/NavbarMobile.dart';
import 'package:e_commerce_app/widgets/footer.dart';
import 'package:e_commerce_app/widgets/navbarHomeMobile.dart';
import 'package:flutter/material.dart';

class HomeMobile extends StatelessWidget {
  const HomeMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return NavbarFixmobile(
      body: bodyHomeMobile(), // Truyền body vào NavbarFixmobile
    );
    // return SingleChildScrollView(
    //   child: Column(
    //     children: [
    //       if (isWeb) Footer(),
    //     ],
    //   ),
    // );
  }
}
