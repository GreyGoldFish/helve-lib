--@ module=true
--@ enable=true
 
--[====[
helve-lib
===========================
 
Tags: gameplay | military
 
Inserts item powers to items based on custom raw tokens.

Usage
-----

    enable helve-lib
    disable helve-lib
]====]

--[[
# DEBUGGING
- Check errorlog.txt
- Check stderr.log
- Check stdout.log
- Check lualog.log (if using DF Lua API)
--]]

-- TODO: I wonder if it's possible to make world generation understand that fire lances have powers

local repeatUtil = require('repeat-util')
local utils = require('utils')

local insert_item_powers = dfhack.reqscript("internal/helve-lib/insert-item-powers")
local shoot_fire = dfhack.reqscript("internal/helve-lib/shoot-fire")

local GLOBAL_KEY = 'helve-lib'

-- Implement the enabled API so DFHack can read this script's status
function isEnabled()
    return state.enabled
end

-- Call this whenever the contents of the state table changes
local function persist_state()
    dfhack.persistent.saveSiteData(GLOBAL_KEY, state)
end

local function do_enable()
    -- Do any initialization the internal scripts might require
    insert_item_powers.onEnable()
    shoot_fire.onEnable()

    repeatUtil.scheduleEvery(GLOBAL_KEY, 1, 'ticks', function()
        insert_item_powers.everyTick()
    end)
    
    dfhack.println("Enabled " .. GLOBAL_KEY)
end

local function do_disable()
    -- Call any shutdown functions the internal scripts might require
    insert_item_powers.onDisable()
    shoot_fire.onDisable()

    repeatUtil.cancel(GLOBAL_KEY)

    dfhack.println("Disabled " .. GLOBAL_KEY)
end

local function get_default_state()
    return {
        enabled=true,
    }
end

-- Register state change handler
dfhack.onStateChange[GLOBAL_KEY] = function(state_change)
    -- Forward state changes to internal modules
    if insert_item_powers.onStateChange then
        insert_item_powers.onStateChange(state_change)
    end
    
    if state_change == SC_MAP_UNLOADED then
        do_disable()
        return
    end

    -- TODO: Review this
    if state_change ~= SC_MAP_LOADED then
        return
    end

    -- Retrieve state saved in game. merge with default state so config
    -- Saved from previous versions can pick up newer defaults.
    state = state or get_default_state()
    utils.assign(state, dfhack.persistent.getSiteData(GLOBAL_KEY, state))
    if state.enabled then
        do_enable()
    end
end

-- TODO: Review this
if dfhack_flags.module then
    return
end

if not dfhack_flags.enable then
    dfhack.println(dfhack.script_help())
    dfhack.println()
    dfhack.println(string.format("%s is currently '%s'", GLOBAL_KEY, state.enabled and 'enabled' or 'disabled'))
    return
end

if dfhack_flags.enable_state then
    state.enabled = true
    do_enable()
else
    state.enabled = false
    do_disable()
end

persist_state()