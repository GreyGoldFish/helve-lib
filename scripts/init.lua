local fire_lance_data = require("data.fire_lance")
local generator = require("core.generator")

do_once.helve_lib = function ()
    local weapon_lines = generator.generate_ranged_weapon_raw_safe(fire_lance_data.id, fire_lance_data)
    
    -- Register items with DF API
    raws.register_items({
        weapon_lines
    })

    local materials_lines = {}
    materials_lines[#materials_lines + 1] = "[INORGANIC:BLACK_POWDER]"
    add_generated_info(materials_lines)
    materials_lines[#materials_lines + 1] = "[USE_MATERIAL_TEMPLATE:SOIL_TEMPLATE]"

    materials_lines[#materials_lines+1] = "[STATE_NAME_ADJ:ALL_SOLID:black powder]"

    materials_lines[#materials_lines + 1] = "[STATE_COLOR:ALL_SOLID:BLACK]"
    materials_lines[#materials_lines + 1] = "[DISPLAY_COLOR:0:0:1]" -- Black
    materials_lines[#materials_lines + 1] = "[TILE:'.']"

    materials_lines[#materials_lines + 1] = "[SPEC_HEAT:1380]" -- 1380 J/(kg.K)
    materials_lines[#materials_lines + 1] = "[MELTING_POINT:NONE]" -- Doesn't melt, burns instead
    materials_lines[#materials_lines + 1] = "[BOILING_POINT:NONE]" -- Doesn't boil, burns instead
    materials_lines[#materials_lines + 1] = "[IGNITE_POINT:10835]"
    materials_lines[#materials_lines + 1] = "[COLDDAM_POINT:9647]"
    materials_lines[#materials_lines + 1] = "[HEATDAM_POINT:10540]"

    materials_lines[#materials_lines + 1] = "[SOLID_DENSITY:1650]"
    materials_lines[#materials_lines + 1] = "[MATERIAL_VALUE:3]"

    materials_lines[#materials_lines + 1] = "[IMPACT_YIELD:5000]"
    materials_lines[#materials_lines + 1] = "[IMPACT_FRACTURE:10000]"
    materials_lines[#materials_lines + 1] = "[IMPACT_STRAIN_AT_YIELD:3]"

    -- Used to be able to make black powder with different reactions
    materials_lines[#materials_lines + 1] = "[REACTION_CLASS:BLACK_POWDER]"
    
    print_table(materials_lines)

    -- TODO: Implement generate_materials_raw
    raws.register_inorganics(materials_lines)

    local reactions_lines = {}

    -- Assemble fire lance from spear
    reactions_lines[#reactions_lines + 1] = "[REACTION:ASSEMBLE_FIRE_LANCE]"
    add_generated_info(reactions_lines)
    reactions_lines[#reactions_lines + 1] = "[FORTRESS_MODE_ENABLED]"
    reactions_lines[#reactions_lines + 1] = "[NAME:Assemble fire lance]"
    reactions_lines[#reactions_lines + 1] = "[BUILDING:BOWYER:NONE]"
    reactions_lines[#reactions_lines + 1] = "[SKILL:BOWYER]"

    -- [REAGENT:<name>:<quantity>:<item token>:<material token>][...modifiers...]
    reactions_lines[#reactions_lines + 1] = "[REAGENT:spear:1:WEAPON:ITEM_WEAPON_SPEAR:NONE:NONE]"
    reactions_lines[#reactions_lines + 1] = "[REAGENT:jug:1:TOOL:ITEM_TOOL_JUG:NONE:NONE]"
    reactions_lines[#reactions_lines + 1] = "     [EMPTY]"
    reactions_lines[#reactions_lines + 1] = "[REAGENT:chain:1:CHAIN:NONE:NONE]"

    -- [PRODUCT:<probability>:<quantity>:<item token>:<material token>][...modifiers...]
    reactions_lines[#reactions_lines + 1] = "[PRODUCT:100:1:WEAPON:ITEM_WEAPON_FIRE_LANCE:GET_MATERIAL_FROM_REAGENT:spear]"
    reactions_lines[#reactions_lines + 1] = "     [PRODUCT_TOKEN:fire_lance]"

    -- [IMPROVEMENT:<probability>:<reagent name>:<improvement type>:<material token>]
    reactions_lines[#reactions_lines + 1] = "[IMPROVEMENT:100:fire_lance:SPECIFIC:TRACTION_BENCH_ROPE:GET_MATERIAL_FROM_REAGENT:chain]"
    reactions_lines[#reactions_lines + 1] = "[IMPROVEMENT:100:fire_lance:SPECIFIC:HANDLE:GET_MATERIAL_FROM_REAGENT:jug]"

    -- Black powder reaction(s)
    -- TODO: Add variations
    reactions_lines[#reactions_lines + 1] = "[REACTION:MAKE_BLACK_POWDER]"
    add_generated_info(reactions_lines)
    reactions_lines[#reactions_lines + 1] = "[FORTRESS_MODE_ENABLED]"
    reactions_lines[#reactions_lines + 1] = "[NAME:Make black powder with saltpeter and brimstone]"
    --reactions_lines[#reactions_lines + 1] = "[BUILDING:CHEMIST:NONE]"
    -- TODO: Use ASHERY *only* if there's no CHEMIST workshop
    reactions_lines[#reactions_lines + 1] = "[BUILDING:ASHERY:NONE]"
    reactions_lines[#reactions_lines + 1] = "[SKILL:LYE_MAKING]"

    -- TODO: Process saltpeter into bag first (create a custom material)
    reactions_lines[#reactions_lines + 1] = "[REAGENT:saltpeter:3:BOULDER:NONE:INORGANIC:SALTPETER]"
    reactions_lines[#reactions_lines + 1] = "[REAGENT:charcoal:1:BAR:NONE:COAL]"
    reactions_lines[#reactions_lines + 1] = "[REAGENT:brimstone:1:BOULDER:NONE:INORGANIC:BRIMSTONE]"

    -- Output container
    reactions_lines[#reactions_lines + 1] = "[REAGENT:black_powder_bag:1:BAG:NONE:NONE:NONE]"
    reactions_lines[#reactions_lines + 1] = "     [EMPTY]"
    reactions_lines[#reactions_lines + 1] = "     [PRESERVE_REAGENT]"
    reactions_lines[#reactions_lines + 1] = "     [DOES_NOT_DETERMINE_PRODUCT_AMOUNT]"

    reactions_lines[#reactions_lines + 1] = "[PRODUCT:100:5:POWDER_MISC:NONE:INORGANIC:BLACK_POWDER]"
    reactions_lines[#reactions_lines + 1] = "     [PRODUCT_TO_CONTAINER:black_powder_bag]"
    reactions_lines[#reactions_lines + 1] = "     [PRODUCT_DIMENSION:150]"

    print_table(reactions_lines)

    -- TODO: Implement generate_reactions_raw
    raws.register_reactions(reactions_lines)

    local interactions_lines = {}
    interactions_lines[#interactions_lines + 1] = "[INTERACTION:SHOOT_FIRE_ITEM_POWER]"
    add_generated_info(interactions_lines)
    -- TODO: Implement attach_item_powers with custom raw tokens
    --interactions_lines[#interactions_lines + 1] = "   [HELVE_LIB_ATTACH_TO_ITEM: " .. fire_lance_data.id .. "]"
    interactions_lines[#interactions_lines + 1] = "   [I_SOURCE:ITEM_POWER]"
    interactions_lines[#interactions_lines + 1] = "       [IS_DESCRIPTION:This item shimmers with fire.]"
    interactions_lines[#interactions_lines + 1] = "       [IS_CDI:ADV_NAME:Shoot fire]"
    interactions_lines[#interactions_lines + 1] = "       [IS_CDI:INTERACTION:SHOOT_FIRE_ITEM_POWER]"
    interactions_lines[#interactions_lines + 1] = "       [IS_CDI:FLOW:FIREJET]"
    interactions_lines[#interactions_lines + 1] = "       [IS_CDI:TARGET:C:LINE_OF_SIGHT]"
    interactions_lines[#interactions_lines + 1] = "       [IS_CDI:TARGET_RANGE:C:25]"
    interactions_lines[#interactions_lines + 1] = "       [IS_CDI:USAGE_HINT:ATTACK]"
    interactions_lines[#interactions_lines + 1] = "       [IS_CDI:VERB:focus:focuses:NA]"
    interactions_lines[#interactions_lines + 1] = "       [IS_CDI:MAX_TARGET_NUMBER:C:1]"
    interactions_lines[#interactions_lines + 1] = "       [IS_CDI:WAIT_PERIOD:50]"
    interactions_lines[#interactions_lines + 1] = "       [IS_CDI:DEFAULT_ICON:ADVENTURE_INTERACTION_ICON_LAUNCH_ICE_BOLT]"
    interactions_lines[#interactions_lines + 1] = "   [I_TARGET:A:MATERIAL]"
    interactions_lines[#interactions_lines + 1] = "       [IT_MATERIAL:CONTEXT_MATERIAL]"
    interactions_lines[#interactions_lines + 1] = "   [I_TARGET:B:LOCATION]"
    interactions_lines[#interactions_lines + 1] = "       [IT_LOCATION:CONTEXT_LOCATION]"
    interactions_lines[#interactions_lines + 1] = "   [I_TARGET:C:LOCATION]"
    interactions_lines[#interactions_lines + 1] = "       [IT_LOCATION:CONTEXT_CREATURE_OR_LOCATION]"
    interactions_lines[#interactions_lines + 1] = "   [IT_MANUAL_INPUT:target]"
    interactions_lines[#interactions_lines + 1] = "   [I_EFFECT:MATERIAL_EMISSION]"
    interactions_lines[#interactions_lines + 1] = "       [IE_TARGET:A]"
    interactions_lines[#interactions_lines + 1] = "       [IE_TARGET:B]"
    interactions_lines[#interactions_lines + 1] = "       [IE_TARGET:C]"
    interactions_lines[#interactions_lines + 1] = "       [IE_IMMEDIATE]"

    print_table(interactions_lines)

    -- TODO: Implement generate_interactions_raw
    -- Register interactions with DF API
    raws.register_interactions(interactions_lines)

    -- TODO: Implement add_to_civilization_entity to add items, reactions, etc. to entities
    --raws.register_entities(entities_lines)
end