# MP Report

## Team

- Name(s): Sadiya Noorain
- AID(s): A20552054

## Self-Evaluation Checklist

Tick the boxes (i.e., fill them with 'X's) that apply to your submission:

- [X] The app builds without error
- [X] I tested the app in at least one of the following platforms (check all that apply):
  - [X] iOS simulator / MacOS
  - [ ] Android emulator
- [X] Users can register and log in to the server via the app
- [X] Session management works correctly; i.e., the user stays logged in after closing and reopening the app, and token expiration necessitates re-login
- [X] The game list displays required information accurately (for both active and completed games), and can be manually refreshed
- [X] A game can be started correctly (by placing ships, and sending an appropriate request to the server)
- [X] The game board is responsive to changes in screen size
- [X] Games can be started with human and all supported AI opponents
- [X] Gameplay works correctly (including ship placement, attacking, and game completion)

## Summary and Reflection

I used Flutter for the front-end and HTTP requests to interact with the backend for game state management. For navigation, I employed Navigator, and FutureBuilder was used to load data asynchronously. I integrated token-based authentication and attempted WebSocket for real-time updates, but struggled with server-related issues preventing full WebSocket functionality.

I enjoyed implementing the game logic and managing the state, but found debugging WebSocket integration challenging due to server configuration issues. More prior knowledge of WebSocket handling would have helped avoid these hurdles.