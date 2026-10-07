import 'package:flutter/material.dart';

// rive is optional; keep import if animations are added later
import 'cart_screen.dart';
import 'chat_screen.dart';
import 'product_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final String username;

  const HomeScreen({super.key, this.username = ''});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          elevation: 2,
          title: Image.asset(
            'assets/images/nubdexchange_logo.png',
            scale: 11.5,
          ),
          centerTitle: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings, size: 24.5),
              onPressed: () => Navigator.pushNamed(context, '/settings'),
            ),
          ],
        ),
        body: PageView(
          physics: const NeverScrollableScrollPhysics(),
          controller: _pageController,
          children: const [
            ProductScreen(),
            CartScreen(embedded: true),
            ProfileScreen(),
          ],
          onPageChanged: (page) {
            setState(() {
              _selectedIndex = page;
            });
          },
        ),
        bottomNavigationBar: BottomNavigationBar(
          showSelectedLabels: false,
          showUnselectedLabels: false,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.shop_2), label: 'Shop'),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart),
              label: 'Cart',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
          currentIndex: _selectedIndex,
          onTap: onTappedBar,
        ),
        floatingActionButton: _selectedIndex == 1
            ? null
            : FloatingActionButton(
                // Enhancement 2: Chat is available as a floating action instead of bottom navigation.
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: (_) => const ChatScreen()),
                ),
                child: const Icon(Icons.chat),
              ),
      ),
    );
  }

  void onTappedBar(int value) {
    if (value == 1) {
      // Enhancement 1: The cart is available from the bottom navigation.
      setState(() {
        _selectedIndex = value;
      });
      _pageController.jumpToPage(value);
      return;
    }

    setState(() {
      _selectedIndex = value;
    });
    _pageController.jumpToPage(value);
  }
}
