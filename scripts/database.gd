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

const SUPPORTS = { # Value, Type, Class
	"Molotov": [5, "Support", "Aggressive"],
	"ReinforcedMelee": [2, "Support", "Aggressive/Survivor"],
	"Rage": [6, "Support", "Aggressive"],
	"Silencer": [4, "Support", "Stealthy/Defensive"],
	"SmokeBomb": [4, "Support", "Crafty/Stealthy"],
	"TrapMine": [5, "Support", "Crafty"],
	"ScavengedParts": [2, "Support", "Survivor"],
	"MedKit": [2, "Support", "Crafty/Defensive"],
	"Resilience": [5, "Support", "Survivor"],
	"Retreat": [4, "Support", "Defensive"],
	"Bottle": [2, "Support", "Stealthy"],
	"Brick": [2, "Support", "Stealthy"],
	"TrainingManual": [2, "Support", "Crafty"],
	"ShotgunShells": [3, "Support", "Survivor"],
	"Supplements": [2, "Support", "Aggressive/Crafty/Defensive/Stealthy/Survivor"],
	"SupplyCache": [0, "Support", "Aggressive/Crafty/Defensive/Stealthy/Survivor"],
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
	"Alice": "res://scripts/perks/alicePerk.gd",
	"SupplyCache": "res://scripts/perks/supplyCachePerk.gd",
}

var AVATARS = {
	Actor.Avatar.JUNE: {
		"name": "June Ravel",
		"description": "Former Firefly",
		"health": 35,
		"headPath": "res://assets/arenaHeads/"
	},
	Actor.Avatar.ETHAN: {
		"name": "Ethan Hark",
		"description": "Patrol Leader",
		"health": 1,
		"headPath": "res://assets/arenaHeads/",
		"arenaPath": "res://assets/arenas/"
	},
	Actor.Avatar.UCKMANN: {
		"name": "Dr Uckmann",
		"description": "Dog Director",
		"health": 1,
		"headPath": "res://assets/arenaHeads/",
		"arenaPath": "res://assets/arenas/"
	},
	Actor.Avatar.ALLEY: {
		"name": "Alley Ross",
		"description": "Scriptweaver",
		"health": 1,
		"headPath": "res://assets/arenaHeads/",
		"arenaPath": "res://assets/arenas/"
	},
	Actor.Avatar.SILAS: {
		"name": "Silas Vane",
		"description": "Scavenger King",
		"health": 1,
		"headPath": "res://assets/arenaHeads/",
		"arenaPath": "res://assets/arenas/"
	},
	Actor.Avatar.MIRA: {
		"name": "Mira Thorne",
		"description": "Ex-Medic",
		"health": 1, 
		"headPath": "res://assets/arenaHeads/",
		"arenaPath": "res://assets/arenas/"
	},
	Actor.Avatar.KAEL: {
		"name": "Kaelen Voss",
		"description": "Shield Brother",
		"health": 1,
		"headPath": "res://assets/arenaHeads/",
		"arenaPath": "res://assets/arenas/"
	}
}
