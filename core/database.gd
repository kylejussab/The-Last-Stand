extends Node2D

const CHARACTERS = { # Value, Type, Faction, Class, Card Name Text, Perk Text
	# Seraphite
	"Yara": [4, "Character", "Seraphite", "Stealthy", "YARA", "On Resolution: +3 if opposing card value is 8 or higher"],
	"Lev": [3, "Character", "Seraphite", "Stealthy/Survivor", "LEV", "+5 if Yara or Abby in hand and +3 if no Seraphite in hand"],
	"TheProphet": [6, "Character", "Seraphite", "Defensive/Stealthy", "THE PROPHET", "+2 if opposing card is Aggressive or Stealthy and +1 for each Stealthy in hand"],
	"Emily": [4, "Character", "Seraphite", "Survivor", "EMILY", "+1 for each Seraphite in hand"],
	"SeraphiteBrute": [5, "Character", "Seraphite", "Aggressive", "BRUTE", "+2 if opposing card's value is 3 or less"],
	"SeraphiteInitiate": [3, "Character", "Seraphite", "Crafty/Survivor", "INITIATE", "+3 if your hand contains no Aggressive cards"],
	
	# WLF
	"Abby": [6, "Character", "WLF", "Aggressive", "ABBY", "+2 if opposing card is Aggressive and +1 if opposing card is Infected"],
	"Manny": [4, "Character", "WLF", "Defensive", "MANNY", "equal value and +2 if opposing card is Aggressive or Defensive"],
	"Nora": [4, "Character", "WLF", "Crafty/Stealthy", "NORA", "+1 if opposing card is Crafty"],
	"Li": [3, "Character", "WLF", "Survivor", "LI", "On Resolution Loss: +1 to random character in hand"],
	"WLFSoldier": [3, "Character", "WLF", "Survivor", "SOLDIER", "-3 to opponent if opposing card is Survivor"],
	"Isaac": [6, "Character", "WLF", "Aggressive/Defensive", "ISAAC", "+2 if opposing card is Seraphite"],
	"Alice": [2, "Character", "WLF", "Stealthy/Survivor", "ALICE", "+3 if opposing card is Infected and +1 for each WLF in hand"],
	
	# Firefly
	"Marlene": [5, "Character", "Firefly", "Crafty", "MARLENE", "+1 if opposing card is Survivor or Stealthy"],
	"FireflySoldier": [2, "Character", "Firefly", "Defensive", "SOLDIER", "+6 if Marlene in hand"],
	"TommyFirefly": [4, "Character", "Firefly", "Survivor", "TOMMY", "+3 if no Firefly in hand"],
	"Eugene": [3, "Character", "Firefly", "Crafty/Survivor", "EUGENE", "On Resolution: +1 for each Crafty in hand and +3 if any Support card is played"],
	"Riley": [3, "Character", "Firefly", "Stealthy", "RILEY", "+3 if Ellie in hand and +2 if no Stealthy in hand"],
	
	# Infected
	"Bloater": [6, "Character", "Infected", "Aggressive/Defensive", "BLOATER", "?"],
	"Runner": [2, "Character", "Infected", "Aggressive", "RUNNER", "Gains the value of all runners in hand, and discard them"],
	"Stalker": [3, "Character", "Infected", "Stealthy", "STALKER", "+2 for each Infected in hand"],
	"Clicker": [5, "Character", "Infected", "Aggressive", "CLICKER", "On Resolution Win: -2 to opponent health"],
	"Shambler": [4, "Character", "Infected", "Defensive", "SHAMBLER", "On Resolution Loss (2 or more): -4 to opponent health"],
	"RatKing": [8, "Character", "Infected", "Aggressive", "RAT KING", "On Resolution Win: -4 to opponent health"],
	"Malik": [3, "Character", "Infected", "Survivor", "MALIK", "+1 for each Infected in hand and +2 if opposing card is Infected"],
	
	# Jackson
	"Joel": [6, "Character", "Jackson", "Crafty/Defensive", "JOEL", "+4 if Ellie or Tommy in hand and +2 if opposing card is multi-type"],
	"Ellie": [5, "Character", "Jackson", "Crafty/Stealthy", "ELLIE", "-2 if opposing card is Stealthy and +1 for each non-matching type in hand"],
	"Dina": [3, "Character", "Jackson", "Stealthy", "DINA", "+4 if opposing card is Defensive and +2 if Jessie or Ellie in hand"],
	"Tommy": [5, "Character", "Jackson", "Aggressive", "TOMMY", "+1 for each Jackson in hand"],
	"Bill": [4, "Character", "Jackson", "Crafty", "BILL", "+4 if the played support card has a backfire chance"],
	"Jessie": [5, "Character", "Jackson", "Defensive", "JESSIE", "-1 to opponent, if opposing card is Aggressive"],
	"Shimmer": [2, "Character", "Jackson", "Defensive", "SHIMMER", "+3 if Ellie or Dina in hand"],
	
	# New / altered cards based on humanity restored modifier
	"JoelSmuggler": [6, "Character", "Smuggler", "Aggressive", "JOEL", "+2 if opposing card is Aggressive or Defensive or Survivor"],
	"BillSmuggler": [4, "Character", "Smuggler", "Crafty", "BILL", "+4 if played support card is Trap Mine"],
	"LiSmuggler": [3, "Character", "Smuggler", "Survivor", "LI", "+2 if opposing card is Survivor"],
	"Tess": [5, "Character", "Smuggler", "Crafty/Survivor", "TESS", "+4 if Joel in hand, and Joel gains +2"],
	"Hunter": [3, "Character", "Smuggler", "Aggressive/Survivor", "HUNTER", "+3 if no other Smuggler in hand"],
	
	"Owen": [4, "Character", "WLF", "Stealthy", "OWEN", "On Resolution Loss: Take 0 health damage"],
	"Mel": [3, "Character", "WLF", "Survivor", "MEL", "On Resolution Win: +2 to random character card in hand"],
	"Maria": [4, "Character", "Firefly", "Defensive", "MARIA", "+2 if Tommy in hand"],
	"Jerry": [2, "Character", "Firefly", "Defensive", "JERRY", "On Resolution Loss: +2 to all Firefly in hand"],
	"AbbyFirefly": [4, "Character", "Firefly", "Crafty/Survivor", "ABBY", "+1 if opposing card is exactly 4"],
	
	"AliceHumanity": [2, "Character", "WLF", "Stealthy/Survivor", "ALICE", "+3 if opposing card is Stealthy and +1 for each WLF in hand"],
	"FireflySoldierHumanity": [2, "Character", "Firefly", "Defensive", "SOLDIER", "+3 if at least one Firefly in hand"],
	"WLFSoldierHumanity": [3, "Character", "WLF", "Survivor", "SOLDIER", "-2 to opponent if opposing card is Firefly or Seraphite"],
	"IsaacHumanity": [6, "Character", "WLF", "Aggressive/Defensive", "ISAAC", "+2 if opposing card is Firefly"],
	"TommyFireflyHumanity": [4, "Character", "Firefly", "Survivor", "TOMMY", "+1 for each Firefly in hand"],
	"RileyHumanity": [3, "Character", "Firefly", "Stealthy", "RILEY", "+3 if the played support card has a backfire chance"],
}

const SUPPORTS = {
	"Molotov": {
		"Value": 5,
		"Type": "Support",
		"Parity": "Negative",
		"CardText": "MOLOTOV",
		"PerkText": "Backfire chance: 33% (10% if your character is Aggressive)"
	},
	"ReinforcedMelee": {
		"Value": 2,
		"Type": "Support",
		"Parity": "Positive",
		"CardText": "REINFORCED MELEE",
		"PerkText": "On Resolution Win: Draw 1 support card"
	},
	"Rage": {
		"Value": 3,
		"Type": "Support",
		"Parity": "Positive",
		"CardText": "RAGE",
		"PerkText": "While in Hand: Gains an additional +1 after every round you win"
	},
	"Silencer": {
		"Value": 3,
		"Type": "Support",
		"Parity": "Positive",
		"CardText": "SILENCER",
		"PerkText": "Gains an additional +2 if played with a character card that is Crafty or Defensive"
	},
	"SmokeBomb": {
		"Value": 4,
		"Type": "Support",
		"Parity": "Negative",
		"CardText": "SMOKE BOMB",
		"PerkText": "Nullifies opponent's perk. Backfire chance: 33%"
	},
	"TrapMine": {
		"Value": 6,
		"Type": "Support",
		"Parity": "Negative",
		"CardText": "TRAP MINE",
		"PerkText": "Backfire chance: 50% (0% if your character's value is 8 or higher)"
	},
	"ScavengedParts": {
		"Value": 2,
		"Type": "Support",
		"Parity": "Positive",
		"CardText": "SCAVENGED PARTS",
		"PerkText": "+2 to a random support card in hand"
	},
	"Resilience": {
		"Value": 1,
		"Type": "Support",
		"Parity": "Positive",
		"CardText": "RESILIENCE",
		"PerkText": "On Resolution Loss: Halves damage taken (rounded down)"
	},
	"Retreat": {
		"Value": 0,
		"Type": "Support",
		"Parity": "Positive",
		"CardText": "RETREAT",
		"PerkText": "On Resolution: Negates all damage dealt this round"
	},
	"Bottle": {
		"Value": 2,
		"Type": "Support",
		"Parity": "Negative",
		"CardText": "BOTTLE",
		"PerkText": "Prevents opponent from playing a support this round. Backfire chance: 20%"
	},
	"Brick": {
		"Value": 2,
		"Type": "Support",
		"Parity": "Negative",
		"CardText": "BRICK",
		"PerkText": "Prevents opponent from playing a support this round. Backfire chance: 20%"
	},
	"ShotgunShells": {
		"Value": 4,
		"Type": "Support",
		"Parity": "Negative",
		"CardText": "SHOTGUN SHELLS",
		"PerkText": "-2 to opponent health. Backfire chance: 25%"
	},
	"Supplements": {
		"Value": 0,
		"Type": "Support",
		"Parity": "Positive",
		"CardText": "SUPPLEMENTS",
		"PerkText": "+3 to a random character card in hand"
	},
	"SupplyCache": {
		"Value": -2,
		"Type": "Support",
		"Parity": "Positive",
		"CardText": "SUPPLY CACHE",
		"PerkText": "While in Hand: Gains an additional +1 every round"
	}
}

const HOLDOUT_PERKS = {
	"Joel": "res://holdout/perks/joelPerk.gd",
	"Marlene": "res://holdout/perks/marlenePerk.gd",
	"Manny": "res://holdout/perks/mannyPerk.gd",
	"Jessie": "res://holdout/perks/jessiePerk.gd",
	"Runner": "res://holdout/perks/runnerPerk.gd",
	"Stalker": "res://holdout/perks/stalkerPerk.gd",
	"Abby": "res://holdout/perks/abbyPerk.gd",
	"Isaac": "res://holdout/perks/isaacPerk.gd",
	"WLFSoldier": "res://holdout/perks/wlfSoldierPerk.gd",
	"Ellie": "res://holdout/perks/elliePerk.gd",
	"FireflySoldier": "res://holdout/perks/fireflySoldierPerk.gd",
	"Nora": "res://holdout/perks/noraPerk.gd",
	"Malik": "res://holdout/perks/malikPerk.gd",
	"Dina": "res://holdout/perks/dinaPerk.gd",
	"Bill": "res://holdout/perks/billPerk.gd",
	"Yara": "res://holdout/perks/yaraPerk.gd",
	"Clicker": "res://holdout/perks/clickerPerk.gd",
	"Lev": "res://holdout/perks/levPerk.gd",
	"Shambler": "res://holdout/perks/shamblerPerk.gd",
	"RatKing": "res://holdout/perks/ratKingPerk.gd",
	"TheProphet": "res://holdout/perks/theProphetPerk.gd",
	"Emily": "res://holdout/perks/emilyPerk.gd",
	"TommyFirefly": "res://holdout/perks/tommyFireflyPerk.gd",
	"Alice": "res://holdout/perks/alicePerk.gd",
	"Riley": "res://holdout/perks/rileyPerk.gd",
	"Eugene": "res://holdout/perks/eugenePerk.gd",
	"Tommy": "res://holdout/perks/tommyPerk.gd",
	"SeraphiteInitiate": "res://holdout/perks/seraphiteInitiatePerk.gd",
	"Li": "res://holdout/perks/liPerk.gd",
	"SeraphiteBrute": "res://holdout/perks/seraphiteBrutePerk.gd",
	"Shimmer": "res://holdout/perks/shimmerPerk.gd",
	
	"JoelSmuggler": "res://holdout/perks/joelSmugglerPerk.gd",
	"BillSmuggler": "res://holdout/perks/billPerk.gd",
	"Tess": "res://holdout/perks/tessPerk.gd",
	"Hunter": "res://holdout/perks/hunterPerk.gd",
	"Mel": "res://holdout/perks/melPerk.gd",
	"Maria": "res://holdout/perks/mariaPerk.gd",
	"LiSmuggler": "res://holdout/perks/liSmugglerPerk.gd",
	"Jerry": "res://holdout/perks/jerryPerk.gd",
	"AliceHumanity": "res://holdout/perks/aliceHumanityPerk.gd",
	"FireflySoldierHumanity": "res://holdout/perks/fireflySoldierHumanityPerk.gd",
	"WLFSoldierHumanity": "res://holdout/perks/wlfSoldierHumanityPerk.gd",
	"IsaacHumanity": "res://holdout/perks/isaacHumanityPerk.gd",
	"Owen": "res://holdout/perks/owenPerk.gd",
	"RileyHumanity": "res://holdout/perks/rileyHumanityPerk.gd",
	"TommyFireflyHumanity": "res://holdout/perks/tommyFireflyHumanityPerk.gd",
	"AbbyFirefly": "res://holdout/perks/abbyFireflyPerk.gd",
	
	"Bottle": "res://holdout/perks/brickBottlePerk.gd",
	"Brick": "res://holdout/perks/brickBottlePerk.gd",
	"Molotov": "res://holdout/perks/molotovPerk.gd",
	"Rage": "res://holdout/perks/ragePerk.gd",
	"ReinforcedMelee": "res://holdout/perks/reinforcedMeleePerk.gd",
	"Resilience": "res://holdout/perks/resiliencePerk.gd",
	"Retreat": "res://holdout/perks/retreatPerk.gd",
	"ScavengedParts": "res://holdout/perks/scavengedPartsPerk.gd",
	"ShotgunShells": "res://holdout/perks/shotgunShellsPerk.gd",
	"Silencer": "res://holdout/perks/silencerPerk.gd",
	"SmokeBomb": "res://holdout/perks/smokeBombPerk.gd",
	"Supplements": "res://holdout/perks/supplementsPerk.gd",
	"SupplyCache": "res://holdout/perks/supplyCachePerk.gd",
	"TrapMine": "res://holdout/perks/trapMinePerk.gd",
}

var AVATARS = {
	Actor.Avatar.JUNE: {
		"name": "June Ravel",
		"description": "Former Firefly",
		"health": "%02d" % 35,
		"headPath": "res://core/ai/heads/"
	},
	Actor.Avatar.DUMMY: {
		"name": "Training Dummy",
		"description": "A Fun Guy",
		"health": "%02d" % 9,
		"headPath": "res://core/ai/heads/",
		"backgroundPath": "res://core/ai/backgrounds/"
	},
	Actor.Avatar.ETHAN: {
		"name": "Ethan Hark",
		"description": "Patrol Leader",
		"health": "%02d" % 20,
		"headPath": "res://core/ai/heads/",
		"backgroundPath": "res://core/ai/backgrounds/",
		"playstyle": "Aggressive"
	},
	Actor.Avatar.RHEA: {
		"name": "Rhea",
		"description": "Matriarch",
		"health": "%02d" % 20,
		"headPath": "res://core/ai/heads/",
		"backgroundPath": "res://core/ai/backgrounds/",
		"playstyle": "Attrition"
	},
	Actor.Avatar.UCKMANN: {
		"name": "Dr Uckmann",
		"description": "Dog Director",
		"health": "%02d" % 20,
		"headPath": "res://core/ai/heads/",
		"backgroundPath": "res://core/ai/backgrounds/",
		"playstyle": "Balanced"
	},
	Actor.Avatar.ALLEY: {
		"name": "Alley Ross",
		"description": "Scriptweaver",
		"health": "%02d" % 20,
		"headPath": "res://core/ai/heads/",
		"backgroundPath": "res://core/ai/backgrounds/",
		"playstyle": "Calculator"
	},
	Actor.Avatar.SILAS: {
		"name": "Silas Vane",
		"description": "Scavenger King",
		"health": "%02d" % 20,
		"headPath": "res://core/ai/heads/",
		"backgroundPath": "res://core/ai/backgrounds/",
		"playstyle": "Counter"
	},
	Actor.Avatar.MIRA: {
		"name": "Mira Thorne",
		"description": "Ex-Medic",
		"health": "%02d" % 20, 
		"headPath": "res://core/ai/heads/",
		"backgroundPath": "res://core/ai/backgrounds/",
		"playstyle": "Momentum"
	},
	Actor.Avatar.KAEL: {
		"name": "Kaelen Voss",
		"description": "Shield Brother",
		"health": "%02d" % 20,
		"headPath": "res://core/ai/heads/",
		"backgroundPath": "res://core/ai/backgrounds/",
		"playstyle": "Predictive"
	}
}

const OPPONENT_HEALTH_AMOUNTS: Array[int] = [
	13, # Round 1
	15, # Round 2
	17, # Round 3
	19, # Round 4
	20, # Round 5
	22, # Round 6
	24, # Round 7
	26, # Round 8
	28, # Round 9
	30, # Round 10
	33, # Round 11
	36  # Round 12 and beyond
]

var avatarHeadTextures = {}

func get_avatar_head_texture(path: String) -> Texture2D:
	if not avatarHeadTextures.has(path):
		avatarHeadTextures[path] = load(path)
	
	return avatarHeadTextures[path]

func clear_avatar_cache():
	avatarHeadTextures.clear()

const JUNE_OPPONENTS = [Actor.Avatar.ETHAN, Actor.Avatar.UCKMANN, Actor.Avatar.ALLEY, Actor.Avatar.MIRA, Actor.Avatar.RHEA]

enum Modifier { REDUCED_HAND, VOLATILE_HAND, CALCULATED_RISK, DEEP_WOUNDS, HEAVY_HITTER, GUERRILLA_TACTICS, BLACK_MARKET, SLOW_BLEED, NO_DEFENSE, LOUD_NOISE, DESPERATE_MEASURES, OVER_EXERTION, INFECTED_DECK, HUMANITY_RESTORED, ALWAYS_FIRST, FORSAKEN_HONOR, STACKED_ODDS, LONE_WOLF, PSYCHO_MANIA, SUPPLY_LINE, CARD_ROT, FRIENDLY_FIRE }

const MODIFIERS = {
	Modifier.VOLATILE_HAND: {
		"id": Modifier.VOLATILE_HAND,
		"name": "Volatile Hand",
		"description": "Every 2 rounds, all your character cards are discarded and redrawn.",
		"icon": "res://holdout/modifiers/icons/Volatile Hand.png",
		"tier": 1,
		"multiplier": 0.05,
		"duration": 3,
	},
	Modifier.CALCULATED_RISK: {
		"id": Modifier.CALCULATED_RISK,
		"name": "Calculated Risk",
		"description": "Winning a round by a margin of exactly 1 deals +3 damage to the opponent's health.",
		"icon": "res://holdout/modifiers/icons/Calculated Risk.png",
		"tier": 1,
		"multiplier": 0.05,
		"duration": 4,
	},
	Modifier.DEEP_WOUNDS: {
		"id": Modifier.DEEP_WOUNDS,
		"name": "Deep Wounds",
		"description": "Take +2 damage if you lose a round by 5 or more.",
		"icon": "res://holdout/modifiers/icons/Deep Wounds.png",
		"tier": 1,
		"multiplier": 0.10,
		"duration": 3,
	},
	Modifier.HEAVY_HITTER: {
		"id": Modifier.HEAVY_HITTER,
		"name": "Heavy Hitter",
		"description": "Take +1 damage if you play a character with a base value of 5 or more.",
		"icon": "res://holdout/modifiers/icons/Heavy Hitter.png",
		"tier": 1,
		"multiplier": 0.10, 
		"duration": 3,
	},
	Modifier.GUERRILLA_TACTICS: {
		"id": Modifier.GUERRILLA_TACTICS,
		"name": "Guerrilla Tactics",
		"description": "Consecutive character cards cannot be the same faction or type.",
		"icon": "res://holdout/modifiers/icons/Guerrilla Tactics.png",
		"tier": 1,
		"multiplier": 0.10,
		"duration": 3,
	},
	Modifier.BLACK_MARKET: {
		"id": Modifier.BLACK_MARKET,
		"name": "Black Market",
		"description": "You start the game with 4 support cards.",
		"icon": "res://holdout/modifiers/icons/Black Market.png",
		"tier": 1,
		"multiplier": 0.10,
		"duration": 1,
	},
	Modifier.SLOW_BLEED: {
		"id": Modifier.SLOW_BLEED,
		"name": "Slow Bleed",
		"description": "Take 1 damage at the end of every other round.",
		"icon": "res://holdout/modifiers/icons/Slow Bleed.png",
		"tier": 1,
		"multiplier": 0.15,
		"duration": 4,
		"amount": 1,
	},
	Modifier.NO_DEFENSE: {
		"id": Modifier.NO_DEFENSE,
		"name": "No Defense",
		"description": "Your defensive character cards have 0 value. Their perks still activate.",
		"icon": "res://holdout/modifiers/icons/No Defense.png",
		"tier": 2,
		"multiplier": 0.20,
		"duration": 2,
	},
	Modifier.LOUD_NOISE: {
		"id": Modifier.LOUD_NOISE,
		"name": "Loud Noise",
		"description": "All your stealth cards become aggressive. All your aggressive cards lose -1 value.",
		"icon": "res://holdout/modifiers/icons/Loud Noise.png",
		"tier": 2,
		"multiplier": 0.20,
		"duration": 2,
	},
	Modifier.DESPERATE_MEASURES: {
		"id": Modifier.DESPERATE_MEASURES,
		"name": "Desperate Measures",
		"description": "Support cards never backfire. Take +1 damage whenever you play one.",
		"icon": "res://holdout/modifiers/icons/Desperate Measures.png",
		"tier": 2,
		"multiplier": 0.25,
		"duration": 1,
	},
	Modifier.OVER_EXERTION: {
		"id": Modifier.OVER_EXERTION,
		"name": "Over-Exertion",
		"description": "Deal +2 damage if your final value is 10 or higher, but take +1 damage.",
		"icon": "res://holdout/modifiers/icons/Over Exertion.png",
		"tier": 2,
		"multiplier": 0.25,
		"duration": 3,
	},
	Modifier.INFECTED_DECK: {
		"id": Modifier.INFECTED_DECK,
		"name": "Infected Deck",
		"description": "Your deck contains significantly more infected cards.",
		"icon": "res://holdout/modifiers/icons/Infected Deck.png",
		"tier": 2,
		"multiplier": 0.25,
		"duration": 2,
	},
	Modifier.HUMANITY_RESTORED: {
		"id": Modifier.HUMANITY_RESTORED,
		"name": "Humanity Restored",
		"description": "Your deck reflects an alternate world where the cure was found.",
		"icon": "res://holdout/modifiers/icons/Humanity Restored.png",
		"tier": 2,
		"multiplier": 0.25,
		"duration": 2,
	},
	Modifier.ALWAYS_FIRST: {
		"id": Modifier.ALWAYS_FIRST,
		"name": "Always First",
		"description": "You must play first every round.",
		"icon": "res://holdout/modifiers/icons/Always First.png",
		"tier": 2,
		"multiplier": 0.30,
		"duration": 2,
	},
	Modifier.FORSAKEN_HONOR: {
		"id": Modifier.FORSAKEN_HONOR,
		"name": "Forsaken Honor",
		"description": "Lose 20 health. Your card’s faction and type are hidden from the opponent.",
		"icon": "res://holdout/modifiers/icons/Forsaken Honor.png",
		"tier": 3,
		"multiplier": 0.35,
		"duration": 2,
		"healthCost": 20,
	},
	Modifier.STACKED_ODDS: {
		"id": Modifier.STACKED_ODDS,
		"name": "Stacked Odds",
		"description": "The opponent gains +1 to their card value at the end of every round.",
		"icon": "res://holdout/modifiers/icons/Stacked Odds.png",
		"tier": 3,
		"multiplier": 0.35,
		"duration": 2,
	},
	Modifier.PSYCHO_MANIA: {
		"id": Modifier.PSYCHO_MANIA,
		"name": "Psycho-mania",
		"description": "Whenever a backfire triggers, a random card in your hand gains +2 value.",
		"icon": "res://holdout/modifiers/icons/Psycho Mania.png",
		"tier": 3,
		"multiplier": 0.35,
		"duration": 2,
	},
	Modifier.LONE_WOLF: {
		"id": Modifier.LONE_WOLF,
		"name": "Lone Wolf",
		"description": "Your support cards are disabled. Character values increased by +50%",
		"icon": "res://holdout/modifiers/icons/Lone Wolf.png",
		"tier": 3,
		"multiplier": 0.40,
		"duration": 1,
	},
	Modifier.SUPPLY_LINE: {
		"id": Modifier.SUPPLY_LINE,
		"name": "Supply Line",
		"description": "Your hand contains only support cards. Your character is auto played from the deck.",
		"icon": "res://holdout/modifiers/icons/Supply Line.png",
		"tier": 3,
		"multiplier": 0.45,
		"duration": 1,
	},
	Modifier.CARD_ROT: {
		"id": Modifier.CARD_ROT,
		"name": "Card Rot",
		"description": "Every 3 rounds, all cards in your hand lose -1 value.",
		"icon": "res://holdout/modifiers/icons/Card Rot.png",
		"tier": 3,
		"multiplier": 0.50,
		"duration": 1,
	},
	Modifier.FRIENDLY_FIRE: {
		"id": Modifier.FRIENDLY_FIRE,
		"name": "Friendly Fire",
		"description": "Your card's value is halved if your faction matches the opponent’s.",
		"icon": "res://holdout/modifiers/icons/Friendly Fire.png",
		"tier": 3,
		"multiplier": 0.50,
		"duration": 1,
	},
	Modifier.REDUCED_HAND: {
		"id": Modifier.REDUCED_HAND,
		"name": "Reduced Hand",
		"description": "Your maximum hand size is reduced to 6.",
		"icon": "res://holdout/modifiers/icons/Reduced Hand.png",
		"tier": 3,
		"multiplier": 0.55,
		"duration": 2,
	},
}

const standardCharacterDeck = [
	"Runner", "Runner", "Runner", "Runner",
	"Stalker", "Stalker", "Stalker",
	"FireflySoldier", "FireflySoldier", "FireflySoldier",
	"WLFSoldier", "WLFSoldier",
	"SeraphiteBrute", "SeraphiteBrute",
	"SeraphiteInitiate", "SeraphiteInitiate",
	
	"Clicker", "Clicker",
	"Shambler",
	"Emily", "Lev", "Yara",
	"Nora", "Manny", "Alice", "Li",
	"Bill", "Dina", "Jessie", "Tommy", "TommyFirefly", "Shimmer",
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
	
	"SmokeBomb", "SmokeBomb",
	"Silencer", "Silencer",
	"ReinforcedMelee", "ReinforcedMelee",
	"Retreat",
	"Resilience",
	"ShotgunShells",
	
	"Molotov",
	"Rage",
	"TrapMine", "TrapMine",
]

const infectedHeavyCharacterDeck = [
	"Runner", "Runner", "Runner", "Runner", "Runner", "Runner",
	"Stalker", "Stalker", "Stalker", "Stalker", "Stalker",
	"Clicker", "Clicker", "Clicker",
	"Shambler", "Shambler",
	"Malik", "Malik",
	
	"Runner", "Runner", "Runner", "Runner",
	"Stalker", "Stalker", "Stalker",
	"FireflySoldier",
	"WLFSoldier",
	"SeraphiteBrute",
	"SeraphiteInitiate", "SeraphiteInitiate",
	
	"Clicker", "Clicker",
	"Shambler",
	"Emily", "Lev", "Yara",
	"Nora", "Manny", "Alice", "Li",
	"Bill", "Dina", "Jessie", "Tommy", "TommyFirefly", "Shimmer",
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
	"SeraphiteInitiate", "SeraphiteInitiate",
	"TheProphet", "Emily", "Lev", "Yara",
	
	"JoelSmuggler", "Tess", 
	"BillSmuggler", 
	"LiSmuggler", 
	"Hunter", "Hunter"
]

const humanityRestoredSupportDeck = [
	"ScavengedParts", "ScavengedParts", 
	"Resilience", "Resilience", 
	"ShotgunShells", "ShotgunShells",
	
	"Bottle", "Bottle", 
	"Brick", "Brick", 
	"SmokeBomb", "Silencer",
	
	"TrapMine", "TrapMine", 
	"Retreat",
	
	"ReinforcedMelee", "ReinforcedMelee", 
	"Molotov", "Rage",
	
	"Supplements", "Supplements", 
	"SupplyCache", "SupplyCache"
]

const tutorialCharacterDeck = [
	"Dina", "Tommy", "Marlene", "Runner", "Li", "FireflySoldier", "Clicker",
	
	
	"SeraphiteInitiate", "TheProphet", "Runner", "Ellie", "Shimmer",
	"Isaac", "WLFSoldier", "Stalker",
	"FireflySoldier",
	"WLFSoldier", "Stalker",
	"SeraphiteBrute", "SeraphiteBrute",
	"SeraphiteInitiate",
	"Runner",
	
	"Clicker", "FireflySoldier",
	"Shambler",
	"Emily", "Lev", "Yara",
	"Nora", "Manny", "Alice",
	"Bill", "Jessie", "TommyFirefly", 
	"Riley", "Eugene", "Malik",
	
	"Joel",
	
	"Abby",
	"Stalker",
	"Runner",
	"RatKing",
]

const tutorialSupportDeck = [
	"Brick", "ScavengedParts", "Resilience", "Bottle", "TrainingManual", "SmokeBomb", "Retreat", "Bottle",
	
	"Rage",
	"Brick", "Bottle", "ScavengedParts",
	"Supplements", "Supplements",
	"SupplyCache", "SupplyCache",
	
	"MedKit", "MedKit",
	"SmokeBomb", "SmokeBomb",
	"ScavengedParts", "Silencer",
	"ReinforcedMelee", "ReinforcedMelee",
	"TrainingManual",
	"Retreat",
	"Resilience",
	"ShotgunShells",
	
	"Molotov",
	"Rage",
	"TrapMine", "TrapMine",
]

const CARD_VIEWER_DESCRIPTIONS = {
	"Abby": "The WLF's top soldier. She excels in fights with brute force, and has spent years turning herself into a weapon in the pursuit of vengeance.\n\nRivalries: Ellie, Emily, Joel, Rat King.",
	"AbbyFirefly": "Just a kid growing up in the Salt Lake City base. She idolizes her dad and genuinely believes the Fireflies are going to save the world.",
	"Alice": "A highly trained WLF guard dog. To her handlers, she's a loyal companion. To trespassers, she's a relentless tracker with a vicious bite.",
	"Bill": "A paranoid survivalist who turned an entire town into his personal fortress. He trusts his tripwires and shotgun traps a whole lot more than he trusts people.",
	"Bloater": "A massive Infected covered in thick, armor-like fungal plates. It's slow and completely blind, but makes up for it by throwing toxic spore bombs and being incredibly hard to kill.",
	"Clicker": "Completely blind, these Infected hunt purely by echolocation. If you make a sound, they will find you, and they will kill you.",
	"Dina": "A quick-witted and highly capable scout from Jackson. She brings a little warmth to the apocalypse, but will fight tooth and nail for the people she cares about.",
	"Ellie": "Resourceful, quick, and immune to the Cordyceps infection. She survived the outbreak, only to let a brutal need for revenge turn her into a ruthless killer.\n\nRivalries: Abby, Nora.",
	"Emily": "A high-ranking Seraphite zealot. She enforces the Prophet's laws with a heavy hand and shows absolutely zero mercy to trespassers or apostates.",
	"Eugene": "An old-school Firefly who traded in the war for a quiet life running patrols and growing weed in a hidden basement.",
	"FireflySoldier": "A militant survivor fighting to restore society. Driven by the hope of a cure, they rely on guerrilla tactics and sheer desperation to stay in the fight.",
	"Hunter": "Brutal, opportunistic scavengers who control their territory through fear and violence. They survive by ambushing anyone unlucky enough to cross their path.",
	"Isaac": "The ruthless, uncompromising leader of the WLF. He runs his massive militia with absolute authority and is willing to burn a city to the ground to wipe out his enemies.\n\nRivalries: Lev, The Prophet, Yara.",
	"Jerry": "The lead surgeon for the Fireflies and Abby's father. He carries the weight of the world on his shoulders, genuinely believing the sacrifice of one life is worth saving humanity.",
	"Jessie": "A fiercely loyal patrol leader from Jackson. He's the kind of guy who will drop everything and walk straight into a warzone just to make sure his friends make it home.",
	"Joel": "A hardened survivor who finally found a quiet life in Jackson. He'd do absolutely anything to protect the people he loves, no matter the cost or the consequences.\n\nRivalries: Abby, Marlene.",
	"JoelSmuggler": "A deeply entrenched Boston smuggler with no reason to ever soften. His brutal, pessimistic worldview has only sharpened into something far more dangerous.",
	"Lev": "A young Seraphite outcast who rejected the Prophet's traditions. He's deadly with a bow, fiercely protective of his sister, and just trying to survive a war he didn't start.\n\nRivalries: Isaac.",
	"Li": "An unpredictable and highly mysterious survivor currently operating as a WLF intelligence asset. They seem to know everyone's secrets, including dark rumors out of Los Angeles, yet fiercely guard their own past. They are incredibly valuable, but you never truly know their endgame.",
	"Malik": "The ruthless leader of a Hunter stronghold in Los Angeles. While others feared the Infected, Malik studied their primal instincts until he learned to command them like twisted attack dogs. He planned to conquer the city with his grotesque army, until a fateful run-in with Tess.",
	"Manny": "A veteran WLF soldier and one of Abby's closest friends. He's loud, fiercely loyal to his crew, and absolutely ruthless when it comes to clearing out Seraphites.",
	"Maria": "The pragmatic, no-nonsense leader of Jackson. She organizes the patrols, manages the town's defenses, and makes the hard calls to keep her people safe.",
	"Marlene": "The leader of the Fireflies. She's fighting a losing war, but her absolute commitment to finding a vaccine means she'll sacrifice anything, and anyone, to see it through.\n\nRivalries: Joel.",
	"Mel": "One of the WLF's top medics, originally trained by the Fireflies. She saves lives on the front lines, but is quietly losing her stomach for the endless brutality of the war.",
	"Nora": "A WLF medic stationed at the Seattle hospital. She's smart, deeply loyal to her old Firefly crew, and more than capable of handling herself when things go south.\n\nRivalries: Ellie.",
	"Owen": "A WLF soldier who is completely burnt out on the endless killing. He's an idealist at heart, desperately looking for a way out of Seattle and a reason to hope again.",
	"RatKing": "A massive amalgamation of the earliest Infected, fused together over decades in the Seattle hospital basement. It is a terrifying, nearly unstoppable wall of fungus and raw brute strength.",
	"Riley": "A rebellious teenager and Ellie's closest friend from the Boston quarantine zone. She joined the Fireflies looking for a real purpose and a way to fight back against the military.",
	"Runner": "The earliest stage of the Cordyceps infection. They still have their vision and attack with terrifying speed, often swarming their targets in overwhelming numbers.",
	"SeraphiteBrute": "A towering, heavily scarred enforcer for the Seraphites. They shrug off bullets and use massive two-handed melee weapons to simply crush anyone in their path.",
	"SeraphiteInitiate": "A deeply devoted warrior of the Seraphite cult. They use stealth, primitive weapons, and a chilling system of whistles to silently hunt trespassers in the overgrown ruins.",
	"Shambler": "A grotesque Infected mutation adapted to Seattle's constant rain. They aggressively charge their targets before erupting, violently expelling thick clouds of corrosive, burning acid.",
	"Shimmer": "Ellie's loyal and well-trained patrol horse from Jackson. Built for speed and endurance, she carries her riders safely across miles of treacherous, overgrown terrain.\n\nRivalries: WLF Soldier.",
	"Stalker": "The cunning second stage of the Cordyceps infection. Instead of rushing head-on, they silently skulk in the dark, flanking their prey and waiting for the perfect moment to strike.",
	"Tess": "A tough, highly respected smuggler running the black market in the Boston quarantine zone. She's ruthless, fiercely practical, and doesn't hesitate to do whatever it takes to survive.",
	"TheProphet": "The martyred founder of the Seraphites. Her teachings of rejecting old-world technology and returning to nature inspired a fanatical movement that completely changed the landscape of Seattle.",
	"Tommy": "A master sniper and one of Jackson's founding pillars. When his family is torn apart, he leaves the quiet life behind, unleashing a relentless, one-man war against those responsible.\n\nRivalries: Abby.",
	"TommyFirefly": "A survivor haunted by the brutal things he had to do to stay alive in the early years of the outbreak. Desperate for a cause he can actually believe in, he joined the Fireflies hoping to build a better world.",
	"WLFSoldier": "A heavily armed and highly trained member of the Washington Liberation Front. Backed by military-grade gear and sheer numbers, they fight a grueling, endless turf war for control of Seattle.",
	"Yara": "A former Seraphite warrior who sacrificed everything to protect her younger brother. Even after suffering a brutal amputation, she remains fiercely determined to keep him safe at any cost.\n\nRivalries: Isaac."
}

const REMNANT_CHARACTERS = {
	#Jackson
	"Joel": [6, "Character", "Jackson", "Aggressive/Survivor", "JOEL", "Duo: +4 if played with Ellie or Tommy and +2 if opposing card is multi-type"],
	"Ellie": [5, "Character", "Jackson", "Stealthy", "ELLIE", "+2 if opposing card is Stealthy and +1 for each non-matching type in hand"],
	"Jessie": [5, "Character", "Jackson", "Aggressive", "JESSIE", "+1 if opposing card is Aggressive"],
	"Maria": [4, "Character", "Jackson", "Leader", "MARIA", "Duo: +2 if played with Tommy"],
	"Dina": [3, "Character", "Jackson", "Survivor", "DINA", "Duo: +3 if played with Ellie or Jessie and +4 if opposing card is Defensive"],
	"JacksonScout": [2, "Character", "Jackson", "Defensive", "SCOUT", "Duo: Can be used as replacement"],
	"JacksonRecruit": [1, "Character", "Jackson", "Aggressive", "RECRUIT", "Duo: Can be used as replacement"],
	"Tommy": [5, "Character", "Jackson", "Aggressive", "TOMMY", "+1 for each Scout or Recruit in hand"],

	#WLF
	"Isaac": [6, "Character", "WLF", "Aggressive/Defensive", "ISAAC", "+3 if opposing card is multi-type"],
	"Abby": [6, "Character", "WLF", "Aggressive/Survivor", "ABBY", "Duo: +2 if played with WLF Scout or Recruit"],
	"Nora": [4, "Character", "WLF", "Defensive/Stealthy", "NORA", "+2 if opposing card is Crafty or Survivor"],
	"Manny": [4, "Character", "WLF", "Defensive", "MANNY", "+2 if played with a card of a different type"],
	"Owen": [4, "Character", "WLF", "Stealthy", "OWEN", "Duo: +3 if played with Abby or Mel"],
	"Mel": [3, "Character", "WLF", "Stealthy/Survivor", "MEL", "On round win: +2 to random card in hand"],
	"WLFScout": [2, "Character", "WLF", "Defensive", "SCOUT", "No perk"],
	"WLFRecruit": [1, "Character", "WLF", "Aggressive", "RECRUIT", "No perk"],
	
	#Seraphite
	"TheProphet": [6, "Character", "Seraphite", "Defensive/Stealthy", "THE PROPHET", "+2 if opposing card is Aggressive or Stealthy and +1 for each Stealthy in hand"],
	"Lev": [3, "Character", "Seraphite", "Stealthy/Survivor", "LEV", "Duo: +5 if played with Yara and +3 if opposing card base value is greater than Lev's"],
	"SeraphiteBrute": [5, "Character", "Seraphite", "Aggressive", "SERAPHITE BRUTE", "+2 if opposing card value is 3 or less"],
	"Yara": [4, "Character", "Seraphite", "Stealthy", "YARA", "+3 if opposing card value is 8 or higher"],
	"SeraphiteInitiate": [2, "Character", "Seraphite", "Survivor", "INITIATE", "+2 if opposing card is Aggressive"],
	"Emily": [4, "Character", "Seraphite", "Survivor", "EMILY", "+1 for each Stealthy or Survivor in hand"],
	"SeraphiteRecruit": [1, "Character", "Seraphite", "Aggressive", "RECRUIT", "No perk"],
	
	#Infected
	"Bloater": [6, "Character", "Infected", "Aggressive/Defensive", "BLOATER", "On round win: Gain 1 additional territory"],
	"Clicker": [5, "Character", "Infected", "Aggressive", "CLICKER", "+3 if opposing card is Stealthy"],
	"Stalker": [3, "Character", "Infected", "Stealthy", "STALKER", "+4 if not paired with another Stalker"],
	"Shambler": [4, "Character", "Infected", "Defensive", "SHAMBLER", "On round loss: Opponent gains 0 territories"],
	"Malik": [3, "Character", "Infected", "Survivor", "MALIK", "+3 if opposing card has no perk"],
	"Runner": [2, "Character", "Infected", "Aggressive", "RUNNER", "+1 if opposing card is Aggressive"],

	#Firefly
	"Marlene": [5, "Character", "Firefly", "Crafty", "MARLENE", "Duo: +6 if played with FF Soldier or Recruit"],
	"TommyFirefly": [4, "Character", "Firefly", "Survivor", "TOMMY", "Duo: +2 if played with FF Soldier or Recruit"],
	"Riley": [3, "Character", "Firefly", "Stealthy", "RILEY", "+3 if Marlene in hand"],
	"Jerry": [2, "Character", "Firefly", "Defensive", "JERRY", "On round loss: +4 to random card in hand"],
	"Eugene": [3, "Character", "Firefly", "Crafty/Survivor", "EUGENE", "+3 if opposing card is Survivor"],
	"FireflySoldier": [2, "Character", "Firefly", "Defensive", "FIREFLY SOLDIER", "+2 if opposing card is Aggressive or Stealthy"],
	"FireflyRecruit": [1, "Character", "Firefly", "Aggressive", "RECRUIT", "No perk"],

	#Smuggler
	"Tess": [5, "Character", "Smuggler", "Crafty/Survivor", "TESS", "+3 if opposing card has a perk"],
	"Hunter": [3, "Character", "Smuggler", "Aggressive/Survivor", "HUNTER", "+4 if base value is higher than opposing card base value"],
	"Bill": [4, "Character", "Smuggler", "Crafty", "BILL", "+4 if opposing card triggers a perk"],
	"Li": [3, "Character", "Smuggler", "Survivor", "LI", "Duo: +3 if played with Scout or Recruit"]
}
