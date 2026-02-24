local fire_lance_data = require("data.fire_lance")
local generator = require("core.generator")

do_once.fire_lance = function ()
    local weapon_raw = generator.generate_ranged_weapon_raw_safe(fire_lance_data.id, fire_lance_data)
    
    -- Register items with DF API
    raws.register_items({
        weapon_raw
    })
    
    -- TODO: Implement add_item_to_civilization
    -- Add fire lance to dwarven civilization
    raws.register_entities({
        {
            ["OBJECT:ENTITY"] = "ENTITY",
            ["MOUNTAIN"] = {
                ["CREATURE:DWARF"] = {
                    ["WEAPON"] = {
                        fire_lance_data.id,
                    }
                }
            }
        }
    })

    local lines = {}
    lines[#lines + 1] = "[INTERACTION:SHOOT_FIRE_ITEM_POWER]"
    add_generated_info(lines)
    lines[#lines + 1] = "   [HELVE_LIB_ATTACH_TO_ITEM: " .. fire_lance_data.id .. "]"
    lines[#lines + 1] = "   [I_SOURCE:ITEM_POWER]"
    lines[#lines + 1] = "       [IS_DESCRIPTION:This item shimmers with fire.]"
    lines[#lines + 1] = "       [IS_CDI:ADV_NAME:Shoot fire]"
    lines[#lines + 1] = "       [IS_CDI:INTERACTION:SHOOT_FIRE_ITEM_POWER]"
    lines[#lines + 1] = "       [IS_CDI:FLOW:FIREJET]"
    lines[#lines + 1] = "       [IS_CDI:TARGET:C:LINE_OF_SIGHT]"
    lines[#lines + 1] = "       [IS_CDI:TARGET_RANGE:C:25]"
    lines[#lines + 1] = "       [IS_CDI:USAGE_HINT:ATTACK]"
    lines[#lines + 1] = "       [IS_CDI:VERB:focus:focuses:NA]"
    lines[#lines + 1] = "       [IS_CDI:MAX_TARGET_NUMBER:C:1]"
    lines[#lines + 1] = "       [IS_CDI:WAIT_PERIOD:50]"
    lines[#lines + 1] = "       [IS_CDI:DEFAULT_ICON:ADVENTURE_INTERACTION_ICON_LAUNCH_ICE_BOLT]"
    lines[#lines + 1] = "   [I_TARGET:A:MATERIAL]"
    lines[#lines + 1] = "       [IT_MATERIAL:CONTEXT_MATERIAL]"
    lines[#lines + 1] = "   [I_TARGET:B:LOCATION]"
    lines[#lines + 1] = "       [IT_LOCATION:CONTEXT_LOCATION]"
    lines[#lines + 1] = "   [I_TARGET:C:LOCATION]"
    lines[#lines + 1] = "       [IT_LOCATION:CONTEXT_CREATURE_OR_LOCATION]"
    lines[#lines + 1] = "   [IT_MANUAL_INPUT:target]"
    lines[#lines + 1] = "   [I_EFFECT:MATERIAL_EMISSION]"
    lines[#lines + 1] = "       [IE_TARGET:A]"
    lines[#lines + 1] = "       [IE_TARGET:B]"
    lines[#lines + 1] = "       [IE_TARGET:C]"
    lines[#lines + 1] = "       [IE_IMMEDIATE]"

    print_table(lines)

    -- TODO: Implement generate_interaction_raw
    -- Register interactions with DF API
    raws.register_interactions(lines)
end