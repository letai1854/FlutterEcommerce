import 'package:e_commerce_app/widgets/footer.dart';
import 'package:e_commerce_app/widgets/navbar.dart';
import 'package:e_commerce_app/widgets/signup_form.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class SignupTablet extends StatelessWidget {
  const SignupTablet({super.key});

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
              const SignForm(),
              SizedBox(height: 20),
              if (kIsWeb) const Footer(),
            ],
          ),
        ),
      ),
    );
  }
}
//comment1

//comment2
