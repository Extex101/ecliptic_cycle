core.register_chatcommand("set_lunar_effect", {
    description = "Sets the current lunar effect.",
    privs = {server = true},
    params = "<hex> <hex> or <int 0 - 1> or <effect name>",
    func = function(name, param)
        if param == "" then
            local hexes, effect = ecliptic_cycle.get_effect()
            if effect == "none" or not hexes then
                return true, "No active effect."
            end
            return true, "Current effect is: "..effect.. " ("..hexes[1]..", "..hexes[2]..")"
        end
        local success, message = ecliptic_cycle.set_effect(param)
        if not success then
            return false, message
        end
        ecliptic_cycle.update_players()
        return true, "Effect set to: "..param
    end
})


core.register_chatcommand("lunar_effects", {
    description = "Lists all lunar effects.",
    func = function(name, param)
        local effects = "Registered Effects: \n • "
        for i, effect_name in pairs(ecliptic_cycle.effects.names) do
            local name_len = string.len(effect_name)
            local colors = ecliptic_cycle.effects.colors[effect_name]
            local col1 = {
                r = tonumber(colors[1]:sub(2, 3), 16),
                g = tonumber(colors[1]:sub(4, 5), 16),
                b = tonumber(colors[1]:sub(6, 7), 16)
            }
            local col2 = {
                r = tonumber(colors[2]:sub(2, 3), 16),
                g = tonumber(colors[2]:sub(4, 5), 16),
                b = tonumber(colors[2]:sub(6, 7), 16)
            }
            for j = 1, name_len do
                local char = string.sub(effect_name, j, j)
                local color_table = {
                    r = math.floor((col1.r + (col2.r - col1.r) * (j - 1) / (name_len - 1))),
                    g = math.floor((col1.g + (col2.g - col1.g) * (j - 1) / (name_len - 1))),
                    b = math.floor((col1.b + (col2.b - col1.b) * (j - 1) / (name_len - 1)))
                }
                local col = string.format("#%02x%02x%02x", color_table.r, color_table.g, color_table.b)
                effects = effects .. core.colorize(col, char)
            end
            if i ~= #ecliptic_cycle.effects.names then
                effects = effects .. "\n • "
            end
        end
        return true, effects
    end
})


core.register_chatcommand("lunar_phase", {
    description = "Adds to the current lunar phase",
    params = "add force",
    func = function(name, param)
        local privs = core.get_player_privs(name)
        local phase = ecliptic_cycle.current_lunar_phase
        local string = ecliptic_cycle.phase_names[phase+1].."(" .. phase .. ")"
        if param:find("-version") then
            return true, "ecliptic_cycle version: "..ecliptic_cycle._VERSION
        end
        if not privs.server then
            return true, "Lunar phase is: "..string
        end
        if param:find("^add") or param:find("^subtract") then
            if param:find("subtract") then
                ecliptic_cycle.phase_offset = ecliptic_cycle.phase_offset - 1
            else
                ecliptic_cycle.phase_offset = ecliptic_cycle.phase_offset + 1
            end
            core.settings:set("ecliptic_cycle.phase_offset", ecliptic_cycle.phase_offset)
            ecliptic_cycle.update_phase(param:find("force"))
            if param == "add force" or param == "subtract force" then
                ecliptic_cycle.update_players()

                return true, "Lunar phase set to: "..ecliptic_cycle.phase_names[phase+1].." (" .. phase .. "). All players updated."
            else
                return true, "Lunar phase set to: "..ecliptic_cycle.phase_names[phase+1].." (" .. phase .. "). Will update next night."
            end
        end
        return true, "Lunar phase is: "..ecliptic_cycle.phase_names[phase+1].." (" .. phase .. ")."
    end
})

core.register_chatcommand("next_lunar_event", {
    description = "Prints how many days until the next lunar event.",
    params = "sprint (Skips several days to the day of the next lunar event. Not recommended)",
    privs = {server=true},
    func = function(name, param)
        local current_day = ecliptic_cycle.get_day()
        if param == "sprint" then
            local time = core.get_timeofday()
            local days = 1
            local event = ecliptic_cycle.is_event(current_day)
            while not event do
                core.set_timeofday(1)
                core.set_timeofday(0.5)
                event = ecliptic_cycle.is_event(current_day+days+1)
                days = days + 1
                if days > 200 then
                    return false, "Sprint failed. More than 200 days elapsed before finding next lunar event."
                end
            end
            core.set_timeofday(time)
            ecliptic_cycle.update_phase()
            ecliptic_cycle.update_players()
            local d = days == 1 and "" or "s"
            return true, "Skipped "..days.." day"..d.." to next lunar event."
        end
        local days = 0
        local event = ecliptic_cycle.is_event(current_day+days)
        while not event do
            days = days + 1
            event = ecliptic_cycle.is_event(current_day+days)
            if days > 200 then
                return false, "More than 200 days elapsed before finding next lunar event."
            end
        end
        local d = days == 1 and "" or "s"
        if days == 0 then
            if core.get_timeofday()*24000 < 6000 then
                return true, "Next Lunar Event is in: 1 day."
            end
            return true, "Next Lunar Event is tonight!"
        end
        return true, "Next Lunar Event is in: "..days.." day"..d.."."
    end
})