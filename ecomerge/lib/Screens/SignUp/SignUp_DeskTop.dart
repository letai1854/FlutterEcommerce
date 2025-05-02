import 'package:e_commerce_app/widgets/footer.dart';
import 'package:e_commerce_app/widgets/login_form.dart';
import 'package:e_commerce_app/widgets/navbar.dart';
import 'package:e_commerce_app/widgets/signup_form.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class SignUpDesktop extends StatelessWidget {
  const SignUpDesktop({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height,
              child: Column(
                children: [
                  Navbar(),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 234, 29, 7),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: Container(
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: AssetImage('/banner.jpg'),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Container(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                width: 500,
                                constraints: BoxConstraints(
                                  maxHeight: 480,
                                  minHeight: 350,
                                ),
                                child: SignForm(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (kIsWeb)
              Column(
                children: [
                  Footer(),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
