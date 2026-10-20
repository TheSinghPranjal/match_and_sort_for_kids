import 'dart:math';

import 'package:flutter/painting.dart';

import '../models/game_models.dart';
import '../models/visual.dart';
import 'themes.dart';

MatchCard _card(
  String id,
  String name,
  Visual visual,
  String key, {
  String? spoken,
}) => MatchCard(id: id, name: name, visual: visual, key: key, spoken: spoken);

MatchCard _emo(
  String id,
  String emoji,
  String name,
  String key, {
  double scale = 1,
  EmojiEffect fx = EmojiEffect.none,
  String? badge,
}) => _card(
  id,
  name,
  EmojiVisual(emoji, scale: scale, effect: fx, badge: badge),
  key,
);

/// Two identical cards (identical-picture style games).
MatchPair _twin(String id, Visual visual, String name, {int lvl = 1}) =>
    MatchPair(
      _card('${id}_1', name, visual, visual.visualId),
      _card('${id}_2', name, visual, visual.visualId),
      minLevel: lvl,
    );

/// Prompt -> answer pair keyed by [key].
MatchPair _p(MatchCard prompt, MatchCard answer, {int lvl = 1}) =>
    MatchPair(prompt, answer, minLevel: lvl);

// Shared scenes.
const _rainScene = SceneVisual(
  'rain',
  ['🌧️', '💧', '💧'],
  Color(0xFF9DB7D9),
  Color(0xFFD7E6F5),
);
const _sunScene = SceneVisual(
  'sunny',
  ['☀️', '🌼', '🌤️'],
  Color(0xFF8ED6FF),
  Color(0xFFFFF0B3),
);
const _coldScene = SceneVisual(
  'cold',
  ['❄️', '🌨️', '⛄'],
  Color(0xFFBFE3FF),
  Color(0xFFFFFFFF),
);
const _windScene = SceneVisual(
  'windy',
  ['🌬️', '🍃', '☁️'],
  Color(0xFFA9E0F7),
  Color(0xFFE8FBFF),
);
const _dayScene = SceneVisual(
  'day',
  ['☀️', '☁️', '🌳'],
  Color(0xFF7FD0FF),
  Color(0xFFFFF4C2),
);
const _nightScene = SceneVisual(
  'night',
  ['🌙', '⭐', '✨'],
  Color(0xFF2E2A6E),
  Color(0xFF6B5BBF),
);

final List<MatchGameDef> matchGames = [
  // 26 --------------------------------------------- identical pictures
  MatchGameDef(
    id: 'identical',
    number: 26,
    title: 'Find the Twins',
    instruction: 'Find two pictures that are the same!',
    section: GameSection.puzzles,
    cover: '🐱',
    theme: Themes.garden,
    rule: MatchRule.imageId,
    layout: MatchLayout.board,
    twoColumns: false,
    pairCounts: const LevelValues(2, 3, 5),
    pairs: [
      _twin('apple', const EmojiVisual('🍎'), 'Apple'),
      _twin('cat', const EmojiVisual('🐱'), 'Cat'),
      _twin('ball', const EmojiVisual('⚽'), 'Ball'),
      _twin('flower', const EmojiVisual('🌸'), 'Flower'),
      _twin('car', const EmojiVisual('🚗'), 'Car'),
      _twin('fish', const EmojiVisual('🐟'), 'Fish', lvl: 2),
      _twin('balloon', const EmojiVisual('🎈'), 'Balloon', lvl: 2),
      _twin('duck', const EmojiVisual('🦆'), 'Duck', lvl: 2),
      _twin('train', const EmojiVisual('🚂'), 'Train', lvl: 3),
      _twin('banana', const EmojiVisual('🍌'), 'Banana', lvl: 3),
      _twin('dog', const EmojiVisual('🐶'), 'Dog', lvl: 3),
    ],
  ),

  // 27 ----------------------------------------------------- colours
  MatchGameDef(
    id: 'match_colors',
    number: 27,
    title: 'Colour Match',
    instruction: 'Which colour is it? Tap the matching colour!',
    section: GameSection.colorShape,
    cover: '🖍️',
    theme: Themes.artRoom,
    rule: MatchRule.colorId,
    layout: MatchLayout.prompt,
    pairs: [
      for (final (emoji, name, color, cname, lvl) in [
        ('🍎', 'Red apple', KidColors.red, 'Red', 1),
        ('🫐', 'Blueberries', KidColors.blue, 'Blue', 1),
        ('🐤', 'Yellow duck', KidColors.yellow, 'Yellow', 1),
        ('🍃', 'Green leaf', KidColors.green, 'Green', 1),
        ('🥕', 'Carrot', KidColors.orange, 'Orange', 2),
        ('🍇', 'Grapes', KidColors.purple, 'Purple', 2),
        ('🌸', 'Pink flower', KidColors.pink, 'Pink', 3),
        ('🍓', 'Strawberry', KidColors.red, 'Red', 2),
        ('🍌', 'Banana', KidColors.yellow, 'Yellow', 2),
        ('🐸', 'Frog', KidColors.green, 'Green', 3),
      ])
        _p(
          _emo('c_$name', emoji, name, cname),
          _card('sw_$cname', cname, SwatchVisual(color, label: cname), cname),
          lvl: lvl,
        ),
    ],
  ),

  // 28 ------------------------------------------------------ shapes
  MatchGameDef(
    id: 'match_shapes',
    number: 28,
    title: 'Shape Match',
    instruction: 'Find the shape that is the same!',
    section: GameSection.colorShape,
    cover: '⭐',
    theme: Themes.artRoom,
    rule: MatchRule.shapeId,
    layout: MatchLayout.prompt,
    pairs: [
      for (final (shape, name, color, lvl) in [
        (ShapeKind.circle, 'Circle', KidColors.red, 1),
        (ShapeKind.square, 'Square', KidColors.blue, 1),
        (ShapeKind.triangle, 'Triangle', KidColors.green, 1),
        (ShapeKind.star, 'Star', KidColors.yellow, 1),
        (ShapeKind.heart, 'Heart', KidColors.pink, 2),
        (ShapeKind.rectangle, 'Rectangle', KidColors.orange, 2),
        (ShapeKind.oval, 'Oval', KidColors.purple, 3),
      ])
        _p(
          _card('p_$name', name, ShapeVisual(shape, color), shape.name),
          _card('a_$name', name, ShapeVisual(shape, color), shape.name),
          lvl: lvl,
        ),
      // Explorer: everyday objects to their basic shape.
      for (final (emoji, name, shape) in [
        ('⚽', 'Ball', ShapeKind.circle),
        ('🎁', 'Gift box', ShapeKind.square),
        ('🥚', 'Egg', ShapeKind.oval),
        ('🌟', 'Star', ShapeKind.star),
      ])
        _p(
          _emo('o_$name', emoji, name, shape.name),
          _card(
            'oa_${shape.name}',
            shape.name,
            ShapeVisual(shape, KidColors.teal),
            shape.name,
          ),
          lvl: 3,
        ),
    ],
  ),

  // 29 ------------------------------------------------------ shadows
  MatchGameDef(
    id: 'shadows',
    number: 29,
    title: 'Shadow Match',
    instruction: 'Whose shadow is this? Find the matching shadow!',
    section: GameSection.puzzles,
    cover: '🌑',
    theme: Themes.park,
    rule: MatchRule.silhouetteId,
    layout: MatchLayout.prompt,
    pairs: [
      for (final (emoji, name, lvl) in [
        ('🍎', 'Apple', 1),
        ('🏠', 'House', 1),
        ('🚗', 'Car', 1),
        ('🐟', 'Fish', 1),
        ('🦋', 'Butterfly', 2),
        ('🐘', 'Elephant', 2),
        ('☂️', 'Umbrella', 2),
        ('🦒', 'Giraffe', 3),
        ('🐌', 'Snail', 3),
        ('🎸', 'Guitar', 3),
      ])
        _p(
          _emo('o_$name', emoji, name, name),
          _emo(
            's_$name',
            emoji,
            '$name shadow',
            name,
            fx: EmojiEffect.silhouette,
          ),
          lvl: lvl,
        ),
    ],
  ),

  // 30 ------------------------------------------ uppercase / lowercase
  MatchGameDef(
    id: 'upper_lower_match',
    number: 30,
    title: 'Letter Partners',
    instruction: 'Match each big letter to its little letter!',
    section: GameSection.letters,
    cover: '🔡',
    theme: Themes.classroom,
    rule: MatchRule.letterId,
    layout: MatchLayout.board,
    minAge: 4,
    pairCounts: const LevelValues(2, 3, 4),
    pairs: [
      for (final l in 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split(''))
        MatchPair(
          _card('U$l', 'Capital $l', LetterVisual(l), l),
          _card(
            'l$l',
            'Small ${l.toLowerCase()}',
            LetterVisual(l.toLowerCase()),
            l,
          ),
          // b/d and p/q look alike: only on Explorer.
          minLevel: 'BDPQ'.contains(l) ? 3 : ('ACEHMOST'.contains(l) ? 1 : 2),
        ),
    ],
  ),

  // 31 ---------------------------------------------- letters to objects
  MatchGameDef(
    id: 'letter_object',
    number: 31,
    title: 'A is for Apple',
    instruction: 'Which picture starts with this letter?',
    section: GameSection.letters,
    cover: '🍎',
    theme: Themes.classroom,
    rule: MatchRule.initialLetter,
    layout: MatchLayout.prompt,
    minAge: 4,
    pairs: [
      for (final (l, emoji, word, lvl) in [
        ('A', '🍎', 'Apple', 1),
        ('B', '⚽', 'Ball', 1),
        ('C', '🐱', 'Cat', 1),
        ('D', '🐶', 'Dog', 1),
        ('E', '🥚', 'Egg', 1),
        ('F', '🐟', 'Fish', 1),
        ('G', '🐐', 'Goat', 2),
        ('H', '🎩', 'Hat', 2),
        ('I', '🍦', 'Ice cream', 2),
        ('J', '🧃', 'Juice', 2),
        ('K', '🪁', 'Kite', 2),
        ('L', '🍃', 'Leaf', 2),
        ('M', '🥭', 'Mango', 2),
        ('N', '🪺', 'Nest', 3),
        ('O', '🍊', 'Orange', 2),
        ('P', '🦜', 'Parrot', 2),
        ('Q', '👸', 'Queen', 3),
        ('R', '🐰', 'Rabbit', 2),
        ('S', '☀️', 'Sun', 1),
        ('T', '🐯', 'Tiger', 2),
        ('U', '☂️', 'Umbrella', 3),
        ('V', '🚐', 'Van', 3),
        ('W', '🍉', 'Watermelon', 3),
        ('X', '🎼', 'Xylophone', 3),
        ('Y', '🪀', 'Yo-yo', 3),
        ('Z', '🦓', 'Zebra', 3),
      ])
        _p(
          _card('L$l', 'Letter $l', LetterVisual(l), l, spoken: l),
          _emo('o_$word', emoji, word, l),
          lvl: lvl,
        ),
    ],
  ),

  // 32 -------------------------------------------------- initial sounds
  MatchGameDef(
    id: 'initial_sounds',
    number: 32,
    title: 'Sound Detective',
    instruction: 'Listen to the sound. Which picture starts with it?',
    section: GameSection.letters,
    cover: '👂',
    theme: Themes.classroom,
    rule: MatchRule.initialSound,
    layout: MatchLayout.prompt,
    minAge: 4,
    parentNote:
        'Cards show the letter and say its sound (not its name), e.g. "mmm" '
        'for M. Words were picked to avoid accent-dependent sounds.',
    pairs: [
      for (final (l, sound, emoji, word, lvl) in [
        ('m', 'mmm', '🐒', 'Monkey', 1),
        ('s', 'sss', '🧦', 'Sock', 1),
        ('b', 'buh', '🚌', 'Bus', 1),
        ('t', 'tuh', '⛺', 'Tent', 1),
        ('f', 'fff', '🦊', 'Fox', 2),
        ('p', 'puh', '🐷', 'Pig', 2),
        ('l', 'lll', '🦁', 'Lion', 2),
        ('d', 'duh', '🦆', 'Duck', 2),
        ('n', 'nnn', '👃', 'Nose', 3),
        ('r', 'rrr', '🌈', 'Rainbow', 3),
        ('h', 'huh', '🐴', 'Horse', 3),
        ('g', 'guh', '🎸', 'Guitar', 3),
      ])
        _p(
          _card('S$l', 'Sound $sound', LetterVisual(l), l, spoken: sound),
          _emo('o_$word', emoji, word, l),
          lvl: lvl,
        ),
    ],
  ),

  // 33 ------------------------------------------------- animal families
  MatchGameDef(
    id: 'animal_families',
    number: 33,
    title: 'Mummy and Baby',
    instruction: 'Help each baby find its grown-up!',
    section: GameSection.animals,
    cover: '🐥',
    theme: Themes.nature,
    rule: MatchRule.familyId,
    layout: MatchLayout.board,
    pairs: [
      for (final (adult, aName, baby, bName, lvl) in [
        ('🐔', 'Hen', '🐤', 'Chick', 1),
        ('🐕', 'Dog', '🐶', 'Puppy', 1),
        ('🐈', 'Cat', '🐱', 'Kitten', 1),
        ('🐄', 'Cow', '🐮', 'Calf', 2),
        ('🐑', 'Sheep', '🐑', 'Lamb', 2),
        ('🐎', 'Horse', '🐴', 'Foal', 3),
        ('🦆', 'Duck', '🐥', 'Duckling', 3),
      ])
        MatchPair(
          _emo('a_$aName', adult, aName, aName),
          _emo('b_$bName', baby, bName, aName, scale: 0.6, badge: '💗'),
          minLevel: lvl,
        ),
    ],
  ),

  // 34 --------------------------------------------------- animal homes
  MatchGameDef(
    id: 'animal_homes',
    number: 34,
    title: 'Animal Homes',
    instruction: 'Where does this animal live? Find its home!',
    section: GameSection.animals,
    cover: '🐝',
    theme: Themes.nature,
    rule: MatchRule.homeId,
    layout: MatchLayout.prompt,
    parentNote:
        'Homes shown are common examples - many animals live in more than one kind of place.',
    pairs: [
      for (final (emoji, name, scene, lvl) in [
        (
          '🐦',
          'Bird',
          const SceneVisual(
            'nest',
            ['🌳', '🥚', '🥚'],
            Color(0xFFBFE8A6),
            Color(0xFFF2FFE0),
          ),
          1,
        ),
        (
          '🐝',
          'Bee',
          const SceneVisual(
            'hive',
            ['🍯', '🌼', '🌸'],
            Color(0xFFFFE08A),
            Color(0xFFFFF7D6),
          ),
          1,
        ),
        (
          '🕷️',
          'Spider',
          const SceneVisual(
            'web',
            ['🕸️', '🍂'],
            Color(0xFFD8D0F0),
            Color(0xFFF6F2FF),
          ),
          2,
        ),
        (
          '🐶',
          'Dog',
          const SceneVisual(
            'kennel',
            ['🛖', '🦴'],
            Color(0xFFFFD2B0),
            Color(0xFFFFF4EA),
          ),
          1,
        ),
        (
          '🐰',
          'Rabbit',
          const SceneVisual(
            'burrow',
            ['🕳️', '🥕', '🌱'],
            Color(0xFFB4DF8F),
            Color(0xFFE9D3B0),
          ),
          2,
        ),
        (
          '🐠',
          'Fish',
          const SceneVisual(
            'water',
            ['🌊', '🪸', '🫧'],
            Color(0xFF6CC8F2),
            Color(0xFFBDEBFF),
          ),
          2,
        ),
        (
          '🦫',
          'Beaver',
          const SceneVisual(
            'lodge',
            ['🪵', '🪵', '🌊'],
            Color(0xFFA7D8F0),
            Color(0xFFD9B98F),
          ),
          3,
        ),
      ])
        _p(
          _emo('a_$name', emoji, name, scene.id),
          _card('h_${scene.id}', '${scene.id} home', scene, scene.id),
          lvl: lvl,
        ),
    ],
  ),

  // 35 ------------------------------------------------ animal habitats
  MatchGameDef(
    id: 'habitats',
    number: 35,
    title: 'Where Do I Live?',
    instruction: 'Take each animal to its home land!',
    section: GameSection.animals,
    cover: '🐫',
    theme: Themes.nature,
    rule: MatchRule.habitatId,
    layout: MatchLayout.prompt,
    pairs: [
      for (final (emoji, name, scene, lvl) in [
        (
          '🐫',
          'Camel',
          const SceneVisual(
            'desert',
            ['🏜️', '🌵', '☀️'],
            Color(0xFFFFD99A),
            Color(0xFFFFF0CC),
          ),
          1,
        ),
        (
          '🐬',
          'Dolphin',
          const SceneVisual(
            'ocean',
            ['🌊', '🐚', '🫧'],
            Color(0xFF5CC3F0),
            Color(0xFFB8ECFF),
          ),
          1,
        ),
        (
          '🐻‍❄️',
          'Polar bear',
          const SceneVisual(
            'arctic',
            ['🧊', '❄️', '🏔️'],
            Color(0xFFCFEFFF),
            Color(0xFFFFFFFF),
          ),
          1,
        ),
        (
          '🐒',
          'Monkey',
          const SceneVisual(
            'forest',
            ['🌴', '🌳', '🍌'],
            Color(0xFF7FCF7A),
            Color(0xFFD9F5C8),
          ),
          2,
        ),
        (
          '🦁',
          'Lion',
          const SceneVisual(
            'savanna',
            ['🌾', '🌳', '☀️'],
            Color(0xFFF7D774),
            Color(0xFFFFF2C4),
          ),
          2,
        ),
        (
          '🐸',
          'Frog',
          const SceneVisual(
            'pond',
            ['🪷', '💧', '🌿'],
            Color(0xFF8ED6B0),
            Color(0xFFCDF2FF),
          ),
          2,
        ),
        (
          '🦌',
          'Deer',
          const SceneVisual(
            'woodland',
            ['🌲', '🌲', '🍄'],
            Color(0xFF9BD48A),
            Color(0xFFE8F8D8),
          ),
          3,
        ),
        (
          '🐯',
          'Tiger',
          const SceneVisual(
            'jungle',
            ['🌿', '🌴', '🌳'],
            Color(0xFF5DBB63),
            Color(0xFFC8EFC0),
          ),
          3,
        ),
      ])
        _p(
          _emo('a_$name', emoji, name, scene.id),
          _card('h_${scene.id}', scene.id, scene, scene.id),
          lvl: lvl,
        ),
    ],
  ),

  // 36 --------------------------------------------------- animal sounds
  MatchGameDef(
    id: 'animal_sounds',
    number: 36,
    title: 'Who Says That?',
    instruction: 'What sound does this animal make?',
    section: GameSection.animals,
    cover: '🐮',
    theme: Themes.nature,
    rule: MatchRule.soundId,
    layout: MatchLayout.prompt,
    pairs: [
      for (final (emoji, name, sound, lvl) in [
        ('🐮', 'Cow', 'Moo', 1),
        ('🐶', 'Dog', 'Woof', 1),
        ('🐱', 'Cat', 'Meow', 1),
        ('🦆', 'Duck', 'Quack', 2),
        ('🦁', 'Lion', 'Roar', 2),
        ('🐑', 'Sheep', 'Baa', 2),
        ('🐷', 'Pig', 'Oink', 3),
        ('🐓', 'Rooster', 'Cock-a-doodle-doo', 3),
      ])
        _p(
          _emo('a_$name', emoji, name, name),
          _card(
            's_$name',
            sound,
            WordVisual(sound, emoji: '🔊'),
            name,
            spoken: sound,
          ),
          lvl: lvl,
        ),
    ],
  ),

  // 37 ------------------------------------------------ weather to clothes
  MatchGameDef(
    id: 'weather_clothes_match',
    number: 37,
    title: 'Dress for the Weather',
    instruction: 'Look at the weather. What should we wear?',
    section: GameSection.weather,
    cover: '🧥',
    theme: Themes.weather,
    rule: MatchRule.weatherId,
    layout: MatchLayout.prompt,
    pairs: [
      _p(
        _card('w_rain1', 'Rainy', _rainScene, 'rain'),
        _card(
          'raincoat',
          'Raincoat',
          const ClothingVisual(ClothingKind.raincoat, KidColors.yellow),
          'rain',
        ),
      ),
      _p(
        _card('w_rain2', 'Rainy', _rainScene, 'rain'),
        _emo('umbrella', '☂️', 'Umbrella', 'rain'),
      ),
      _p(
        _card('w_cold1', 'Cold', _coldScene, 'cold'),
        _card(
          'sweater',
          'Sweater',
          const ClothingVisual(ClothingKind.sweater, KidColors.red),
          'cold',
        ),
      ),
      _p(
        _card('w_cold2', 'Cold', _coldScene, 'cold'),
        _emo('gloves', '🧤', 'Gloves', 'cold'),
        lvl: 2,
      ),
      _p(
        _card('w_cold3', 'Snowy', _coldScene, 'cold'),
        _emo('scarf', '🧣', 'Scarf', 'cold'),
        lvl: 2,
      ),
      _p(
        _card('w_sun1', 'Sunny', _sunScene, 'sunny'),
        _emo('sunhat', '👒', 'Sun hat', 'sunny'),
      ),
      _p(
        _card('w_sun2', 'Sunny', _sunScene, 'sunny'),
        _emo('cap', '🧢', 'Cap', 'sunny'),
        lvl: 2,
      ),
      _p(
        _card('w_sun3', 'Sunny', _sunScene, 'sunny'),
        _card(
          'shorts',
          'Shorts',
          const ClothingVisual(ClothingKind.shorts, KidColors.orange),
          'sunny',
        ),
        lvl: 3,
      ),
    ],
  ),

  // 38 ------------------------------------------------ weather to objects
  MatchGameDef(
    id: 'weather_objects',
    number: 38,
    title: 'Weather Helpers',
    instruction: 'Which thing goes with this weather?',
    section: GameSection.weather,
    cover: '🌈',
    theme: Themes.weather,
    rule: MatchRule.weatherId,
    layout: MatchLayout.prompt,
    choiceCounts: const LevelValues(2, 3, 4),
    pairs: [
      _p(
        _card('w_rain', 'Rainy', _rainScene, 'rain'),
        _emo('umbrella', '☂️', 'Umbrella', 'rain'),
      ),
      _p(
        _card('w_sun', 'Sunny', _sunScene, 'sunny'),
        _emo('sunglasses', '🕶️', 'Sunglasses', 'sunny'),
      ),
      _p(
        _card('w_snow', 'Snowy', _coldScene, 'cold'),
        _emo('snowman', '⛄', 'Snowman', 'cold'),
      ),
      _p(
        _card('w_wind', 'Windy', _windScene, 'windy'),
        _emo('kite', '🪁', 'Flying kite', 'windy'),
        lvl: 2,
      ),
      _p(
        _card('w_sun2', 'Sunny', _sunScene, 'sunny'),
        _emo('icecream', '🍦', 'Ice cream', 'sunny'),
        lvl: 2,
      ),
      _p(
        _card('w_wind2', 'Windy', _windScene, 'windy'),
        _emo('pinwheel', '🎐', 'Wind chime', 'windy'),
        lvl: 3,
      ),
      _p(
        _card('w_rain2', 'Rainy', _rainScene, 'rain'),
        _emo('boots', '🥾', 'Boots', 'rain'),
        lvl: 3,
      ),
    ],
  ),

  // 39 ---------------------------------------------- tops & bottoms outfits
  MatchGameDef(
    id: 'outfits',
    number: 39,
    title: 'Dress-Up Outfits',
    instruction: 'Find the bottom that matches each top!',
    section: GameSection.clothes,
    cover: '👗',
    theme: Themes.wardrobe,
    rule: MatchRule.outfitId,
    layout: MatchLayout.board,
    parentNote:
        'Outfits are colour-coordinated sets. Any style can be worn by anyone.',
    pairs: [
      for (final (top, bottom, color, pattern, lvl) in [
        (
          ClothingKind.tshirt,
          ClothingKind.shorts,
          KidColors.red,
          SockPattern.dots,
          1,
        ),
        (
          ClothingKind.shirt,
          ClothingKind.trousers,
          KidColors.blue,
          SockPattern.plain,
          1,
        ),
        (
          ClothingKind.sweater,
          ClothingKind.jeans,
          KidColors.green,
          SockPattern.stripes,
          2,
        ),
        (
          ClothingKind.tshirt,
          ClothingKind.skirt,
          KidColors.purple,
          SockPattern.stars,
          2,
        ),
        (
          ClothingKind.jacket,
          ClothingKind.leggings,
          KidColors.orange,
          SockPattern.hearts,
          3,
        ),
      ])
        MatchPair(
          _card(
            't_${color.toARGB32()}',
            'Top',
            ClothingVisual(top, color, pattern: pattern),
            'outfit_${color.toARGB32()}',
          ),
          _card(
            'b_${color.toARGB32()}',
            'Bottom',
            ClothingVisual(bottom, color, pattern: pattern),
            'outfit_${color.toARGB32()}',
          ),
          minLevel: lvl,
        ),
    ],
  ),

  // 40 ------------------------------------------------------------ socks
  MatchGameDef(
    id: 'socks',
    number: 40,
    title: 'Sock Pairs',
    instruction: 'Oh no, the socks got mixed up! Find each pair.',
    section: GameSection.clothes,
    cover: '🧦',
    theme: Themes.laundry,
    rule: MatchRule.imageId,
    layout: MatchLayout.board,
    twoColumns: false,
    pairCounts: const LevelValues(2, 3, 5),
    pairs: [
      _twin(
        'red',
        const SockVisual(KidColors.red, SockPattern.plain),
        'Red socks',
      ),
      _twin(
        'bluestripe',
        const SockVisual(KidColors.blue, SockPattern.stripes),
        'Blue striped socks',
      ),
      _twin(
        'yellowstar',
        const SockVisual(KidColors.yellow, SockPattern.stars),
        'Yellow star socks',
      ),
      _twin(
        'greendots',
        const SockVisual(KidColors.green, SockPattern.dots),
        'Green spotty socks',
        lvl: 2,
      ),
      _twin(
        'pinkheart',
        const SockVisual(KidColors.pink, SockPattern.hearts),
        'Pink heart socks',
        lvl: 2,
      ),
      _twin(
        'purple',
        const SockVisual(KidColors.purple, SockPattern.plain),
        'Purple socks',
        lvl: 3,
      ),
      _twin(
        'orangestripe',
        const SockVisual(KidColors.orange, SockPattern.stripes),
        'Orange striped socks',
        lvl: 3,
      ),
    ],
  ),

  // 41 -------------------------------------------- numbers to quantities
  MatchGameDef(
    id: 'numbers',
    number: 41,
    title: 'Count and Match',
    instruction: 'How many? Find the group with this many!',
    section: GameSection.patterns,
    cover: '🔢',
    theme: Themes.numbers,
    rule: MatchRule.quantity,
    layout: MatchLayout.prompt,
    minAge: 4,
    pairs: [
      for (final (n, emoji) in [
        (1, '🍎'),
        (2, '⚽'),
        (3, '🌸'),
        (4, '⭐'),
        (5, '🐟'),
        (6, '🍓'),
        (7, '🎈'),
        (8, '🐞'),
        (9, '🍪'),
        (10, '🫐'),
      ])
        _p(
          _card('n$n', 'Number $n', LetterVisual('$n'), '$n', spoken: '$n'),
          _card('q$n', '$n', QuantityVisual(emoji, n), '$n'),
          lvl: n <= 3 ? 1 : (n <= 5 ? 2 : 3),
        ),
    ],
  ),

  // 42 ----------------------------------------------------- object uses
  MatchGameDef(
    id: 'object_uses',
    number: 42,
    title: 'What Is It For?',
    instruction: 'What do we use this for?',
    section: GameSection.puzzles,
    cover: '🔑',
    theme: Themes.home,
    rule: MatchRule.useId,
    layout: MatchLayout.prompt,
    pairs: [
      for (final (emoji, name, useEmoji, useName, lvl) in [
        ('🪥', 'Toothbrush', '🦷', 'Teeth', 1),
        ('🔑', 'Key', '🔒', 'Lock', 1),
        ('🥄', 'Spoon', '🍲', 'Eating', 1),
        ('✏️', 'Pencil', '📝', 'Writing', 2),
        ('☂️', 'Umbrella', '🌧️', 'Rain', 2),
        ('🧽', 'Sponge', '🍽️', 'Washing dishes', 3),
        ('🧹', 'Broom', '🍂', 'Sweeping', 3),
      ])
        _p(
          _emo('o_$name', emoji, name, name),
          _emo('u_$name', useEmoji, useName, name),
          lvl: lvl,
        ),
    ],
  ),

  // 43 ----------------------------------------------------- object rooms
  MatchGameDef(
    id: 'object_rooms',
    number: 43,
    title: 'Which Room?',
    instruction: 'Which room does this belong in?',
    section: GameSection.clothes,
    cover: '🛋️',
    theme: Themes.home,
    rule: MatchRule.roomId,
    layout: MatchLayout.prompt,
    pairs: [
      for (final (emoji, name, scene, lvl) in [
        (
          '🛏️',
          'Bed',
          const SceneVisual(
            'Bedroom',
            ['🌙', '🧸', '🪟'],
            Color(0xFFD6C8FF),
            Color(0xFFF4EEFF),
          ),
          1,
        ),
        (
          '🫖',
          'Kettle',
          const SceneVisual(
            'Kitchen',
            ['🍳', '🧂', '🥖'],
            Color(0xFFFFE08A),
            Color(0xFFFFF8E0),
          ),
          1,
        ),
        (
          '🛁',
          'Bathtub',
          const SceneVisual(
            'Bathroom',
            ['🚿', '🧴', '🫧'],
            Color(0xFFA9DCFF),
            Color(0xFFE9F7FF),
          ),
          1,
        ),
        (
          '🛋️',
          'Sofa',
          const SceneVisual(
            'Living room',
            ['📺', '🪴', '🖼️'],
            Color(0xFFFFC4A8),
            Color(0xFFFFF0E6),
          ),
          2,
        ),
        (
          '📚',
          'Books',
          const SceneVisual(
            'Study',
            ['🪑', '📐', '💡'],
            Color(0xFFB8EBC8),
            Color(0xFFEFFFF3),
          ),
          3,
        ),
      ])
        _p(
          _emo('o_$name', emoji, name, scene.id),
          _card('r_${scene.id}', scene.id, scene, scene.id),
          lvl: lvl,
        ),
    ],
  ),

  // 44 --------------------------------------------------- picture halves
  MatchGameDef(
    id: 'halves',
    number: 44,
    title: 'Picture Halves',
    instruction: 'Put the two halves back together!',
    section: GameSection.puzzles,
    cover: '🦋',
    theme: Themes.garden,
    rule: MatchRule.halfId,
    layout: MatchLayout.board,
    pairs: [
      for (final (emoji, name, lvl) in [
        ('🦋', 'Butterfly', 1),
        ('❤️', 'Heart', 1),
        ('🍎', 'Apple', 1),
        ('❄️', 'Snowflake', 2),
        ('🍓', 'Strawberry', 2),
        ('🌸', 'Flower', 3),
        ('🐞', 'Ladybug', 3),
      ])
        MatchPair(
          _emo(
            'l_$name',
            emoji,
            'Left half of $name',
            name,
            fx: EmojiEffect.leftHalf,
          ),
          _emo(
            'r_$name',
            emoji,
            'Right half of $name',
            name,
            fx: EmojiEffect.rightHalf,
          ),
          minLevel: lvl,
        ),
    ],
  ),

  // 45 --------------------------------------------------------- patterns
  MatchGameDef(
    id: 'patterns',
    number: 45,
    title: 'What Comes Next?',
    instruction: 'Look at the pattern. What comes next?',
    section: GameSection.patterns,
    cover: '🔁',
    theme: Themes.numbers,
    rule: MatchRule.patternNext,
    layout: MatchLayout.prompt,
    minAge: 5,
    generator: generatePatterns,
  ),

  // 46 ----------------------------------------------------- colour words
  MatchGameDef(
    id: 'color_words',
    number: 46,
    title: 'Colour Words',
    instruction: 'Read the word. Tap its colour!',
    section: GameSection.letters,
    cover: '📖',
    theme: Themes.classroom,
    rule: MatchRule.colorWord,
    layout: MatchLayout.prompt,
    minAge: 5,
    parentNote: 'Optional reading game - not needed for any other game.',
    pairs: [
      for (final (word, color, lvl) in [
        ('RED', KidColors.red, 1),
        ('BLUE', KidColors.blue, 1),
        ('YELLOW', KidColors.yellow, 1),
        ('GREEN', KidColors.green, 1),
        ('ORANGE', KidColors.orange, 2),
        ('PINK', KidColors.pink, 2),
        ('PURPLE', KidColors.purple, 3),
        ('BROWN', KidColors.brown, 3),
      ])
        _p(
          _card(
            'w_$word',
            word,
            WordVisual(word),
            word,
            spoken: word.toLowerCase(),
          ),
          _card('s_$word', word, SwatchVisual(color), word),
          lvl: lvl,
        ),
    ],
  ),

  // 47 --------------------------------------------------- day/night scenes
  MatchGameDef(
    id: 'day_night_match',
    number: 47,
    title: 'Day or Night?',
    instruction: 'Does this happen in the day or at night?',
    section: GameSection.weather,
    cover: '🌗',
    theme: Themes.night,
    rule: MatchRule.timeOfDay,
    layout: MatchLayout.prompt,
    choiceCounts: const LevelValues(2, 2, 2),
    pairs: [
      for (final (emoji, name, isDay, lvl) in [
        ('🏖️', 'Sunny beach', true, 2),
        ('😴', 'Sleeping child', false, 1),
        ('⭐', 'Stars', false, 1),
        ('🌞', 'Bright sun', true, 1),
        ('🌈', 'Rainbow', true, 1),
        ('🦉', 'Owl awake', false, 2),
        ('🏫', 'School time', true, 3),
        ('🌕', 'Full moon', false, 3),
      ])
        _p(
          _emo('o_$name', emoji, name, isDay ? 'day' : 'night'),
          isDay
              ? _card('day', 'Day', _dayScene, 'day')
              : _card('night', 'Night', _nightScene, 'night'),
          lvl: lvl,
        ),
    ],
  ),

  // 48 ------------------------------------------------ animals by look
  MatchGameDef(
    id: 'appearance',
    number: 48,
    title: 'Spot the Same Animal',
    instruction: 'Find two animals with the same look!',
    section: GameSection.puzzles,
    cover: '🦓',
    theme: Themes.nature,
    rule: MatchRule.appearanceId,
    layout: MatchLayout.board,
    twoColumns: false,
    pairCounts: const LevelValues(2, 3, 5),
    pairs: [
      _twin('zebra', const EmojiVisual('🦓'), 'Zebra'),
      _twin('ladybug', const EmojiVisual('🐞'), 'Ladybug'),
      _twin('butterfly', const EmojiVisual('🦋'), 'Butterfly'),
      _twin('fish', const EmojiVisual('🐠'), 'Fish', lvl: 2),
      _twin('leopard', const EmojiVisual('🐆'), 'Leopard', lvl: 2),
      _twin('tiger', const EmojiVisual('🐅'), 'Tiger', lvl: 3),
      _twin('giraffe', const EmojiVisual('🦒'), 'Giraffe', lvl: 3),
      // Subtle on purpose: these look alike, so only on Explorer.
      _twin('blowfish', const EmojiVisual('🐡'), 'Pufferfish', lvl: 3),
      _twin('tropical', const EmojiVisual('🐟'), 'Blue fish', lvl: 3),
    ],
  ),
];

/// Builds pattern-completion rounds. AB patterns for Very Easy, AAB/ABB on
/// Easy and ABC on Explorer. Each round uses one rule (colour, shape or
/// picture), never a combination.
List<MatchPair> generatePatterns(int seed, Level level) {
  final rnd = Random(seed);
  final domains = <List<(String, Visual)>>[
    [
      for (final (n, c) in [
        ('red', KidColors.red),
        ('blue', KidColors.blue),
        ('yellow', KidColors.yellow),
        ('green', KidColors.green),
      ])
        (n, ShapeVisual(ShapeKind.circle, c)),
    ],
    [
      for (final s in [
        ShapeKind.circle,
        ShapeKind.square,
        ShapeKind.triangle,
        ShapeKind.star,
      ])
        (s.name, ShapeVisual(s, KidColors.blue)),
    ],
    [
      for (final (n, e) in [
        ('apple', '🍎'),
        ('banana', '🍌'),
        ('grapes', '🍇'),
        ('pear', '🍐'),
      ])
        (n, EmojiVisual(e)),
    ],
  ];
  final templates = switch (level) {
    Level.veryEasy => [
      [0, 1, 0, 1, 0],
    ],
    Level.easy => [
      [0, 1, 0, 1, 0],
      [0, 0, 1, 0, 0],
      [0, 1, 1, 0, 1],
    ],
    Level.explorer => [
      [0, 1, 1, 0, 1],
      [0, 0, 1, 0, 0],
      [0, 1, 2, 0, 1],
    ],
  };
  final answerIndex = <String, int>{
    '0,1,0,1,0': 1,
    '0,0,1,0,0': 1,
    '0,1,1,0,1': 1,
    '0,1,2,0,1': 2,
  };

  final pairs = <MatchPair>[];
  for (var i = 0; i < 8; i++) {
    final domain = [...domains[rnd.nextInt(domains.length)]]..shuffle(rnd);
    final t = templates[rnd.nextInt(templates.length)];
    final ans = answerIndex[t.join(',')]!;
    final seq = SequenceVisual([for (final k in t) domain[k].$2]);
    final answer = domain[ans];
    MatchCard toCard((String, Visual) e, String idPrefix) =>
        _card('$idPrefix${e.$1}', e.$1, e.$2, e.$1);
    // Distractors: the other elements of the pattern first, then the rest.
    final others = domain.where((e) => e.$1 != answer.$1).toList();
    final used = t.toSet();
    others.sort((a, b) {
      final ai = used.contains(domain.indexOf(a)) ? 0 : 1;
      final bi = used.contains(domain.indexOf(b)) ? 0 : 1;
      return ai.compareTo(bi);
    });
    pairs.add(
      MatchPair(
        _card('seq$i', 'Pattern', seq, answer.$1),
        toCard(answer, 'ans${i}_'),
        distractors: [for (final o in others) toCard(o, 'd${i}_')],
      ),
    );
  }
  return pairs;
}
