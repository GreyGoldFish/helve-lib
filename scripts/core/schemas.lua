local SCHEMAS = {}

local ENUMS = require("core.constants").ENUMS

SCHEMAS.WEAPON = {
    fields = {
        id = "string", -- Unique string identifier for the weapon token.
        name = "string", -- Name of the weapon, e.g. "copper dagger".
        name_plural = "string", -- Plural name of the weapon, e.g. "copper daggers".
        material_size = "number", -- Number of bar units needed for forging, as well as the amount gained from melting.
        attacks = "table", -- You can have many ATTACK tags and one will be randomly selected for each attack.
        adjective = "string", -- Adjective of the weapon, e.g. the "large" in "large copper dagger".
        size = "number", -- Volume of weapon in mL or cubic cm. Defaults to 100.
        skill = "string", -- The skill to determine effectiveness in melee with this weapon. Defaults to MACE.
        two_handed = "number", -- Below this size, one-handed use of a weapon will cause a penalty to hit. Defaults to 50000.
        minimum_size = "number", -- Minimum body size to use the weapon at all (multigrasp required until TWO_HANDED value). Defaults to 40000.
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
        skill = ENUMS.SKILLS,
    }
}

SCHEMAS.ATTACK = {
    fields = {
        attack_type = "string",
        contact_area = "number", -- The area of the weapon that makes contact with the target, in square cm.
        penetration_size = "number", -- The size of the wound created by the attack, in square cm.
        verb_2nd = "string", -- Verb used when the weapon is the subject of a sentence.
        verb_3rd = "string", -- Verb used when the weapon is the object of a sentence.
        noun = "string", -- Describes what part of the weapon is being used in the attack, or NO_SUB for none.
        velocity_multiplier = "number", -- Is a multiplier for the attack momentum, increasing effectiveness.
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
        attack_type = ENUMS.ATTACK_TYPES,
        multiattack_flag = ENUMS.MULTIATTACK_FLAGS,
    }
}

SCHEMAS.ATTACK_PREPARE_AND_RECOVER = {
    fields = {
        preparation_time = "number", -- Time in Adventure mode ticks to prepare the attack.
        recovery_time = "number", -- Time in Adventure mode ticks to recover from the attack.
    },
    required = {
        "preparation_time",
        "recovery_time",
    }
}

SCHEMAS.RANGED_WEAPON = {
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

SCHEMAS.SHOOT_FORCE_REQUIRES = {
    fields = {
        attribute_or_skill = "string", -- The name of the attribute or skill that limits the shoot force.
        value = "number", -- The minimum value of the attribute or skill needed to use the shoot force.
    },
    required = {
        "attribute_or_skill",
        "value",
    },
    enums = {
        attribute_or_skill = table.move(ENUMS.ATTRIBUTES, 1, #ENUMS.ATTRIBUTES, 1, ENUMS.SKILLS)
    }
}

SCHEMAS.LOADED_NOCKED = {
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
        ammo_handling = ENUMS.AMMO_HANDLING,
    }
}

-- Validate data against a schema
-- @param data table: Data to validate
-- @param schema table: Schema to validate against  
-- @param context string: Context for error messages
-- @return boolean: True if valid, throws error if invalid
function SCHEMAS.validate(data, schema, context)
    context = context or "data"
    
    -- Basic type check
    if type(data) ~= "table" then
        error(string.format("Validation Error: %s must be a table, got %s", context, type(data)))
    end
    
    -- Handle schema extension
    local effective_schema = schema
    if schema.extends then
        local parent_schema = SCHEMAS[schema.extends]
        if not parent_schema then
            error(string.format("Validation Error: %s extends unknown schema '%s'", context, schema.extends))
        end
        
        -- Merge: copy parent, then override with child
        effective_schema = {
            fields = parent_schema.fields and shallow_copy(parent_schema.fields) or {},
            required = parent_schema.required and shallow_copy(parent_schema.required) or {},
            enums = parent_schema.enums and shallow_copy(parent_schema.enums) or {}
        }
        
        if schema.fields then
            for k, v in pairs(schema.fields) do
                effective_schema.fields[k] = v
            end
        end
        if schema.enums then
            for k, v in pairs(schema.enums) do
                effective_schema.enums[k] = v
            end
        end
        if schema.required then
            for _, field in ipairs(schema.required) do
                table.insert(effective_schema.required, field)
            end
        end
    end
    
    -- Validate required fields
    if effective_schema.required then
        for _, field in ipairs(effective_schema.required) do
            if data[field] == nil then
                error(string.format("Validation Error: %s missing required field '%s'", context, field))
            end
        end
    end
    
    -- Validate fields
    if effective_schema.fields then
        for field_name, field_type in pairs(effective_schema.fields) do
            local value = data[field_name]
            if value ~= nil then
                local field_context = string.format("%s.%s", context, field_name)
                
                -- Type validation
                if type(value) ~= field_type then
                    error(string.format("Validation Error: %s must be %s, got %s", field_context, field_type, type(value)))
                end
                
                -- Enum validation
                if effective_schema.enums and effective_schema.enums[field_name] then
                    local valid_values = effective_schema.enums[field_name]
                    local is_valid = false
                    for _, enum_value in pairs(valid_values) do
                        if value == enum_value then
                            is_valid = true
                            break
                        end
                    end
                    if not is_valid then
                        local valid_list = {}
                        for _, enum_value in pairs(valid_values) do
                            table.insert(valid_list, tostring(enum_value))
                        end
                        error(string.format("Validation Error: %s must be one of [%s], got '%s'", 
                            field_context, table.concat(valid_list, ", "), tostring(value)))
                    end
                end
                
                -- Nested validation
                if field_type == "table" then
                    if field_name == "attacks" then
                        -- Array of attacks
                        for i, attack in ipairs(value) do
                            SCHEMAS.validate(attack, SCHEMAS.ATTACK, string.format("%s[%d]", field_context, i))
                        end
                    elseif field_name == "attack_prepare_and_recover" then
                        SCHEMAS.validate(value, SCHEMAS.ATTACK_PREPARE_AND_RECOVER, field_context)
                    elseif field_name == "shoot_force_requires" then
                        SCHEMAS.validate(value, SCHEMAS.SHOOT_FORCE_REQUIRES, field_context)
                    elseif field_name == "loaded_nocked" then
                        SCHEMAS.validate(value, SCHEMAS.LOADED_NOCKED, field_context)
                    end
                end
            end
        end
    end
    
    return true
end
    
return SCHEMAS