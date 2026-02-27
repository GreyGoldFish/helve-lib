--@ module=true

local utils = dfhack.reqscript("internal/helve-lib/utils")

-- TODO: Replace me
local ITEM_SUBTYPE_TOKEN = ""
local INTERACTION_NAME = "SHOOT_FIRE_ITEM_POWER"

local item_power_interaction_index = nil

-- TODO: Review this (memory leak?)
local handled_items = {}

local last_item_count = 0

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

-- Called when the state changes
function onStateChange(state_change)
    if state_change == SC_MAP_UNLOADED then
        -- Reset index when map is unloaded
        item_power_interaction_index = nil
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
            if power.interaction_index == item_power_interaction_index then
                return -- Already has power
            end
        end

        -- Attach the power
        local new_power = {
            new = true,
            interaction_index = item_power_interaction_index,
            interaction_source_index = 0,
            delay = 0,
        }
        item.magic.power:insert('#', new_power)
    end
end

-- Called every in-game tick
function everyTick()
    if not item_power_interaction_index then
        item_power_interaction_index = get_item_power_interaction_index(INTERACTION_NAME)
    end

    local current_item_count = #df.global.world.items.all
    if current_item_count == last_item_count then
        return
    end
    last_item_count = current_item_count

    for _, item in ipairs(df.global.world.items.all) do
        if not handled_items[item.id] then
            local token = utils.get_subtype_token(item)
            if token == ITEM_SUBTYPE_TOKEN then
                insert_magic_power_to_item(item)
            end
            handled_items[item.id] = true
        end
    end
end

-- Called when mod is enabled
function onEnable()
    item_power_interaction_index = nil
    handled_items = {}
end

-- Called when mod is disabled
function onDisable()
    item_power_interaction_index = nil
    handled_items = {}
end
