local CONSTANTS = require("core.constants")

local M = {}

function M.weapon()
    return {
        fields = {
            id = "string", -- Unique string identifier for weapon token.
            name = "string", -- Name of weapon, e.g. "copper dagger".
            name_plural = "string", -- Plural name of weapon, e.g. "copper daggers".
            material_size = "number", -- Number of bar units needed for forging, as well as amount gained from melting.
            attacks = "table", -- You can have many ATTACK tags and one will be randomly selected for each attack.
            adjective = "string", -- Adjective of weapon, e.g. "large" in "large copper dagger".
            size = "number", -- Volume of weapon in mL or cubic cm. Defaults to 100.
            skill = "string", -- The skill to determine effectiveness in melee with this weapon. Defaults to MACE.
            two_handed = "number", -- Below this size, one-handed use of a weapon will cause a penalty to hit. Defaults to 50000.
            minimum_size = "number", -- Minimum body size to use weapon at all (multigrasp required until TWO_HANDED value). Defaults to 40000.
            can_stone = "boolean", -- Allows the weapon to be made at a craftsdwarf's workshop from a sharp ([MAX_EDGE:10000] or higher) stone (i.e. obsidian) plus a wood log.
            training = "boolean", -- Restricts this weapon to being made of wood.
        },
        required = {
            "id",
            "name", "name_plural",
            "material_size", 
            "attacks",
        },
        enums = {
            skill = CONSTANTS.ENUMS.SKILLS,
        }
    }
end

function M.attack()
    return {
        fields = {
            attack_type = "string",
            contact_area = "number", -- The area of weapon that makes contact with the target, in square cm.
            penetration_size = "number", -- The size of wound created by the attack, in square cm.
            verb_2nd = "string", -- Verb used when the weapon is the subject of a sentence.
            verb_3rd = "string", -- Verb used when the weapon is the object of a sentence.
            noun = "string", -- Describes what part of the weapon is being used in the attack, or NO_SUB for none.
            velocity_multiplier = "number", -- Is a multiplier for attack momentum, increasing effectiveness.
            attack_prepare_and_recover = "table", -- Determines the length of time to prepare this attack and until one can perform this attack again.
            multiattack_flag = "string", -- Determines how this attack functions when performing multiple attacks in the same round.
        },
        required = {
            "attack_type",
            "contact_area",
            "penetration_size",
            "verb_2nd",
            "verb_3rd",
            "noun",
            "velocity_multiplier",
        },
        enums = {
            attack_type = CONSTANTS.ENUMS.ATTACK_TYPES,
            multiattack_flag = CONSTANTS.ENUMS.MULTIATTACK_FLAGS,
        }
    }
end

function M.attack_prepare_and_recover()
    return {
        fields = {
            preparation_time = "number", -- Time in Adventure mode ticks to prepare the attack.
            recovery_time = "number", -- Time in Adventure mode ticks to recover from the attack.
        },
        required = {
            "preparation_time",
            "recovery_time",
        }
    }
end

function M.ranged_weapon()
    return {
        extends = "WEAPON",
        fields = {
            skill = "string", -- The skill to determine effectiveness in ranged combat with this weapon. Overrides the WEAPON skill field.
            ammo_class = "string", -- The class of ammo used by this weapon, which determines
            shoot_force = "number", -- The amount of force used when firing projectiles - velocity is presumably determined by the projectile's mass. Defaults to 0.
            shoot_force_requires = "table", -- Limits the force of fired projectiles based on the user's stats.
            shoot_max_vel = "number", -- The maximum velocity of projectiles fired from this weapon, in cm/s. Defaults to 1000.
            aim_difficulty  = "number", -- Higher values cause fired projectiles to be less accurate.
            loaded_nocked = "table", -- Determines how long it takes to load ammunition into this weapon.
            initiate_shot_time = "number", -- Shooting this weapon takes this many ticks before the projectile is fired.
            shot_recovery_time = "number", -- After shooting this weapon, wait this many ticks to recover.
        },
        required = {
            "skill",
            "ammo_class",
            "loaded_nocked",
        }
    }
end

function M.shoot_force_requires()
    return {
        fields = {
            attribute_or_skill = "string", -- The name of the attribute or skill that limits the shoot force.
            value = "number", -- The minimum value of the attribute or skill needed to use the shoot force.
        },
        required = {
            "attribute_or_skill",
            "value",
        },
        enums = {
            attribute_or_skill = table.move(CONSTANTS.ENUMS.ATTRIBUTES, 1, #CONSTANTS.ENUMS.ATTRIBUTES, 1, CONSTANTS.ENUMS.SKILLS)
        }
    }
end

function M.loaded_nocked()
    return {
        fields = {
            ammo_handling = "string",
            maximum_ticks = "number",
            minimum_ticks = "number",
        },
        required = {
            "ammo_handling",
            "maximum_ticks", -- An unskilled archer takes the maximum time.
            "minimum_ticks", -- Each level in the weapon's ranged skill reduces the loading time by one tick until the minimum time is reached.
        },
        enums = {
            ammo_handling = CONSTANTS.ENUMS.AMMO_HANDLING,
        }
    }
end

return M