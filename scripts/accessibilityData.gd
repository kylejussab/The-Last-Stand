extends Node

enum CardStyle { DEFAULT, NO_ARTWORK, MINIMAL }

enum CardUISize { SMALL, MEDIUM, LARGE }

var currentCardStyle: CardStyle = CardStyle.DEFAULT
var currentCardUISize: CardUISize = CardUISize.MEDIUM
var animationsDisabled: bool = false
