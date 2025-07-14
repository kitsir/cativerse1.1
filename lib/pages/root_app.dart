import 'package:cativerse/pages/like_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cativerse/pages/account_page.dart';
import 'package:cativerse/pages/chat_page.dart';
import 'package:cativerse/pages/explore_page.dart';
import 'package:cativerse/theme/colors.dart';

class RootApp extends StatefulWidget {
  const RootApp({super.key});

  @override
  _RootAppState createState() => _RootAppState();
}

class _RootAppState extends State<RootApp> {
  int pageIndex = 0;

  final List<Widget> _pages = [
    ExplorePage(),
    ChatPage(),
    AccountPage(),
  ];

  final List<String> _icons = [
    "assets/images/explore_active_icon.svg",
    "assets/images/chat_active_icon.svg",
    "assets/images/account_active_icon.svg",
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
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_icons.length, (index) {
          return IconButton(
            onPressed: () {
              setState(() {
                pageIndex = index;
              });
            },
            icon: SvgPicture.asset(
              _icons[index],
              color: pageIndex == index ? Colors.orange : Colors.grey,
              width: 26,
              height: 26,
            ),
          );
        }),
      ),
    );
  }
}
