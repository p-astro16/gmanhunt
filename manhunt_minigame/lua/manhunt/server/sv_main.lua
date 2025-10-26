--[[
    Manhunt Minigame - Server Core Logic
    Handles game state, timers, roles, and all server-side mechanics
]]--

util.AddNetworkString("manhunt_game_state")
util.AddNetworkString("manhunt_player_roles")
util.AddNetworkString("manhunt_timer_update")
util.AddNetworkString("manhunt_show_surveillance")
util.AddNetworkString("manhunt_hide_surveillance")
util.AddNetworkString("manhunt_emergency_surveillance")
util.AddNetworkString("manhunt_endgame_mode")
util.AddNetworkString("manhunt_config_update")
util.AddNetworkString("manhunt_ui_request")
util.AddNetworkString("manhunt_speed_boost")
util.AddNetworkString("manhunt_victory")
util.AddNetworkString("manhunt_ping_marker")

-- Game state variables
Manhunt.GameState = GAME_STATE_IDLE
Manhunt.MainTimer = 0
Manhunt.IntervalTimer = 0
Manhunt.CountdownTimer = 0
Manhunt.Hunter = nil
Manhunt.Fugitive = nil
Manhunt.SoloMode = false
Manhunt.EndgameMode = false
Manhunt.LastPingPos = nil
Manhunt.SpeedBoostTimer = 0

-- Statistics tracking
Manhunt.Stats = {
    GamesPlayed = 0,
    HunterWins = 0,
    FugitiveWins = 0,
    TotalGameTime = 0
}

--[[
    Game State Management
]]--
function Manhunt.UpdateGameState(newState)
    Manhunt.GameState = newState
    
    -- Broadcast state to all clients
    net.Start("manhunt_game_state")
    net.WriteUInt(newState, 8)
    net.Broadcast()
    
    print("[Manhunt] Game state changed to: " .. Manhunt.GetStateString(newState))
end

function Manhunt.StartGame(duration, interval, hunter, fugitive, soloMode)
    if Manhunt.GameState != GAME_STATE_IDLE then
        return false, "Game already in progress"
    end
    
    -- Validate players
    if not IsValid(hunter) or not hunter:IsPlayer() then
        return false, "Invalid hunter"
    end
    
    if not soloMode and (not IsValid(fugitive) or not fugitive:IsPlayer()) then
        return false, "Invalid fugitive"
    end
    
    -- Set game parameters
    Manhunt.MainTimer = duration
    Manhunt.Config.PingInterval = interval
    Manhunt.Hunter = hunter
    Manhunt.Fugitive = soloMode and hunter or fugitive
    Manhunt.SoloMode = soloMode
    Manhunt.EndgameMode = false
    Manhunt.SpeedBoostTimer = Manhunt.Config.SpeedBoostInterval
    
    -- Start countdown
    Manhunt.CountdownTimer = Manhunt.Config.CountdownTime
    Manhunt.UpdateGameState(GAME_STATE_COUNTDOWN)
    
    -- Assign roles
    Manhunt.BroadcastRoles()
    
    -- Give hunter emergency weapon
    Manhunt.Hunter:Give(Manhunt.Config.EmergencyWeapon)
    Manhunt.Hunter:SetAmmo(Manhunt.Config.EmergencyWeaponAmmo, Manhunt.Hunter:GetWeapon(Manhunt.Config.EmergencyWeapon):GetPrimaryAmmoType())
    
    print("[Manhunt] Game starting - Hunter: " .. hunter:Nick() .. ", Fugitive: " .. (soloMode and "Solo Mode" or fugitive:Nick()))
    
    return true, "Game started successfully"
end

function Manhunt.EndGame(winner, reason)
    if Manhunt.GameState == GAME_STATE_IDLE or Manhunt.GameState == GAME_STATE_ENDED then
        return
    end
    
    Manhunt.UpdateGameState(GAME_STATE_ENDED)
    
    -- Update statistics
    Manhunt.Stats.GamesPlayed = Manhunt.Stats.GamesPlayed + 1
    if winner == ROLE_HUNTER then
        Manhunt.Stats.HunterWins = Manhunt.Stats.HunterWins + 1
    elseif winner == ROLE_FUGITIVE then
        Manhunt.Stats.FugitiveWins = Manhunt.Stats.FugitiveWins + 1
    end
    
    -- Broadcast victory
    net.Start("manhunt_victory")
    net.WriteUInt(winner, 8)
    net.WriteString(reason)
    net.Broadcast()
    
    print("[Manhunt] Game ended - Winner: " .. (winner == ROLE_HUNTER and "Hunter" or "Fugitive") .. " (" .. reason .. ")")
    
    -- Auto-reset after 10 seconds
    timer.Simple(10, function()
        Manhunt.ResetGame()
    end)
end

function Manhunt.ResetGame()
    Manhunt.GameState = GAME_STATE_IDLE
    Manhunt.MainTimer = 0
    Manhunt.IntervalTimer = 0
    Manhunt.CountdownTimer = 0
    Manhunt.Hunter = nil
    Manhunt.Fugitive = nil
    Manhunt.SoloMode = false
    Manhunt.EndgameMode = false
    Manhunt.LastPingPos = nil
    Manhunt.SpeedBoostTimer = 0
    
    Manhunt.UpdateGameState(GAME_STATE_IDLE)
    
    print("[Manhunt] Game reset")
end

function Manhunt.BroadcastRoles()
    net.Start("manhunt_player_roles")
    net.WriteEntity(Manhunt.Hunter or NULL)
    net.WriteEntity(Manhunt.Fugitive or NULL)
    net.WriteBool(Manhunt.SoloMode)
    net.Broadcast()
end

--[[
    Timer System
]]--
function Manhunt.Think()
    if Manhunt.GameState == GAME_STATE_IDLE or Manhunt.GameState == GAME_STATE_ENDED then
        return
    end
    
    -- Countdown phase
    if Manhunt.GameState == GAME_STATE_COUNTDOWN then
        Manhunt.CountdownTimer = Manhunt.CountdownTimer - 1
        
        if Manhunt.CountdownTimer <= 0 then
            -- Start headstart phase
            Manhunt.IntervalTimer = Manhunt.Config.PingInterval
            Manhunt.UpdateGameState(GAME_STATE_HEADSTART)
            
            -- Freeze hunter
            if IsValid(Manhunt.Hunter) then
                Manhunt.Hunter:Freeze(true)
            end
        end
        
        Manhunt.BroadcastTimers()
        return
    end
    
    -- Main game timer
    Manhunt.MainTimer = Manhunt.MainTimer - 1
    
    -- Check for endgame mode
    if not Manhunt.EndgameMode and Manhunt.MainTimer <= Manhunt.Config.EndgameThreshold then
        Manhunt.EndgameMode = true
        
        -- Halve the interval timer if it's currently running
        if Manhunt.IntervalTimer > 0 then
            Manhunt.IntervalTimer = math.ceil(Manhunt.IntervalTimer / 2)
        end
        
        net.Start("manhunt_endgame_mode")
        net.WriteBool(true)
        net.Broadcast()
        
        print("[Manhunt] Endgame mode activated - surveillance interval halved")
    end
    
    -- Check for fugitive victory
    if Manhunt.MainTimer <= 0 then
        Manhunt.EndGame(ROLE_FUGITIVE, "Survived until time ran out")
        return
    end
    
    -- Interval timer (ping system)
    Manhunt.IntervalTimer = Manhunt.IntervalTimer - 1
    
    if Manhunt.IntervalTimer <= 0 then
        -- Trigger surveillance
        Manhunt.TriggerSurveillance()
        
        -- Reset interval timer (halved in endgame)
        local baseInterval = Manhunt.Config.PingInterval
        Manhunt.IntervalTimer = Manhunt.EndgameMode and math.ceil(baseInterval / 2) or baseInterval
        
        -- End headstart phase
        if Manhunt.GameState == GAME_STATE_HEADSTART then
            Manhunt.UpdateGameState(GAME_STATE_ACTIVE)
            
            -- Unfreeze hunter
            if IsValid(Manhunt.Hunter) then
                Manhunt.Hunter:Freeze(false)
            end
        end
    end
    
    -- Speed boost timer
    Manhunt.SpeedBoostTimer = Manhunt.SpeedBoostTimer - 1
    
    if Manhunt.SpeedBoostTimer <= 0 and Manhunt.GameState == GAME_STATE_ACTIVE then
        Manhunt.TriggerSpeedBoost()
        Manhunt.SpeedBoostTimer = Manhunt.Config.SpeedBoostInterval
    end
    
    Manhunt.BroadcastTimers()
end

function Manhunt.BroadcastTimers()
    net.Start("manhunt_timer_update")
    net.WriteUInt(Manhunt.MainTimer, 16)
    net.WriteUInt(Manhunt.IntervalTimer, 16)
    net.WriteUInt(Manhunt.CountdownTimer, 8)
    net.WriteUInt(Manhunt.GameState, 8)
    net.Broadcast()
end

--[[
    Surveillance System
]]--
function Manhunt.TriggerSurveillance()
    if not IsValid(Manhunt.Fugitive) then return end
    
    Manhunt.LastPingPos = Manhunt.Fugitive:GetPos()
    
    -- Show surveillance feed to hunter
    net.Start("manhunt_show_surveillance")
    net.WriteVector(Manhunt.LastPingPos)
    net.WriteAngle(Manhunt.Fugitive:EyeAngles())
    if IsValid(Manhunt.Hunter) then
        net.Send(Manhunt.Hunter)
    end
    
    -- Create 3D ping marker
    net.Start("manhunt_ping_marker")
    net.WriteVector(Manhunt.LastPingPos)
    if IsValid(Manhunt.Hunter) then
        net.Send(Manhunt.Hunter)
    end
    
    -- Auto-hide after 5 seconds
    timer.Simple(5, function()
        net.Start("manhunt_hide_surveillance")
        if IsValid(Manhunt.Hunter) then
            net.Send(Manhunt.Hunter)
        end
    end)
    
    print("[Manhunt] Surveillance triggered at " .. tostring(Manhunt.LastPingPos))
end

function Manhunt.EmergencySurveillance(hunter)
    if not IsValid(hunter) or hunter != Manhunt.Hunter then return end
    if Manhunt.GameState != GAME_STATE_ACTIVE then return end
    if not IsValid(Manhunt.Fugitive) then return end
    
    -- Trigger instant surveillance
    Manhunt.LastPingPos = Manhunt.Fugitive:GetPos()
    
    net.Start("manhunt_emergency_surveillance")
    net.WriteVector(Manhunt.LastPingPos)
    net.WriteAngle(Manhunt.Fugitive:EyeAngles())
    net.Send(hunter)
    
    -- Create 3D ping marker
    net.Start("manhunt_ping_marker")
    net.WriteVector(Manhunt.LastPingPos)
    net.Send(hunter)
    
    -- Auto-hide after 3 seconds
    timer.Simple(3, function()
        net.Start("manhunt_hide_surveillance")
        if IsValid(hunter) then
            net.Send(hunter)
        end
    end)
    
    print("[Manhunt] Emergency surveillance used by " .. hunter:Nick())
end

--[[
    Speed Boost System
]]--
function Manhunt.TriggerSpeedBoost()
    if not IsValid(Manhunt.Fugitive) then return end
    
    -- Apply speed boost
    local oldSpeed = Manhunt.Fugitive:GetWalkSpeed()
    local oldRunSpeed = Manhunt.Fugitive:GetRunSpeed()
    
    Manhunt.Fugitive:SetWalkSpeed(oldSpeed * Manhunt.Config.SpeedBoostMultiplier)
    Manhunt.Fugitive:SetRunSpeed(oldRunSpeed * Manhunt.Config.SpeedBoostMultiplier)
    
    -- Notify fugitive
    net.Start("manhunt_speed_boost")
    net.WriteBool(true)
    net.Send(Manhunt.Fugitive)
    
    -- Remove after duration
    timer.Simple(Manhunt.Config.SpeedBoostDuration, function()
        if IsValid(Manhunt.Fugitive) then
            Manhunt.Fugitive:SetWalkSpeed(oldSpeed)
            Manhunt.Fugitive:SetRunSpeed(oldRunSpeed)
            
            net.Start("manhunt_speed_boost")
            net.WriteBool(false)
            net.Send(Manhunt.Fugitive)
        end
    end)
    
    print("[Manhunt] Speed boost activated for " .. Manhunt.Fugitive:Nick())
end

--[[
    Damage Detection
]]--
hook.Add("EntityTakeDamage", "Manhunt.DamageDetection", function(target, dmginfo)
    if Manhunt.GameState != GAME_STATE_ACTIVE and Manhunt.GameState != GAME_STATE_HEADSTART then
        return
    end
    
    -- Check if fugitive took damage
    if IsValid(target) and target == Manhunt.Fugitive then
        local attacker = dmginfo:GetAttacker()
        
        -- Check if hunter dealt the damage
        if IsValid(attacker) and attacker == Manhunt.Hunter then
            Manhunt.EndGame(ROLE_HUNTER, "Hunter eliminated the fugitive")
            return true -- Cancel damage, game is over
        end
    end
end)

--[[
    Emergency Weapon Hook
]]--
hook.Add("EntityFireBullets", "Manhunt.EmergencyWeapon", function(ent, data)
    if not IsValid(ent) or not ent:IsPlayer() then return end
    if ent != Manhunt.Hunter then return end
    if Manhunt.GameState != GAME_STATE_ACTIVE then return end
    
    local weapon = ent:GetActiveWeapon()
    if not IsValid(weapon) then return end
    
    if weapon:GetClass() == Manhunt.Config.EmergencyWeapon then
        -- Trigger emergency surveillance
        Manhunt.EmergencySurveillance(ent)
    end
end)

--[[
    Player Disconnect Handling
]]--
hook.Add("PlayerDisconnected", "Manhunt.PlayerDisconnect", function(ply)
    if Manhunt.GameState == GAME_STATE_IDLE or Manhunt.GameState == GAME_STATE_ENDED then
        return
    end
    
    if ply == Manhunt.Hunter then
        Manhunt.EndGame(ROLE_FUGITIVE, "Hunter disconnected")
    elseif ply == Manhunt.Fugitive then
        Manhunt.EndGame(ROLE_HUNTER, "Fugitive disconnected")
    end
end)

-- Main game loop
timer.Create("Manhunt.GameLoop", 1, 0, function()
    Manhunt.Think()
end)

print("[Manhunt] Server core logic initialized")
