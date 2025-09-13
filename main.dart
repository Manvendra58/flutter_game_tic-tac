// Tic Tac Toe — Polished Flutter UI
// Single-file app. Save as lib/main.dart and run `flutter run`.
// Features:
//  - Clean responsive UI with Material 3 styling
//  - Animated cell taps, subtle shadows, and winning-line highlight
//  - Single-player (unbeatable Minimax) and local two-player modes
//  - Scoreboard cards, mode & player selectors, New Round / Reset
//  - Accessible color contrast and simple animations (no external packages)

// ignore_for_file: deprecated_member_use

import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const TicTacToeApp());
}

class TicTacToeApp extends StatelessWidget {
  const TicTacToeApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tic Tac Toe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
        textTheme: const TextTheme(bodyLarge: TextStyle(fontSize: 16.0)),
      ),
      home: const TicTacToeHome(),
    );
  }
}

enum Player { X, O, none }

String pToStr(Player p) => p == Player.X
    ? 'X'
    : p == Player.O
    ? 'O'
    : '';

class TicTacToeHome extends StatefulWidget {
  const TicTacToeHome({Key? key}) : super(key: key);

  @override
  State<TicTacToeHome> createState() => _TicTacToeHomeState();
}

class _TicTacToeHomeState extends State<TicTacToeHome>
    with SingleTickerProviderStateMixin {
  List<Player> _board = List.filled(9, Player.none);
  Player _turn = Player.X;
  List<int> _winLine = [];

  int _scoreX = 0;
  int _scoreO = 0;
  int _draws = 0;

  bool _singlePlayer = false;
  Player _human = Player.X;
  bool _aiThinking = false;

  late final AnimationController _foxController;

  static const _wins = [
    [0, 1, 2],
    [3, 4, 5],
    [6, 7, 8],
    [0, 3, 6],
    [1, 4, 7],
    [2, 5, 8],
    [0, 4, 8],
    [2, 4, 6],
  ];

  @override
  void initState() {
    super.initState();
    _foxController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _foxController.dispose();
    super.dispose();
  }

  void _newRound({bool keepScores = true}) {
    setState(() {
      _board = List.filled(9, Player.none);
      _turn = Player.X;
      _winLine = [];
      _aiThinking = false;
      if (!keepScores) {
        _scoreX = 0;
        _scoreO = 0;
        _draws = 0;
      }
    });
  }

  void _tapCell(int idx) async {
    if (_board[idx] != Player.none) return;
    if (_winLine.isNotEmpty) return;
    if (_singlePlayer && _turn != _human) return; // not human turn
    if (_aiThinking) return;

    setState(() {
      _board[idx] = _turn;
    });

    final res = _checkWinner();
    if (res != null) {
      _onGameEnd(res);
      return;
    }

    // switch turn
    setState(() => _turn = _turn == Player.X ? Player.O : Player.X);

    // If AI mode and it's AI's turn, run AI
    if (_singlePlayer && _turn != _human) await _performAiMove();
  }

  Future<void> _performAiMove() async {
    setState(() => _aiThinking = true);
    await Future.delayed(const Duration(milliseconds: 300));
    final move = _bestMove(_board, _turn);
    if (move >= 0) {
      setState(() => _board[move] = _turn);
    }
    final res = _checkWinner();
    if (res != null) {
      _onGameEnd(res);
    } else {
      setState(() {
        _turn = _turn == Player.X ? Player.O : Player.X;
        _aiThinking = false;
      });
    }
  }

  // Winner: Player.X / Player.O ; Player.none => draw; null => not finished
  Player? _checkWinner() {
    for (final w in _wins) {
      final a = w[0], b = w[1], c = w[2];
      if (_board[a] != Player.none &&
          _board[a] == _board[b] &&
          _board[b] == _board[c]) {
        _winLine = w;
        return _board[a];
      }
    }
    if (_board.every((p) => p != Player.none)) return Player.none;
    return null;
  }

  void _onGameEnd(Player result) {
    if (result == Player.none) {
      _draws++;
    } else if (result == Player.X) {
      _scoreX++;
    } else if (result == Player.O) {
      _scoreO++;
    }

    _foxController.forward(from: 0.0);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final t = result == Player.none
            ? 'Draw'
            : 'Player ${pToStr(result)} wins!';
        return AlertDialog(
          title: Text(t),
          content: const Text(
            'Choose to start a new round or reset the scores.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _newRound(keepScores: true);
              },
              child: const Text('New Round'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _newRound(keepScores: false);
              },
              child: const Text('Reset All'),
            ),
          ],
        );
      },
    );
  }

  // --- Minimax implementation ---
  Player? _staticCheck(List<Player> board) {
    for (final w in _wins) {
      final a = w[0], b = w[1], c = w[2];
      if (board[a] != Player.none &&
          board[a] == board[b] &&
          board[b] == board[c]) {
        return board[a];
      }
    }
    if (board.every((p) => p != Player.none)) return Player.none;
    return null;
  }

  int _minimax(List<Player> board, Player player, Player maximizing) {
    final s = _staticCheck(board);
    if (s != null) {
      if (s == maximizing) return 10;
      if (s == Player.none) return 0;
      return -10;
    }

    final scores = <int>[];
    for (int i = 0; i < 9; i++) {
      if (board[i] == Player.none) {
        board[i] = player;
        final sc = _minimax(
          board,
          player == Player.X ? Player.O : Player.X,
          maximizing,
        );
        scores.add(sc);
        board[i] = Player.none;
      }
    }

    if (player == maximizing) return scores.reduce(max);
    return scores.reduce(min);
  }

  int _bestMove(List<Player> board, Player player) {
    int bestScore = -999;
    int move = -1;
    final rand = Random();
    for (int i = 0; i < 9; i++) {
      if (board[i] == Player.none) {
        board[i] = player;
        final sc = _minimax(
          board,
          player == Player.X ? Player.O : Player.X,
          player,
        );
        board[i] = Player.none;
        if (sc > bestScore || (sc == bestScore && rand.nextBool())) {
          bestScore = sc;
          move = i;
        }
      }
    }
    if (move == -1) {
      for (int i = 0; i < 9; i++) {
        if (board[i] == Player.none) return i;
      }
    }
    return move;
  }

  // --- UI widgets ---

  Widget _scoreCard(String label, int val, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              CircleAvatar(
                radius: 20,
                backgroundColor: color.withOpacity(0.12),
                child: Text(
                  val.toString(),
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _controlRow() {
    return Column(
      children: [
        Row(
          children: [
            const Text('Mode:'),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('Single'),
              selected: _singlePlayer,
              onSelected: (v) {
                setState(() {
                  _singlePlayer = true;
                  _newRound();
                });
              },
            ),
            const SizedBox(width: 6),
            ChoiceChip(
              label: const Text('Two Player'),
              selected: !_singlePlayer,
              onSelected: (v) {
                setState(() {
                  _singlePlayer = false;
                  _newRound();
                });
              },
            ),
            const Spacer(),
            const Text('Human:'),
            const SizedBox(width: 8),
            ToggleButtons(
              isSelected: [_human == Player.X, _human == Player.O],
              onPressed: (i) {
                setState(() {
                  _human = i == 0 ? Player.X : Player.O;
                  _newRound();
                });
              },
              borderRadius: BorderRadius.circular(8),
              children: const [
                Padding(padding: EdgeInsets.all(6), child: Text('X')),
                Padding(padding: EdgeInsets.all(6), child: Text('O')),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () => _newRound(keepScores: true),
              icon: const Icon(Icons.restart_alt),
              label: const Text('New Round'),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () => _newRound(keepScores: false),
              icon: const Icon(Icons.refresh),
              label: const Text('Reset All'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBoard() {
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        children: [
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            padding: const EdgeInsets.all(12),
            itemCount: 9,
            itemBuilder: (context, i) => _cell(i),
          ),
          // Winning line painter overlay
          Positioned.fill(
            child: IgnorePointer(
              ignoring: true,
              child: AnimatedBuilder(
                animation: _foxController,
                builder: (context, _) {
                  if (_winLine.isEmpty) return const SizedBox.shrink();
                  return CustomPaint(
                    painter: _WinLinePainter(
                      _winLine,
                      progress: _foxController.value,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cell(int i) {
    final p = _board[i];

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _tapCell(i),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, anim) {
              return ScaleTransition(scale: anim, child: child);
            },
            child: Text(
              pToStr(p),
              key: ValueKey(p),
              style: TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.bold,
                color: p == Player.X
                    ? Colors.indigo.shade700
                    : Colors.red.shade700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tic Tac Toe — UI')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  _scoreCard('Player X', _scoreX, Colors.indigo),
                  const SizedBox(width: 8),
                  _scoreCard('Draws', _draws, Colors.grey),
                  const SizedBox(width: 8),
                  _scoreCard('Player O', _scoreO, Colors.red),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(child: _buildBoard()),
              const SizedBox(height: 12),
              Text(
                'Turn: ${pToStr(_turn)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_aiThinking)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: LinearProgressIndicator(),
                ),
              const SizedBox(height: 12),
              _controlRow(),
            ],
          ),
        ),
      ),
    );
  }
}

// Painter that draws a line across the winning cells.
class _WinLinePainter extends CustomPainter {
  final List<int> cells; // length 3
  final double progress; // 0..1

  _WinLinePainter(this.cells, {required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (cells.length != 3) return;

    final paint = Paint()
      ..color = Colors.amber.withOpacity(0.95)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final cellW = (size.width - 24) / 3; // subtract padding used in grid
    final cellH = (size.height - 24) / 3;

    Offset centerOf(int idx) {
      final row = idx ~/ 3;
      final col = idx % 3;
      final x = 12 + col * (cellW + 12) + cellW / 2;
      final y = 12 + row * (cellH + 12) + cellH / 2;
      return Offset(x, y);
    }

    final p0 = centerOf(cells[0]);
    final p2 = centerOf(cells[2]);
    final p = Offset.lerp(p0, p2, progress.clamp(0.0, 1.0))!;

    canvas.drawLine(p0, p, paint);
  }

  @override
  bool shouldRepaint(covariant _WinLinePainter old) =>
      old.progress != progress || old.cells != cells;
}
