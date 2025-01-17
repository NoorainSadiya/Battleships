import 'package:flutter/material.dart';

class NewGameScreen extends StatefulWidget {
  final Function(List<String>) onStartGame;

  NewGameScreen({Key? key, required this.onStartGame}) : super(key: key);

  @override
  _NewGameScreenState createState() => _NewGameScreenState();
}

class _NewGameScreenState extends State<NewGameScreen> {
  List<String> selectedShips = [];
  List<List<String>> board = List.generate(5, (index) => List.filled(5, ''));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Place Your Ships'),
      ),
      body: Column(
        children: [
          Container(
            margin: EdgeInsets.all(16.0),
            child: GridView.builder(
                shrinkWrap: true,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 4.0,
                  mainAxisSpacing: 4.0,
                ),
                itemCount: 25,
                itemBuilder: (context, index) {
                  final row = index ~/ 5;
                  final col = index % 5;

                  if (row >= 0 &&
                      row < board.length &&
                      col >= 0 &&
                      col < board[row].length) {
                    final cellValue = board[row][col];

                    return GestureDetector(
                      onTap: () {
                        if (cellValue.isEmpty && selectedShips.length < 5) {
                          setState(() {
                            board[row][col] = 'X';
                            selectedShips.add(
                                '${String.fromCharCode(row + 65)}${col + 1}');
                          });
                        } else if (cellValue.isNotEmpty) {
                          setState(() {
                            board[row][col] = '';
                            selectedShips.remove(
                                '${String.fromCharCode(row + 65)}${col + 1}');
                          });
                        }
                        print(
                            'Cell Tapped: row=$row, col=$col, selectedShips=$selectedShips');
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(),
                        ),
                        alignment: Alignment.center,
                        child: Text(cellValue),
                      ),
                    );
                  }
                }),
          ),
          ElevatedButton(
            onPressed: () {
              if (selectedShips.length == 5) {
                widget.onStartGame(selectedShips);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please place 5 ships to start the game.'),
                  ),
                );
              }
            },
            child: Text('Start Game'),
          ),
        ],
      ),
    );
  }
}