extends Node2D

const CHARACTERS = { # Value, Type, Faction, Class
	"Yara": [4, "Character", "Seraphite", "Stealthy"],
	"Lev": [3, "Character", "Seraphite", "Stealthy/Survivor"],
	"TheProphet": [6, "Character", "Seraphite", "Stealthy/Defensive"],
	"Emily": [4, "Character", "Seraphite", "Survivor"],
	"Ezra": [3, "Character", "Seraphite", "Crafty/Defensive"],
	"Lyra": [2, "Character", "Seraphite", "Survivor"],
	"SeraphiteBrute": [5, "Character", "Seraphite", "Aggressive"],
	
	"Abby": [6, "Character", "WLF", "Aggressive"],
	"Manny": [4, "Character", "WLF", "Defensive"],
	"Nora": [4, "Character", "WLF", "Stealthy"],
	"Li": [3, "Character", "WLF", "Survivor"],
	"WLFSoldier": [3, "Character", "WLF", "Survivor"],
	"Isaac": [6, "Character", "WLF", "Aggressive/Defensive"],
	"Alice": [2, "Character", "WLF", "Survivor/Stealthy"],
	
	"Marlene": [5, "Character", "Firefly", "Crafty"],
	"FireflySoldier": [2, "Character", "Firefly", "Defensive"],
	"TommyFirefly": [4, "Character", "Firefly", "Survivor"],
	"Eugene": [3, "Character", "Firefly", "Crafty/Survivor"],
	"Riley": [3, "Character", "Firefly", "Stealthy"],
	
	"Runner": [2, "Character", "Infected", "Aggressive"],
	"Stalker": [3, "Character", "Infected", "Stealthy"],
	"Clicker": [5, "Character", "Infected", "Aggressive"],
	"Bloater": [4, "Character", "Infected", "Defensive"],
	"RatKing": [8, "Character", "Infected", "Aggressive"],
	"Malik": [3, "Character", "Infected", "Survivor"],
	
	"Joel": [6, "Character", "Jackson", "Crafty/Defensive"],
	"Ellie": [5, "Character", "Jackson", "Stealthy/Crafty"],
	"Dina": [3, "Character", "Jackson", "Stealthy"],
	"Tommy": [5, "Character", "Jackson", "Aggressive"],
	"Bill": [4, "Character", "Jackson", "Crafty"],
	"Jessie": [5, "Character", "Jackson", "Defensive"],
}

const SUPPORTS = { # Value, Type, Class, Positive/Negative
	"Molotov": [5, "Support", "Aggressive", "Negative"],
	"ReinforcedMelee": [2, "Support", "Aggressive/Survivor", "Positive"],
	"Rage": [6, "Support", "Aggressive", "Positive"],
	"Silencer": [4, "Support", "Stealthy/Defensive", "Positive"],
	"SmokeBomb": [4, "Support", "Crafty/Stealthy", "Negative"],
	"TrapMine": [5, "Support", "Crafty", "Negative"],
	"ScavengedParts": [2, "Support", "Survivor", "Positive"],
	"MedKit": [2, "Support", "Crafty/Defensive", "Positive"],
	"Resilience": [5, "Support", "Survivor", "Positive"],
	"Retreat": [4, "Support", "Defensive", "Positive"],
	"Bottle": [2, "Support", "Stealthy", "Negative"],
	"Brick": [2, "Support", "Stealthy", "Negative"],
	"TrainingManual": [2, "Support", "Crafty", "Positive"],
	"ShotgunShells": [3, "Support", "Survivor", "Positive"],
	"Supplements": [2, "Support", "Aggressive/Crafty/Defensive/Stealthy/Survivor", "Positive"],
	"SupplyCache": [0, "Support", "Aggressive/Crafty/Defensive/Stealthy/Survivor", "Positive"],
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

enum Modifier { REDUCED_HAND, VOLATILE_HAND, SLOW_BLEED, NO_DEFENSE, INFECTED_DECK, ALWAYS_FIRST, LONE_WOLF, SUPPLY_LINE, CARD_ROT }

const MODIFIERS = {
	Modifier.REDUCED_HAND: {
		"id": Modifier.REDUCED_HAND,
		"name": "Reduced Hand",
		"description": "Maximum hand size reduced to 6.",
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
		"description": "Defensive cards have 0 value. Their perks still activate.",
		"icon": "res://assets/modifiers/No Defense.png",
		"tier": 2,
		"multiplier": 1.5,
		"duration": 2,
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
	Modifier.ALWAYS_FIRST: {
		"id": Modifier.ALWAYS_FIRST,
		"name": "Always First",
		"description": "You must play first every round.",
		"icon": "res://assets/modifiers/Always First.png",
		"tier": 2,
		"multiplier": 2.25,
		"duration": 2,
	},
	Modifier.LONE_WOLF: {
		"id": Modifier.LONE_WOLF,
		"name": "Lone Wolf",
		"description": "Support cards are disabled. Character values increased by +50%",
		"icon": "res://assets/modifiers/Lone Wolf.png",
		"tier": 3,
		"multiplier": 2.75,
		"duration": 1,
	},
	Modifier.SUPPLY_LINE: {
		"id": Modifier.SUPPLY_LINE,
		"name": "Supply Line",
		"description": "Hand contains only support cards. Your character is auto played from the deck.",
		"icon": "res://assets/modifiers/Supply Line.png",
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
} 

var standardCharacterDeck = [
	"Runner", "Runner", "Runner", "Runner",
	"Stalker", "Stalker", "Stalker",
	"FireflySoldier", "FireflySoldier", "FireflySoldier",
	"WLFSoldier", "WLFSoldier",
	"SeraphiteBrute", "SeraphiteBrute",
	
	"Clicker", "Clicker",
	"Bloater",
	"Emily", "Ezra", "Lev", "Yara",
	"Nora", "Manny", "Alice",
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

var standardSupportDeck = [
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

var infectedHeavyCharacterDeck = [
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
	"Nora", "Manny", "Alice",
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

var infectedHeavySupportDeck = [
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
