--@ module=true

-- cached globals for perf
local dfhack = dfhack
local df = df
local maps = dfhack.maps
local spawnFlow = maps.spawnFlow
local getTileBlock = maps.getTileBlock
local getTileType = maps.getTileType
local abs = math.abs

-- Turn DEBUG off before release
local DEBUG = true
function debug_println(...)
    if DEBUG then
        local args = {...}
        if #args > 0 then
            dfhack.println("[DEBUG] " .. string.format(...))
        end
    end
end

--- Return the subtype token string for an item, or nil if none.
function get_subtype_token(item)
    if not item then
        debug_println("get_subtype_token: Invalid item")
        return nil
    end
    local subtype_id = item:getSubtype()
    if subtype_id == -1 then
        debug_println("get_subtype_token: Invalid subtype")
        return nil
    end
    local def = dfhack.items.getSubtypeDef(item:getType(), subtype_id)
    debug_println("get_subtype_token: %s", def and def.id or "nil")
    return def and def.id or nil
end

--- Bresenham ray from (ox,oy) -> (tx,ty). 'range' caps steps. callback(x,y,step) -> true to continue
function bresenham_line(ox, oy, tx, ty, range, callback)
    local dx, dy = abs(tx - ox), abs(ty - oy)
    local sx = ox < tx and 1 or -1
    local sy = oy < ty and 1 or -1
    local err = dx - dy
    local x, y = ox, oy
    local steps = 0

    debug_println("bresenham_line: from (%d,%d) -> (%d,%d) steps=%d",
        ox, oy, tx, ty, steps)

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

--- Returns true when the tile at 'pos' is passable for projectile/fire.
function is_passable(pos)
    local tile_type = getTileType(pos)
    if not tile_type then
        debug_println("is_passable: Invalid tile at (%d,%d,%d)", pos.x, pos.y, pos.z)
        return false
    end
    local attrs = df.tiletype.attrs[tile_type]
    local shape = attrs.shape
    if shape == df.tiletype_shape.WALL then
        local special = attrs.special
        return special == df.tiletype_special.FORTIFICATION
    end
    return shape == df.tiletype_shape.FLOOR
        or shape == df.tiletype_shape.OPEN_SPACE
        or shape == df.tiletype_shape.RAMP_TOP
        or shape == df.tiletype_shape.ENDLESS_PIT
end

--- Spawn a contained fire flow and flag it as non-expanding.
--- pos = df.coord-like table {x,y,z}; oz is z, density an int
function spawn_contained_fire_flow(pos, oz, density)
    local block = getTileBlock(pos.x, pos.y, oz)
    local before = block and #block.flows or 0

    spawnFlow(pos, df.flow_type.Fire, -1, -1, density)

    if block then
        for i = before, #block.flows - 1 do
            local flow = block.flows[i]
            if flow and flow.type == df.flow_type.Fire then
                flow.expanding = false -- Prevents spread
            end
        end
    end

    debug_println("spawn_contained_fire_flow: Spawned fire at (%d,%d,%d) density=%d", pos.x, pos.y, pos.z, density)
end

local function get_tile_material_at(x, y, z)
    local pos = xyz2pos(x, y, z)
    local tile_type = getTileType(pos)
    if not tile_type then
        debug_println("get_tile_material_at: Invalid tile at (%d,%d,%d)", x, y, z)
        return nil
    end
    return df.tiletype.attrs[tile_type].material
end

--- Returns true when the tile at (x,y,z) is a grass tile.
function is_xyz_grass(x, y, z)
    local material = get_tile_material_at(x, y, z)
    return material == df.tiletype_material.GRASS_LIGHT
        or material == df.tiletype_material.GRASS_DARK
        or material == df.tiletype_material.GRASS_DRY
        or material == df.tiletype_material.GRASS_DEAD
end

--- Returns true when the tile at (x,y,z) is an ash tile.
function is_xyz_ash(x, y, z)
    local material = get_tile_material_at(x, y, z)
    return material == df.tiletype_material.ASHES
end

function is_xyz_dry_grass(x, y, z)
    local material = get_tile_material_at(x, y, z)
    return material == df.tiletype_material.GRASS_DRY
end

-- Returns true when the unit is on fire.
function is_unit_on_fire(unit)
    for _, status in ipairs(unit.body.components.body_part_status) do
        if status.on_fire then
            debug_println("is_unit_on_fire: Unit %d is on fire", unit.id)
            return true
        end
    end
    debug_println("is_unit_on_fire: Unit %d is not on fire", unit.id)
    return false
end

function is_xyz_on_fire(x, y, z)
    local tile_block = getTileBlock(x, y, z)
    if not tile_block then
        debug_println("is_xyz_on_fire: Invalid tile block at (%d,%d,%d)", x, y, z)
        return false
    end
    local local_x = x % 16
    local local_y = y % 16
    if tile_block.tiletype[local_x][local_y] == df.tiletype['Fire'] then
        return true
    end
    return false
end

-- Count keys in a table
function count_keys(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

-- Get all keys from a table
function get_keys(t)
    local keys = {}
    for k in pairs(t) do table.insert(keys, k) end
    return keys
end