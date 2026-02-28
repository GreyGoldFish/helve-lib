--@ module=true

local eventful = require('plugins.eventful')
local extinguish = dfhack.reqscript("extinguish")
local utils = dfhack.reqscript("internal/helve-lib/utils")

local FIRE_FLOW_DENSITY = 300
local MIN_FIRE_FLOW_DENSITY = 50
local SMOKE_FLOW_DENSITY = 20
local CALLBACK_ID = "helve-lib-flamethrower"
local FUEL_AMMO_TOKEN = "ITEM_AMMO_FIRE_CHARGE"
local DEFAULT_RANGE = 6
local WEAPON_RANGES = {
    ["ITEM_WEAPON_FIRE_LANCE"] = DEFAULT_RANGE,
}
local CONE_ANGLE_RADIANS = math.rad(60)
local BURN_DURATION = 50

local GRASS_MATERIALS = {
    [df.tiletype_material.GRASS_LIGHT] = true,
    [df.tiletype_material.GRASS_DARK] = true,
}

-- Ash tiletypes to randomly vary the look
local ASH_TILETYPES = {
    df.tiletype.Ashes1,
    df.tiletype.Ashes2,
    df.tiletype.Ashes3,
}

-- TODO: Fix memory leak
local handled_projectiles = {}

local function bresenham_line(ox, oy, tx, ty, range, callback)
    local dx = math.abs(tx - ox)
    local dy = math.abs(ty - oy)
    local sx = ox < tx and 1 or -1
    local sy = oy < ty and 1 or -1
    local err = dx - dy
    local x, y = ox, oy
    local steps = 0

    while steps < range do
        if not (x == ox and y == oy) then
            if not callback(x, y, steps) then return end
        end
        if x == tx and y == ty then break end
        local e2 = 2 * err
        if e2 > -dy then err = err - dy; x = x + sx end
        if e2 <  dx then err = err + dx; y = y + sy end
        steps = steps + 1
    end
end

-- Checks if a tile blocks projectiles or not
local function is_passable(pos)
    local tile_type = dfhack.maps.getTileType(pos)
    if not tile_type then return false end
    local shape = df.tiletype.attrs[tile_type].shape

    if shape == df.tiletype_shape.WALL then
        dfhack.println(string.format("  blocked at (%d,%d) tiletype=%s shape=%s",
            pos.x, pos.y,
            tile_type and df.tiletype[tile_type] or "nil",
            df.tiletype_shape[shape] or "nil"))
        -- Fortifications are walls but passable to projectiles
        local special = df.tiletype.attrs[tile_type].special
        return special == df.tiletype_special.FORTIFICATION
    end

    return shape == df.tiletype_shape.FLOOR
        or shape == df.tiletype_shape.OPEN_SPACE
        or shape == df.tiletype_shape.RAMP_TOP
        or shape == df.tiletype_shape.ENDLESS_PIT
end

local function angle_to_half_width(cone_angle_radians, range)
    return math.tan(cone_angle_radians / 2) * range
end

local function scorch_grass(x, y, oz)
    local block = dfhack.maps.getTileBlock(x, y, oz)
    if not block then return false end
    local lx, ly = x % 16, y % 16
    local tiletype = block.tiletype[lx][ly]
    local material = df.tiletype.attrs[tiletype].material
    if not GRASS_MATERIALS[material] then return false end
    -- Convert to a random ash tiletype
    block.tiletype[lx][ly] = ASH_TILETYPES[math.random(#ASH_TILETYPES)]
    return true
end

local function spawn_contained_fire(pos, oz, density)
    local block = dfhack.maps.getTileBlock(pos.x, pos.y, oz)
    local before = block and #block.flows or 0
 
    dfhack.maps.spawnFlow(pos, df.flow_type.Fire, -1, -1, density)
 
    if block then
        for i = before, #block.flows - 1 do
            local flow = block.flows[i]
            if flow.type == df.flow_type.Fire then
                flow.expanding = false -- Prevent spreading
            end
        end
    end
end

local function spawn_fire_cone(origin_pos, n_dir_x, n_dir_y, range, half_width)
    local ox = origin_pos.x
    local oy = origin_pos.y
    local oz = origin_pos.z
    local px, py = -n_dir_y, n_dir_x

    -- Spawn smoke on shooter
    dfhack.maps.spawnFlow(xyz2pos(ox, oy, oz), df.flow_type.Smoke, -1, -1, SMOKE_FLOW_DENSITY)

    -- Track visited positions to avoid duplicate fire spawns
    local visited = {}
    -- Cache inverse range for density calculation
    local inv_range = 1 / range
    -- Track units that were burned to extinguish them later
    local burned_unit_ids = {}
    local function fire_callback(x, y, steps)
        -- Initialize row if not exists
        if not visited[x] then visited[x] = {} end
        -- visited[x][y] states:
        -- nil: Not processed yet
        -- true: Passable tile with fire
        -- false: Obstacle/invalid tile (blocks fire)
        if visited[x][y] ~= nil then return visited[x][y] end
        
        local pos = xyz2pos(x, y, oz)
        if not dfhack.maps.isValidTilePos(pos) then
            visited[x][y] = false
            return false
        end
        if not is_passable(pos) then
            -- Block fire, spawn smoke
            dfhack.maps.spawnFlow(pos, df.flow_type.Smoke, -1, -1, SMOKE_FLOW_DENSITY)
            visited[x][y] = false
            return false
        end
        -- Density drops exponentially with distance
        local density = math.max(MIN_FIRE_FLOW_DENSITY, FIRE_FLOW_DENSITY * (1 - steps * inv_range)^2 // 1)

        -- Track any units standing in the fire right now to extinguish them later
        local units_here = dfhack.units.getUnitsInBox(x, y, oz, x, y, oz)
        for _, unit in ipairs(units_here) do
            burned_unit_ids[unit.id] = true
        end

        scorch_grass(x, y, oz)
        spawn_contained_fire(pos, oz, density)
        dfhack.println(string.format("  fire at (%d,%d) steps=%d density=%d", x, y, steps, density))
        visited[x][y] = true
        return true
    end

    -- For each ray in the cone:
    for w = -half_width, half_width do
        local far_x = math.floor(ox + n_dir_x * range + px * w + 0.5)
        local far_y = math.floor(oy + n_dir_y * range + py * w + 0.5)
        dfhack.println(string.format("  ray w=%d far=(%d,%d)", w, far_x, far_y))
        bresenham_line(ox, oy, far_x, far_y, range, fire_callback)
    end

    -- Extinguish any fires after BURN_DURATION ticks
    dfhack.timeout(BURN_DURATION, 'ticks', function()
        -- Extinguish tiles
        for x, row in pairs(visited) do
            for y, passable in pairs(row) do
                if passable then
                    extinguish.extinguishLocation(x, y, oz)
                end
            end
        end
        -- Extinguish tracked units wherever they now are
        for unit_id in pairs(burned_unit_ids) do
            local unit = df.unit.find(unit_id)
            if unit then
                extinguish.extinguishUnit(unit)
            end
        end
    end)
end

-- Flag the projectile for deletion and flag its item for garbage collection
local function consume_projectile(projectile)
    projectile.flags.to_be_deleted = true
    -- TODO: Check if this is really necessary
    if projectile.item then
        projectile.item.flags.garbage_collect = true
    end
end

-- TODO: Use custom raws for this?
local function get_weapon_range(weapon_id)
    if weapon_id == -1 then return DEFAULT_RANGE end
    local weapon = df.item.find(weapon_id)
    if not weapon then return DEFAULT_RANGE end
    local token = utils.get_subtype_token(weapon)
    return (token and WEAPON_RANGES[token]) or DEFAULT_RANGE
end

local function get_direction(projectile)
    local dx = projectile.target_pos.x - projectile.origin_pos.x
    local dy = projectile.target_pos.y - projectile.origin_pos.y
    local mag = math.sqrt(dx * dx + dy * dy)
    if mag < 1 then return nil end
    return dx / mag, dy / mag
end

local function on_projectile_move(projectile)
    if handled_projectiles[projectile.id] then return end
    if not projectile.item then return end
    if projectile.item:getType() ~= df.item_type.AMMO then return end
    if utils.get_subtype_token(projectile.item) ~= FUEL_AMMO_TOKEN then return end

    local nx, ny = get_direction(projectile)
    if not nx then return end

    handled_projectiles[projectile.id] = true

    local range = get_weapon_range(projectile.bow_id)
    local half_width = math.floor(angle_to_half_width(CONE_ANGLE_RADIANS, range))

    dfhack.println(string.format(
        "id=%d origin=(%d,%d) target=(%d,%d) dir=(%.2f,%.2f)",
        projectile.id,
        projectile.origin_pos.x, projectile.origin_pos.y,
        projectile.target_pos.x, projectile.target_pos.y,
        nx or 0, ny or 0
    ))

    dfhack.println(string.format("range=%d half_width=%d", range, half_width))

    spawn_fire_cone(projectile.origin_pos, nx, ny, range, half_width)
    consume_projectile(projectile)
end

function onEnable()
    handled_projectiles = {}
    eventful.onProjItemCheckMovement[CALLBACK_ID] = on_projectile_move
end

function onDisable()
    handled_projectiles = {}
    eventful.onProjItemCheckMovement[CALLBACK_ID] = nil
end