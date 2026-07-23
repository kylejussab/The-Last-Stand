extends Node
var timing: String = "onPlay"
const DIRECT_DAMAGE: int = 2
const BACKFIRE_CHANCE: float = 0.25

func apply_on_play_perk(thisCharacterCard, thisSupportCard, otherCharacterCard, _otherSupportCard, _thisHand, forceNoBackfire: bool = false) -> Dictionary:
	var didBackfire = false if forceNoBackfire else randf() < BACKFIRE_CHANCE
	var value = thisSupportCard.value
	
	if didBackfire:
		var animationPlayer = thisSupportCard.get_node("AnimationPlayer")
		animationPlayer.play("backfire")
		await thisSupportCard.get_tree().create_timer(0.35).timeout
		AudioManager.play_card_hover()
		await thisSupportCard.get_tree().create_timer(0.3).timeout
		AudioManager.play_card_hover()
		await animationPlayer.animation_finished
		
		thisSupportCard.modify_value(-value)
		await thisCharacterCard.modify_value(-value)
		return {
			"handled": true,
			"log": [[-value, "self"]],
			"directDamageSelf": true,
			"directDamageAmount": DIRECT_DAMAGE,
			"backfired": true
		}
	else:
		thisSupportCard.modify_value(-value)
		await otherCharacterCard.modify_value(-value)
		return {
			"handled": true,
			"log": [[-value, "opponent"]],
			"directDamageSelf": false,
			"directDamageAmount": DIRECT_DAMAGE,
			"backfired": false
		}
