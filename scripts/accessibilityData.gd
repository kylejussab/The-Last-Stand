extends Node

enum CardStyle { DEFAULT, MINIMAL, NO_ARTWORK }

enum CardUISize { SMALL, MEDIUM, LARGE }

var currentCardStyle: CardStyle = CardStyle.DEFAULT
var currentCardUISize: CardUISize = CardUISize.SMALL
var animationsEnabled: bool = true
