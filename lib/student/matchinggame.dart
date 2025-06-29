import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class MatchingGame extends StatefulWidget {
  @override
  MatchingGameState createState() => MatchingGameState();
}

class MatchingGameState extends State<MatchingGame> {
  final List<String> imagePaths = [
    'assets/images/apple.jpg',
    'assets/images/banana.jpg',
    'assets/images/grapes.jpg',
    'assets/images/strawberry.jpg',
    'assets/images/watermelon.png',
    'assets/images/pineapple.jpg',
  ];

  // Make gameImages nullable or initialize it with an empty list
  // before the async operation completes.
  List<String> gameImages = []; // Initialize to an empty list
  List<bool> flipped = [];
  List<bool> matched = [];
  List<bool> redFlash = [];
  List<bool> greenFlash = [];
  List<int> selected = [];
  int score = 0;
  int level = 1;
  int timerSeconds = 60;
  Timer? levelTimer;

  final AudioPlayer flipPlayer = AudioPlayer();
  final AudioPlayer matchPlayer = AudioPlayer();

  // Add a boolean to track if the game data is loaded
  bool _isGameDataLoaded = false;

  @override
  void initState() {
    super.initState();
    _initializeGameData(); // Start the async initialization
  }

  // New method to handle the asynchronous initialization sequence
  Future<void> _initializeGameData() async {
    await loadProgress(); // First, load saved progress
    initGame(); // Then, initialize the game board
    setState(() {
      _isGameDataLoaded = true; // Mark as loaded once everything is set up
    });
  }

  Future<void> loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    // Use setState here if you want to update UI while loading progress
    // though for these simple values, it's fine to do it before initGame.
    level = prefs.getInt('level') ?? 1;
    score = prefs.getInt('score') ?? 0;
    timerSeconds = prefs.getInt('timer') ?? 60;
  }

  Future<void> saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('level', level);
    await prefs.setInt('score', score);
    await prefs.setInt('timer', timerSeconds);
  }

  void initGame() {
    gameImages = List.from(imagePaths)..addAll(imagePaths);
    gameImages.shuffle();
    flipped = List.filled(gameImages.length, false);
    matched = List.filled(gameImages.length, false);
    redFlash = List.filled(gameImages.length, false);
    greenFlash = List.filled(gameImages.length, false);
    selected = [];
    startTimer();
  }

  void startTimer() {
    levelTimer?.cancel();
    levelTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timerSeconds > 0) {
        setState(() {
          timerSeconds--;
        });
      } else {
        timer.cancel();
        showGameOverDialog();
      }
    });
  }

  void playFlipSound() => flipPlayer.play(AssetSource('sounds/flip.mp3'));
  void playMatchSound() => matchPlayer.play(AssetSource('sounds/match.mp3'));

  void handleTap(int index) {
    if (flipped[index] || matched[index] || selected.length == 2) return;

    setState(() {
      flipped[index] = true;
      selected.add(index);
    });

    playFlipSound();

    if (selected.length == 2) {
      Future.delayed(const Duration(seconds: 1), () {
        int first = selected[0];
        int second = selected[1];

        setState(() {
          if (gameImages[first] == gameImages[second]) {
            matched[first] = true;
            matched[second] = true;
            score += 100;
            timerSeconds += 10;
            playMatchSound();
            saveProgress();

            greenFlash[first] = true;
            greenFlash[second] = true;

            Future.delayed(const Duration(milliseconds: 300), () {
              setState(() {
                greenFlash[first] = false;
                greenFlash[second] = false;
              });
            });

            if (matched.where((m) => m).length == gameImages.length) {
              nextLevel();
            }
          } else {
            flipped[first] = false;
            flipped[second] = false;
            score = (score - 30).clamp(0, 99999);
            timerSeconds = (timerSeconds - 5).clamp(0, 999);

            redFlash[first] = true;
            redFlash[second] = true;

            Future.delayed(const Duration(milliseconds: 300), () {
              setState(() {
                redFlash[first] = false;
                redFlash[second] = false;
              });
            });

            if (timerSeconds == 0) {
              levelTimer?.cancel();
              showGameOverDialog();
            }
          }
          selected.clear();
        });
      });
    }
  }

  void nextLevel() {
    levelTimer?.cancel();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Level $level Complete! Starting next level..."),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green[600],
      ),
    );

    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        level++;
        saveProgress();
        initGame();
      });
    });
  }

  void resetGame() {
    levelTimer?.cancel();
    setState(() {
      level = 1;
      score = 0;
      timerSeconds = 60;
      saveProgress();
      initGame();
    });
  }

  void showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('⏰ Game Over'),
        content: Text(
          'You ran out of time on Level $level.\nTry again and beat your last score!',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              resetGame();
            },
            child: const Text('Restart'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    levelTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show a loading indicator if the game data hasn't been initialized yet
    if (!_isGameDataLoaded) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      appBar: AppBar(
        title: const Text('Matching Game'),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: resetGame),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Text('Level: $level',
              style: const TextStyle(fontSize: 20, color: Colors.indigo)),
          const SizedBox(height: 6),
          Text('Score: $score',
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo)),
          const SizedBox(height: 6),
          Text('Time Left: $timerSeconds s',
              style: const TextStyle(fontSize: 18, color: Colors.red)),
          const SizedBox(height: 10),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: gameImages.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (context, index) {
                if (matched[index]) return Container();
                return GestureDetector(
                  onTap: () => handleTap(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: redFlash[index]
                          ? Colors.red
                          : greenFlash[index]
                              ? Colors.green
                              : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.indigo, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.indigo.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(3, 3),
                        )
                      ],
                    ),
                    child: Center(
                      child: flipped[index]
                          ? Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(
                                  gameImages[index],
                                  fit: BoxFit.cover,
                                ),
                              ),
                            )
                          : const Icon(Icons.question_mark,
                              size: 40, color: Colors.indigo),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}