# Characters Database changed for python simulation
CHARACTERS = {
    "Yara": [4, "Seraphite", "Stealthy", [("hand_bonus", "Lev", 2, None)]],
    "Lev": [3, "Seraphite", "Stealthy/Survivor", [("tie_bonus", None, 5, None)]],
    "TheProphet": [6, "Seraphite", "Defensive/Stealthy", [("vs_type", "Aggressive", 2, None), ("vs_type", "Stealthy", 2, None)]],
    "Emily": [4, "Seraphite", "Survivor", [("scaling", "Seraphite", 1, "hand")]],
    "Ezra": [3, "Seraphite", "Crafty/Defensive", []],
    "Lyra": [2, "Seraphite", "Survivor", []],
    "SeraphiteBrute": [5, "Seraphite", "Aggressive", []],
    "Abby": [6, "WLF", "Aggressive", [("vs_type", "Aggressive", 2, None), ("vs_faction", "Infected", 1, None)]],
    "Manny": [4, "WLF", "Defensive", [("equalize", "Aggressive", 2, None), ("equalize", "Defensive", 2, None)]],
    "Nora": [4, "WLF", "Stealthy", [("vs_type", "Crafty", 1, None)]],
    "Li": [3, "WLF", "Survivor", []],
    "WLFSoldier": [3, "WLF", "Survivor", [("debuff_vs_type", "Survivor", -3, None)]],
    "Isaac": [6, "WLF", "Aggressive/Defensive", [("vs_faction", "Seraphite", 2, None)]],
    "Alice": [2, "WLF", "Stealthy/Survivor", [("vs_faction", "Infected", 2, None)]],
    "Marlene": [5, "Firefly", "Crafty", [("vs_type", "Survivor", 1, None), ("vs_type", "Stealthy", 1, None)]],
    "FireflySoldier": [2, "Firefly", "Defensive", [("hand_bonus", "Marlene", 6, None)]],
    "TommyFirefly": [4, "Firefly", "Survivor", [("solo_bonus", "Firefly", 3, None)]],
    "Eugene": [3, "Firefly", "Crafty/Survivor", []],
    "Riley": [3, "Firefly", "Stealthy", [("hand_bonus", "Ellie", 3, None)]],
    "Runner": [2, "Infected", "Aggressive", [("scaling", "Runner", 2, "hand_name")]],
    "Stalker": [3, "Infected", "Stealthy", [("scaling", "Infected", 2, "hand")]],
    "Clicker": [5, "Infected", "Aggressive", [("on_win", None, 2, "health_dmg")]],
    "Bloater": [4, "Infected", "Defensive", [("on_heavy_loss", None, 4, "health_dmg")]],
    "RatKing": [8, "Infected", "Aggressive", [("on_win", None, 4, "health_dmg")]],
    "Malik": [3, "Infected", "Survivor", [("scaling", "Infected", 1, "hand"), ("vs_faction", "Infected", 2, None)]],
    "Joel": [6, "Jackson", "Crafty/Defensive", [("hand_bonus", "Ellie", 4, None)]],
    "Ellie": [5, "Jackson", "Crafty/Stealthy", [("debuff_vs_type", "Stealthy", -1, None)]],
    "Dina": [3, "Jackson", "Stealthy", [("vs_type", "Defensive", 2, None)]],
    "Tommy": [5, "Jackson", "Aggressive", []],
    "Bill": [4, "Jackson", "Crafty", [("support_bonus", "TrapMine", 4, None)]],
    "Jessie": [5, "Jackson", "Defensive", [("debuff_vs_type", "Aggressive", -1, None)]],
}

SUPPORTS = {
	"Molotov": [5, "Support", "Aggressive", "Negative", "MOLOTOV"],
	"ReinforcedMelee": [2, "Support", "Aggressive/Survivor", "Positive", "REINFORCED MELEE"],
	"Rage": [6, "Support", "Aggressive", "Positive", "RAGE"],
	"Silencer": [4, "Support", "Defensive/Stealthy", "Positive", "SILENCER"],
	"SmokeBomb": [4, "Support", "Crafty/Stealthy", "Negative", "SMOKE BOMB"],
	"TrapMine": [5, "Support", "Crafty", "Negative", "TRAP MINE"],
	"ScavengedParts": [2, "Support", "Survivor", "Positive", "SCAVENGED PARTS"],
	"MedKit": [2, "Support", "Crafty/Defensive", "Positive", "MEDKIT"],
	"Resilience": [5, "Support", "Survivor", "Positive", "RESILIENCE"],
	"Retreat": [4, "Support", "Defensive", "Positive", "RETREAT"],
	"Bottle": [2, "Support", "Stealthy", "Negative", "BOTTLE"],
	"Brick": [2, "Support", "Stealthy", "Negative", "BRICK"],
	"TrainingManual": [2, "Support", "Crafty", "Positive", "TRAINING MANUAL"],
	"ShotgunShells": [3, "Support", "Survivor", "Positive", "SHOTGUN SHELLS"],
	"Supplements": [2, "Support", "Aggressive/Crafty/Defensive/Stealthy/Survivor", "Positive", "SUPPLEMENTS"],
	"SupplyCache": [0, "Support", "Aggressive/Crafty/Defensive/Stealthy/Survivor", "Positive", "SUPPLY CACHE", "+2 to random card in hand"],
}

standardCharacterDeck = [
    "Runner", "Runner", "Runner", "Runner",
    "Stalker", "Stalker", "Stalker",
    "FireflySoldier", "FireflySoldier", "FireflySoldier",
    "WLFSoldier", "WLFSoldier",
    "SeraphiteBrute", "SeraphiteBrute",
    "Clicker", "Clicker", "Bloater",
    "Emily", "Ezra", "Lev", "Yara", "Lyra",
    "Nora", "Manny", "Alice", "Li",
    "Bill", "Dina", "Jessie", "Tommy", "TommyFirefly",
    "Riley", "Eugene", "Malik",
    "Joel", "Ellie", "Abby", "Isaac", "TheProphet", "Marlene", "RatKing"
]

standardSupportDeck = [
    "Brick", "Brick", "Bottle", "Bottle",
    "ScavengedParts", "ScavengedParts", "ScavengedParts",
    "Supplements", "Supplements", "SupplyCache", "SupplyCache",
    "MedKit", "MedKit", "SmokeBomb", "SmokeBomb",
    "Silencer", "Silencer", "ReinforcedMelee", "ReinforcedMelee",
    "TrainingManual", "Retreat", "Resilience", "ShotgunShells",
    "Molotov", "Rage", "TrapMine"
]

CHARACTERSTWO = {
    # Seraphite
    "Yara": [4, "Seraphite", "Stealthy", [("vs_value_min", 8, 3, None)]],
    "Lev": [3, "Seraphite", "Stealthy/Survivor", [("hand_bonus", "Yara", 5, None), ("hand_bonus", "Abby", 5, None), ("solo_bonus", "Seraphite", 3, None)]],
    "TheProphet": [6, "Seraphite", "Defensive/Stealthy", [("vs_type", "Aggressive", 2, None), ("vs_type", "Stealthy", 2, None), ("scaling", "Stealthy", 1, "hand")]],
    "Emily": [4, "Seraphite", "Survivor", [("scaling", "Seraphite", 1, "hand")]],
    "Ezra": [3, "Seraphite", "Crafty/Defensive", [("no_type_in_hand", "Aggressive", 2, None)]],
    "Lyra": [2, "Seraphite", "Survivor", [("no_enemy_support", None, 2, None)]],
    "SeraphiteBrute": [5, "Seraphite", "Aggressive", [("vs_value_max", 3, 2, None)]],
    
    # WLF
    "Abby": [6, "WLF", "Aggressive", [("vs_type", "Aggressive", 2, None), ("vs_faction", "Infected", 1, None)]],
    "Manny": [4, "WLF", "Defensive", [("equalize", "Aggressive", 2, None), ("equalize", "Defensive", 2, None)]],
    "Nora": [4, "WLF", "Stealthy", [("vs_type", "Crafty", 1, None)]],
    "Li": [3, "WLF", "Survivor", [("on_loss_buff_hand", "random", 1, None)]],
    "WLFSoldier": [3, "WLF", "Survivor", [("debuff_vs_type", "Survivor", -3, None)]],
    "Isaac": [6, "WLF", "Aggressive/Defensive", [("vs_faction", "Seraphite", 2, None)]],
    "Alice": [2, "WLF", "Stealthy/Survivor", [("vs_faction", "Infected", 3, None), ("scaling", "WLF", 1, "hand")]],
    
    # Firefly
    "Marlene": [5, "Firefly", "Crafty", [("vs_type", "Survivor", 1, None), ("vs_type", "Stealthy", 1, None)]],
    "FireflySoldier": [2, "Firefly", "Defensive", [("hand_bonus", "Marlene", 6, None)]],
    "TommyFirefly": [4, "Firefly", "Survivor", [("solo_bonus", "Firefly", 3, None)]],
    "Eugene": [3, "Firefly", "Crafty/Survivor", [("scaling", "Crafty", 1, "hand"), ("support_class_bonus", "Survivor", 3, None)]],
    "Riley": [3, "Firefly", "Stealthy", [("hand_bonus", "Ellie", 3, None), ("solo_bonus", "Stealthy", 2, None)]],
    
    # Infected
    "Runner": [2, "Infected", "Aggressive", [("scaling", "Runner", 2, "hand_name")]],
    "Stalker": [3, "Infected", "Stealthy", [("scaling", "Infected", 2, "hand")]],
    "Clicker": [5, "Infected", "Aggressive", [("on_win", None, 2, "health_dmg")]],
    "Shambler": [4, "Infected", "Defensive", [("on_heavy_loss", None, 4, "health_dmg")]],
    "RatKing": [8, "Infected", "Aggressive", [("on_win", None, 4, "health_dmg")]],
    "Malik": [3, "Infected", "Survivor", [("scaling", "Infected", 1, "hand"), ("vs_faction", "Infected", 2, None)]],
    
    # Jackson
    "Joel": [6, "Jackson", "Crafty/Defensive", [("hand_bonus", "Ellie", 4, None), ("hand_bonus", "Tommy", 4, None), ("vs_multi_type", None, 2, None)]],
    "Ellie": [5, "Jackson", "Crafty/Stealthy", [("debuff_vs_type", "Stealthy", -2, None), ("scaling", "non_matching", 1, "hand")]],
    "Dina": [3, "Jackson", "Stealthy", [("vs_type", "Defensive", 4, None), ("hand_bonus", "Jessie", 2, None), ("hand_bonus", "Ellie", 2, None)]],
    "Tommy": [5, "Jackson", "Aggressive", [("scaling", "Jackson", 1, "hand")]],
    "Bill": [4, "Jackson", "Crafty", [("support_bonus", "TrapMine", 4, None)]],
    "Jessie": [5, "Jackson", "Defensive", [("debuff_vs_type", "Aggressive", -1, None)]]
}