
core.register_chatcommand("effect", {
    description = "Sets the current lunar phase",
    privs = {server = true},
    params = "<hex> <hex> or <int 0 - 1>",
    func = function(name, param)
        local success, message = ecliptic_cycle.set_effect(param)
        if not success then
            return false, message
        end
        for _, player in pairs(core.get_connected_players()) do
            ecliptic_cycle.update_player_moon(player)
        end
        return true, "Effect set to: "..param
    end
})


core.register_chatcommand("phase", {
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
        if param:find("^add") or param:find("subtract") then
            if param:find("subtract") then
                ecliptic_cycle.phase_offset = ecliptic_cycle.phase_offset - 1
            else
                ecliptic_cycle.phase_offset = ecliptic_cycle.phase_offset + 1
            end
            core.settings:set("ecliptic_cycle.phase_offset", ecliptic_cycle.phase_offset)
            ecliptic_cycle.set_phase()
            if param == "add force" or param == "subtract foce" then
                for _, player in pairs(core.get_connected_players()) do
                    ecliptic_cycle.update_player_moon(player)
                end

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
    params = "sprint (Skips several days to the day before the next lunar event, kind of bugged. Not reccomended)",
    privs = {server=true},
    func = function(name, param)
        local current_day = ecliptic_cycle.get_day()
        if param == "sprint" then
            local days = 1
            local event = ecliptic_cycle.is_event(current_day)
            while not event do
                core.set_timeofday(1)
                core.set_timeofday(0.5)
                event = ecliptic_cycle.is_event(current_day+days+1)
                days = days + 1
            end
            ecliptic_cycle.current_lunar_phase = ecliptic_cycle.get_day(true)
            for _, player in pairs(core.get_connected_players()) do
                ecliptic_cycle.update_player_moon(player)
            end
            local d = days == 1 and "" or "s"
            return true, "Skipped "..days.." day"..d.." to next lunar event."
        end
        local days = 0
        local event = ecliptic_cycle.is_event(current_day+days)
        while not event do
            days = days + 1
            event = ecliptic_cycle.is_event(current_day+days)
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