import 'package:flutter/material.dart';

/// ホーム画面の白い角丸カード（影つき）。
class HomeCard extends StatelessWidget {
  final Widget child;
  const HomeCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: 220,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 4))],
        ),
        child: child,
      );
}
