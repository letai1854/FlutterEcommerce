import 'package:e_commerce_app/widgets/login_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../widgets/footer.dart';
import 'package:e_commerce_app/widgets/navbar.dart';

class LoginTablet extends StatefulWidget {
  const LoginTablet({super.key});

  @override
  State<LoginTablet> createState() => _LoginTabletState();
}

class _LoginTabletState extends State<LoginTablet> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
    appBar: PreferredSize(
      preferredSize: Size.fromHeight(80),
      child: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Navbar(),
        actions: [
          Builder(
            builder: (context) => Container(
              margin: EdgeInsets.only(right: 10),
              
            ),
          ),
        ],
      ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 234, 29, 7),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 20),
              const LoginForm(),
              SizedBox(height: 20),
              if (kIsWeb) const Footer(),
            ],
          ),
        ),
      ),
    );
  }
}
