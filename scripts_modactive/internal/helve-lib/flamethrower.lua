--@ module=true

local FIRE_FLOW_DENSITY = 50
local SMOKE_FLOW_DENSITY = 10

local INTERACTION_NAME = "SHOOT_FIRE_CREATURE_ACTION"

local item_power_interaction_index = nil

-- Checks if a tile blocks projectiles
-- [[
local function is_solid_obstacle(pos)
    local tile_type = dfhack.maps.getTileType(pos)
    if not tile_type then return true end

    local shape = df.tiletype.attrs[tile_type].shape
    
    if shape == df.tiletype_shape.WALL or 
       shape == df.tiletype_shape.BOULDER or
       shape == df.tiletype_shape.DOOR or
       shape == df.tiletype_shape.BRANCH or
       shape == df.tiletype_shape.TRUNK then
        return true
    end
    
    return false
end
-- ]]

-- Spawn a line of fire from origin to target
-- [[
local function spawn_fire_line(projectile, range)
    local ox, oy, oz = projectile.origin_pos.x, projectile.origin_pos.y, projectile.origin_pos.z
    local tx, ty, tz = projectile.target_pos.x, projectile.target_pos.y, projectile.target_pos.z

    -- Calculate difference
    local dx = tx - ox
    local dy = ty - oy
    local dz = tz - oz

    local magnitude = math.sqrt((dx * dx) + (dy * dy) + (dz * dz))
    if magnitude < 0.1 then return end

    -- Normalize vector
    local nx = dx / magnitude
    local ny = dy / magnitude
    local nz = dz / magnitude

    -- Spawn smoke on shooter
    local origin_pos = xyz2pos(ox, oy, oz)
    if dfhack.maps.isValidTilePos(origin_pos) then
        dfhack.maps.spawnFlow(origin_pos, df.flow_type.Smoke, -1, -1, SMOKE_FLOW_DENSITY)
    end

    -- Start at 2 to avoid spawning on the shooter
    for i = 2, range do
        local px = math.floor(ox + (nx * i) + 0.5)
        local py = math.floor(oy + (ny * i) + 0.5)
        local pz = math.floor(oz + (nz * i) + 0.5)
        -- Flow density is higher closer to the origin
        local distance_factor = 1 - ((i - 2) / (range - 2))
        local current_density = math.max(20, math.floor(FIRE_FLOW_DENSITY * (0.5 + distance_factor * 0.5)))

        local current_pos = xyz2pos(px, py, pz)

        if is_solid_obstacle(current_pos) then
            dfhack.maps.spawnFlow(current_pos, df.flow_type.Smoke, -1, -1, SMOKE_FLOW_DENSITY)
            break
        elseif dfhack.maps.isValidTilePos(current_pos) then
            dfhack.maps.spawnFlow(current_pos, df.flow_type.Fire, -1, -1, current_density)
        end
    end
end
-- ]]

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
-- [[
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
-- ]]