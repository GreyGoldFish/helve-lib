local fire_lance_data <const> = require("data.fire_lance")
local generator <const> = require("core.generator")

do_once.fire_lance = function ()
    -- Generate and register weapon
    local raw_data = generator.generate_ranged_weapon_raw_safe(fire_lance_data.id, fire_lance_data)
    raws.register_items({
        raw_data
    })
    
    -- Add fire lance to dwarven civilization
    raws.register_entities({
        {
            ["OBJECT:ENTITY"] = "ENTITY",
            ["MOUNTAIN"] = {
                ["CREATURE:DWARF"] = {
                    ["WEAPON"] = {
                        "ITEM_WEAPON_FIRE_LANCE",
                        -- Add other existing weapons here as needed
                    }
                }
            }
        }
    })
end