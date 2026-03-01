--@ module=true

local eventful = require('plugins.eventful')
local extinguish = dfhack.reqscript("extinguish")
local utils = dfhack.reqscript("internal/helve-lib/helve-lib-utils")

-- TODO: Replace me
local FUEL_AMMO_TOKEN = ""
local DEFAULT_RANGE = 8
local WEAPON_RANGES = {
    ["ITEM_WEAPON_FIRE_LANCE"] = DEFAULT_RANGE,
}
-- Set to 0 until I can figure out how (if) it works
local MAGICAL_PROJECTILE_DAMAGE = 0
local EXTINGUISH_RADIUS = 3
local EXTINGUISH_DELAY = 50     -- Ticks before surrounding area is extinguished
local IMPACT_BURN_DURATION = 200 -- Ticks before impact tile itself is extinguished
local CALLBACK_ID = "helve-lib-shoot-fireball"

local magic_projectiles = {}
local magic_projectile_positions = {}
local world_active = false

-- TODO: Use custom raws for this?
local function get_weapon_range(weapon_id)
    if weapon_id == -1 then return DEFAULT_RANGE end
    local weapon = df.item.find(weapon_id)
    if not weapon then return DEFAULT_RANGE end
    local token = utils.get_subtype_token(weapon)
    return (token and WEAPON_RANGES[token]) or DEFAULT_RANGE
end

local function insert_into_proj_list(proj)
    -- Create a new list link node and attach it to the projectile
    local new_link = df.proj_list_link:new()
    new_link.item = proj
    proj.link = new_link

    -- Walk to the last node in the list
    local last = df.global.world.projectiles.all
    while last.next ~= nil do
        last = last.next
    end

    -- Attach the new link to the end of the list
    last.next = new_link
    new_link.prev = last
    new_link.next = nil
end

local function extinguish_area(pos)
    -- Extinguish surrounding area after EXTINGUISH_DELAY
    dfhack.timeout(EXTINGUISH_DELAY, 'ticks', function()
        if not world_active then return end
        for dx = -EXTINGUISH_RADIUS, EXTINGUISH_RADIUS do
            for dy = -EXTINGUISH_RADIUS, EXTINGUISH_RADIUS do
                local x, y, z = pos.x + dx, pos.y + dy, pos.z
                if (dx ~= 0 or dy ~= 0) and dfhack.maps.isValidTilePos(xyz2pos(x, y, z)) then
                    extinguish.extinguishLocation(x, y, z)
                end
            end
        end
    end)

    -- Extinguish impact tile after longer duration
    dfhack.timeout(IMPACT_BURN_DURATION, 'ticks', function()
        if not world_active then return end
        extinguish.extinguishLocation(pos.x, pos.y, pos.z)
    end)
end

local function find_projectile(id)
    local node = df.global.world.projectiles.all.next
    while node ~= nil do
        if node.item and node.item.id == id then
            return node.item
        end
        node = node.next
    end
    return nil
end

local function watch_magic_projectile(id)
    if not world_active or not magic_projectiles[id] then return end

    local proj = find_projectile(id)
    if proj then
        magic_projectile_positions[id] = xyz2pos(
            proj.cur_pos.x, proj.cur_pos.y, proj.cur_pos.z
        )
        dfhack.timeout(1, 'ticks', function()
            watch_magic_projectile(id)
        end)
    else
        local pos = magic_projectile_positions[id]
        magic_projectiles[id] = nil
        magic_projectile_positions[id] = nil
        if pos then
            -- TODO: Don't extinguish fire that wasn't made by me
            extinguish_area(pos)
        end
    end
end

local function create_magic_projectile(projectile)
    local firer = projectile.firer
    local target_pos = projectile.target_pos

    local id = df.global.proj_next_id
    df.global.proj_next_id = id + 1

    if magic_projectiles[id] then
        dfhack.printerr("helve-lib: projectile ID collision at " .. id)
        return nil
    end

    local magic_proj = df.proj_magicst:new()
    magic_proj.id = id
    magic_proj.firer = firer
    magic_proj.origin_pos.x = firer.pos.x
    magic_proj.origin_pos.y = firer.pos.y
    magic_proj.origin_pos.z = firer.pos.z
    magic_proj.target_pos.x = target_pos.x
    magic_proj.target_pos.y = target_pos.y
    magic_proj.target_pos.z = target_pos.z
    magic_proj.cur_pos.x = firer.pos.x
    magic_proj.cur_pos.y = firer.pos.y
    magic_proj.cur_pos.z = firer.pos.z
    magic_proj.prev_pos.x = firer.pos.x
    magic_proj.prev_pos.y = firer.pos.y
    magic_proj.prev_pos.z = firer.pos.z
    magic_proj.velocity = projectile.velocity
    magic_proj.fall_threshold = get_weapon_range(projectile.bow_id)
    magic_proj.fall_delay = 0
    magic_proj.fall_counter = 0
    magic_proj.hit_rating = projectile.hit_rating
    magic_proj.type = df.proj_magic_type.FIREBALL
    magic_proj.damage = MAGICAL_PROJECTILE_DAMAGE

    insert_into_proj_list(magic_proj)

    magic_projectiles[id] = magic_proj
    magic_projectile_positions[id] = xyz2pos(firer.pos.x, firer.pos.y, firer.pos.z)
    watch_magic_projectile(id)
    return magic_proj
end

local function consume_projectile(projectile)
    projectile.flags.to_be_deleted = true
    if projectile.item then
        projectile.item.flags.garbage_collect = true
    end
end

local function on_projectile_move(projectile)
    if projectile.flags.to_be_deleted then return end
    if not projectile.item then return end
    if projectile.item:getType() ~= df.item_type.AMMO then return end
    local token = utils.get_subtype_token(projectile.item)
    if token ~= FUEL_AMMO_TOKEN then return end

    create_magic_projectile(projectile)
    consume_projectile(projectile)
end

dfhack.onStateChange[CALLBACK_ID] = function(code)
    if code == SC_WORLD_UNLOADED then
        world_active = false
        magic_projectiles = {}
        magic_projectile_positions = {}
    end
end

function onEnable()
    world_active = true
    magic_projectiles = {}
    magic_projectile_positions = {}
    eventful.onProjItemCheckMovement[CALLBACK_ID] = on_projectile_move
end

function onDisable()
    world_active = false
    magic_projectiles = {}
    magic_projectile_positions = {}
    eventful.onProjItemCheckMovement[CALLBACK_ID] = nil
end