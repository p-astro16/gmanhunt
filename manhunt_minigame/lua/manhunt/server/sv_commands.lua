--[[
    Manhunt Minigame - Console Commands
    Admin and player commands for game control
]]--

--[[
    Admin Commands
]]--

concommand.Add("manhunt_help", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then
        ply:PrintMessage(HUD_PRINTCONSOLE, "[Manhunt] You must be an admin to use this command")
        return
    end
    
    local helpText = [[
=== Manhunt Minigame - Command Reference ===

ADMIN COMMANDS:
  manhunt_help                                    - Show this help
  manhunt_players                                 - List available players
  manhunt_start <time> <interval> <hunter_name>   - Start game
  manhunt_reset                                   - Stop current game
  manhunt_config                                  - Open configuration panel
  manhunt_debug_toggle                            - Toggle debug output

PLAYER COMMANDS:
  manhunt_menu                                    - Open player menu
  manhunt_stats                                   - Show personal statistics
  manhunt_settings                                - Open personal settings

DEBUG COMMANDS:
  manhunt_surveillance_test                       - Test 360° feed visibility
  manhunt_surveillance_status                     - Check surveillance state
    ]]
    
    if IsValid(ply) then
        ply:PrintMessage(HUD_PRINTCONSOLE, helpText)
    else
        print(helpText)
    end
end)

concommand.Add("manhunt_players", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then
        ply:PrintMessage(HUD_PRINTCONSOLE, "[Manhunt] You must be an admin to use this command")
        return
    end
    
    local players = player.GetAll()
    local output = "[Manhunt] Available Players (" .. #players .. "):\n"
    
    for i, p in ipairs(players) do
        output = output .. "  " .. i .. ". " .. p:Nick() .. " (SteamID: " .. p:SteamID() .. ")\n"
    end
    
    if IsValid(ply) then
        ply:PrintMessage(HUD_PRINTCONSOLE, output)
    else
        print(output)
    end
end)

concommand.Add("manhunt_start", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then
        ply:PrintMessage(HUD_PRINTCONSOLE, "[Manhunt] You must be an admin to use this command")
        return
    end
    
    if #args < 3 then
        local usage = "[Manhunt] Usage: manhunt_start <time> <interval> <hunter_name> [fugitive_name]\n"
        usage = usage .. "  time: Game duration in seconds (300-900)\n"
        usage = usage .. "  interval: Ping interval in seconds (30-60)\n"
        usage = usage .. "  hunter_name: Name of hunter player\n"
        usage = usage .. "  fugitive_name: (Optional) Name of fugitive player, omit for solo mode"
        
        if IsValid(ply) then
            ply:PrintMessage(HUD_PRINTCONSOLE, usage)
        else
            print(usage)
        end
        return
    end
    
    local duration = tonumber(args[1])
    local interval = tonumber(args[2])
    local hunterName = args[3]
    local fugitiveName = args[4]
    
    -- Validate duration
    if not duration or duration < 300 or duration > 900 then
        local msg = "[Manhunt] Invalid duration. Must be between 300 and 900 seconds"
        if IsValid(ply) then
            ply:PrintMessage(HUD_PRINTCONSOLE, msg)
        else
            print(msg)
        end
        return
    end
    
    -- Validate interval
    if not interval or interval < 30 or interval > 60 then
        local msg = "[Manhunt] Invalid interval. Must be between 30 and 60 seconds"
        if IsValid(ply) then
            ply:PrintMessage(HUD_PRINTCONSOLE, msg)
        else
            print(msg)
        end
        return
    end
    
    -- Find hunter
    local hunter = nil
    for _, p in ipairs(player.GetAll()) do
        if string.find(string.lower(p:Nick()), string.lower(hunterName)) then
            hunter = p
            break
        end
    end
    
    if not IsValid(hunter) then
        local msg = "[Manhunt] Could not find hunter: " .. hunterName
        if IsValid(ply) then
            ply:PrintMessage(HUD_PRINTCONSOLE, msg)
        else
            print(msg)
        end
        return
    end
    
    -- Find fugitive (or use solo mode)
    local fugitive = nil
    local soloMode = false
    
    if fugitiveName then
        for _, p in ipairs(player.GetAll()) do
            if string.find(string.lower(p:Nick()), string.lower(fugitiveName)) then
                fugitive = p
                break
            end
        end
        
        if not IsValid(fugitive) then
            local msg = "[Manhunt] Could not find fugitive: " .. fugitiveName
            if IsValid(ply) then
                ply:PrintMessage(HUD_PRINTCONSOLE, msg)
            else
                print(msg)
            end
            return
        end
    else
        soloMode = true
        fugitive = hunter
    end
    
    -- Start the game
    local success, message = Manhunt.StartGame(duration, interval, hunter, fugitive, soloMode)
    
    local output = "[Manhunt] " .. message
    if IsValid(ply) then
        ply:PrintMessage(HUD_PRINTCONSOLE, output)
    else
        print(output)
    end
    
    -- Broadcast to all players
    if success then
        for _, p in ipairs(player.GetAll()) do
            p:ChatPrint("[Manhunt] Game started! Hunter: " .. hunter:Nick() .. 
                       (soloMode and " (Solo Mode)" or ", Fugitive: " .. fugitive:Nick()))
        end
    end
end)

concommand.Add("manhunt_reset", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then
        ply:PrintMessage(HUD_PRINTCONSOLE, "[Manhunt] You must be an admin to use this command")
        return
    end
    
    Manhunt.ResetGame()
    
    local msg = "[Manhunt] Game reset"
    if IsValid(ply) then
        ply:PrintMessage(HUD_PRINTCONSOLE, msg)
    else
        print(msg)
    end
    
    -- Broadcast to all players
    for _, p in ipairs(player.GetAll()) do
        p:ChatPrint(msg)
    end
end)

concommand.Add("manhunt_config", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then
        ply:ChatPrint("[Manhunt] You must be an admin to use this command")
        return
    end
    
    if IsValid(ply) then
        net.Start("manhunt_ui_request")
        net.WriteString("config")
        net.Send(ply)
    end
end)

concommand.Add("manhunt_debug_toggle", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then
        ply:PrintMessage(HUD_PRINTCONSOLE, "[Manhunt] You must be an admin to use this command")
        return
    end
    
    Manhunt.Debug = not Manhunt.Debug
    
    local msg = "[Manhunt] Debug mode " .. (Manhunt.Debug and "enabled" or "disabled")
    if IsValid(ply) then
        ply:PrintMessage(HUD_PRINTCONSOLE, msg)
    else
        print(msg)
    end
end)

--[[
    Player Commands
]]--

concommand.Add("manhunt_menu", function(ply, cmd, args)
    if not IsValid(ply) then return end
    
    net.Start("manhunt_ui_request")
    net.WriteString("menu")
    net.Send(ply)
end)

concommand.Add("manhunt_stats", function(ply, cmd, args)
    if not IsValid(ply) then return end
    
    local stats = string.format([[
=== Manhunt Statistics ===
Games Played: %d
Hunter Wins: %d
Fugitive Wins: %d
Win Rate (Hunter): %.1f%%
Win Rate (Fugitive): %.1f%%
Total Game Time: %s
]], 
        Manhunt.Stats.GamesPlayed,
        Manhunt.Stats.HunterWins,
        Manhunt.Stats.FugitiveWins,
        Manhunt.Stats.GamesPlayed > 0 and (Manhunt.Stats.HunterWins / Manhunt.Stats.GamesPlayed * 100) or 0,
        Manhunt.Stats.GamesPlayed > 0 and (Manhunt.Stats.FugitiveWins / Manhunt.Stats.GamesPlayed * 100) or 0,
        Manhunt.FormatTime(Manhunt.Stats.TotalGameTime)
    )
    
    ply:PrintMessage(HUD_PRINTCONSOLE, stats)
end)

concommand.Add("manhunt_settings", function(ply, cmd, args)
    if not IsValid(ply) then return end
    
    net.Start("manhunt_ui_request")
    net.WriteString("settings")
    net.Send(ply)
end)

--[[
    Debug Commands
]]--

concommand.Add("manhunt_surveillance_test", function(ply, cmd, args)
    if not IsValid(ply) then return end
    if not ply:IsAdmin() then
        ply:ChatPrint("[Manhunt] You must be an admin to use this command")
        return
    end
    
    -- Trigger test surveillance
    net.Start("manhunt_show_surveillance")
    net.WriteVector(ply:GetPos())
    net.WriteAngle(ply:EyeAngles())
    net.Send(ply)
    
    ply:ChatPrint("[Manhunt] Surveillance test activated for 5 seconds")
    
    timer.Simple(5, function()
        if IsValid(ply) then
            net.Start("manhunt_hide_surveillance")
            net.Send(ply)
        end
    end)
end)

concommand.Add("manhunt_surveillance_status", function(ply, cmd, args)
    if not IsValid(ply) then return end
    
    local status = string.format([[
=== Manhunt Surveillance Status ===
Game State: %s
Hunter: %s
Fugitive: %s
Solo Mode: %s
Endgame Mode: %s
Last Ping Position: %s
]], 
        Manhunt.GetStateString(Manhunt.GameState),
        IsValid(Manhunt.Hunter) and Manhunt.Hunter:Nick() or "None",
        IsValid(Manhunt.Fugitive) and Manhunt.Fugitive:Nick() or "None",
        Manhunt.SoloMode and "Yes" or "No",
        Manhunt.EndgameMode and "Yes" or "No",
        Manhunt.LastPingPos and tostring(Manhunt.LastPingPos) or "None"
    )
    
    ply:PrintMessage(HUD_PRINTCONSOLE, status)
end)

print("[Manhunt] Console commands registered")
