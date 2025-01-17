import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Service extends ChangeNotifier {
  final String baseUrl = "http://165.227.117.48";
  final http.Client client = http.Client();

  String? _accessToken;

  String? get accessToken => _accessToken;

  bool get isAuthenticated => _accessToken != null;
  String? _username;

  String? get username => _username;

  Future<Map<String, dynamic>> authenticate(
      String username, String password, bool isLogin) async {
    if (isLogin) {
      return _login(username, password);
    } else {
      return _register(username, password);
    }
  }

  Future<void> storeToken(String token) async {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('accessToken', token);
      prefs.setString('username', username!);
    });
  }

  Future<void> loadToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('accessToken');
    _username = prefs.getString('username');
    notifyListeners();
  }

  Future<void> removeToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    _accessToken = null;
    notifyListeners();
  }

  Future<Map<String, dynamic>> getActiveGames() async {
    if (_accessToken == null) {
      return {'success': false, 'message': 'Not authenticated.'};
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/games'),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      return await _handleActiveGamesResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> _handleActiveGamesResponse(
      http.Response response) async {
    if (response.statusCode == 200) {
      try {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData.containsKey('games')) {
          final dynamic games = responseData['games'];
          if (games is List) {
            return {'success': true, 'games': games};
          } else {
            return {
              'success': false,
              'message': 'Invalid response format: "games" is not a list.'
            };
          }
        } else {
          return {
            'success': false,
            'message': 'Invalid response format: "games" key not found.'
          };
        }
      } catch (e) {
        return {'success': false, 'message': 'Invalid response format.'};
      }
    } else {
      final Map<String, dynamic> error = jsonDecode(response.body);

      if (error.containsKey('message')) {
        String errorMessage = error['message'];
        return {'success': false, 'message': errorMessage};
      } else {
        return {'success': false, 'message': 'Unknown error.'};
      }
    }
  }

  Future<Map<String, dynamic>> _register(
      String username, String password) async {
    if (username.length < 3 ||
        password.length < 3 ||
        username.contains(' ') ||
        password.contains(' ')) {
      return {'success': false, 'message': 'Invalid username or password.'};
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      return _handleAuthResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> _login(String username, String password) async {
    if (username.isEmpty || password.isEmpty) {
      return {
        'success': false,
        'message': 'Username and password cannot be empty.'
      };
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );
      final authResponse = _handleAuthResponse(response);
      if (authResponse['success']) {
        _accessToken = authResponse['token'];
        _username = username;
      }

      return authResponse;
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> playShot(String gameId, String shot) async {
    if (_accessToken == null) {
      return {'success': false, 'message': 'Not authenticated.'};
    }

    final RegExp shotFormat = RegExp(r'^[A-E][1-5]$');
    if (!shotFormat.hasMatch(shot)) {
      return {'success': false, 'message': 'Invalid shot format.'};
    }

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/games/$gameId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_accessToken',
        },
        body: jsonEncode({'shot': shot}),
      );

      if (response.statusCode == 200) {
        return _handleShotResponse(response);
      } else {
        final Map<String, dynamic> error = jsonDecode(response.body);

        if (error.containsKey('message')) {
          String errorMessage = error['message'];
          return {'success': false, 'message': errorMessage};
        } else {
          return {'success': false, 'message': 'Unknown error.'};
        }
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Map<String, dynamic> _handleShotResponse(http.Response response) {
    try {
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (responseData.containsKey('message') &&
            responseData.containsKey('sunk_ship') &&
            responseData.containsKey('won')) {
          return {
            'success': true,
            'message': responseData['message'],
            'sunk_ship': responseData['sunk_ship'],
            'won': responseData['won'],
          };
        }

        return {
          'success': false,
          'message': 'Invalid response format for shot response.',
        };
      }

      return {
        'success': false,
        'message': 'Non-200 status code: ${response.statusCode}',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error decoding shot response: $e',
      };
    }
  }

  Future<Map<String, dynamic>> getGameDetails(String gameId) async {
    if (_accessToken == null) {
      throw TokenExpiredException('Not authenticated.');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/games/$gameId'),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      if (response.statusCode == 200) {
        return _handleGameDetailsResponse(response);
      } else if (response.statusCode == 401) {
        throw TokenExpiredException('Token expired');
      } else {
        final Map<String, dynamic> error = jsonDecode(response.body);

        if (error.containsKey('message')) {
          String errorMessage = error['message'];
          return {'success': false, 'message': errorMessage};
        } else {
          return {'success': false, 'message': 'Unknown error.'};
        }
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Map<String, dynamic> _handleGameDetailsResponse(http.Response response) {
    if (response.statusCode == 200) {
      try {
        final Map<String, dynamic>? responseData = jsonDecode(response.body);

        if (responseData == null) {
          return {'success': false, 'message': 'Invalid response format.'};
        }

        if (responseData.containsKey('id') &&
            responseData.containsKey('player1') &&
            responseData.containsKey('player2') &&
            responseData.containsKey('position') &&
            responseData.containsKey('ships') &&
            responseData.containsKey('wrecks') &&
            responseData.containsKey('shots') &&
            responseData.containsKey('sunk') &&
            responseData.containsKey('status') &&
            responseData.containsKey('turn')) {
          final gameDetails = {
            'id': responseData['id'],
            'player1': responseData['player1'],
            'player2': responseData['player2'],
            'position': responseData['position'],
            'ships': responseData['ships'],
            'wrecks': responseData['wrecks'],
            'shots': responseData['shots'],
            'sunk': responseData['sunk'],
            'status': responseData['status'],
            'turn': responseData['turn'],
          };

          return {'success': true, 'data': gameDetails};
        } else {
          return {
            'success': false,
            'message': 'Invalid response format for game details.'
          };
        }
      } catch (e) {
        return {
          'success': false,
          'message': 'Error decoding game details response: $e'
        };
      }
    } else {
      final Map<String, dynamic> error = jsonDecode(response.body);

      if (error.containsKey('message')) {
        String errorMessage = error['message'];
        return {'success': false, 'message': errorMessage};
      } else {
        return {'success': false, 'message': 'Unknown error.'};
      }
    }
  }

  Future<void> logout() async {
    await removeToken();
  }

  Future<Map<String, dynamic>> getOpponentMove(String gameId) async {
    final endpoint = Uri.parse('$baseUrl/getOpponentMove?gameId=$gameId');

    try {
      final response = await http.get(endpoint);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Failed to get opponent\'s move');
      }
    } catch (e) {
      throw Exception('Network error');
    }
  }

  Future<Map<String, dynamic>> createGame(List<String> ships,
      {String? ai}) async {
    if (_accessToken == null) {
      return {'success': false, 'message': 'Not authenticated.'};
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/games'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_accessToken',
        },
        body: jsonEncode({'ships': ships, 'ai': ai}),
      );

      return _handleGameResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> startGameWithAi(
      List<String> ships, String aiType) async {
    try {
      final response = await createGame(ships, ai: aiType);

      if (response['success']) {
        return {'success': true};
      } else {
        return {'success': false, 'message': response['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> getGames() async {
    if (_accessToken == null) {
      return {'success': false, 'message': 'Not authenticated.'};
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/games'),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      return _handleGameResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> cancelGame(String gameId) async {
    if (_accessToken == null) {
      return {'success': false, 'message': 'Not authenticated.'};
    }

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/games/$gameId'),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        return {'success': true, 'data': data};
      } else {
        final Map<String, dynamic> error = jsonDecode(response.body);

        return {
          'success': false,
          'message': error['message'] ?? 'Unknown error'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Map<String, dynamic> _handleAuthResponse(http.Response response) {
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);

      if (data.containsKey('access_token')) {
        return {'success': true, 'token': data['access_token']};
      } else {
        return {'success': false, 'message': 'Access token not found.'};
      }
    } else if (response.statusCode == 404) {
      return {
        'success': false,
        'message': 'Account not found. Please register.'
      };
    } else if (response.statusCode == 409) {
      return {
        'success': false,
        'message': 'Account already registered. Please log in.'
      };
    } else {
      final Map<String, dynamic> error = jsonDecode(response.body);

      if (error.containsKey('message')) {
        String errorMessage = error['message'];
        return {'success': false, 'message': errorMessage};
      } else {
        return {'success': false, 'message': 'Unknown error.'};
      }
    }
  }

  Map<String, dynamic> _handleGameResponse(http.Response response) {
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return {'success': true, 'data': data};
    } else {
      final Map<String, dynamic> error = jsonDecode(response.body);

      if (error.containsKey('message')) {
        String errorMessage = error['message'];
        return {'success': false, 'message': errorMessage};
      } else {
        return {'success': false, 'message': 'Unknown error.'};
      }
    }
  }

  void setAccessToken(String? token) {
    _accessToken = token;
    notifyListeners();
  }
}

class TokenExpiredException implements Exception {
  final String message;

  TokenExpiredException(this.message);

  @override
  String toString() {
    return 'TokenExpiredException: $message';
  }
}