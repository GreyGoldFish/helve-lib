--@ module=true

-- Find the interaction index of the magic power
local function get_item_power_interaction_index(interaction_name)
    for i, interaction in ipairs(df.global.world.raws.interactions.all) do
        if interaction.name == interaction_name then
            return i
        end
    end
    dfhack.println(interaction_name .. " not found")

    return nil
end

-- TODO: effect:activateOnUnit doesn't work as expected
local function trigger_interaction_from_projectile(projectile, interaction_index)
    -- Get the creature who fired the weapon
    local firer = projectile.firer
    if not firer then
        return
    end

    dfhack.println("Firer is " .. firer.id)

    -- Get the interaction from the index
    local interaction = df.global.world.raws.interactions.all[interaction_index]
    if not interaction then
        return
    end

    dfhack.println("Interaction is " .. interaction.name)

    -- Create interaction instance
    local instance = df.interaction_instance:new()
    instance.id = #df.global.world.interaction_instances.all
    instance.interaction_id = interaction_index
    instance.source_context.type = df.interaction_context_type.NONE

    -- Add the shooter to affected units
    instance.affected_units:insert('#', firer.id)

    -- Register the instance globally
    df.global.world.interaction_instances.all:insert('#', instance)

    -- Find and execute the MATERIAL_EMISSION effect
    for _, effect in ipairs(interaction.effects) do
        if effect:getType() == df.interaction_effect_type.MATERIAL_EMISSION then
            dfhack.println("Found MATERIAL_EMISSION effect")
            -- Execute the effect directly
            effect:activateOnUnit(firer, instance, true, nil, nil)
            return true
        end
    end
    
    dfhack.println("No MATERIAL_EMISSION effect found")
    return false
end