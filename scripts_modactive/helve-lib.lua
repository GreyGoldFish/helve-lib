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

-- DFHack modules
local eventful = require('plugins.eventful')
local repeatUtil = require('repeat-util')
local utils = require('utils')

-- Internal modules
local insert_item_powers = dfhack.reqscript("internal/helve-lib/insert-item-powers")
local shoot_fireball = dfhack.reqscript("internal/helve-lib/shoot-fireball")
local shoot_fire_cone = dfhack.reqscript("internal/helve-lib/helve-lib-shoot-fire-cone")

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
    shoot_fire_cone.onEnable()

    eventful.onProjItemCheckMovement[GLOBAL_KEY] = function(...)
        shoot_fire_cone.onProjItemCheckMovement(...)
    end
    
    dfhack.println("Enabled " .. GLOBAL_KEY)
end

local function do_disable()
    -- Call any shutdown functions the internal scripts might require
    shoot_fire_cone.onDisable()

    eventful.onProjItemCheckMovement[GLOBAL_KEY] = nil

    repeatUtil.cancel(GLOBAL_KEY)

    dfhack.println("Disabled " .. GLOBAL_KEY)
end

local function get_default_state()
    return {
        enabled=true,
    }
end

-- Retrieve state saved in game. merge with default state so config
-- Saved from previous versions can pick up newer defaults.
-- Initialize state at module level
state = state or get_default_state()

-- Register state change handler
dfhack.onStateChange[GLOBAL_KEY] = function(state_change)
    if state_change == SC_MAP_UNLOADED then
        do_disable()
        -- ensure our mod doesn't run when a different
        -- world is loaded where we are *not* active
        dfhack.onStateChange[GLOBAL_KEY] = nil
        return
    end

    if state_change ~= SC_MAP_LOADED then
        return
    end

    -- retrieve state saved in game. merge with default state so config
    -- saved from previous versions can pick up newer defaults.
    state = get_default_state()
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