--@ module=true

local ITEM_SUBTYPE_TOKEN = "ITEM_WEAPON_FIRE_LANCE"
local INTERACTION_NAME = "SHOOT_FIRE_ITEM_POWER"

local interaction_index = nil

local handled = {}

local function get_subtype_token(item)
    local ok, def = pcall(function()
        return dfhack.items.getSubtypeDef(item:getType(), item:getSubtype())
    end)
    return (ok and def and def.id) or nil
end

-- Find the interaction index of the magic power
local function get_interaction_index(interaction_name)
    for i, interaction in ipairs(df.global.world.raws.interactions.all) do
        if interaction.name == interaction_name then
            return i
        end
    end
    dfhack.println(interaction_name .. " not found")

    return nil
end

-- Called when the state changes
function onStateChange(state_change)
    if state_change == SC_MAP_UNLOADED then
        -- Reset index when map is unloaded
        interaction_index = nil
    end
end

-- TODO: Doesn't work when reloading map; more testing is required
local function insert_magic_power_to_item(item)
    -- If the 'magic' pointer is null, allocate it
    if df.isnull(item.magic) then
        item.magic = {
            new = true,
            power = {
                new = true,
                resize = true,
            },
        }
    end

    -- Check if the item already has the power
    if item.magic and item.magic.power then
        for _, power in ipairs(item.magic.power) do
            if power.interaction_index == interaction_index then
                return -- Already has power
            end
        end

        -- Attach the power
        local new_power = {
            new = true,
            interaction_index = interaction_index,
            interaction_source_index = 0,
            delay = 0,
        }
        item.magic.power:insert('#', new_power)
    end
end

-- Called every tick
function everyTick()
    if not interaction_index then
        interaction_index = get_interaction_index(INTERACTION_NAME)
    end

    for _, item in ipairs(df.global.world.items.all) do
        if not handled[item.id] then
            local token = get_subtype_token(item)
            if token == ITEM_SUBTYPE_TOKEN then
                insert_magic_power_to_item(item)
            end
            handled[item.id] = true
        end
    end
end

-- Called when mod is enabled
function onEnable()
end

-- Called when mod is disabled
function onDisable()
end
