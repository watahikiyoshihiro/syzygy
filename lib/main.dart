import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:syzygy/overlays/game_over.dart';
import 'package:syzygy/overlays/main_menu.dart';

import 'ember_quest.dart';

void main() {
  runApp(
    GameWidget<EmberQuestGame>.controlled(
      gameFactory: EmberQuestGame.new,
      overlayBuilderMap: {
        'MainMenu': (_, game) => MainMenu(game: game),
        'GameOver': (_, game) => GameOver(game: game),
      },
      initialActiveOverlays: const ['MainMenu'],
    ),
  );
}
