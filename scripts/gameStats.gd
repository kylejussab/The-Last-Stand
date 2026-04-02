extends Node

enum Mode { SPLASH_SCREEN, MAIN_MENU, MODIFIER_SELECTION, CARD_DRAW, JUNE_RAVEL, HOLDOUT, HOLDOUT_ROUND_COMPLETED }

var invitationAccepted: bool = false
var gameMode: Mode = Mode.MAIN_MENU

var totalInGameTimePlayed: float = 0.0

var rations: int = 0
