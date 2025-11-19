const CHARACTERS = { # Value, Type, Faction, Class
	"JoelRare": [6, "Character", "Jackson", "Crafty/Defensive"],
	"Joel": [5, "Character", "Jackson", "Defensive"],
	"EllieRare": [5, "Character", "Jackson", "Stealthy/Crafty"],
	"TommyRare": [4, "Character", "Jackson", "Survivor/Aggressive"],
	"Tommy": [5, "Character", "Jackson", "Survivor"],
	"Dina": [3, "Character", "Jackson", "Stealthy"],
	"Bill": [4, "Character", "Jackson", "Crafty"],
	
	"Marlene": [5, "Character", "Firefly", "Crafty"],
	"FireflySoldier": [2, "Character", "Firefly", "Defensive"],
	"Nora": [4, "Character", "Firefly", "Stealthy"],
	"Tess": [6, "Character", "Firefly", "Aggressive"],
	
	"Manny": [4, "Character", "WLF", "Defensive"],
	"Abby": [6, "Character", "WLF", "Aggressive"],
	"WLFSoldier": [3, "Character", "WLF", "Survivor"],
	"Li": [3, "Character", "WLF", "Survivor"],
	
	"Runner": [1, "Character", "Infected", "Aggressive"],
	"Stalker": [2, "Character", "Infected", "Stealthy"],
	"Clicker": [5, "Character", "Infected", "Aggressive"],
	"Bloater": [3, "Character", "Infected", "Defensive"],
	"RatKingRare": [8, "Character", "Infected", "Aggressive"],
	"Malik": [3, "Character", "Infected", "Survivor"],
	
	"LevRare": [3, "Character", "Seraphites", "Stealthy/Survivor"],
	"Yara": [3, "Character", "Seraphites", "Stealthy"],
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
	"JoelRare": "res://scripts/perks/joelRarePerk.gd",
	"Marlene": "res://scripts/perks/marlenePerk.gd",
	"TommyRare": "res://scripts/perks/tommyRarePerk.gd",
	"Manny": "res://scripts/perks/mannyPerk.gd",
	"Joel": "res://scripts/perks/joelPerk.gd",
	"Runner": "res://scripts/perks/runnerPerk.gd",
	"Abby": "res://scripts/perks/abbyPerk.gd",
	"Tess": "res://scripts/perks/tessPerk.gd",
	"WLFSoldier": "res://scripts/perks/wlfSoldierPerk.gd",
	"EllieRare": "res://scripts/perks/ellieRarePerk.gd",
	"FireflySoldier": "res://scripts/perks/fireflySoldierPerk.gd",
	"Nora": "res://scripts/perks/noraPerk.gd",
	"Malik": "res://scripts/perks/malikPerk.gd",
	"Dina": "res://scripts/perks/dinaPerk.gd",
	"Bill": "res://scripts/perks/billPerk.gd",
	"Yara": "res://scripts/perks/yaraPerk.gd",
	"Clicker": "res://scripts/perks/clickerPerk.gd",
	"LevRare": "res://scripts/perks/levRarePerk.gd",
	"Bloater": "res://scripts/perks/bloaterPerk.gd",
	"RatKingRare": "res://scripts/perks/ratKingRarePerk.gd",
}
