if not core.settings:get("ecliptic_cycle.phase_offset") then
    core.settings:set("ecliptic_cycle.phase_offset", 3763156)
end

if not core.settings:get("ecliptic_cycle.update_timer") then
    core.settings:set("ecliptic_cycle.update_timer", 10)
end

if core.settings:get_bool("ecliptic_cycle.enable_event_messages") == nil then
    core.settings:set_bool("ecliptic_cycle.enable_event_messages", true)
end

ecliptic_cycle = {
    _VERSION = "1.3-i",
    phase_offset = tonumber(core.settings:get("ecliptic_cycle.phase_offset")),
    update_timer = tonumber(core.settings:get("ecliptic_cycle.update_timer")),
    enable_event_messages = core.settings:get_bool("ecliptic_cycle.enable_event_messages"),
    list_lunar_effects = "Registered Effects:", -- Cache the colorized effect list to be returned by /list_lunar_effects
    current_lunar_phase = 0, -- Unset. Server needs to start before it can be set.
    effect = {}, -- Current active effect. [1] = color1, [2] = color2, [3] = name/source, [4] = message
    major_event_threshold = 1.94, -- Threshold for registered effect events
    minor_event_threshold = 1.5, -- Threshold for random color variance events
    variance = 0.3, -- Variance for random color in minor events
}



local path = core.get_modpath(core.get_current_modname())
dofile(path.."/api.lua")
dofile(path.."/commands.lua")


ecliptic_cycle.register_effect("Frosted Rose",           "#4a2950", "#cb4c66",
"*** The Angel of music bids farewell...")
ecliptic_cycle.register_effect("Dusty Oranges",          "#533922", "#f58b3a",
"The fires of a forgotten heart burn bright tonight.")
ecliptic_cycle.register_effect("Frozen Blueberries",     "#535eae", "#c7c0dd",
"*** A bitter chill runs through your bones...")
ecliptic_cycle.register_effect("Penicillin",             "#4d4f39", "#bcaa84",
"*** The daylight decays, leaving naught but rot to take it's place...")
ecliptic_cycle.register_effect("Pumpkin",                "#5c3036", "#e26e4d",
"*** You look around and there's not a sign of hypocrisy. Nothing but sincerity as far as the eye can see.")
ecliptic_cycle.register_effect("Sol's Fury",             "#713600", "#c6a333",
"*** Witness the fury of the father.")
ecliptic_cycle.register_effect("Star Wars",              "#222441", "#555c65",
"*** You feel a great disturbance, as if millions of voices suddenly cried out in terror and then were silenced.")
ecliptic_cycle.register_effect("Weeping Bride",          "#136eb5", "#b1ddfa",
"*** The Weeping Depths tremble...")
ecliptic_cycle.register_effect("Spectre",                "#7100a0", "#b1ddfa",
"*** The terrible Spectre rises from her Crypt.")
ecliptic_cycle.register_effect("Blackmore's Night",      "#3a3b71", "#c272b1",
"*** Raise your hats and your glasses too, you will dance the whole night through, under a violet moon!")
ecliptic_cycle.register_effect("Doom",                   "#50002f", "#ff2f00",
"*** Ye have spilled blood unrighteously and have stained the land. For blood ye shall render blood, and beyond the world ye shall dwell in Death's shadow.")
ecliptic_cycle.register_effect("Nori",                   "#384769", "#60a658",
"*** You feel as though a mountain has walked or stumbled from the sea.")
ecliptic_cycle.register_effect("Mars",                   "#3b2b32", "#9c4a37",
"Mars rises! War is upon us!")
ecliptic_cycle.register_effect("Chicken Nugget",         "#a10000", "#e7a200",
"*** The sky feels as if a raging bonfire.")
ecliptic_cycle.register_effect("Pluto",                  "#8c1e15", "#b6ad8e",
"*** The Cries of Hades echo through the night.")
ecliptic_cycle.register_effect("Halloween Dream Machine","#3b2132", "#555e5f",
"*** The air hums. Some Ancient Machine awakens.")
ecliptic_cycle.register_effect("Cosmic Clockwork",       "#09362b", "#926e45",
"*** Tick... \n*** Tick... \n*** Tick...")


local server_started = false

core.register_on_joinplayer(function(player)
    if not server_started then
        ecliptic_cycle.update_phase()
        server_started = true
    end
    ecliptic_cycle.update_player_moon(player)
end)

local timer = 0
core.register_globalstep(function(dtime)
    timer = timer + dtime
    if timer > ecliptic_cycle.update_timer then
        local time = core.get_timeofday()*24000
        -- After Sunrise and Before Sunset (moonset/moonrise)
        if time > 6000 and time < 18000 then
            local current_day = ecliptic_cycle.get_day()
            local new_phase = current_day % 30

            -- Check if the phase has changed (account for the looping)
            if ecliptic_cycle.current_lunar_phase < new_phase or ecliptic_cycle.current_lunar_phase == 29 and new_phase == 0 then
                ecliptic_cycle.update_phase()
                ecliptic_cycle.update_players()
            end
        end

        -- During/After sunset, check if we have an effect message to print to chat
        if ecliptic_cycle.enable_event_messages and ecliptic_cycle.effect[4] and time > 18000 then
            -- Line breaks around for dramatic effect
            core.chat_send_all("\n\n"..ecliptic_cycle.effect[4].."\n\n")

            -- Clear the message
            ecliptic_cycle.effect[4] = nil
        end
        timer = 0
    end
end)


-- MINECLONE Support:

-- SCOUT-14: Base, this is Scout-14, priority transmition, over.
local kill_the_moon = core.global_exists("mcl_moon")
-- BASE: Go ahead, Scout-14.
if kill_the_moon then
    -- SCOUT-14: Base, this is Scout-14. Celestial Mimic spotted, bearing zero-niner-zero. Over.

    -- BASE: Scout-14, say again. Over.

    -- SCOUT-14: Repeat, Celestial Mimic spotted, bearing zero-niner-zero. Over.

    -- BASE: Scout-14, Stand by. Out.

    -- BASE: Base to Command, request immediate authorization to launch a strike, bearing 090. Over.

    -- COMMAND: Base, this is Command. Authorization granted. Out.

    -- ... > Priming missiles < ...
    local function remove_callback(callback, modname)
        -- ... > Ignition < ...
        for i, func in ipairs(callback) do
            -- .. > Scanning potential targets < ...
            local info = debug.getinfo(func)
            -- .. > Locate the target < ...
            if info.source:find(modname) then
                -- ... > Neutralize target < ...
                callback[i] = function(player) end
            end
        end
    end

    -- BASE: Fire at will.
    remove_callback(core.registered_on_joinplayers, "mcl_moon")
    remove_callback(core.registered_globalsteps, "mcl_moon")
    mcl_moon.get_moon_phase = function()
        return 0
    end

    -- BASE: Scout-14, this is Base. Come in. Report. Over.

    -- SCOUT-14: Base, Scout-14. Target neutralized. Out.
end