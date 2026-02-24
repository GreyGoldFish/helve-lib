--@ module=true
--@ enable=true
 
--[====[
helve-lib
===========================
 
Tags: gameplay | military
 
Attaches item powers to items based on custom raw tokens.

Usage
-----

    enable helve-lib
    disable helve-lib
]====]

local repeatUtil = require('repeat-util')
local utils = require('utils')
local customRawTokens = require('custom-raw-tokens')

local attach_item_powers = dfhack.reqscript("internal/helve-lib/attach-item-powers")

local GLOBAL_KEY = 'helve-lib'

local function get_default_state()
    return {
        enabled=true,
    }
end

state = state or get_default_state()

-- implement the enabled API so DFHack can read this script's status
function isEnabled()
    return state.enabled
end

-- call this whenever the contents of the state table changes
local function persist_state()
    dfhack.persistent.saveSiteData(GLOBAL_KEY, state)
end

local function do_enable()
    attach_item_powers.onEnable()

    repeatUtil.scheduleEvery(GLOBAL_KEY .. " every tick", 1000, 'ticks', function()
        attach_item_powers.everyTick()
    end)
    
    dfhack.println("Enabled " .. GLOBAL_KEY)
end

local function do_disable()
    attach_item_powers.onDisable()

    repeatUtil.cancel(GLOBAL_KEY .. " every tick")

    dfhack.println("Disabled " .. GLOBAL_KEY)
end

dfhack.onStateChange[GLOBAL_KEY] = function(state_change)
    if state_change == SC_MAP_UNLOADED then
        do_disable()

        -- ensure our mod doesn't run when a different
        -- world is loaded where we are *not* active
        dfhack.onStateChange[GLOBAL_KEY] = nil

        return
    end

    if state_change ~= SC_MAP_LOADED or not (dfhack.world.isFortressMode() or dfhack.world.isArena() or dfhack.world.isAdventureMode()) then
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
    local current_df_version = dfhack.getDFVersion():sub(2, -1):gsub("[ -].+$", "") -- Remove v and extra info, leaving only the numbers
	if consts.DFVersion ~= current_df_version then
		dialogs.showMessage("Error",
			"This version of " .. GLOBAL_KEY .. " is for DF version " .. consts.DFVersion .. ",\n" ..
			"current DF version is " .. current_df_version .. ". The script will now disable.\n" ..
			"Behaviour may break."
		)
		disable()
		return
	end
    state.enabled = true
    do_enable()
else
    state.enabled = false
    do_disable()
end

persist_state()