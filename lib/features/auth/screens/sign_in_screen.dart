import 'package:flutter/material.dart';

import 'email_login_screen.dart';
import 'account_create_screen.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.school_outlined,
                  size: 90,
                ),

                const SizedBox(height: 16),

                const Text(
                  'Manapass',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 48),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                          const EmailLoginScreen(),
                        ),
                      );
                    },
                    child: const Text('メールアドレスでログイン'),
                  ),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                          const AccountCreateScreen(),
                        ),
                      );
                    },
                    child: const Text('新規アカウント作成'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}