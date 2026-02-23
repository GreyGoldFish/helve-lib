local CONSTANTS = {}

CONSTANTS.ENUMS = {
    ATTACK_TYPES = {
        BLUNT = "BLUNT",
        EDGE = "EDGE",
    },
    MULTIATTACK_FLAGS = {
        ATTACK_FLAG_BAD_MULTIATTACK = "ATTACK_FLAG_BAD_MULTIATTACK", -- Multiple strikes with this attack cannot be performed effectively.
        ATTACK_FLAG_INDEPENDENT_MULTIATTACK = "ATTACK_FLAG_INDEPENDENT_MULTIATTACK", -- Multiple strikes with this attack can be performed with no penalty.
    },
    SKILLS = {
        AXE = "AXE",
        BOW = "BOW",
        CROSSBOW = "CROSSBOW",
        DAGGER = "DAGGER",
        HAMMER = "HAMMER",
        MACE = "MACE",
        PICK = "PICK",
        PIKE = "PIKE",
        SPEAR = "SPEAR",
        SWORD = "SWORD",
    },
    ATTRIBUTES = {
        STRENGTH = "STRENGTH",
        AGILITY = "AGILITY",
        TOUGHNESS = "TOUGHNESS",
        ENDURANCE = "ENDURANCE",
        RECUPERATION = "RECUPERATION",
        DISEASE_RESISTANCE = "DISEASE_RESISTANCE",
        ANALYTICAL_ABILITY = "ANALYTICAL_ABILITY",
        FOCUS = "FOCUS",
        WILLPOWER = "WILLPOWER",
        CREATIVITY = "CREATIVITY",
        INTUITION = "INTUITION",
        PATIENCE = "PATIENCE",
        MEMORY = "MEMORY",
        LINGUISTIC_ABILITY = "LINGUISTIC_ABILITY",
        SPATIAL_SENSE = "SPATIAL_SENSE",
        MUSICALITY = "MUSICALITY",
        KINESTHETIC_SENSE = "KINESTHETIC_SENSE",
        EMPATHY = "EMPATHY",
        SOCIAL_AWARENESS = "SOCIAL_AWARENESS",
    },
    AMMO_HANDLING = {
        LOADED = "LOADED", -- Ammo is stored inside the weapon.
        NOCKED = "NOCKED", -- Ammo stays inside the same inventory and remembers that it is nocked to the weapon.
    }
}

return CONSTANTS