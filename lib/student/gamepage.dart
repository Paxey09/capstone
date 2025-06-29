import 'package:flutter/material.dart';
import 'matchinggame.dart';
import 'squishyslime.dart';

class GamePage extends StatelessWidget {
  String getImageForIndex(int index) {
    if (index == 0) {
      return 'assets/images/matching_game.gif';
    } else if (index == 1) {
      return 'assets/images/water_ripple_taps.gif';
    } else if (index == 2) {
      return 'assets/images/water_ripple_taps.gif';
    } else if (index == 3) {
      return 'assets/images/water_ripple_taps.gif';
    } else if (index == 4) {
      return 'assets/images/water_ripple_taps.gif';
    } else if (index == 5) {
      return 'assets/images/water_ripple_taps.gif';
    } else if (index == 6) {
      return 'assets/images/water_ripple_taps.gif';
    } else if (index == 7) {
      return 'assets/images/water_ripple_taps.gif';
    } else if (index == 8) {
      return 'assets/images/water_ripple_taps.gif';
    } else if (index == 9) {
      return 'assets/images/water_ripple_taps.gif';
    } else if (index == 10) {
      return 'assets/images/water_ripple_taps.gif';
    } else {
      return 'assets/images/water_ripple_taps.gif';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Calmademic Games')),
      body: Scrollbar(
        thumbVisibility: true,
        child: GridView.count(
          padding: const EdgeInsets.all(12),
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.75,
          children: List.generate(12, (index) {
            final imagePath = getImageForIndex(index);
            final isSpecialItem = index == 0 || index == 1;

            final gridItem = Container(
              decoration: isSpecialItem
                  ? null
                  : BoxDecoration(
                      color: Colors.blue[(index % 8 + 1) * 100],
                      borderRadius: BorderRadius.circular(12),
                    ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Image.asset(
                        imagePath,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    if (!isSpecialItem) ...[
                      SizedBox(height: 8),
                      Text(
                        'Item ${index + 1}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            );

            if (index == 0) {
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MatchingGame()),
                  );
                },
                child: gridItem,
              );
            } else if (index == 1) {
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SlimeGame()),
                  );
                },
                child: gridItem,
              );
            }

            return gridItem;
          }),
        ),
      ),
    );
  }
}
