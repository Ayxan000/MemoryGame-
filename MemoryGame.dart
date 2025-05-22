import 'dart:async';
import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

enum Difficulty { easy, medium, hard }

List<GameResult> gameResults = [];

class GameResult {
  final Difficulty difficulty;
  final int moves;
  final int timeLeft;
  final int score;

  GameResult(this.difficulty, this.moves, this.timeLeft, this.score);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Difficulty selectedDifficulty = Difficulty.easy;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Memory Game - Home')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select Difficulty:', style: TextStyle(fontSize: 24)),
              const SizedBox(height: 20),
              DropdownButton<Difficulty>(
                value: selectedDifficulty,
                items: const [
                  DropdownMenuItem(value: Difficulty.easy, child: Text('Easy (4x4)')),
                  DropdownMenuItem(value: Difficulty.medium, child: Text('Medium (6x6)')),
                  DropdownMenuItem(value: Difficulty.hard, child: Text('Hard (8x8)')),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedDifficulty = value!;
                  });
                },
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) => GamePage(difficulty: selectedDifficulty),
                  ));
                },
                child: const Text('Start Game', style: TextStyle(fontSize: 24)),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) => const LeaderboardPage(),
                  ));
                },
                child: const Text('Leaderboard / History', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GamePage extends StatefulWidget {
  final Difficulty difficulty;
  const GamePage({super.key, required this.difficulty});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late int gridSize;
  late List<String> cards;
  late List<bool> cardsFlipped;
  int? firstSelectedIndex;
  int moveCount = 0;
  int score = 0;

  static const int startingTime = 60;
  late int remainingTime;
  Timer? countdownTimer;

  @override
  void initState() {
    super.initState();
    switch (widget.difficulty) {
      case Difficulty.easy:
        gridSize = 4;
        break;
      case Difficulty.medium:
        gridSize = 6;
        break;
      case Difficulty.hard:
        gridSize = 8;
        break;
    }
    startGame();
  }

  void startGame() {
    List<String> baseEmojis = [
      '🍎','🚗','🐶','🎵','🌟','⚽','🎲','🧩',
      '🍀','🐱','🎈','🌈','🍔','🚀','📚','🎮',
      '🐸','🍉','🦄','🎤','🏀','🌹','🎧','🐢',
      '🍕','🎯','🚴','🐰','🎹','🌻','🛵','📷',
    ];

    int totalCards = gridSize * gridSize;
    int pairCount = totalCards ~/ 2;

    cards = baseEmojis.take(pairCount).toList();
    cards = [...cards, ...cards];
    cards.shuffle();

    cardsFlipped = List.generate(totalCards, (_) => false);
    firstSelectedIndex = null;
    moveCount = 0;
    score = 0;

    remainingTime = startingTime;
    countdownTimer?.cancel();
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingTime == 0) {
        timer.cancel();
        showGameOverDialog(timeOut: true);
      } else {
        setState(() {
          remainingTime--;
        });
      }
    });

    setState(() {});
  }

  void onCardTap(int index) {
    if (cardsFlipped[index] || remainingTime == 0) return;

    setState(() {
      cardsFlipped[index] = true;

      if (firstSelectedIndex == null) {
        firstSelectedIndex = index;
      } else {
        moveCount++;
        if (cards[firstSelectedIndex!] != cards[index]) {
          Future.delayed(const Duration(milliseconds: 800), () {
            setState(() {
              cardsFlipped[firstSelectedIndex!] = false;
              cardsFlipped[index] = false;
              firstSelectedIndex = null;
            });
          });
        } else {
          score += 5;
          firstSelectedIndex = null;

          if (cardsFlipped.every((flipped) => flipped)) {
            countdownTimer?.cancel();
            showGameOverDialog();
          }
        }
      }
    });
  }

  void showGameOverDialog({bool timeOut = false}) {
    countdownTimer?.cancel();

    gameResults.add(GameResult(widget.difficulty, moveCount, remainingTime, score));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(timeOut ? 'Time\'s Up!' : 'Game Over!'),
        content: Text(timeOut
            ? 'You ran out of time!\nMoves: $moveCount\nScore: $score'
            : 'Congratulations!\nMoves: $moveCount\nTime left: $remainingTime seconds\nScore: $score'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              startGame();
            },
            child: const Text('Play Again'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('Home'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double baseCardSize = 20; // Kart kutusu boyutu 2 kat daha küçültüldü (önce 40 idi)

    return Scaffold(
      appBar: AppBar(
        title: const Text('Memory Game'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(child: Text('Moves: $moveCount', style: const TextStyle(fontSize: 14))),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(child: Text('Time left: $remainingTime s', style: const TextStyle(fontSize: 14))),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(child: Text('Score: $score', style: const TextStyle(fontSize: 14))),
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: gridSize,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          childAspectRatio: 1,
        ),
        itemCount: cards.length,
        itemBuilder: (context, index) {
          return SizedBox(
            width: baseCardSize,
            height: baseCardSize,
            child: AnimatedCard(
              isFlipped: cardsFlipped[index],
              content: cards[index],
              fontSize: 56, // Emoji font büyüklüğü aynı kaldı
              onTap: () => onCardTap(index),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => startGame(),
        tooltip: 'Restart',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

class AnimatedCard extends StatefulWidget {
  final bool isFlipped;
  final String content;
  final VoidCallback onTap;
  final double fontSize;

  const AnimatedCard({
    super.key,
    required this.isFlipped,
    required this.content,
    required this.onTap,
    required this.fontSize,
  });

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);

    if (widget.isFlipped) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFlipped != oldWidget.isFlipped) {
      if (widget.isFlipped) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final angle = _animation.value * 3.1416;

        bool showFront = _animation.value < 0.5;

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle),
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              decoration: BoxDecoration(
                color: showFront ? Colors.blue : Colors.orange,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                showFront ? '❓' : widget.content,
                style: TextStyle(fontSize: widget.fontSize),
              ),
            ),
          ),
        );
      },
    );
  }
}

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  String difficultyToString(Difficulty diff) {
    switch (diff) {
      case Difficulty.easy:
        return 'Easy';
      case Difficulty.medium:
        return 'Medium';
      case Difficulty.hard:
        return 'Hard';
    }
  }

  @override
  Widget build(BuildContext context) {
    List<GameResult> sortedResults = List.from(gameResults);
    sortedResults.sort((a, b) => a.moves.compareTo(b.moves));

    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard / History')),
      body: sortedResults.isEmpty
          ? const Center(child: Text('No game results yet.'))
          : ListView.builder(
              itemCount: sortedResults.length,
              itemBuilder: (context, index) {
                final result = sortedResults[index];
                return ListTile(
                  leading: Text('#${index + 1}'),
                  title: Text(
                      '${difficultyToString(result.difficulty)} - Moves: ${result.moves}'),
                  subtitle: Text('Time left: ${result.timeLeft}s | Score: ${result.score}'),
                );
              },
            ),
    );
  }
}
