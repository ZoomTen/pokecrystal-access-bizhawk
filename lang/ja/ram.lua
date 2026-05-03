RAM_wBattleMode = 0xd22d
RAM_wMenuHeader = 0xcf75
RAM_wMapGroup = 0xdc7b
RAM_wMapNumber = 0xdc7c
RAM_wYCoord = 0xdc7d
RAM_wXCoord = 0xdc7e
RAM_wMapAttributes = 0xd1ce
RAM_wMapScriptsBank = RAM_wMapAttributes+6
RAM_wMapEventsPointer = RAM_wMapAttributes+9
RAM_wMapConnections = RAM_wMapAttributes+11
RAM_wNorthMapConnection = RAM_wMapConnections+1
RAM_wSouthMapConnection = RAM_wMapConnections+1+(1*12)
RAM_wWestMapConnection = RAM_wMapConnections+1+(2*12)
RAM_wEastMapConnection = RAM_wMapConnections+1+(3*12)
RAM_wMapObjects = 0xd711
RAM_wObjectMasks = RAM_wMapObjects+0x100
RAM_wMapHeight = RAM_wMapAttributes + 1
RAM_wMapWidth = RAM_wMapAttributes + 2
RAM_TILE_DOWN = 0xc2fa
RAM_TILE_UP = RAM_TILE_DOWN+1
RAM_TILE_LEFT = RAM_TILE_UP+1
RAM_TILE_RIGHT = RAM_TILE_LEFT+1
RAM_wPlayerTileCollision = 0xd4d7
RAM_wTilesetCollisionBank = 0xd210
RAM_wTilesetCollisionAddress = 0xd211
RAM_wObject1Struct = 0xd4c9
RAM_wSpriteAnim2Var1 = 0xc330
RAM_wSpriteAnim2Var2 = 0xc331
RAM_FarCall_hl = 0x2d35
KEYBOARD_STRING = "ていせい  けってい"
KEYBOARD_UPPER_STRING = "カナ"
KEYBOARD_UPPER = {
{"ア", "イ", "ウ", "エ", "ォ", "ナ", "ニ", "ヌ", "ネ", "ノ", "ヤ", "ユ", "ヨ"},
{"カ", "キ", "ク", "ケ", "コ", "ハ", "ヒ", "フ", "へ", "ホ", "ワ", "ヲ", "ン"},
{"サ", "シ", "ス", "セ", "ソ", "マ", "ミ", "ム", "メ", "モ", "ャ", "ュ", "ョ", "ッ", "ー"},
{"タ", "チ", "ツ", "テ", "ト", "ラ", "り", "ル", "レ", "ロ", "ァ", "ィ", "é", "→", ","},
{"かな", "", "", "", "", "ていせい", "", "", "", "", "けってい", "", "", "", "けってい"}
}
KEYBOARD_LOWER = {
{"あ", "い", "う", "え", "お", "な", "に", "ぬ", "ね", "の", "や", "ゆ", "よ"},
{"か", "き", "く", "け", "こ", "は", "ひ", "ふ", "へ", "ほ", "わ", "を", "ん"},
{"さ", "し", "す", "せ", "そ", "ま", "み", "む", "め", "も", "ゃ", "ゅ", "ょ", "っ", "ー"},
{"た", "ち", "つ", "て", "と", "ら", "り", "る", "れ", "ろ", "?", "!"},
{"カナ", "", "", "", "", "ていせい", "", "", "", "", "けってい", "", "", "", "けってい"}
}
MSG_HOW_MANY = "いくつ おかいあげになりますか"
