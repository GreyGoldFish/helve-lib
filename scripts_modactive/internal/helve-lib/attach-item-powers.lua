--@ module=true

-- Cache IDs
local fire_lance_item_def = nil
local shoot_fire_interaction_index = nil

-- TODO: Use custom-raw-tokens to find the IDs
local function initialize_ids()
    -- Return true if IDs are already initialized
    if fire_lance_item_def and shoot_fire_interaction_index then
        return true
    end

    -- Find the fire lance item def
    -- TODO: Use custom-raw-tokens to find it
    for _, def in ipairs(df.global.world.raws.itemdefs.weapons) do
        if def.id == "FIRE_LANCE" then
            fire_lance_item_def = def
            break
        end
    end

    -- Find the interaction index of the power
    -- TODO: Use custom-raw-tokens to find it
    for i, interaction in ipairs(df.global.world.raws.interactions.all) do
        if interaction.name == "SHOOT_FIRE_ITEM_POWER" then
            dfhack.println("Found interaction: " .. tostring(interaction.name) .. " (ID: " .. tostring(interaction.id) .. ")")
            shoot_fire_interaction_index = i
            break
        end
    end

    dfhack.println("ID initialization - fire lance item def: " .. tostring(fire_lance_item_def) .. ", Interaction index: " .. tostring(shoot_fire_interaction_index))
    return (fire_lance_item_def and shoot_fire_interaction_index)
end

-- Called when the state changes
function onStateChange(state_change)
    -- Initialize IDs on map load
    if state_change == SC_MAP_LOADED then
        initialize_ids()
    end
    if state_change == SC_MAP_UNLOADED then
        -- Reset IDs when map is unloaded
        fire_lance_item_def = nil
        shoot_fire_interaction_index = nil
    end
end

-- TODO: Make this generic
-- TODO: Doesn't work when reloading map; more testing is required
local function process_fire_lance(item)
    -- If the 'magic' pointer is null, allocate it
    if df.isnull(item.magic) then
        item.magic = {
            new = true,
            power = {
                new = true,
                resize = true,
            },
        }
        dfhack.println("Allocated magic structure for " .. item.id)
    end

    -- Check if the item already has the power
    if item.magic and item.magic.power then
        for _, power in ipairs(item.magic.power) do
            if power.interaction_index == shoot_fire_interaction_index then
                return -- Already has power
            end
        end

        -- Attach the power
        local new_power = {
            new = true,
            interaction_index = shoot_fire_interaction_index,
            interaction_source_index = 0,
            delay = 0,
        }
        item.magic.power:insert('#', new_power)
        dfhack.println("Successfully attached power to " .. item.id)
    else
        dfhack.println("Error: item.magic.power is nil or invalid for " .. item.id)
    end
end

-- Called every tick
function everyTick()
    -- TODO: Make this generic
    if not (fire_lance_item_def and shoot_fire_interaction_index) then
        return
    end

    local fire_lance_count = 0
    local processed_count = 0

    -- Iterate over all weapons
    -- TODO: Make this generic
    for _, item in ipairs(df.global.world.items.other.WEAPON) do
        if item.subtype == fire_lance_item_def then
            fire_lance_count = fire_lance_count + 1
            process_fire_lance(item)
            processed_count = processed_count + 1
        end
    end
end

-- Called when mod is enabled
function onEnable()
end

-- Called when mod is disabled
function onDisable()
end
