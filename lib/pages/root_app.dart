// lib/pages/root_app.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cativerse/pages/account_page.dart';
import 'package:cativerse/pages/chat_page.dart';
import 'package:cativerse/pages/explore_page.dart';
import 'package:cativerse/theme/colors.dart';

class RootApp extends StatefulWidget {
  const RootApp({super.key});

  @override
  State<RootApp> createState() => _RootAppState();
}

class _RootAppState extends State<RootApp> {
  int pageIndex = 0;

  final List<Widget> _pages = const [
    ExplorePage(),
    ChatPage(),
    AccountPage(),
  ];

  final List<String> _icons = const [
    "assets/images/explore_active_icon.svg",
    "assets/images/chat_active_icon.svg",
    "assets/images/account_active_icon.svg",
  ];

  final List<String> _titles = const [
    "Cativerse",
    "Messages",
    "Profile",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      appBar: _buildAppBar(),
      body: IndexedStack(
        index: pageIndex,
        children: _pages,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: white,
      elevation: 0,
      centerTitle: true,
      toolbarHeight: 92,
      titleSpacing: 0,
      title: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ชื่อหน้า (เปลี่ยนตามแท็บ)
          Text(
            _titles[pageIndex],
            style: TextStyle(
              color: Colors.orange.shade700,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          // แถบไอคอนสลับหน้า
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_icons.length, (index) {
              final isActive = pageIndex == index;
              return IconButton(
                onPressed: () => setState(() => pageIndex = index),
                icon: SvgPicture.asset(
                  _icons[index],
                  width: 26,
                  height: 26,
                  color: isActive ? Colors.orange : Colors.grey,
                ),
                splashRadius: 22,
              );
            }),
          ),
        ],
      ),
    );
  }
}
