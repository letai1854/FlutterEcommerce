import 'package:e_commerce_app/Responsive/ResponsiveLayout.dart';
import 'package:e_commerce_app/Screens/SignUp/SIgnUp_Tablet.dart';
import 'package:e_commerce_app/Screens/SignUp/SignUp_DeskTop.dart';
import 'package:e_commerce_app/Screens/SignUp/SignUp_Mobile.dart';
import 'package:e_commerce_app/providers/signup_form_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ReponsiveSignUp extends StatelessWidget {
  const ReponsiveSignUp({super.key});

  @override
  Widget build(BuildContext context) {
    // Make sure we have a single instance of the form provider
    // This ensures state is preserved across layout changes
    return ChangeNotifierProvider(
      create: (_) => SignupFormProvider(),
      child: ResponsiveLayout(
        mobileScaffold: const SignupMobile(),
        tableScaffold: const SignupTablet(),
        destopScaffold: const SignUpDesktop(),
      ),
    );
  }
}
