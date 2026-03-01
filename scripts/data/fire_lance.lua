local CONSTANTS = require("core.constants")

local FIRE_LANCE = {
    id = "FIRE_LANCE",
    name = "fire lance", name_plural = "fire lances",
    material_size = 100,
    skill = "SPEAR",
    ammo_class = "FIRE_CHARGE",
    attacks = {
        {
            attack_type = CONSTANTS.ENUMS.ATTACK_TYPES.EDGE,
            contact_area = 15,
            penetration_size = 1200,
            verb_2nd = "stab", verb_3rd = "stabs",
            noun = "NO_SUB",
            velocity_multiplier = 550,
        },
    },
    shoot_force = 600,
    shoot_max_vel = 0,
    initiate_shot_time = 15,
    shot_recovery_time = 1200,
    loaded_nocked = {
        ammo_handling = CONSTANTS.ENUMS.AMMO_HANDLING.LOADED,
        maximum_ticks = 120,
        minimum_ticks = 80,
    }
}

return FIRE_LANCE