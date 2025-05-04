import 'package:e_commerce_app/Provider/UserProvider.dart';
import 'package:e_commerce_app/database/Storage/UserInfo.dart';
import 'package:flutter/material.dart';

class AuthGuard extends StatelessWidget {
  final Widget child;
  final bool requireAuth;

  const AuthGuard({
    Key? key,
    required this.child,
    required this.requireAuth,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (BuildContext context) {
        final currentUser = UserInfo().currentUser;
        final bool isAuthenticated = currentUser != null;
         print("bool "+isAuthenticated.toString());
        if (isAuthenticated && !requireAuth) {
          // Replace current history entry with home
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/home',
              (route) => false, // Remove all previous routes
            );
          });
          return const SizedBox.shrink();
        }

        if (!isAuthenticated && requireAuth) {
          // Replace current history entry with login
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/login',
              (route) => false, // Remove all previous routes
            );
          });
          return const SizedBox.shrink();
        }

        return child;
      },
    );
  }
}
