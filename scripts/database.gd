extends Node2D

const CHARACTERS = { # Value, Type, Faction, Class, Card Name Text, Perk Text
	# Seraphite
	"Yara": [4, "Character", "Seraphite", "Stealthy", "YARA", "+3 if opposing card value is 8 or higher"],
	"Lev": [3, "Character", "Seraphite", "Stealthy/Survivor", "LEV", "+5 if Yara or Abby in hand and +3 if no Seraphite in hand"],
	"TheProphet": [6, "Character", "Seraphite", "Defensive/Stealthy", "THE PROPHET", "+2 if opposing card is Aggressive or Stealthy and +1 for each Stealthy in hand"],
	"Emily": [4, "Character", "Seraphite", "Survivor", "EMILY", "+1 for each Seraphite in hand"],
	"Ezra": [3, "Character", "Seraphite", "Crafty/Defensive", "EZRA", "+2 if your hand contains no Aggressive cards"],
	"Lyra": [2, "Character", "Seraphite", "Survivor", "LYRA", "+2 if opponent plays no support card"],
	"SeraphiteBrute": [5, "Character", "Seraphite", "Aggressive", "SERAPHITE BRUTE", "+2 if opposing card's value is 3 or less"],
	
	# WLF
	"Abby": [6, "Character", "WLF", "Aggressive", "ABBY", "+2 if opposing card is Aggressive and +1 if opposing card is Infected"],
	"Manny": [4, "Character", "WLF", "Defensive", "MANNY", "equal value and +2 if opposing card is Aggressive or Defensive"],
	"Nora": [4, "Character", "WLF", "Stealthy", "NORA", "+1 if opposing card is Crafty"],
	"Li": [3, "Character", "WLF", "Survivor", "LI", "On round loss: +1 to random character in hand"],
	"WLFSoldier": [3, "Character", "WLF", "Survivor", "WLF SOLDIER", "-3 to opponent, if opposing card is Survivor"],
	"Isaac": [6, "Character", "WLF", "Aggressive/Defensive", "ISAAC", "+2 if opposing card is Seraphite"],
	"Alice": [2, "Character", "WLF", "Stealthy/Survivor", "ALICE", "+3 if opposing card is Infected and +1 for each WLF in hand"],
	
	# Firefly
	"Marlene": [5, "Character", "Firefly", "Crafty", "MARLENE", "+1 if opposing card is Survivor or Stealthy"],
	"FireflySoldier": [2, "Character", "Firefly", "Defensive", "FIREFLY SOLDIER", "+6 if Marlene in hand"],
	"TommyFirefly": [4, "Character", "Firefly", "Survivor", "TOMMY", "+3 if no Firefly in hand"],
	"Eugene": [3, "Character", "Firefly", "Crafty/Survivor", "EUGENE", "On round end: +1 for each Crafty in hand and +3 if support card is Survivor"],
	"Riley": [3, "Character", "Firefly", "Stealthy", "RILEY", "+3 if Ellie in hand and +2 if no Stealthy in hand"],
	
	# Infected
	"Runner": [2, "Character", "Infected", "Aggressive", "RUNNER", "Gain the value of all runners in hand, and discard them"],
	"Stalker": [3, "Character", "Infected", "Stealthy", "STALKER", "+2 for each Infected in hand"],
	"Clicker": [5, "Character", "Infected", "Aggressive", "CLICKER", "On round win: -2 to opponent health"],
	"Bloater": [4, "Character", "Infected", "Defensive", "BLOATER", "On round loss of 2 or more: -4 to opponent health"],
	"RatKing": [8, "Character", "Infected", "Aggressive", "RAT KING", "On round win: -4 to opponent health"],
	"Malik": [3, "Character", "Infected", "Survivor", "MALIK", "+1 for each Infected in hand and +2 if opposing card is Infected"],
	
	# Jackson
	"Joel": [6, "Character", "Jackson", "Crafty/Defensive", "JOEL", "+4 if Ellie or Tommy in hand and +2 if opposing card is multi-type"],
	"Ellie": [5, "Character", "Jackson", "Crafty/Stealthy", "ELLIE", "-2 if opposing card is Stealthy and +1 for each non-matching type in hand"],
	"Dina": [3, "Character", "Jackson", "Stealthy", "DINA", "+4 if opposing card is Defensive and +2 if Jessie or Ellie in hand"],
	"Tommy": [5, "Character", "Jackson", "Aggressive", "TOMMY", "+1 for each Jackson in hand"],
	"Bill": [4, "Character", "Jackson", "Crafty", "BILL", "+4 if played support card is Trap Mine"],
	"Jessie": [5, "Character", "Jackson", "Defensive", "JESSIE", "-1 to opponent, if opposing card is Aggressive"],
	
	# New / altered cards based on humanity restored modifier
	"JoelSmuggler": [6, "Character", "Smuggler", "Aggressive", "JOEL", "+2 if opposing card is Aggressive or Defensive or Survivor"],
	"BillSmuggler": [4, "Character", "Smuggler", "Crafty", "BILL", "+4 if played support card is Trap Mine"],
	"LiSmuggler": [3, "Character", "Smuggler", "Survivor", "LI", "+2 if opposing card is Survivor"],
	"Tess": [5, "Character", "Smuggler", "Crafty/Survivor", "TESS", "+4 if Joel in hand, and Joel gains +2"],
	"Hunter": [3, "Character", "Smuggler", "Aggressive/Survivor", "HUNTER", "+3 if no other Smuggler in hand"],
	
	"Owen": [4, "Character", "WLF", "Stealthy", "OWEN", "On round loss: Take 0 health damage"],
	"Mel": [3, "Character", "WLF", "Survivor", "MEL", "On round win: +2 to random character card in hand"],
	"Maria": [4, "Character", "Firefly", "Defensive", "MARIA", "+2 if Tommy in hand"],
	"Jerry": [2, "Character", "Firefly", "Defensive", "JERRY", "On round loss: +2 to all Firefly in hand"],
	"AbbyFirefly": [4, "Character", "Firefly", "Survivor", "ABBY", "+1 if opposing card is exactly 4"],
	
	"AliceHumanity": [2, "Character", "WLF", "Stealthy/Survivor", "ALICE", "+3 if opposing card is Stealthy and +1 for each WLF in hand"],
	"FireflySoldierHumanity": [2, "Character", "Firefly", "Defensive", "FIREFLY SOLDIER", "+3 if at least one Firefly in hand"],
	"WLFSoldierHumanity": [3, "Character", "WLF", "Survivor", "WLF SOLDIER", "-2 to opponent, if opposing card is Firefly or Seraphite"],
	"IsaacHumanity": [6, "Character", "WLF", "Aggressive/Defensive", "ISAAC", "+2 if opposing card is Firefly"],
	"TommyFireflyHumanity": [4, "Character", "Firefly", "Survivor", "TOMMY", "+1 for each Firefly in hand"],
	"RileyHumanity": [3, "Character", "Firefly", "Stealthy", "RILEY", "+4 if played support card is Bottle or Brick"],
}

const SUPPORTS = { # Value, Type, Class, Positive/Negative, Card Name Text, Perk Text
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

const PERKS = {
	"Joel": "res://scripts/perks/joelPerk.gd",
	"Marlene": "res://scripts/perks/marlenePerk.gd",
	"Manny": "res://scripts/perks/mannyPerk.gd",
	"Jessie": "res://scripts/perks/jessiePerk.gd",
	"Runner": "res://scripts/perks/runnerPerk.gd",
	"Stalker": "res://scripts/perks/stalkerPerk.gd",
	"Abby": "res://scripts/perks/abbyPerk.gd",
	"Isaac": "res://scripts/perks/isaacPerk.gd",
	"WLFSoldier": "res://scripts/perks/wlfSoldierPerk.gd",
	"Ellie": "res://scripts/perks/elliePerk.gd",
	"FireflySoldier": "res://scripts/perks/fireflySoldierPerk.gd",
	"Nora": "res://scripts/perks/noraPerk.gd",
	"Malik": "res://scripts/perks/malikPerk.gd",
	"Dina": "res://scripts/perks/dinaPerk.gd",
	"Bill": "res://scripts/perks/billPerk.gd",
	"Yara": "res://scripts/perks/yaraPerk.gd",
	"Clicker": "res://scripts/perks/clickerPerk.gd",
	"Lev": "res://scripts/perks/levPerk.gd",
	"Bloater": "res://scripts/perks/bloaterPerk.gd",
	"RatKing": "res://scripts/perks/ratKingPerk.gd",
	"TheProphet": "res://scripts/perks/theProphetPerk.gd",
	"Emily": "res://scripts/perks/emilyPerk.gd",
	"TommyFirefly": "res://scripts/perks/tommyFireflyPerk.gd",
	"Alice": "res://scripts/perks/alicePerk.gd",
	"SupplyCache": "res://scripts/perks/supplyCachePerk.gd",
	"Riley": "res://scripts/perks/rileyPerk.gd",
	"Eugene": "res://scripts/perks/eugenePerk.gd",
	"Tommy": "res://scripts/perks/tommyPerk.gd",
	"Ezra": "res://scripts/perks/ezraPerk.gd",
	"Lyra": "res://scripts/perks/lyraPerk.gd",
	"Li": "res://scripts/perks/liPerk.gd",
	"SeraphiteBrute": "res://scripts/perks/seraphiteBrutePerk.gd",
	
	"JoelSmuggler": "res://scripts/perks/joelSmugglerPerk.gd",
	"BillSmuggler": "res://scripts/perks/billPerk.gd",
	"Tess": "res://scripts/perks/tessPerk.gd",
	"Hunter": "res://scripts/perks/hunterPerk.gd",
	"Mel": "res://scripts/perks/melPerk.gd",
	"Maria": "res://scripts/perks/mariaPerk.gd",
	"LiSmuggler": "res://scripts/perks/liSmugglerPerk.gd",
	"Jerry": "res://scripts/perks/jerryPerk.gd",
	"AliceHumanity": "res://scripts/perks/aliceHumanityPerk.gd",
	"FireflySoldierHumanity": "res://scripts/perks/fireflySoldierHumanityPerk.gd",
	"WLFSoldierHumanity": "res://scripts/perks/wlfSoldierHumanityPerk.gd",
	"IsaacHumanity": "res://scripts/perks/isaacHumanityPerk.gd",
	"Owen": "res://scripts/perks/owenPerk.gd",
	"RileyHumanity": "res://scripts/perks/rileyHumanityPerk.gd",
	"TommyFireflyHumanity": "res://scripts/perks/tommyFireflyHumanityPerk.gd",
	"AbbyFirefly": "res://scripts/perks/abbyFireflyPerk.gd",
}

var AVATARS = {
	Actor.Avatar.JUNE: {
		"name": "June Ravel",
		"description": "Former Firefly",
		"health": "%02d" % 35,
		"headPath": "res://assets/arenaHeads/"
	},
	Actor.Avatar.ETHAN: {
		"name": "Ethan Hark",
		"description": "Patrol Leader",
		"health": "%02d" % 20,
		"headPath": "res://assets/arenaHeads/",
		"arenaPath": "res://assets/arenas/"
	},
	Actor.Avatar.RHEA: {
		"name": "Rhea",
		"description": "Matriarch",
		"health": "%02d" % 20,
		"headPath": "res://assets/arenaHeads/",
		"arenaPath": "res://assets/arenas/"
	},
	Actor.Avatar.UCKMANN: {
		"name": "Dr Uckmann",
		"description": "Dog Director",
		"health": "%02d" % 20,
		"headPath": "res://assets/arenaHeads/",
		"arenaPath": "res://assets/arenas/"
	},
	Actor.Avatar.ALLEY: {
		"name": "Alley Ross",
		"description": "Scriptweaver",
		"health": "%02d" % 20,
		"headPath": "res://assets/arenaHeads/",
		"arenaPath": "res://assets/arenas/"
	},
	Actor.Avatar.SILAS: {
		"name": "Silas Vane",
		"description": "Scavenger King",
		"health": "%02d" % 20,
		"headPath": "res://assets/arenaHeads/",
		"arenaPath": "res://assets/arenas/"
	},
	Actor.Avatar.MIRA: {
		"name": "Mira Thorne",
		"description": "Ex-Medic",
		"health": "%02d" % 20, 
		"headPath": "res://assets/arenaHeads/",
		"arenaPath": "res://assets/arenas/"
	},
	Actor.Avatar.KAEL: {
		"name": "Kaelen Voss",
		"description": "Shield Brother",
		"health": "%02d" % 20,
		"headPath": "res://assets/arenaHeads/",
		"arenaPath": "res://assets/arenas/"
	}
}

const JUNE_OPPONENTS = [Actor.Avatar.ETHAN, Actor.Avatar.UCKMANN, Actor.Avatar.ALLEY, Actor.Avatar.MIRA, Actor.Avatar.RHEA]

enum Modifier { REDUCED_HAND, VOLATILE_HAND, CALCULATED_RISK, DEEP_WOUNDS, HEAVY_HITTER, GUERRILLA_TACTICS, SLOW_BLEED, NO_DEFENSE, LOUD_NOISE, OVER_EXERTION, INFECTED_DECK, HUMANITY_RESTORED, ALWAYS_FIRST, FORSAKEN_HONOR, STACKED_ODDS, LONE_WOLF, SUPPLY_LINE, DESPERATE_MEASURES, CARD_ROT, FRIENDLY_FIRE }

const MODIFIERS = {
	Modifier.REDUCED_HAND: {
		"id": Modifier.REDUCED_HAND,
		"name": "Reduced Hand",
		"description": "Your maximum hand size is reduced to 6.",
		"icon": "res://assets/modifiers/Reduced Hand.png",
		"tier": 1,
		"multiplier": 0.5,
		"duration": 3,
	},
	Modifier.VOLATILE_HAND: {
		"id": Modifier.VOLATILE_HAND,
		"name": "Volatile Hand",
		"description": "Every 2 rounds, your entire hand is discarded and redrawn.",
		"icon": "res://assets/modifiers/Volatile Hand.png",
		"tier": 1,
		"multiplier": 0.75,
		"duration": 3,
	},
	Modifier.CALCULATED_RISK: {
		"id": Modifier.CALCULATED_RISK,
		"name": "Calculated Risk",
		"description": "Winning a round by a margin of exactly 1 deals +3 damage to the opponent's health.",
		"icon": "res://assets/modifiers/Calculated Risk.png",
		"tier": 1,
		"multiplier": 0.75,
		"duration": 4,
	},
	Modifier.DEEP_WOUNDS: {
		"id": Modifier.DEEP_WOUNDS,
		"name": "Deep Wounds",
		"description": "Take +2 damage if you lose a round by 5 or more.",
		"icon": "res://assets/modifiers/Deep Wounds.png",
		"tier": 1,
		"multiplier": 1.0,
		"duration": 3,
	},
	Modifier.HEAVY_HITTER: {
		"id": Modifier.HEAVY_HITTER,
		"name": "Heavy Hitter",
		"description": "Take +1 damage if you play a character with a base value of 5 or more.",
		"icon": "res://assets/modifiers/Heavy Hitter.png",
		"tier": 1,
		"multiplier": 1.0,
		"duration": 3,
	},
	Modifier.GUERRILLA_TACTICS: {
		"id": Modifier.GUERRILLA_TACTICS,
		"name": "Guerrilla Tactics",
		"description": "Consecutive character cards cannot be the same faction or type.",
		"icon": "res://assets/modifiers/Guerrilla Tactics.png",
		"tier": 1,
		"multiplier": 1.0,
		"duration": 3,
	},
	Modifier.SLOW_BLEED: {
		"id": Modifier.SLOW_BLEED,
		"name": "Slow Bleed",
		"description": "Take 1 damage at the end of every other round.",
		"icon": "res://assets/modifiers/Slow Bleed.png",
		"tier": 1,
		"multiplier": 1.25,
		"duration": 4,
		"amount": 1,
	},
	Modifier.NO_DEFENSE: {
		"id": Modifier.NO_DEFENSE,
		"name": "No Defense",
		"description": "Your defensive character cards have 0 value. Their perks still activate.",
		"icon": "res://assets/modifiers/No Defense.png",
		"tier": 2,
		"multiplier": 1.5,
		"duration": 2,
	},
	Modifier.LOUD_NOISE: {
		"id": Modifier.LOUD_NOISE,
		"name": "Loud Noise",
		"description": "All your stealth cards become aggressive. All your aggressive cards lose -1 value.",
		"icon": "res://assets/modifiers/Loud Noise.png",
		"tier": 2,
		"multiplier": 1.75,
		"duration": 2,
	},
	Modifier.OVER_EXERTION: {
		"id": Modifier.OVER_EXERTION,
		"name": "Over-Exertion",
		"description": "Deal +2 damage if your final value is 10 or higher, but take +1 damage.",
		"icon": "res://assets/modifiers/Over Exertion.png",
		"tier": 2,
		"multiplier": 2.0,
		"duration": 3,
	},
	Modifier.INFECTED_DECK: {
		"id": Modifier.INFECTED_DECK,
		"name": "Infected Deck",
		"description": "Your deck contains significantly more infected cards.",
		"icon": "res://assets/modifiers/Infected Deck.png",
		"tier": 2,
		"multiplier": 2.0,
		"duration": 2,
	},
	Modifier.HUMANITY_RESTORED: {
		"id": Modifier.HUMANITY_RESTORED,
		"name": "Humanity Restored",
		"description": "Your deck reflects an alternate world where the cure was found.",
		"icon": "res://assets/modifiers/Humanity Restored.png",
		"tier": 2,
		"multiplier": 2.0,
		"duration": 2,
	},
	Modifier.ALWAYS_FIRST: {
		"id": Modifier.ALWAYS_FIRST,
		"name": "Always First",
		"description": "You must play first every round.",
		"icon": "res://assets/modifiers/Always First.png",
		"tier": 2,
		"multiplier": 2.25,
		"duration": 2,
	},
	Modifier.FORSAKEN_HONOR: {
		"id": Modifier.FORSAKEN_HONOR,
		"name": "Forsaken Honor",
		"description": "Lose 20 health. Your card’s faction and type are hidden from the opponent.",
		"icon": "res://assets/modifiers/Forsaken Honor.png",
		"tier": 3,
		"multiplier": 1.5,
		"duration": 2,
		"healthCost": 20,
	},
	Modifier.STACKED_ODDS: {
		"id": Modifier.STACKED_ODDS,
		"name": "Stacked Odds",
		"description": "The opponent gains +1 to their card value at the end of every round.",
		"icon": "res://assets/modifiers/Stacked Odds.png",
		"tier": 3,
		"multiplier": 2.0,
		"duration": 2,
	},
	Modifier.LONE_WOLF: {
		"id": Modifier.LONE_WOLF,
		"name": "Lone Wolf",
		"description": "Your support cards are disabled. Character values increased by +50%",
		"icon": "res://assets/modifiers/Lone Wolf.png",
		"tier": 3,
		"multiplier": 2.75,
		"duration": 1,
	},
	Modifier.SUPPLY_LINE: {
		"id": Modifier.SUPPLY_LINE,
		"name": "Supply Line",
		"description": "Your hand contains only support cards. Your character is auto played from the deck.",
		"icon": "res://assets/modifiers/Supply Line.png",
		"tier": 3,
		"multiplier": 3.0,
		"duration": 1,
	},
	Modifier.DESPERATE_MEASURES: {
		"id": Modifier.DESPERATE_MEASURES,
		"name": "Desperate Measures",
		"description": "Support cards ignore type requirements, but take +3 damage if it’s a mismatch.",
		"icon": "res://assets/modifiers/Desperate Measures.png",
		"tier": 3,
		"multiplier": 3.0,
		"duration": 1,
	},
	Modifier.CARD_ROT: {
		"id": Modifier.CARD_ROT,
		"name": "Card Rot",
		"description": "Every 3 rounds, all cards in your hand lose -1 value.",
		"icon": "res://assets/modifiers/Card Rot.png",
		"tier": 3,
		"multiplier": 3.5,
		"duration": 1,
	},
	Modifier.FRIENDLY_FIRE: {
		"id": Modifier.FRIENDLY_FIRE,
		"name": "Friendly Fire",
		"description": "Your card's value is halved if your faction matches the opponent’s.",
		"icon": "res://assets/modifiers/Friendly Fire.png",
		"tier": 3,
		"multiplier": 3.5,
		"duration": 1,
	},
} 

const standardCharacterDeck = [
	"Runner", "Runner", "Runner", "Runner",
	"Stalker", "Stalker", "Stalker",
	"FireflySoldier", "FireflySoldier", "FireflySoldier",
	"WLFSoldier", "WLFSoldier",
	"SeraphiteBrute", "SeraphiteBrute",
	
	"Clicker", "Clicker",
	"Bloater",
	"Emily", "Ezra", "Lev", "Yara",
	"Nora", "Manny", "Alice", "Li",
	"Bill", "Dina", "Jessie", "Tommy", "TommyFirefly",
	"Riley", "Eugene", "Malik",
	
	"Joel",
	"Ellie",
	"Abby",
	"Isaac",
	"TheProphet",
	"Marlene",
	"RatKing",
]

const standardSupportDeck = [
	"Brick", "Brick",
	"Bottle", "Bottle",
	"ScavengedParts", "ScavengedParts", "ScavengedParts",
	"Supplements", "Supplements",
	"SupplyCache", "SupplyCache",
	
	"MedKit", "MedKit",
	"SmokeBomb", "SmokeBomb",
	"Silencer", "Silencer",
	"ReinforcedMelee", "ReinforcedMelee",
	"TrainingManual",
	"Retreat",
	"Resilience",
	"ShotgunShells",
	
	"Molotov",
	"Rage",
	"TrapMine",
]

const infectedHeavyCharacterDeck = [
	"Runner", "Runner", "Runner", "Runner", "Runner", "Runner",
	"Stalker", "Stalker", "Stalker", "Stalker", "Stalker",
	"Clicker", "Clicker", "Clicker",
	"Bloater", "Bloater",
	"Malik", "Malik",
	
	"Runner", "Runner", "Runner", "Runner",
	"Stalker", "Stalker", "Stalker",
	"FireflySoldier",
	"WLFSoldier",
	"SeraphiteBrute",
	
	"Clicker", "Clicker",
	"Bloater",
	"Emily", "Ezra", "Lev", "Yara",
	"Nora", "Manny", "Alice", "Li",
	"Bill", "Dina", "Jessie", "Tommy", "TommyFirefly",
	"Riley", "Eugene", "Malik",
	
	"Joel",
	"Ellie",
	"Abby",
	"Isaac",
	"TheProphet",
	"Marlene",
	"RatKing",
]

const infectedHeavySupportDeck = [
	"Brick", "Brick", "Brick", 
	"Bottle", "Bottle", "Bottle",
	
	"Supplements", "Supplements", "Supplements",
	"SupplyCache", "SupplyCache", "SupplyCache",
	
	"Molotov", "Molotov", 
	"Rage", "Rage", "Rage",
	"ReinforcedMelee", "ReinforcedMelee", "ReinforcedMelee",
	
	"ScavengedParts", "ScavengedParts",
	"Resilience",
	"ShotgunShells",
	
	"MedKit", "MedKit",
	"SmokeBomb", "SmokeBomb",
	"Silencer", 
	"TrapMine",
]

const humanityRestoredCharacterDeck = [
	"FireflySoldierHumanity", "FireflySoldierHumanity", "FireflySoldierHumanity", "FireflySoldierHumanity",
	"Marlene", "Jerry", "AbbyFirefly", 
	"Maria", "TommyFireflyHumanity", 
	"RileyHumanity", "Eugene", 
	
	"WLFSoldierHumanity", "WLFSoldierHumanity", "WLFSoldierHumanity", "WLFSoldierHumanity",
	"IsaacHumanity", "Owen", "Mel", 
	"Manny", "Nora", "AliceHumanity",
	
	"SeraphiteBrute", "SeraphiteBrute", "SeraphiteBrute",
	"TheProphet", "Emily", "Ezra", "Lev", "Yara", "Lyra",
	
	"JoelSmuggler", "Tess", 
	"BillSmuggler", 
	"LiSmuggler", 
	"Hunter", "Hunter"
]
