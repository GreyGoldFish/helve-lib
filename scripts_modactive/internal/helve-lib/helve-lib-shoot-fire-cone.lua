--@ module=true

local extinguish = dfhack.reqscript("extinguish")

local utils = dfhack.reqscript("internal/helve-lib/helve-lib-utils")

local FIRE_FLOW_DENSITY = 1000
local MIN_FIRE_FLOW_DENSITY = 100
local SMOKE_FLOW_DENSITY = 20
local CALLBACK_ID = "helve-lib-shoot-fire-cone"
local FUEL_AMMO_TOKEN = "ITEM_AMMO_FIRE_CHARGE"
local DEFAULT_RANGE = 8 -- Below this dwarves will try to shoot while out of range
local WEAPON_RANGES = {
    ["ITEM_WEAPON_FIRE_LANCE"] = DEFAULT_RANGE,
}
local CONE_ANGLE_RADIANS = math.rad(60)
local BURN_DURATION = 150
local PROJECTILE_CLEANUP_DURATION = 150
local EXTINGUISH_RADIUS = 2

local math = math
local floor = math.floor
local sqrt = math.sqrt
local tan = math.tan
local max = math.max

local dfhack = dfhack
local maps = dfhack.maps
local spawnFlow = maps.spawnFlow
local isValidTilePos = maps.isValidTilePos

local handled_projectiles = {}

-- TODO: Can fire lances be added to world gen?
-- TODO: Add a chance for fire lances to break with every shot based on material

-- Returns the area that should be extinguished based on the units that were affected
local function get_extinguish_unit_area(units)
    local extinguish_area = {}
    
    for _, unit in pairs(units) do
        if unit and unit.id then
            -- Extinguish unit immediately
            extinguish.extinguishUnit(unit)
            
            -- Get area in radius around unit
            for dx = -EXTINGUISH_RADIUS, EXTINGUISH_RADIUS do
                for dy = -EXTINGUISH_RADIUS, EXTINGUISH_RADIUS do
                    local cx, cy = unit.pos.x + dx, unit.pos.y + dy
                    -- Only extinguish non-dry grass tiles
                    if utils.is_xyz_grass(cx, cy, unit.pos.z)
                    and not utils.is_xyz_dry_grass(cx, cy, unit.pos.z) then
                        if not extinguish_area[cx] then extinguish_area[cx] = {} end
                        extinguish_area[cx][cy] = true
                    end
                end
            end
        end
    end

    return extinguish_area
end

-- Returns the area that should be extinguished based on the visited tiles
local function get_extinguish_tile_area(visited)
    local extinguish_area = {}
    
    for x, row in pairs(visited) do
        for y, tile_state in pairs(row) do
            -- tile_state == true means the tile is passable and has fire
            if tile_state == true then
                if not extinguish_area[x] then extinguish_area[x] = {} end
                extinguish_area[x][y] = true
            end
        end
    end
    
    return extinguish_area
end

-- Extinguish all locations in the provided area
local function extinguish_area(area, z)
    for x, row in pairs(area) do
        for y, _ in pairs(row) do
            extinguish.extinguishLocation(x, y, z)
            utils.debug_println("Extinguishing location at (%d,%d,%d)", x, y, z)
        end
    end
end

local function spawn_fire_cone(origin_pos, n_dir_x, n_dir_y, range, half_width)
    local ox, oy, oz = origin_pos.x, origin_pos.y, origin_pos.z
    local px, py = -n_dir_y, n_dir_x

    -- Spawn smoke on shooter
    spawnFlow(xyz2pos(ox, oy, oz), df.flow_type.Smoke, -1, -1, SMOKE_FLOW_DENSITY)

    -- Track visited positions to avoid duplicate fire spawns
    local visited = {}
    -- Cache inverse range for density calculation
    local inv_range = 1 / range
    -- Collect scheduled spawns, deduplicated by position
    -- Multiple rays may hit the same tile; keep the closest hit (highest density)
    local scheduled = {}

    local function collect_callback(x, y, steps)
        -- Initialize row if not exists
        if not visited[x] then visited[x] = {} end
        -- visited[x][y] states:
        -- nil: Not processed yet
        -- true: Passable tile with fire
        -- false: Obstacle/invalid tile (blocks fire)
        if visited[x][y] ~= nil then return visited[x][y] end

        local pos = xyz2pos(x, y, oz)
        if not isValidTilePos(pos) then
            -- Invalid tile, skip
            visited[x][y] = false
            -- Stop the ray
            return false
        end
        if not utils.is_passable(pos) then
            -- Obstacle, block fire
            spawnFlow(pos, df.flow_type.Smoke, -1, -1, SMOKE_FLOW_DENSITY)
            visited[x][y] = false
            -- Stop the ray
            return false
        end

        -- Check if tile already has fire
        if utils.is_xyz_on_fire(x, y, oz) then
            -- Tile already has fire, mark as existing and skip
            visited[x][y] = "existing"
            -- Continue tracing the line to the next tile
            return true
        end

        local key = x .. "," .. y
        if not scheduled[key] then
            -- Calculate density based on distance
            local density = max(MIN_FIRE_FLOW_DENSITY,
                floor(FIRE_FLOW_DENSITY * (1 - steps * inv_range)^2))
            scheduled[key] = {x = x, y = y, steps = steps, density = density}
        end

        -- Tile was processed successfully
        visited[x][y] = true
        -- Continue tracing the line to the next tile
        return true
    end

    -- For each ray in the cone
    for w = -half_width, half_width do
        local far_x = floor(ox + n_dir_x * range + px * w + 0.5)
        local far_y = floor(oy + n_dir_y * range + py * w + 0.5)
        utils.bresenham_line(ox, oy, far_x, far_y, range, collect_callback)
    end

    -- Track units that were affected
    local affected_units = {}

    -- Fire propagates outward; i.e. step 1 tiles appear first, step N tiles appear last
    -- e.g.: with range=3 the cone resolves in 3 ticks
    for _, s in pairs(scheduled) do
        local x, y, steps, density = s.x, s.y, s.steps, s.density
        dfhack.timeout(steps, 'ticks', function()
            -- Check for units first (units only exist on passable tiles)
            local units_here = dfhack.units.getUnitsInBox(x, y, oz, x, y, oz)
            for _, unit in ipairs(units_here) do
                affected_units[unit.id] = unit
            end
            
            -- Only check passability if no units were found
            if #units_here == 0 then
                local pos = xyz2pos(x, y, oz)
                if utils.is_passable(pos) then
                    utils.spawn_contained_fire_flow(pos, oz, density)
                end
            else
                -- Unit present, tile must be passable, spawn fire flow
                local pos = xyz2pos(x, y, oz)
                utils.spawn_contained_fire_flow(pos, oz, density)
            end
        end)
    end

    dfhack.timeout(BURN_DURATION, 'ticks', function()
        -- Get extinguish areas from affected units and tiles
        local unit_radius_area = get_extinguish_unit_area(affected_units)
        local fire_tile_area = get_extinguish_tile_area(visited)
        
        -- Merge the areas
        local combined_area = {}
        
        -- Add unit radius areas
        for x, row in pairs(unit_radius_area) do
            if not combined_area[x] then combined_area[x] = {} end
            for y, _ in pairs(row) do
                combined_area[x][y] = true
            end
        end
        
        -- Add fire tile areas
        for x, row in pairs(fire_tile_area) do
            if not combined_area[x] then combined_area[x] = {} end
            for y, _ in pairs(row) do
                combined_area[x][y] = true
            end
        end
        
        -- Extinguish everything
        extinguish_area(combined_area, oz)
    end)

    utils.debug_println("spawn_fire_cone: Spawned fire cone from (%d,%d,%d) range=%d half_width=%d",
        ox, oy, oz, range, half_width)
end

function onProjItemCheckMovement(projectile)
    if handled_projectiles[projectile.id] then return end
    if not projectile.item or projectile.item:getType() ~= df.item_type.AMMO then return end
    local token = utils.get_subtype_token(projectile.item)
    if token ~= FUEL_AMMO_TOKEN then return end

    local origin_pos = projectile.origin_pos
    local target_pos = projectile.target_pos
    local dx = target_pos.x - origin_pos.x
    local dy = target_pos.y - origin_pos.y
    local mag = sqrt(dx * dx + dy * dy)
    if mag < 1 then return end

    utils.debug_println("Handled projectile %d with token %s", 
        projectile.id, token or "nil")

    handled_projectiles[projectile.id] = true
    -- Clean up to prevent memory leak
    dfhack.timeout(PROJECTILE_CLEANUP_DURATION, 'ticks', function()
        handled_projectiles[projectile.id] = nil
    end)

    projectile.flags.to_be_deleted = true
    projectile.item.flags.garbage_collect = true

    local weapon = df.item.find(projectile.bow_id)
    token = weapon and utils.get_subtype_token(weapon)
    local range = WEAPON_RANGES[token] or DEFAULT_RANGE

    if mag > range then
        utils.debug_println("Shot is out-of-range (dist=%.1f > range=%d)", mag, range)
    end

    local nx, ny = dx / mag, dy / mag
    local half_width = floor(tan(CONE_ANGLE_RADIANS / 2) * range)

    spawn_fire_cone(origin_pos, nx, ny, range, half_width)
end

function onEnable()
    handled_projectiles = {}
end

function onDisable()
    handled_projectiles = {}
end
