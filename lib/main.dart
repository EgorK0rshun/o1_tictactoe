/*
  В этом варианте мы применяем ряд предложений по улучшению игры:

  1. Сохранение настроек и статистики:
     - Используем пакет SharedPreferences для сохранения выбранного размера поля, режима игры (одиночная/мультиплеер),
       сложности ИИ и статистики побед.
     - При запуске приложения восстанавливаем эти данные.

  2. Темная тема (переключение темы):
     - Добавлен переключатель темы в настройках.
     - Тема приложения может быть светлой или темной.
     - Состояние темы тоже сохраняется в SharedPreferences.

  3. Подсветка выигрышной линии:
     - Если игрок выигрывает, теперь подсвечиваем клетки выигрышной комбинации другим цветом.
     - Для этого сохраняем выигрышный паттерн и при отрисовке клеток проверяем, входит ли индекс в выигрышную комбинацию.

  4. Другие улучшения:
     - Добавлены комментарии и более явная структура кода.
     - Возможна локализация (идея), но не реализована сейчас полностью.
     - Можно при желании расширить до загрузки кастомных иконок для "X" и "O".

  Чтобы это работало, добавьте в pubspec.yaml зависимость:
    dependencies:
      shared_preferences: ^2.2.0

  Затем выполните:
    flutter pub get

  И запустите:
    flutter run
*/

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  runApp(MyApp(
    prefs: prefs,
  ));
}

/// Основной виджет приложения, умеет переключать тему.
class MyApp extends StatefulWidget {
  const MyApp({super.key, required this.prefs});
  final SharedPreferences prefs;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.prefs.getBool('darkMode') ?? false;
  }

  void _toggleTheme(bool isDark) {
    setState(() {
      _isDarkMode = isDark;
      widget.prefs.setBool('darkMode', _isDarkMode);
    });
  }

  @override
  Widget build(final BuildContext context) {
    return MaterialApp(
      title: 'Крестики-нолики',
      theme: _isDarkMode ? ThemeData.dark() : ThemeData(
        primarySwatch: Colors.deepOrange,
        brightness: Brightness.light,
      ),
      home: TicTacToeGamePage(
        prefs: widget.prefs,
        isDarkMode: _isDarkMode,
        onThemeChanged: _toggleTheme,
      ),
    );
  }
}

/// Основной экран игры.
class TicTacToeGamePage extends StatefulWidget {
  const TicTacToeGamePage({super.key, required this.prefs, required this.isDarkMode, required this.onThemeChanged});

  final SharedPreferences prefs;
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;

  @override
  State<TicTacToeGamePage> createState() => _TicTacToeGamePageState();
}

class _TicTacToeGamePageState extends State<TicTacToeGamePage> {
  late GameLogic _gameLogic;
  bool _singlePlayer = false;
  Difficulty _difficulty = Difficulty.easy;
  int _boardSize = 3;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _gameLogic = GameLogic(
      boardSize: _boardSize,
      scoreX: widget.prefs.getInt('scoreX') ?? 0,
      scoreO: widget.prefs.getInt('scoreO') ?? 0,
    );
  }

  Future<void> _loadSettings() async {
    setState(() {
      _boardSize = widget.prefs.getInt('boardSize') ?? 3;
      _singlePlayer = widget.prefs.getBool('singlePlayer') ?? false;
      _difficulty = Difficulty.values[widget.prefs.getInt('difficulty') ?? 0];
    });
  }

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Крестики-нолики'),
        centerTitle: true,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            /// Панель статистики
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                children: <Widget>[
                  const Text(
                    'Статистика побед:',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      Text(
                        'X: ${_gameLogic.scoreX}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      Text(
                        'O: ${_gameLogic.scoreO}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16.0),

            /// Отображение текущего игрока
            Text(
              'Ход игрока: ${_gameLogic.currentPlayer}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16.0),

            /// Игровое поле
            Expanded(
              child: AspectRatio(
                aspectRatio: 1.0,
                child: GridView.builder(
                  itemCount: _gameLogic.boardSize * _gameLogic.boardSize,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _gameLogic.boardSize,
                    mainAxisSpacing: 8.0,
                    crossAxisSpacing: 8.0,
                  ),
                  itemBuilder: (final BuildContext context, final int index) {
                    final String value = _gameLogic.board[index];
                    final bool highlight = _gameLogic.winningPattern != null && _gameLogic.winningPattern!.contains(index);
                    return BoardCell(
                      value: value,
                      highlight: highlight,
                      onTap: () => _handleTap(index),
                    );
                  },
                ),
              ),
            ),

            /// Кнопки для сброса
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                ElevatedButton(
                  onPressed: _resetBoard,
                  child: const Text('Сбросить поле'),
                ),
                ElevatedButton(
                  onPressed: _resetAll,
                  child: const Text('Сбросить всё'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Обработчик нажатия на ячейку.
  void _handleTap(final int index) {
    if (_gameLogic.makeMove(index)) {
      _saveStats();
      // Если после хода обнаружили победителя или ничью, показать диалог.
      if (_gameLogic.gameOver) {
        _showResultDialog(_gameLogic.resultMessage);
      } else {
        // Если одиночная игра и сейчас ход "O" (который управляется ИИ), сделать ход ИИ.
        if (_singlePlayer && _gameLogic.currentPlayer == 'O') {
          Future.delayed(const Duration(milliseconds: 300), _makeAiMove);
        }
      }
      setState(() {});
    }
  }

  /// Ход ИИ.
  void _makeAiMove() {
    if (_gameLogic.gameOver) return;
    _gameLogic.makeAiMove(difficulty: _difficulty);
    _saveStats();
    if (_gameLogic.gameOver) {
      _showResultDialog(_gameLogic.resultMessage);
    }
    setState(() {});
  }

  /// Отображает диалог с результатом игры.
  Future<void> _showResultDialog(final String message) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (final BuildContext context) {
        return AlertDialog(
          title: const Text('Результат игры'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetBoard();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  /// Сброс поля.
  void _resetBoard() {
    setState(() {
      _gameLogic.resetBoard();
    });
  }

  /// Полный сброс всего: поле и статистика.
  void _resetAll() {
    setState(() {
      _gameLogic.resetAll();
      _saveStats();
    });
  }

  Future<void> _saveStats() async {
    await widget.prefs.setInt('scoreX', _gameLogic.scoreX);
    await widget.prefs.setInt('scoreO', _gameLogic.scoreO);
  }

  /// Диалог настроек.
  Future<void> _showSettingsDialog() async {
    int tempSize = _gameLogic.boardSize;
    bool tempSinglePlayer = _singlePlayer;
    Difficulty tempDifficulty = _difficulty;
    bool tempDarkMode = widget.isDarkMode;

    await showDialog<void>(
      context: context,
      builder: (final BuildContext context) {
        return StatefulBuilder(
          builder: (final BuildContext context, final void Function(void Function()) setStateDialog) {
            return AlertDialog(
              title: const Text('Настройки'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Размер поля:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: <Widget>[
                        for (int size in [3, 4, 5])
                          Expanded(
                            child: RadioListTile<int>(
                              title: Text('${size}x$size'),
                              value: size,
                              groupValue: tempSize,
                              onChanged: (final int? val) {
                                if (val != null) {
                                  setStateDialog(() {
                                    tempSize = val;
                                  });
                                }
                              },
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Режим игры:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    CheckboxListTile(
                      title: const Text('Одиночная игра (против AI)'),
                      value: tempSinglePlayer,
                      onChanged: (final bool? val) {
                        if (val != null) {
                          setStateDialog(() {
                            tempSinglePlayer = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Сложность ИИ:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    DropdownButton<Difficulty>(
                      value: tempDifficulty,
                      items: Difficulty.values.map((final Difficulty diff) {
                        return DropdownMenuItem<Difficulty>(
                          value: diff,
                          child: Text(diff == Difficulty.easy ? 'Легкая' : 'Сложная'),
                        );
                      }).toList(),
                      onChanged: (final Difficulty? val) {
                        if (val != null) {
                          setStateDialog(() {
                            tempDifficulty = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Тема:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SwitchListTile(
                      title: const Text('Темная тема'),
                      value: tempDarkMode,
                      onChanged: (bool val) {
                        setStateDialog(() {
                          tempDarkMode = val;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Отмена'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  child: const Text('Применить'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _applySettings(tempSize, tempSinglePlayer, tempDifficulty, tempDarkMode);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Применяем настройки и сохраняем их.
  void _applySettings(final int size, final bool singlePlayer, final Difficulty diff, final bool darkMode) {
    setState(() {
      _singlePlayer = singlePlayer;
      _difficulty = diff;
      widget.onThemeChanged(darkMode);
      if (_boardSize != size) {
        _boardSize = size;
        _gameLogic.changeBoardSize(_boardSize);
      }
    });
    widget.prefs.setInt('boardSize', _boardSize);
    widget.prefs.setBool('singlePlayer', _singlePlayer);
    widget.prefs.setInt('difficulty', _difficulty.index);
  }
}

/// Класс, управляющий логикой игры.
class GameLogic {
  GameLogic({required this.boardSize, this.scoreX = 0, this.scoreO = 0}) {
    _initBoard();
  }

  /// Размер поля (например 3 для 3x3).
  int boardSize;

  /// Текущий игрок: "X" или "O".
  String _currentPlayer = 'X';

  /// Список для хранения состояния поля.
  late List<String> board;

  /// Подсчет побед для "X".
  int scoreX;

  /// Подсчет побед для "O".
  int scoreO;

  /// Флаг окончания игры.
  bool _gameOver = false;

  /// Сообщение о результате.
  String _resultMessage = '';

  /// Выигрышный паттерн (список индексов клеток, образующих выигрышную линию).
  List<int>? _winningPattern;

  String get currentPlayer => _currentPlayer;
  bool get gameOver => _gameOver;
  String get resultMessage => _resultMessage;
  List<int>? get winningPattern => _winningPattern;

  void _initBoard() {
    board = List<String>.filled(boardSize * boardSize, '', growable: false);
    _currentPlayer = 'X';
    _gameOver = false;
    _resultMessage = '';
    _winningPattern = null;
  }

  /// Смена размера поля. При этом сбрасываем текущее поле, но не сбрасываем статистику.
  void changeBoardSize(final int newSize) {
    boardSize = newSize;
    _initBoard();
  }

  /// Сделать ход в ячейку [index].
  bool makeMove(final int index) {
    if (_gameOver || index < 0 || index >= board.length) return false;
    if (board[index].isEmpty) {
      board[index] = _currentPlayer;
      _checkGameState();
      if (!_gameOver) {
        _switchPlayer();
      }
      return true;
    }
    return false;
  }

  /// Ход ИИ.
  void makeAiMove({required Difficulty difficulty}) {
    if (_gameOver) return;

    int moveIndex;
    if (difficulty == Difficulty.easy) {
      // Легкий уровень — случайный ход.
      final List<int> emptyCells = [];
      for (int i = 0; i < board.length; i++) {
        if (board[i].isEmpty) {
          emptyCells.add(i);
        }
      }
      if (emptyCells.isEmpty) {
        _checkGameState();
        return;
      }
      final Random random = Random();
      moveIndex = emptyCells[random.nextInt(emptyCells.length)];
    } else {
      // Сложный уровень — minimax.
      moveIndex = _bestMoveMinimax();
    }

    board[moveIndex] = _currentPlayer;
    _checkGameState();
    if (!_gameOver) {
      _switchPlayer();
    }
  }

  /// Находим лучший ход для ИИ (предполагаем, что ИИ — это 'O').
  /// Используем алгоритм minimax.
  int _bestMoveMinimax() {
    int bestVal = -100000;
    int bestMove = -1;

    for (int i = 0; i < board.length; i++) {
      if (board[i].isEmpty) {
        board[i] = 'O'; // Пробуем ход 'O'
        int moveVal = _minimax(0, false);
        board[i] = '';
        if (moveVal > bestVal) {
          bestVal = moveVal;
          bestMove = i;
        }
      }
    }

    return bestMove;
  }

  /// Функция minimax для оценки позиции.
  int _minimax(int depth, bool isMax) {
    // Проверяем терминальные условия.
    if (_checkWin('O')) {
      return 10 - depth;
    }
    if (_checkWin('X')) {
      return depth - 10;
    }
    if (!board.contains('')) {
      return 0; // Ничья
    }

    if (isMax) {
      int best = -100000;
      for (int i = 0; i < board.length; i++) {
        if (board[i].isEmpty) {
          board[i] = 'O';
          best = max(best, _minimax(depth + 1, false));
          board[i] = '';
        }
      }
      return best;
    } else {
      int best = 100000;
      for (int i = 0; i < board.length; i++) {
        if (board[i].isEmpty) {
          board[i] = 'X';
          best = min(best, _minimax(depth + 1, true));
          board[i] = '';
        }
      }
      return best;
    }
  }

  /// Проверка состояния игры после хода.
  void _checkGameState() {
    List<int>? pattern = _getWinPattern(_currentPlayer);
    if (pattern != null) {
      _gameOver = true;
      _winningPattern = pattern;
      _resultMessage = 'Победил $_currentPlayer!';
      if (_currentPlayer == 'X') {
        scoreX++;
      } else {
        scoreO++;
      }
      return;
    }

    if (!board.contains('')) {
      _gameOver = true;
      _resultMessage = 'Ничья!';
    }
  }

  /// Проверка, выиграл ли указанный игрок и возврат выигрышной комбинации.
  List<int>? _getWinPattern(final String player) {
    List<List<int>> winPatterns = [];

    // Строки
    for (int r = 0; r < boardSize; r++) {
      List<int> row = [];
      for (int c = 0; c < boardSize; c++) {
        row.add(r * boardSize + c);
      }
      winPatterns.add(row);
    }

    // Столбцы
    for (int c = 0; c < boardSize; c++) {
      List<int> col = [];
      for (int r = 0; r < boardSize; r++) {
        col.add(r * boardSize + c);
      }
      winPatterns.add(col);
    }

    // Диагонали
    List<int> diag1 = [];
    for (int i = 0; i < boardSize; i++) {
      diag1.add(i * boardSize + i);
    }
    winPatterns.add(diag1);

    List<int> diag2 = [];
    for (int i = 0; i < boardSize; i++) {
      diag2.add(i * boardSize + (boardSize - 1 - i));
    }
    winPatterns.add(diag2);

    for (final List<int> pattern in winPatterns) {
      bool won = true;
      for (int idx in pattern) {
        if (board[idx] != player) {
          won = false;
          break;
        }
      }
      if (won) return pattern;
    }

    return null;
  }

  bool _checkWin(final String player) {
    return _getWinPattern(player) != null;
  }

  /// Смена текущего игрока.
  void _switchPlayer() {
    _currentPlayer = (_currentPlayer == 'X') ? 'O' : 'X';
  }

  /// Сброс поля, статистика остается.
  void resetBoard() {
    _initBoard();
  }

  /// Полный сброс, включая статистику.
  void resetAll() {
    scoreX = 0;
    scoreO = 0;
    _initBoard();
  }
}

/// Виджет для одной клетки игрового поля.
class BoardCell extends StatefulWidget {
  const BoardCell({super.key, required this.value, required this.onTap, this.highlight = false});

  final String value;
  final VoidCallback onTap;
  final bool highlight;

  @override
  State<BoardCell> createState() => _BoardCellState();
}

class _BoardCellState extends State<BoardCell> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // Анимация при нажатии.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnimation = _controller.drive(CurveTween(curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward(from: 0.95).then((_) {
      _controller.reverse();
    });
    widget.onTap();
  }

  @override
  Widget build(final BuildContext context) {
    Color baseColor = widget.highlight
        ? Colors.yellow.shade300
        : Colors.deepOrange.shade50;
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: _handleTap,
        child: Container(
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Center(
            child: Text(
              widget.value,
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: widget.value == 'X' ? Colors.deepOrange : Colors.blueAccent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Сложность ИИ.
enum Difficulty {
  easy,
  hard,
}

/*
  Дополнительные возможные улучшения:

  - Локализация: использовать intl для перевода строк.
  - Более расширенные настройки: выбор цвета "X" и "O", выбор тем оформления, добавление музыки или звуковых эффектов.
  - Более интеллектуальный AI для больших полей или применение эвристик.
  - Онлайн-режим: игра по сети с другими игроками.
  - История ходов: показать последовательность сделанных ходов.

*/
