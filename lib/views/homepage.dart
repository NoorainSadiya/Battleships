import 'package:battleships/views/newgame.dart';
import 'package:flutter/material.dart';
import 'package:battleships/utils/service.dart';
import 'package:battleships/views/loginregisteration.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:battleships/views/gamescreen.dart';

class HomeScreen extends StatefulWidget {
  final Service authentication;

  HomeScreen({
    Key? key,
    required this.authentication,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late List<Map<String, dynamic>> allGames;
  late List<Map<String, dynamic>> activeGames = [];
  late List<Map<String, dynamic>> completedGames = [];

  bool showActiveGames = true;

  @override
  void initState() {
    super.initState();
    allGames = [];
    fetchGames();
  }

  Future<void> fetchGames() async {
    try {
      final gamesResponse = await widget.authentication.getGames();
      handleGamesResponse(gamesResponse);
    } catch (e) {
      showFetchErrorSnackbar('Network error: $e');
    }
  }

  void handleGamesResponse(Map<String, dynamic> response) {
    if (response.containsKey('success') && response['success'] == true) {
      final dynamic responseData = response['data']['games'];

      if (responseData is List) {
        setState(() {
          allGames = List<Map<String, dynamic>>.from(responseData);
          activeGames = List<Map<String, dynamic>>.from(allGames
              .where((game) => game['status'] == 0 || game['status'] == 3));
          completedGames = List<Map<String, dynamic>>.from(allGames
              .where((game) => game['status'] == 1 || game['status'] == 2));
        });
      } else {
        showFetchErrorSnackbar('Invalid response format for games');
      }
    } else {
      showFetchErrorSnackbar(response['message'] ?? 'Unknown error');
    }
  }

  void showFetchErrorSnackbar(String errorMessage) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(errorMessage)),
    );
  }

  Future<void> startNewGame(BuildContext context) async {
    final List<String>? ships = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewGameScreen(
          onStartGame: (ships) async {
            final response = await widget.authentication.createGame(ships);
            if (response['success']) {
              await fetchGames();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(response['message'])),
              );
            }
          },
        ),
      ),
    );
    Navigator.pop(context);
  }

  void logout(BuildContext context) {
    widget.authentication.logout();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => LoginPage(),
      ),
    );
  }

  void toggleGamesView() {
    setState(() {
      showActiveGames = !showActiveGames;
    });
  }

  Future<bool> deleteGame(BuildContext context, String gameId) async {
    if (widget.authentication.accessToken == null) {
      return false;
    }

    try {
      final response = await http.delete(
        Uri.parse('${widget.authentication.baseUrl}/games/$gameId'),
        headers: {
          'Authorization': 'Bearer ${widget.authentication.accessToken}'
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final Map<String, dynamic> error = jsonDecode(response.body);

        if (error['error'] == 'Game already over') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Cannot delete game, it is already over')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error['message'] ?? 'Unknown error')),
          );
        }

        return false;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error: $e')),
      );
      return false;
    }
  }

  Future<void> _showAiSelectionDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('What type of AI you want to play against?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Random'),
                onTap: () {
                  Navigator.pop(context);
                  _startGameWithAi(ai: 'random');
                },
              ),
              ListTile(
                title: Text('Perfect'),
                onTap: () {
                  Navigator.pop(context);
                  _startGameWithAi(ai: 'perfect');
                },
              ),
              ListTile(
                title: Text('One Ship (A1)'),
                onTap: () {
                  Navigator.pop(context);
                  _startGameWithAi(ai: 'oneship');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _startGameWithAi({required String ai}) async {
    final List<String>? ships = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewGameScreen(
          onStartGame: (ships) async {
            final response =
                await widget.authentication.createGame(ships, ai: ai);
            if (response['success']) {
              await fetchGames();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(response['message'])),
              );
            }
          },
        ),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> gamesToDisplay;

    if (showActiveGames) {
      gamesToDisplay = activeGames;
    } else {
      gamesToDisplay = completedGames;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Battleships'),
        actions: [
          IconButton(
            onPressed: () async {
              await fetchGames();
            },
            icon: Icon(Icons.refresh),
          ),
        ],
        backgroundColor: Colors.blueGrey,
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blueGrey,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Battleships",
                    style: TextStyle(fontSize: 28),
                  ),
                  Text('Logged In as ${widget.authentication.username}'),
                ],
              ),
            ),
            ListTile(
                leading: Icon(Icons.add),
                title: const Text('New Game'),
                onTap: () {
                  startNewGame(context);
                }),
            ListTile(
              leading: Icon(Icons.smart_toy_outlined),
              title: const Text('New Game(AI)'),
              onTap: () {
                _showAiSelectionDialog(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.list),
              title: Text(showActiveGames
                  ? 'Show Completed Games'
                  : 'Show Active Games'),
              onTap: () {
                toggleGamesView();
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: const Text('Log out'),
              onTap: () => logout(context),
            ),
          ],
        ),
      ),
      body: ListView.builder(
        itemCount: gamesToDisplay.length,
        itemBuilder: (context, index) {
          final game = gamesToDisplay[index];
          print('Debug: Game - $game');
          final player1 = game['player1'];
          final player2 = game['player2'];
          print('${player1.runtimeType}');
          print('${player2.runtimeType}');

          return Dismissible(
            key: Key(game['id'].toString()),
            onDismissed: (direction) async {
              final success = await deleteGame(context, game['id'].toString());

              await Future.delayed(Duration(milliseconds: 500));
              setState(() {
                if (success) {
                  allGames = List.from(allGames)..removeAt(index);
                  activeGames = List.from(activeGames)..removeAt(index);
                  completedGames = List.from(completedGames)..removeAt(index);
                }
              });
            },
            background: Container(
              color: Colors.red,
              child: Icon(Icons.delete, color: Colors.white),
              alignment: Alignment.centerRight,
              padding: EdgeInsets.only(right: 16.0),
            ),
            child: ListTile(
              title: Text('#${game['id']}'),
              subtitle: _getSubtitle(game, player1, player2),
              trailing: Text(
                '${getStatusText(game['status'], game['players'], game['turn'])}',
                style: TextStyle(fontSize: 14),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GamePlayScreen(
                      gameId: game['id'].toString(),
                      authentication: widget.authentication,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _getSubtitle(
      Map<String, dynamic> game, dynamic player1, dynamic player2) {
    if (game['status'] == 0) {
      return Text('Waiting for opponent');
    } else if (game['status'] == 3) {
      return _getInProgressSubtitle(player1, player2);
    } else {
      return Container();
    }
  }

  Widget _getInProgressSubtitle(dynamic player1, dynamic player2) {
    if (player1 is Map<String, dynamic> && player2 is Map<String, dynamic>) {
      final username1 = player1['username'] ?? 'Player 1';
      final username2 = player2['username'] ?? 'Player 2';
      return Text('In Progress: $username1 vs $username2');
    } else if (player1 is String && player2 is String) {
      return Text('In progress: $player1 vs $player2');
    } else {
      print('Debug: In Progress - Players: $player1, $player2');
      return Text('In progress: unknown vs unknown');
    }
  }

  String getStatusText(int status, List<dynamic>? players, int turn) {
    switch (status) {
      case 0:
        return 'Matchmaking';
      case 1:
        return 'Lost';
      case 2:
        return 'Won';
      case 3:
        return turn == 1 ? 'Your Turn' : 'Opponent\'s Turn';

      default:
        return 'Unknown';
    }
  }
}