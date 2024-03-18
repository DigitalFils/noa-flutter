import 'package:flutter/material.dart';
import 'package:noa/style.dart';
import 'package:noa/widgets/bottom_nav_bar.dart';
import 'package:noa/widgets/top_title_bar.dart';

class HackPage extends StatelessWidget {
  const HackPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorDark,
      appBar: topTitleBar(context, 'HACK', true, false),
      body: const Center(
        child: Text("Hack"),
      ),
      bottomNavigationBar: bottomNavBar(context, 2, true),
    );
  }
}
