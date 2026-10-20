import 'package:flutter/painting.dart';

import '../models/game_models.dart';

/// Scene themes. Each game picks the one that fits its story; all share the
/// same sky-and-hills garden world so the app feels like one place.
class Themes {
  Themes._();

  static const garden = GameTheme(
    top: Color(0xFF8ED6FF),
    bottom: Color(0xFFD6F1FF),
    ground: Color(0xFF8EDB6A),
    decorations: ['🌻', '🌷', '🦋', '🌳'],
  );

  static const artRoom = GameTheme(
    top: Color(0xFFFFC7E6),
    bottom: Color(0xFFFFF0D9),
    ground: Color(0xFFFFD27A),
    decorations: ['🖍️', '🎨', '✏️', '🖌️'],
  );

  static const park = GameTheme(
    top: Color(0xFF9FE3FF),
    bottom: Color(0xFFE6FAFF),
    ground: Color(0xFF7ED67A),
    decorations: ['🌳', '🎈', '🌼', '☁️'],
  );

  static const kitchenGarden = GameTheme(
    top: Color(0xFFB6F0C9),
    bottom: Color(0xFFF3FFE8),
    ground: Color(0xFFC8955E),
    decorations: ['🌱', '🧺', '🐝', '🌿'],
  );

  static const laundry = GameTheme(
    top: Color(0xFFBFE6FF),
    bottom: Color(0xFFF0FAFF),
    ground: Color(0xFFB9C9FF),
    decorations: ['🫧', '🧺', '🫧', '🧼'],
  );

  static const wardrobe = GameTheme(
    top: Color(0xFFE2D4FF),
    bottom: Color(0xFFFFF2FA),
    ground: Color(0xFFE8B98A),
    decorations: ['🪞', '🎀', '👒', '✨'],
  );

  static const weather = GameTheme(
    top: Color(0xFF9CC9FF),
    bottom: Color(0xFFFFF3C4),
    ground: Color(0xFF94DB78),
    decorations: ['🌈', '☁️', '🌤️', '💧'],
  );

  static const nature = GameTheme(
    top: Color(0xFFA7E8C8),
    bottom: Color(0xFFF2FFE6),
    ground: Color(0xFF6CC56A),
    decorations: ['🌳', '🍄', '🌿', '🦋'],
  );

  static const ocean = GameTheme(
    top: Color(0xFF8FD8FF),
    bottom: Color(0xFFCFF4FF),
    ground: Color(0xFF6EC7F0),
    decorations: ['🐚', '🫧', '🌊', '⭐'],
  );

  static const classroom = GameTheme(
    top: Color(0xFFFFE08A),
    bottom: Color(0xFFFFF9E6),
    ground: Color(0xFFFFB98A),
    decorations: ['🔤', '📚', '✏️', '🍎'],
  );

  static const scienceLab = GameTheme(
    top: Color(0xFFC8F2EA),
    bottom: Color(0xFFF4FFFC),
    ground: Color(0xFFA9D8FF),
    decorations: ['🔬', '🧪', '🧲', '✨'],
  );

  static const night = GameTheme(
    top: Color(0xFF9A8CFF),
    bottom: Color(0xFFFFD9B8),
    ground: Color(0xFF8BD08A),
    decorations: ['⭐', '🌙', '☀️', '☁️'],
  );

  static const playroom = GameTheme(
    top: Color(0xFFFFD1C4),
    bottom: Color(0xFFFFF6EC),
    ground: Color(0xFFA7E07C),
    decorations: ['🧸', '🪁', '🎈', '🧩'],
  );

  static const home = GameTheme(
    top: Color(0xFFFFE3B8),
    bottom: Color(0xFFFFF8EE),
    ground: Color(0xFFD9A876),
    decorations: ['🪴', '🖼️', '🕰️', '🪟'],
  );

  static const numbers = GameTheme(
    top: Color(0xFFB7E3FF),
    bottom: Color(0xFFFFF0F7),
    ground: Color(0xFFFFC9E3),
    decorations: ['🔢', '⭐', '🎈', '🔷'],
  );
}

/// Kid-friendly named colours shared by colour games.
class KidColors {
  KidColors._();

  static const red = Color(0xFFFF4D4D);
  static const blue = Color(0xFF3D8BFF);
  static const yellow = Color(0xFFFFD21F);
  static const green = Color(0xFF3CCB5A);
  static const orange = Color(0xFFFF9330);
  static const purple = Color(0xFFA25CFF);
  static const pink = Color(0xFFFF7EC4);
  static const white = Color(0xFFF7F7F7);
  static const brown = Color(0xFFA0683A);
  static const teal = Color(0xFF22C3B5);
}
