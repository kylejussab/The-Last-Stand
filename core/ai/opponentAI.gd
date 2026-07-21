extends Node
class_name OpponentAI

var playstyleName: String = "Base"
var isFlipScriptActive: bool = false

func play_character_card(_opponentHand, _playerHand, _playerPlayedCard = null):
	# Override in subclass
	return null

func choose_support_card(_opponent_hand, _opponent_character, _player_character, _opponent_health = 99, _player_health = 99):
	# Override in subclass
	return null

# Scripts needed for Flip the Script perk
func set_flip_script_active(active: bool) -> void:
	isFlipScriptActive = active

# Inverts "which side is ahead" — used anywhere currentDiff gates support decisions
func _effective_diff(rawDiff: int) -> int:
	return -rawDiff if isFlipScriptActive else rawDiff

# Replaces raw "score > best" comparisons so maximize becomes minimize under Flip
func _is_better_score(a: float, b: float) -> bool:
	return (a < b) if isFlipScriptActive else (a > b)

# The correct "worst possible" sentinel to seed a running best-score search
func _worst_score() -> float:
	return INF if isFlipScriptActive else -1.0
