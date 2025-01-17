import 'package:battleships/utils/service.dart';
import 'package:flutter/material.dart';


class GamePlayScreen extends StatefulWidget {
  final String gameId;
  final Service authentication;

  GamePlayScreen({required this.gameId, required this.authentication});

  @override
  _GamePlayScreenState createState() => _GamePlayScreenState();
}

class _GamePlayScreenState extends State<GamePlayScreen> {
  late List<List<String>> gameBoard;
  bool isUserTurn = false;
  bool isGameWon = false;
  Map<String, dynamic>? gameDetails;

  @override
  void initState() {
    super.initState();
    gameBoard = List.generate(5, (index) => List.filled(5, ''));
    fetchGameDetails();
  }

  Future<void> fetchGameDetails() async {
    try {
      final gameDetails =
          await widget.authentication.getGameDetails(widget.gameId);
      print('game details: $gameDetails');
      setState(() {
        this.gameDetails = gameDetails;
      });

      if (gameDetails != null) {
        if (gameDetails['success'] == false &&
            gameDetails['message'] == 'Token expired') {
          await widget.authentication.logout();
          return;
        }

        final data = gameDetails['data'] as Map<String, dynamic>?;

        if (data != null) {
          final ships = data['ships'] as List<dynamic>?;

          if (ships != null) {
            setState(() {
              gameBoard =
                  List<List<String>>.generate(5, (index) => List.filled(5, ''));

              ships.forEach((ship) {
                final row =
                    ship[0].toUpperCase().codeUnitAt(0) - 'A'.codeUnitAt(0);
                final col = int.tryParse(ship.substring(1)) ?? -1;

                if (row >= 0 && row < 5 && col >= 1 && col <= 5) {
                  gameBoard[row][col - 1] = 'X';
                }
              });

              final player1 = data['player1'] as String?;
              final player2 = data['player2'] as String?;
              final currentPlayer = widget.authentication.username;

              isUserTurn = (data['turn'] == 1 && currentPlayer == player1) ||
                  (data['turn'] == 2 && currentPlayer == player2);

              updateGameBoard(data);
            });

            if (!isGameWon) {
              final opponentShipsSunk = isShotsMade(gameBoard);
              if (opponentShipsSunk) {
                setState(() {
                  isGameWon = true;
                });
              }
            }
          } else {
            handleInvalidResponse(
                'Invalid game details response: Missing or invalid "ships" field');
          }
        } else {
          handleInvalidResponse(
              'Invalid game details response: Missing or invalid "data" field');
        }
      } else {
        handleNullResponse('Null game details response');
      }
    } catch (e) {
      if (e is TokenExpiredException) {
        await widget.authentication.logout();
      } else {
        handleError('Error fetching game details: $e');
      }
    }
  }

  void updateGameBoard(Map<String, dynamic> data) {
    
    final shots = data['shots'] as List<dynamic>? ?? [];
    final hits = data['sunk'] as List<dynamic>? ?? [];
    final sunkShips = data['wrecks'] as List<dynamic>? ?? [];

   
    shots.forEach((shot) {
      updateCellWithShot(shot, 'M');
    });

   
    hits.forEach((hit) {
      updateCellWithShot(hit, 'H');
    });

    
    sunkShips.forEach((sunkShip) {
      updateCellWithShot(sunkShip, 'W');
    });
  }

  void updateCellWithShot(String shot, String symbol) {
    final row = shot[0].toUpperCase().codeUnitAt(0) - 'A'.codeUnitAt(0);
    final col = int.tryParse(shot.substring(1)) ?? -1;

    if (row >= 0 && row < 5 && col >= 1 && col <= 5) {
      gameBoard[row][col - 1] = symbol;
    }
  }

  Future<void> playShot(int row, int col) async {
    try {
      if (!isUserTurn || gameBoard[row][col].isNotEmpty) {
        showSnackbar('Shot already played in this cell.');
        return;
      }

      final rowLetter = String.fromCharCode('A'.codeUnitAt(0) + row);
      final colString = (col + 1).toString();
      final shotCoordinates = '$rowLetter$colString';

      final shotResponse = await widget.authentication.playShot(
        widget.gameId,
        shotCoordinates,
      );

      if (shotResponse != null) {
        final success = shotResponse['success'] as bool?;
        final sunkShip = shotResponse['sunk_ship'] as bool?;
        final gameBoardData = shotResponse['gameBoard'] as List<dynamic>?;
        final updatedIsUserTurn = shotResponse['isUserTurn'] as bool? ?? false;

        if (success == true && sunkShip == true && gameBoardData != null) {
          setState(() {
            gameBoard = List<List<String>>.from(gameBoardData);
            isUserTurn = updatedIsUserTurn;
          });
        }

        if (sunkShip == true) {
          showOpponentShipSunkNotification();
        }

        if (isUserTurn) {
          await fetchGameDetails();
        }
      } else {
        handleNullResponse('Null shot response');
      }
    } catch (e) {
      handleError('Error playing shot: $e');
    }
  }

  void showOpponentShipSunkNotification() {
    const snackBar = SnackBar(
      content: Text(
          'Opponent Ship Sunk! You have successfully sunk one of your opponent\'s ships.'),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  bool isShotsMade(List<dynamic>? gameBoardData) {
    if (gameBoardData == null) {
      return false;
    }

    for (final row in gameBoardData) {
      for (final cell in row) {
        if (cell == 'X') {
          return false;
        }
      }
    }

    return true;
  }

  void handleNullResponse(String message) {
    showSnackbar('Null response: $message');
  }

  void handleInvalidResponse(String message) {
    showSnackbar('Invalid response: $message');
  }

  void handleError(String message) {
    showSnackbar('Error: $message');
  }

  void showSnackbar(String message) {
    final snackBar = SnackBar(
      content: Text(message),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  bool isOpponentShipsSunk(List<List<String>> gameBoard) {
    for (final row in gameBoard) {
      for (final cell in row) {
        if (cell == 'X') {
          return false;
        }
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    double cellSize = MediaQuery.of(context).size.width / 6;
    return Scaffold(
      appBar: AppBar(
        title: Text('Battleships - Game: ${widget.gameId}'),
        backgroundColor: Colors.blueGrey,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            margin: const EdgeInsets.all(16.0),
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 4.0,
                mainAxisSpacing: 4.0,
                childAspectRatio: 1.0,
              ),
              itemCount: 25,
              itemBuilder: (context, index) {
                final row = index ~/ 5;
                final col = index % 5;
                final cellValue = gameBoard[row][col];

                if (gameDetails != null) {
                  final data = gameDetails!['data'] as Map<String, dynamic>?;

                  if (data != null) {
                    final ships = data['ships'] as List<dynamic>?;
                    final currentPlayer = widget.authentication.username;

                    if (ships != null) {
                      Widget cellContent;

                      if (cellValue == 'X') {
                       
                        cellContent =
                            const Text('🚢', style: TextStyle(fontSize: 20));
                      } else if (cellValue == 'W') {
                        
                        cellContent = cellContent =
                            const Text('💦', style: TextStyle(fontSize: 20));
                      } else if (cellValue == 'M') {
                        
                        cellContent =
                            const Text('💣', style: TextStyle(fontSize: 20));
                      } else if (cellValue == 'H') {
                       
                        cellContent =
                            const Text('💥', style: TextStyle(fontSize: 20));
                      } else {
                        cellContent = const Text('');
                      }

                      return GestureDetector(
                        onTap: () {
                          if (isUserTurn && cellValue.isEmpty) {
                            playShot(row, col);
                          }
                        },
                        child: Container(
                          width: cellSize,
                          height: cellSize,
                          decoration: BoxDecoration(
                            border: Border.all(),
                          ),
                          alignment: Alignment.center,
                          child: cellContent,
                        ),
                      );
                    }
                  }
                }

                return const SizedBox.shrink();
              },
            ),
          ),
  
        ],
      ),
    );
  }
}