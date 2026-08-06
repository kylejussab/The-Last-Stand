extends AllegianceHandler

func prevents_backfire(characterCard: Node2D) -> bool:
	return is_instance_valid(characterCard) and characterCard.faction == "Jackson"
