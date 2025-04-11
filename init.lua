if not core.settings:get("ecliptic_cycle.phase_offset") then
    core.settings:set("ecliptic_cycle.phase_offset", 3763150)
end

if not core.settings:get("ecliptic_cycle.update_timer") then
    core.settings:set("ecliptic_cycle.update_timer", 30)
end

ecliptic_cycle = {
    phase_offset = tonumber(core.settings:get("ecliptic_cycle.phase_offset")),
    update_timer = tonumber(core.settings:get("ecliptic_cycle.update_timer")),
    current_lunar_phase = 0,
    effect = {},
    threshold = 1.94, -- Threshold for registered effect events
    variance_threshold = 1.5, -- Threshold for random color variance events
    variance = 0.3, -- Variance for random color events
}


local path = core.get_modpath(core.get_current_modname())
dofile(path.."/api.lua")
dofile(path.."/commands.lua")


ecliptic_cycle.register_effect("Frosted Rose",          "#4a2950", "#cb4c66")
ecliptic_cycle.register_effect("Dusty Oranges",         "#533922", "#f58b3a")
ecliptic_cycle.register_effect("Frozen Blueberries",    "#535eae", "#c7c0dd")
ecliptic_cycle.register_effect("Penicillin",            "#4d4f39", "#bcaa84")
ecliptic_cycle.register_effect("Pumpkin",               "#5c3036", "#e26e4d")
ecliptic_cycle.register_effect("Sol's Fury",            "#713600", "#c6a333")
ecliptic_cycle.register_effect("Star Wars",             "#222441", "#555c65")
ecliptic_cycle.register_effect("Morning Dew",           "#9096c4", "#d6e4e1")
ecliptic_cycle.register_effect("Weeping Bride",         "#136eb5", "#b1ddfa")
ecliptic_cycle.register_effect("Spectre",               "#7100a0", "#b1ddfa")
ecliptic_cycle.register_effect("Blackmore's Night",     "#3a3b71", "#c272b1")
ecliptic_cycle.register_effect("Doom",                  "#50002f", "#ff2f00")



core.register_on_joinplayer(function(player)
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
                ecliptic_cycle.current_lunar_phase = new_phase
                local event, random_event = ecliptic_cycle.is_event(current_day)
                if event then
                    ecliptic_cycle.set_effect("shuffle")
                elseif random_event then
                    ecliptic_cycle.set_effect(ecliptic_cycle.variance)
                elseif not event and #ecliptic_cycle.effect > 0 then
                    ecliptic_cycle.effect = {}
                end
                for _, player in pairs(core.get_connected_players()) do
                    ecliptic_cycle.update_player_moon(player)
                end
            end
        end
        timer = 0
    end
end)
