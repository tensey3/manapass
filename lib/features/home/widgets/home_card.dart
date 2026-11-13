import 'package:flutter/material.dart';

/// ホーム画面の白い角丸カード（影つき）。
/// スマホでは横幅いっぱいにするため、width を変えられる。
class HomeCard extends StatelessWidget {
  final Widget child;
  final double width;
  final double? height;
  const HomeCard({super.key, required this.child, this.width = 220, this.height});

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 4))],
        ),
        child: child,
      );
}
