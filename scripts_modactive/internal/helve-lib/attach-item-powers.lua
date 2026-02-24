--@ module=true

-- Called when mod is enabled
function onEnable()
end

-- Called when mod is disabled
function onDisable()
end

-- Cache IDs to avoid looking up strings every tick
local fire_lance_subtype = nil
local shoot_fire_interaction_index = nil

-- TODO: Use custom-raw-tokens to find the IDs
local function initialize_ids()
    dfhack.println("=== Available weapons ===")
    for i, def in ipairs(df.global.world.raws.itemdefs.weapons) do
        dfhack.println(i .. ": " .. def.id .. " (subtype: " .. def.subtype .. ")")
    end
    dfhack.println("=== End weapons ===")

    dfhack.println("=== Available interactions ===")
    for i, inter in ipairs(df.global.world.raws.interactions.all) do
        dfhack.println(i .. ": " .. inter.name)
    end
    dfhack.println("=== End interactions ===")

    if fire_lance_subtype and shoot_fire_interaction_index then
        return true
    end

    -- find the fire lance subtype
    for _, def in ipairs(df.global.world.raws.itemdefs.weapons) do
        if def.id == "FIRE_LANCE" then
            fire_lance_subtype = def.subtype
            break
        end
    end

    -- Find the interaction index of the power
    for i, interaction in ipairs(df.global.world.raws.interactions.all) do
        if interaction.name == "SHOOT_FIRE_ITEM_POWER" then
            shoot_fire_interaction_index = i
            break
        end
    end

    return (fire_lance_subtype and shoot_fire_interaction_index)
end

-- Called every tick
function everyTick()
    dfhack.println("=== SCRIPT RUNNING: " .. os.date() .. " ===")
    dfhack.println("Game mode: " .. (dfhack.world.isFortressMode() and "Fortress" or "Arena" or "Adventure" or "Unknown"))
    dfhack.println("Map loaded: " .. tostring(dfhack.isMapLoaded()))

    dfhack.println("fire_lance_subtype: " .. tostring(fire_lance_subtype))
    dfhack.println("shoot_fire_interaction_index: " .. tostring(shoot_fire_interaction_index))

    if not initialize_ids() then
        dfhack.println("Failed to initialize IDs")
        return
    end

    dfhack.println("Processing weapons...")
    local weapon_count = 0
    local magic_allocated = 0
    local power_attached = 0

    -- TODO: Check for item subtype
    for _, item in ipairs(df.global.world.items.other.WEAPON) do
        weapon_count = weapon_count + 1

        -- If the 'magic' pointer is null, allocate it
        if df.isnull(item.magic) then
            item.magic = {
                new = true,
                power = {
                    new = true,
                    resize = true,
                },
            }
            magic_allocated = magic_allocated + 1
            dfhack.println("Allocated magic for item: " .. item.id)
        end

        -- Check if the item already has the power
        local has_power = false
        if item.magic and item.magic.power then
            for _, power in ipairs(item.magic.power) do
                if power.interaction_index == shoot_fire_interaction_index then
                    has_power = true
                    break
                end
            end
        end

        -- If it doesn't have it, attach it
        if not has_power and item.magic and item.magic.power then
            local new_power = {
                new = true,
                -- The index of the interaction in the interactions.raws table
                interaction_index = shoot_fire_interaction_index,
                -- The index of the source in the interaction
                interaction_source_index = 0,
                -- The delay in ticks before the power can be used
                delay = 0,
            }
            -- Insert the new power at the end of the magic power vector
            item.magic.power:insert('#', new_power)
            power_attached = power_attached + 1
            dfhack.println("Attached power to item: " .. item.id)
        end
    end

    dfhack.println("Processed " .. weapon_count .. " weapons")
    dfhack.println("Allocated magic for " .. magic_allocated .. " items")
    dfhack.println("Attached power to " .. power_attached .. " items")
end