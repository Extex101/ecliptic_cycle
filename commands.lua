core.register_chatcommand("lunar_effect", {
    description = "Sets the current lunar phase",
    privs = {server = true},
    params = "<hex> <hex> or <int 0 - 1>",
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


core.register_chatcommand("lunar_phase", {
    description = "Adds to the current lunar phase",
    params = "add force",
    func = function(name, param)
        local privs = core.get_player_privs(name)
        local phase = ecliptic_cycle.current_lunar_phase
        local string = ecliptic_cycle.phase_names[phase+1].."(" .. phase .. ")"
        if not privs.server then
            if param:gmatch("force") or param:gmatch("add") then
                return false, "Insufficient privileges."
            end
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