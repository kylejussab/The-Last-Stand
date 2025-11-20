const CHARACTERS = { # Value, Type, Faction, Class
	"Yara": [3, "Character", "Seraphite", "Stealthy"],
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
	
	"Runner": [1, "Character", "Infected", "Aggressive"],
	"Stalker": [2, "Character", "Infected", "Stealthy"],
	"Clicker": [5, "Character", "Infected", "Aggressive"],
	"Bloater": [3, "Character", "Infected", "Defensive"],
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
	"SmokeBomb": [2, "Support", "Crafty"],
	"SmokeBombRare": [2, "Support", "Stealthy/Crafty"],

	"Rage": [2, "Support", "Aggressive"],
	"RageRare": [3, "Support", "Aggressive"],

	"TrapMine": [2, "Support", "Crafty/Defensive"],
	"Silencer": [2, "Support", "Stealthy"],

	"Resilience": [1, "Support", "Survivor"],
	"ResilienceRare": [3, "Support", "Survivor"],

	"AdrenalineRare": [3, "Support", "Aggressive/Survivor"],

	"ShotgunShells": [3, "Support", "Aggressive"],

	"PoisonDart": [1, "Support", "Stealthy"],
	"Cloak": [2, "Support", "Stealthy"],
	"CloakRare": [2, "Support", "Stealthy"],

	"ScavengedParts": [1, "Support", "Survivor"],
	"ScavengedPartsRare": [1, "Support", "Survivor/Defensive"],

	"Barricade": [3, "Support", "Stealthy/Defensive"],

	"MedKit": [3, "Support", "Crafty"],
	"MedKitRare": [3, "Support", "Crafty/Defensive"],

	"Armor": [2, "Support", "Defensive"],

	"Molotov": [3, "Support", "Aggressive"],
	"MolotovRare": [3, "Support", "Aggressive"],

	"SupplyCacheRare": [0, "Support", "Crafty/Defensive"],

	"Shield": [1, "Support", "Defensive"],
	"Fortify": [2, "Support", "Defensive"]
}

const PERKS = {
	"Joel": "res://scripts/perks/joelPerk.gd",
	"Marlene": "res://scripts/perks/marlenePerk.gd",
	"Manny": "res://scripts/perks/mannyPerk.gd",
	"Jessie": "res://scripts/perks/jessiePerk.gd",
	"Runner": "res://scripts/perks/runnerPerk.gd",
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
}
