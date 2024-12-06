/*
  Этот пример демонстрирует простую игру "Крестики-нолики" на Flutter.
  Особенности:
  - Приятный пользовательский интерфейс с использованием Material Design.
  - Подсчет статистики побед для "X" и для "O".
  - Возможность сброса игры и статистики.
  - Комментарии и пояснения по ключевым моментам.
  - Код "как есть": достаточно скопировать в основной файл проекта Flutter и запустить.

  Пример структуры проекта:
  lib/
    main.dart (этот файл)

  Перед запуском убедитесь, что у вас установлен Flutter SDK.
  Команда для запуска:
    flutter run
*/

import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

/// Виджет корневого приложения.
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

/// Страница с игрой "Крестики-нолики".
/// Содержит игровое поле, панель статистики и кнопки сброса.
class TicTacToeGamePage extends StatefulWidget {
  const TicTacToeGamePage({super.key});

  @override
  State<TicTacToeGamePage> createState() => _TicTacToeGamePageState();
}

/// Состояние страницы с игрой "Крестики-нолики".
class _TicTacToeGamePageState extends State<TicTacToeGamePage> {
  /// Список для хранения состояния игрового поля.
  /// Индексы от 0 до 8 соответствуют клеткам поля 3x3.
  /// Пустая строка означает, что ячейка не занята.
  final List<String> _board = List<String>.filled(9, '', growable: false);

  /// Текущий игрок: "X" или "O". Изначально ходит "X".
  String _currentPlayer = 'X';

  /// Подсчет побед для игрока "X".
  int _scoreX = 0;

  /// Подсчет побед для игрока "O".
  int _scoreO = 0;

  /// Проверка: была ли игра окончена (например, после победы).
  bool _gameOver = false;

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Крестики-нолики'),
        centerTitle: true,
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
                        'X: $_scoreX',
                        style: const TextStyle(fontSize: 16),
                      ),
                      Text(
                        'O: $_scoreO',
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
              'Ход игрока: $_currentPlayer',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16.0),

            /// Само поле 3x3
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                mainAxisSpacing: 8.0,
                crossAxisSpacing: 8.0,
                children: <Widget>[
                  for (int i = 0; i < 9; i++) _buildCell(i),
                ],
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

  /// Создает виджет-ячейку игрового поля по индексу [index].
  /// Использует ElevatedButton, внутри которого текст: "X", "O" или пусто.
  Widget _buildCell(final int index) {
    final String value = _board[index];
    return GestureDetector(
      onTap: () {
        _handleTap(index);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.deepOrange.shade50,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Center(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: value == 'X' ? Colors.deepOrange : Colors.blueAccent,
            ),
          ),
        ),
      ),
    );
  }

  /// Обработчик нажатия на ячейку с индексом [index].
  /// Если игра не окончена и ячейка пустая — делаем ход.
  void _handleTap(final int index) {
    if (_board[index].isEmpty && !_gameOver) {
      setState(() {
        _board[index] = _currentPlayer;
        if (_checkWin(_currentPlayer)) {
          _gameOver = true;
          _showResultDialog('Победили $_currentPlayer!');
          if (_currentPlayer == 'X') {
            _scoreX++;
          } else {
            _scoreO++;
          }
        } else if (!_board.contains('')) {
          // Ничья, если нет пустых ячеек и никто не выиграл.
          _gameOver = true;
          _showResultDialog('Ничья!');
        } else {
          // Если никто не выиграл, переключаем текущего игрока.
          _currentPlayer = _currentPlayer == 'X' ? 'O' : 'X';
        }
      });
    }
  }

  /// Проверка на победу игрока [player].
  /// Возвращает true, если игрок собрал три в ряд.
  bool _checkWin(final String player) {
    // Возможные комбинации индексов для победы (3 в ряд)
    final List<List<int>> winPatterns = <List<int>>[
      <int>[0, 1, 2],
      <int>[3, 4, 5],
      <int>[6, 7, 8],
      <int>[0, 3, 6],
      <int>[1, 4, 7],
      <int>[2, 5, 8],
      <int>[0, 4, 8],
      <int>[2, 4, 6],
    ];
    for (final List<int> pattern in winPatterns) {
      if (_board[pattern[0]] == player &&
          _board[pattern[1]] == player &&
          _board[pattern[2]] == player) {
        return true;
      }
    }
    return false;
  }

  /// Отображает диалоговое окно с результатом игры.
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

  /// Сброс только игрового поля, статистика побед сохраняется.
  void _resetBoard() {
    setState(() {
      for (int i = 0; i < _board.length; i++) {
        _board[i] = '';
      }
      _currentPlayer = 'X';
      _gameOver = false;
    });
  }

  /// Полный сброс всего: поле и статистика.
  void _resetAll() {
    setState(() {
      for (int i = 0; i < _board.length; i++) {
        _board[i] = '';
      }
      _currentPlayer = 'X';
      _scoreX = 0;
      _scoreO = 0;
      _gameOver = false;
    });
  }
}

/*
   ---------------------------
   ВОЗМОЖНЫЕ РАСШИРЕНИЯ И УЛУЧШЕНИЯ
   ---------------------------
   1. Добавить искусственный интеллект (AI):
      - Реализовать простой или сложный алгоритм, например, минимакс, для игры против компьютера.
      - Добавить выбор сложности: легкий (рандомные ходы), средний, сложный (идеальная игра).

   2. Улучшить интерфейс:
      - Добавить анимации при нажатии на клетку.
      - Применить нестандартные шрифты и иконки.
      - Использовать кастомные виджеты для клетки (например, иконки "X" и "O").

   3. Расширить поле:
      - Сделать поле 4x4 или другое нестандартное.
      - Добавить возможность настройки размера поля перед началом игры.

   4. Добавить систему пользовательских настроек:
      - Сохранять статистику между сессиями с помощью SharedPreferences или локальной базы данных (sqlite).
      - Добавить экран настроек (например, выбор темы, языка, сложности).

   ---------------------------
   ИДЕИ ДЛЯ ТЕСТИРОВАНИЯ (Юнит-тесты)
   ---------------------------
   1. Тестирование логики определения победы:
      - Проверить, что при заданном состоянии поля корректно определяется победитель.
      - Проверить, что при отсутствии победителя возвращается корректный результат.

   2. Тестирование смены текущего игрока:
      - Проверить, что после хода "X", ход переходит к "O" и наоборот.

   3. Тестирование состояния ничьи:
      - Заполнить поле так, чтобы не было победителя, и убедиться, что игра определяет ничью.

   4. Тестирование сбросов:
      - Проверить, что после вызова _resetBoard() поле очищается, а статистика сохраняется.
      - Проверить, что после вызова _resetAll() сбрасывается и поле, и статистика.

   ---------------------------
   ОПТИМИЗАЦИЯ КОДА
   ---------------------------
   1. Вынести логику игры в отдельный класс, чтобы было легче тестировать и поддерживать.
   2. Создать отдельный виджет для отображения одной клетки.
   3. Использовать state management (например, Provider или Riverpod), чтобы отделить логику от UI.
   4. Добавить локализацию через intl, чтобы обеспечить многоязычную поддержку.
   5. Оптимизировать отрисовку: сейчас это не критично, так как поле маленькое, но для больших полей можно применить оптимизации.
*/
