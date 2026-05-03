RAM_vTiles1 = 0x8800
RAM_wBattleMode = 0xd22d
RAM_wTilemap = 0xc4a0
RAM_wMenuHeader = 0xcf81
RAM_wMapGroup = 0xdcb5
RAM_wMapNumber = 0xdcb6
RAM_wYCoord = 0xdcb7
RAM_wXCoord = 0xdcb8
RAM_wMapAttributes = 0xd19d
RAM_wMapScriptsBank = RAM_wMapAttributes+6
RAM_wMapEventsPointer = RAM_wMapAttributes+9
RAM_wMapConnections = RAM_wMapAttributes+11
RAM_wNorthMapConnection = RAM_wMapConnections+1
RAM_wSouthMapConnection = RAM_wMapConnections+1+(1*12)
RAM_wWestMapConnection = RAM_wMapConnections+1+(2*12)
RAM_wEastMapConnection = RAM_wMapConnections+1+(3*12)
RAM_wMapObjects = 0xd71e
RAM_wObjectMasks = RAM_wMapObjects+0x100
RAM_wMapAttributes = 0xd19d
RAM_wMapHeight = RAM_wMapAttributes + 1
RAM_wMapWidth = RAM_wMapAttributes + 2
RAM_wPlayerTileCollision = 0xd4e4
RAM_wTilesetCollisionBank = 0xd1df
RAM_wTilesetCollisionAddress = 0xd1e0
RAM_wObject1Struct = 0xd4fe
RAM_wSpriteAnim2Var1 = 0xc330 -- keyboard X
RAM_wSpriteAnim2Var2 = 0xc331 -- keyboard Y
RAM_FOOTSTEP_FUNCTION = 0x2914 + 0x18 -- GetMovementPermissions after setting wPlayerTileCollision
RAM_FarCall_hl = 0x2d63
KEYBOARD_STRING = "DEL   END"
KEYBOARD_UPPER = {
{"a", "b", "c", "d", "e", "f", "g", "h", "i"},
{"j", "k", "l", "m", "n", "o", "p", "q", "r"},
{"s", "t", "u", "v", "w", "x", "y", "z"},
{"-", "?", "!", "/", ".", ","},
{"lower", "", "", "del", "", "", "end", "", "end"}
}

KEYBOARD_LOWER = {
{"a", "b", "c", "d", "e", "f", "g", "h", "i"},
{"j", "k", "l", "m", "n", "o", "p", "q", "r"},
{"s", "t", "u", "v", "w", "x", "y", "z", "space"},
{"�", "(", ")", ":", ";", "[", "]", "pk", "mn"},
{"upper", "", "", "del", "", "", "end", "", "end"}
}
KEYBOARD_UPPER_STRING = "UPPER"
MSG_HOW_MANY = "How many?"
