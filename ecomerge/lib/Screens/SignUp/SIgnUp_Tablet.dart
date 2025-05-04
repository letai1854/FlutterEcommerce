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
      backgroundColor: const Color.fromARGB(255, 234, 29, 7),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80),
        child: Navbar(),
      ),
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        child: SingleChildScrollView(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isTablet = constraints.maxWidth > 600;

              return Column(
                children: [
                  SizedBox(height: 20),
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isTablet ? 500 : double.infinity,
                        minWidth: isTablet ? 500 : double.infinity,
                      ),
                      child: const SignForm(),
                    ),
                  ),
                  SizedBox(height: 20),
                  if (kIsWeb) const Footer(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
