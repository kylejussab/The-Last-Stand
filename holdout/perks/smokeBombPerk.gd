extends Node
var timing: String = "onPlay"
const BACKFIRE_CHANCE: float = 0.33

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
		
		return {"handled": true, "log": [[-value, "self"]], "backfired": true}
	
	thisSupportCard.modify_value(-value)
	await otherCharacterCard.modify_value(-value)
	otherCharacterCard.isNullified = true
	
	var revertedAmount = 0
	if otherCharacterCard.perkValueAppliedMidRound != 0:
		revertedAmount = otherCharacterCard.perkValueAppliedMidRound
		otherCharacterCard.modify_value(-revertedAmount)
		otherCharacterCard.perkValueAppliedMidRound = 0
	
	return {
		"handled": true,
		"log": [[-value, "opponent"], [-revertedAmount, "opponent"]] if revertedAmount != 0 else [[-value, "opponent"]],
		"backfired": false
	}
