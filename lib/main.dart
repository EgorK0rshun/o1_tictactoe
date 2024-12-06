/*
  Этот пример демонстрирует расширенную версию игры "Крестики-нолики" на Flutter.

  Что добавлено и улучшено по сравнению с предыдущим вариантом:
  1. Вынесена логика игры в отдельный класс GameLogic, что упрощает тестирование и поддержку.
  2. Добавлен режим игры против "компьютера" (AI):
     - При включенном "Одиночном режиме" (single player), за игрока "O" ходит ИИ.
     - ИИ в данном примере простой — он делает случайный ход.
       (При желании можно расширить до алгоритма с использованием минимакса).
  3. Добавлен выбор размера поля (3x3, 4x4 и т.д.) с помощью диалога настроек.
  4. Добавлен выбор сложности ИИ (легкая, сложная — пока условно, без реального изменения логики).
  5. Создан отдельный виджет для клетки игрового поля (BoardCell).
  6. Добавлен более гибкий UI:
     - Настройки (иконка настроек в AppBar), где можно выбрать размер поля, режим игры и сложность.
     - Анимация при нажатии на клетку.
  7. Идеи для тестирования (юнит-тесты) и оптимизации остались в комментариях.

  Код готов к запуску «как есть»:
  - Поместите этот файл в lib/main.dart вашего проекта Flutter.
  - Выполните команду: flutter run

  Идеи для тестирования, расширения и оптимизации остаются актуальными.
*/

import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

/// Корневой виджет приложения.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(final BuildContext context) {
    return MaterialApp(
      title: 'Крестики-нолики',
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        brightness: Brightness.light,
      ),
      home: const TicTacToeGamePage(),
    );
  }
}

/// Основной экран игры.
class TicTacToeGamePage extends StatefulWidget {
  const TicTacToeGamePage({super.key});

  @override
  State<TicTacToeGamePage> createState() => _TicTacToeGamePageState();
}

class _TicTacToeGamePageState extends State<TicTacToeGamePage> {
  /// Логика игры вынесена в отдельный класс.
  late GameLogic _gameLogic;

  /// Режим одиночной игры против компьютера.
  bool _singlePlayer = false;

  /// Текущая сложность ИИ (пока не влияет на логику, но может быть использована в будущем).
  Difficulty _difficulty = Difficulty.easy;

  @override
  void initState() {
    super.initState();
    // Инициализируем логику игры с размером поля 3x3 по умолчанию.
    _gameLogic = GameLogic(boardSize: 3);
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
                    return BoardCell(
                      value: value,
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

  /// Ход ИИ (простой случайный ход).
  void _makeAiMove() {
    if (_gameLogic.gameOver) return;
    _gameLogic.makeAiMove(difficulty: _difficulty);
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
    });
  }

  /// Диалог настроек.
  Future<void> _showSettingsDialog() async {
    int tempSize = _gameLogic.boardSize;
    bool tempSinglePlayer = _singlePlayer;
    Difficulty tempDifficulty = _difficulty;

    await showDialog<void>(
      context: context,
      builder: (final BuildContext context) {
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
                              tempSize = val;
                              setState(() {});
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
                      tempSinglePlayer = val;
                    }
                    setState(() {});
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
                      tempDifficulty = val;
                    }
                    setState(() {});
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
                _applySettings(tempSize, tempSinglePlayer, tempDifficulty);
              },
            ),
          ],
        );
      },
    );
  }

  /// Применяем настройки.
  void _applySettings(final int size, final bool singlePlayer, final Difficulty diff) {
    setState(() {
      _singlePlayer = singlePlayer;
      _difficulty = diff;
      _gameLogic.changeBoardSize(size);
    });
  }
}

/// Класс, управляющий логикой игры.
class GameLogic {
  GameLogic({required this.boardSize}) {
    _initBoard();
  }

  /// Размер поля (например 3 для 3x3).
  int boardSize;

  /// Текущий игрок: "X" или "O".
  String _currentPlayer = 'X';

  /// Список для хранения состояния поля.
  late List<String> board;

  /// Подсчет побед для "X".
  int scoreX = 0;

  /// Подсчет побед для "O".
  int scoreO = 0;

  /// Флаг окончания игры.
  bool _gameOver = false;

  /// Сообщение о результате (например "Победил X!" или "Ничья!").
  String _resultMessage = '';

  String get currentPlayer => _currentPlayer;
  bool get gameOver => _gameOver;
  String get resultMessage => _resultMessage;

  void _initBoard() {
    board = List<String>.filled(boardSize * boardSize, '', growable: false);
    _currentPlayer = 'X';
    _gameOver = false;
    _resultMessage = '';
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

  /// Ход ИИ - простой случайный ход (можно улучшить логику).
  void makeAiMove({required Difficulty difficulty}) {
    if (_gameOver) return;

    // Список пустых клеток
    final List<int> emptyCells = [];
    for (int i = 0; i < board.length; i++) {
      if (board[i].isEmpty) {
        emptyCells.add(i);
      }
    }

    if (emptyCells.isEmpty) {
      // Нет хода, ничья.
      _checkGameState();
      return;
    }

    // В зависимости от сложности можно улучшить стратегию.
    // Пока что — просто случайный ход.
    final Random random = Random();
    final int moveIndex = emptyCells[random.nextInt(emptyCells.length)];
    board[moveIndex] = _currentPlayer;
    _checkGameState();
    if (!_gameOver) {
      _switchPlayer();
    }
  }

  /// Проверка состояния игры после хода.
  void _checkGameState() {
    // Проверяем победу.
    if (_checkWin(_currentPlayer)) {
      _gameOver = true;
      _resultMessage = 'Победил $_currentPlayer!';
      if (_currentPlayer == 'X') {
        scoreX++;
      } else {
        scoreO++;
      }
      return;
    }

    // Проверяем ничью (если нет пустых клеток).
    if (!board.contains('')) {
      _gameOver = true;
      _resultMessage = 'Ничья!';
    }
  }

  /// Проверка, выиграл ли указанный игрок.
  bool _checkWin(final String player) {
    // Генерируем все линии (строки, столбцы, диагонали).
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

    // Проверяем, есть ли у player три (или boardSize) в ряд
    for (final List<int> pattern in winPatterns) {
      bool won = true;
      for (int idx in pattern) {
        if (board[idx] != player) {
          won = false;
          break;
        }
      }
      if (won) return true;
    }

    return false;
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
  const BoardCell({super.key, required this.value, required this.onTap});

  final String value;
  final VoidCallback onTap;

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
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: _handleTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.deepOrange.shade50,
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
   ---------------------------
   ВОЗМОЖНЫЕ РАСШИРЕНИЯ
   ---------------------------
   1. Реализовать AI более интеллектуально:
      - Использовать алгоритм минимакса для идеальных ходов.
      - Учитывать сложность: "Легкая" — случайный ход, "Сложная" — умный ход.

   2. Более продвинутый UI:
      - Анимации появления "X" и "O".
      - Кастомные иконки или изображения вместо текста.
      - Цветовые темы, выбор стиля.

   3. Дополнительные настройки:
      - Сохранение статистики и настроек между сессиями (SharedPreferences).
      - Многоязычная поддержка (intl пакет).

   4. Расширить поле, например 5x5 с новой логикой победы (три в ряд, или пять в ряд).

   ---------------------------
   ИДЕИ ДЛЯ ТЕСТИРОВАНИЯ (Юнит-тесты)
   ---------------------------
   1. Проверить логику _checkWin() для разных ситуаций.
   2. Проверить правильность смены игрока.
   3. Проверить корректное определение ничьи.
   4. Тестирование методов resetBoard() и resetAll().

   ---------------------------
   ОПТИМИЗАЦИЯ КОДА
   ---------------------------
   1. Разделение логики игры и UI уже сделано (GameLogic).
   2. Можно вынести виджеты в отдельные файлы для лучшей структуры проекта.
   3. Добавить менеджер состояния (Provider, Riverpod, BLoC) для управления логикой.
   4. Добавить локализацию и тесты покрытия.

*/
