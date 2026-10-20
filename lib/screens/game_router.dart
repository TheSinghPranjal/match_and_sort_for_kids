import 'package:flutter/material.dart';

import '../models/game_models.dart';
import '../services/app_scope.dart';
import 'game_intro_screen.dart';
import 'match_board_screen.dart';
import 'match_prompt_screen.dart';
import 'sort_game_screen.dart';

/// The gameplay screen for a game: one screen per interaction mode, shared
/// by every activity of that mode.
Widget gameScreenFor(GameDef game) => switch (game) {
  SortGameDef() => SortGameScreen(game: game),
  MatchGameDef(layout: MatchLayout.board) => MatchBoardScreen(game: game),
  MatchGameDef() => MatchPromptScreen(game: game),
};

/// Opens a game from the home screen. The first time a game is played the
/// short introduction is shown; afterwards children jump straight in (the
/// intro stays reachable from the pause menu).
void launchGame(BuildContext context, GameDef game) {
  final seen = AppScope.of(context).settings.seenIntros.contains(game.id);
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => seen ? gameScreenFor(game) : GameIntroScreen(game: game),
    ),
  );
}
