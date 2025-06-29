import 'package:flutter/material.dart';

void main() => runApp(SlimeGame());

class SlimeGame extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SlimeHome(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SlimeHome extends StatefulWidget {
  @override
  SlimeHomeState createState() => SlimeHomeState();
}

class SlimeHomeState extends State<SlimeHome> {
  Offset dragOffset = Offset.zero;
  double scaleX = 1.0;
  double scaleY = 1.0;

  void onPanUpdate(DragUpdateDetails details) {
    setState(() {
      dragOffset += details.delta;

      // Stretch amount
      scaleX = 1.0 + (dragOffset.dx / 300).clamp(-0.4, 0.4);
      scaleY = 1.0 + (dragOffset.dy / 300).clamp(-0.4, 0.4);
    });
  }

  void onPanEnd(DragEndDetails details) {
    setState(() {
      dragOffset = Offset.zero;
      scaleX = 1.0;
      scaleY = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.deepPurple[100],
      body: GestureDetector(
        onPanUpdate: onPanUpdate,
        onPanEnd: onPanEnd,
        child: Stack(
          children: [
            // Slime background
            AnimatedContainer(
              duration: Duration(milliseconds: 300),
              width: screenSize.width,
              height: screenSize.height,
              transform: Matrix4.identity()
                ..scale(scaleX, scaleY)
                ..translate(dragOffset.dx, dragOffset.dy),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.limeAccent,
                    Colors.greenAccent,
                    Colors.tealAccent,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 80,
                    spreadRadius: 40,
                    offset: Offset(0, 20),
                  ),
                ],
              ),
            ),
            // Optional swirl effect overlay or gooey effect could go here
          ],
        ),
      ),
    );
  }
}
