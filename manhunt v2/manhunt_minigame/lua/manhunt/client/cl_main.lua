--[[
    Manhunt Minigame - Client Main Logic
    Handles client-side game state and network messages
]]--

-- Client-side game state
Manhunt.LocalGameState = GAME_STATE_IDLE
Manhunt.LocalMainTimer = 0
Manhunt.LocalIntervalTimer = 0
Manhunt.LocalCountdownTimer = 0
Manhunt.LocalHunter = nil
Manhunt.LocalFugitive = nil
Manhunt.LocalSoloMode = false
Manhunt.LocalRole = ROLE_NONE
Manhunt.LocalEndgameMode = false
Manhunt.SurveillanceActive = false
Manhunt.PingMarkers = {}
Manhunt.MatchStats = {}

--[[
    Network Message Handlers
]]--

net.Receive("manhunt_game_state", function()
    local newState = net.ReadUInt(8)
    Manhunt.LocalGameState = newState
    
    print("[Manhunt] Game state updated: " .. Manhunt.GetStateString(newState))
    
    -- Play sound effects based on state
    if newState == GAME_STATE_COUNTDOWN then
        surface.PlaySound("buttons/button14.wav")
    elseif newState == GAME_STATE_ACTIVE then
        surface.PlaySound("buttons/button9.wav")
    elseif newState == GAME_STATE_ENDED then
        surface.PlaySound("buttons/button10.wav")
    end
end)

net.Receive("manhunt_player_roles", function()
    Manhunt.LocalHunter = net.ReadEntity()
    Manhunt.LocalFugitive = net.ReadEntity()
    Manhunt.LocalSoloMode = net.ReadBool()
    
    -- Determine local player role
    local ply = LocalPlayer()
    if ply == Manhunt.LocalHunter then
        Manhunt.LocalRole = ROLE_HUNTER
    elseif ply == Manhunt.LocalFugitive then
        Manhunt.LocalRole = ROLE_FUGITIVE
    else
        Manhunt.LocalRole = ROLE_NONE
    end
    
    print("[Manhunt] Roles assigned - Your role: " .. 
          (Manhunt.LocalRole == ROLE_HUNTER and "Hunter" or 
           Manhunt.LocalRole == ROLE_FUGITIVE and "Fugitive" or "Spectator"))
end)

net.Receive("manhunt_timer_update", function()
    Manhunt.LocalMainTimer = net.ReadUInt(16)
    Manhunt.LocalIntervalTimer = net.ReadUInt(16)
    Manhunt.LocalCountdownTimer = net.ReadUInt(8)
    Manhunt.LocalGameState = net.ReadUInt(8)
end)

net.Receive("manhunt_show_surveillance", function()
    local pos = net.ReadVector()
    local ang = net.ReadAngle()
    
    Manhunt.SurveillanceActive = true
    Manhunt.SurveillancePos = pos
    Manhunt.SurveillanceAng = ang
    
    surface.PlaySound("buttons/button17.wav")
    
    print("[Manhunt] Surveillance feed activated")
end)

net.Receive("manhunt_hide_surveillance", function()
    Manhunt.SurveillanceActive = false
    Manhunt.SurveillancePos = nil
    Manhunt.SurveillanceAng = nil
    
    print("[Manhunt] Surveillance feed deactivated")
end)

net.Receive("manhunt_emergency_surveillance", function()
    local pos = net.ReadVector()
    local ang = net.ReadAngle()
    
    Manhunt.SurveillanceActive = true
    Manhunt.SurveillancePos = pos
    Manhunt.SurveillanceAng = ang
    
    surface.PlaySound("weapons/357/357_fire2.wav")
    
    chat.AddText(Color(255, 100, 100), "[Manhunt] ", Color(255, 255, 255), "Emergency surveillance activated!")
    
    print("[Manhunt] Emergency surveillance activated")
end)

net.Receive("manhunt_endgame_mode", function()
    local active = net.ReadBool()
    Manhunt.LocalEndgameMode = active
    
    if active then
        surface.PlaySound("ambient/alarms/warningbell1.wav")
        chat.AddText(Color(255, 50, 50), "[Manhunt] ", Color(255, 255, 255), "ENDGAME MODE - Surveillance interval halved!")
    end
    
    print("[Manhunt] Endgame mode: " .. (active and "Active" or "Inactive"))
end)

net.Receive("manhunt_victory", function()
    local winner = net.ReadUInt(8)
    local reason = net.ReadString()
    
    Manhunt.VictoryWinner = winner
    Manhunt.VictoryReason = reason
    Manhunt.VictoryTime = CurTime()
    
    -- Play victory/defeat sound
    if (winner == ROLE_HUNTER and Manhunt.LocalRole == ROLE_HUNTER) or
       (winner == ROLE_FUGITIVE and Manhunt.LocalRole == ROLE_FUGITIVE) then
        surface.PlaySound("misc/achievement_earned.wav")
    else
        surface.PlaySound("buttons/button11.wav")
    end
    
    print("[Manhunt] Victory: " .. (winner == ROLE_HUNTER and "Hunter" or "Fugitive") .. " - " .. reason)
end)

net.Receive("manhunt_ping_marker", function()
    local pos = net.ReadVector()
    
    table.insert(Manhunt.PingMarkers, {
        pos = pos,
        time = CurTime(),
        alpha = 255
    })
    
    print("[Manhunt] Ping marker created at " .. tostring(pos))
end)

net.Receive("manhunt_match_stats", function()
    Manhunt.MatchStats = {
        BulletsFired = net.ReadUInt(16),
        DamageDealt = net.ReadFloat(),
        HunterDistanceTraveled = net.ReadFloat(),
        FugitiveDistanceTraveled = net.ReadFloat(),
        ClosestDistance = net.ReadFloat()
    }
    
    print("[Manhunt] Match stats received")
end)

net.Receive("manhunt_ui_request", function()
    local uiType = net.ReadString()
    
    if uiType == "config" then
        Manhunt.OpenConfigMenu()
    elseif uiType == "menu" then
        Manhunt.OpenMainMenu()
    elseif uiType == "settings" then
        Manhunt.OpenSettingsMenu()
    end
end)

--[[
    Utility Functions
]]--

function Manhunt.GetDistanceToFugitive()
    if not IsValid(Manhunt.LocalFugitive) then return 0 end
    
    local ply = LocalPlayer()
    if not IsValid(ply) then return 0 end
    
    return math.floor(ply:GetPos():Distance(Manhunt.LocalFugitive:GetPos()))
end

function Manhunt.IsLocalPlayerInGame()
    return Manhunt.LocalRole != ROLE_NONE
end

-- Cleanup on disconnect
hook.Add("ShutDown", "Manhunt.Cleanup", function()
    Manhunt.PingMarkers = {}
    Manhunt.SurveillanceActive = false
end)

print("[Manhunt] Client main logic initialized")
