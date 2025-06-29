import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rive/rive.dart'; // Import the rive package
import '../login/signup/Login_Screen.dart';
import 'gamepage.dart';

class HomeScreen extends StatefulWidget {
  final String studentName;
  final String studentEmail;
  final String studentCourse;

  const HomeScreen({
    super.key,
    required this.studentName,
    required this.studentEmail,
    required this.studentCourse,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // To manage the selected tab in the bottom navigation bar

  // Note: _widgetOptions is not strictly used for displaying full pages here,
  // but if you expand your bottom navigation, each index would correspond to a different
  // widget to display in the body. For this current setup, the body remains constant
  // and the bottom nav primarily handles navigation to GamePage.
  static const List<Widget> _widgetOptions = <Widget>[
    Text('Index 0: Home Content'), // Placeholder for Home Contenttaeeeeeeeeeeeeegit
    Text('Index 1: Game Content'), // Placeholder for Game (actual navigation happens on tap)
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      
    });

    if (index == 1) {
      // Navigate to the GamePage when the game icon is tapped
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) =>  GamePage()), // Use const with GamePage if it's stateless
      );
    }
    // If you add more tabs, you'd add more if/else if conditions here
    // for specific navigations or to update the body content based on index.
  }

  Future<void> _logout(BuildContext context) async {
    // Show confirmation dialog
    bool confirmLogout = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to log out?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // User canceled
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // User confirmed
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    // If the user confirmed, proceed with logout
    if (confirmLogout == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Logged out successfully."),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: Colors.cyan[200]),
              accountName: Text(widget.studentName),
              accountEmail: Text(widget.studentEmail),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  widget.studentName.isNotEmpty
                      ? widget.studentName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(fontSize: 24, color: Colors.cyan),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.school),
              title: Text('Course: ${widget.studentCourse}'),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () => _logout(context),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.cyan[200],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Student Home',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 30),
            buildButton("Mood Check"),
            const SizedBox(height: 10),
            buildButton("Assessment"),
            const SizedBox(height: 20),
            const SizedBox(height: 40),
            Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: 0,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.cyan[100],
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Text(
                      "How’s your day buddy",
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
                Column(
                  children: [
                    const SizedBox(height: 40),
                    // Replaced Image.network with RiveAnimation.asset
                    SizedBox(
                      height: 150, // Maintain the same height as the image
                      width: 150, // You might need to adjust width based on your animation
                      child: RiveAnimation.asset(
                        'assets/animation/Cat.riv', // Path to your Rive file
                        fit: BoxFit.contain, // Adjust fit as needed
                        // You can also add an `onInit` callback to control the Rive animation
                        // onInit: (artboard) {
                        //   final controller = StateMachineController.fromArtboard(artboard, 'State Machine 1');
                        //   artboard.addController(controller!);
                        // },
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, size: 35),
                  onPressed: () {},
                ),
                const Text("🍎🍌🍇", style: TextStyle(fontSize: 30)),
                IconButton(
                  icon: const Icon(Icons.arrow_forward, size: 35),
                  onPressed: () {},
                ),
              ],
            )
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.videogame_asset), // The game icon
            label: 'Game',
          ),
          // You can add more BottomNavigationBarItems here for other sections
          // BottomNavigationBarItem(
          //   icon: Icon(Icons.settings),
          //   label: 'Settings',
          // ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.cyan[800],
        onTap: _onItemTapped,
      ),
    );
  }

  Widget buildButton(String text) {
    return ElevatedButton(
      onPressed: () {
        // You can define navigation or action here later for Mood Check/Assessment
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.cyan[400],
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(text,
          style: const TextStyle(fontSize: 16, color: Colors.black)),
    );
  }
}