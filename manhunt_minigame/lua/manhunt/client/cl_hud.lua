--[[
    Manhunt Minigame - HUD System
    Displays all in-game UI elements
]]--

-- HUD configuration
local HUD_CONFIG = {
    MainTimerSize = 48,
    IntervalTimerSize = 24,
    CountdownSize = 128,
    DistanceSize = 32,
    PingDuration = 10, -- seconds before ping marker fades
}

-- Colors
local COLOR_WHITE = Color(255, 255, 255)
local COLOR_RED = Color(255, 50, 50)
local COLOR_BLUE = Color(100, 150, 255)
local COLOR_YELLOW = Color(255, 200, 50)
local COLOR_GREEN = Color(100, 255, 100)
local COLOR_BLACK = Color(0, 0, 0, 200)

-- Fonts
surface.CreateFont("Manhunt_MainTimer", {
    font = "Roboto",
    size = HUD_CONFIG.MainTimerSize,
    weight = 700,
    antialias = true,
})

surface.CreateFont("Manhunt_IntervalTimer", {
    font = "Roboto",
    size = HUD_CONFIG.IntervalTimerSize,
    weight = 500,
    antialias = true,
})

surface.CreateFont("Manhunt_Countdown", {
    font = "Roboto",
    size = HUD_CONFIG.CountdownSize,
    weight = 900,
    antialias = true,
})

surface.CreateFont("Manhunt_Distance", {
    font = "Roboto",
    size = HUD_CONFIG.DistanceSize,
    weight = 600,
    antialias = true,
})

surface.CreateFont("Manhunt_Label", {
    font = "Roboto",
    size = 18,
    weight = 500,
    antialias = true,
})

surface.CreateFont("Manhunt_Alert", {
    font = "Roboto",
    size = 36,
    weight = 700,
    antialias = true,
})

--[[
    Main HUD Drawing
]]--

hook.Add("HUDPaint", "Manhunt.DrawHUD", function()
    if Manhunt.LocalGameState == GAME_STATE_IDLE then return end
    
    local scrW, scrH = ScrW(), ScrH()
    
    -- Draw countdown
    if Manhunt.LocalGameState == GAME_STATE_COUNTDOWN then
        Manhunt.DrawCountdown(scrW, scrH)
        return
    end
    
    -- Draw main timer
    Manhunt.DrawMainTimer(scrW, scrH)
    
    -- Draw interval timer
    Manhunt.DrawIntervalTimer(scrW, scrH)
    
    -- Draw role-specific HUD
    if Manhunt.LocalRole == ROLE_HUNTER then
        Manhunt.DrawHunterHUD(scrW, scrH)
    elseif Manhunt.LocalRole == ROLE_FUGITIVE then
        Manhunt.DrawFugitiveHUD(scrW, scrH)
    end
    
    -- Draw victory screen
    if Manhunt.LocalGameState == GAME_STATE_ENDED then
        Manhunt.DrawVictoryScreen(scrW, scrH)
    end
    
    -- Draw ping markers in 3D
    Manhunt.DrawPingMarkers()
end)

--[[
    Countdown Display
]]--

function Manhunt.DrawCountdown(scrW, scrH)
    local centerX = scrW / 2
    local centerY = scrH / 2
    
    -- Background
    draw.RoundedBox(8, centerX - 100, centerY - 100, 200, 200, COLOR_BLACK)
    
    -- Countdown number
    local countText = tostring(Manhunt.LocalCountdownTimer)
    draw.SimpleText(countText, "Manhunt_Countdown", centerX, centerY - 30, COLOR_YELLOW, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    
    -- Label
    draw.SimpleText("GET READY", "Manhunt_Label", centerX, centerY + 60, COLOR_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

--[[
    Main Timer Display
]]--

function Manhunt.DrawMainTimer(scrW, scrH)
    local centerX = scrW / 2
    local topY = 30
    
    -- Determine color based on urgency
    local timerColor = COLOR_WHITE
    if Manhunt.LocalMainTimer <= 30 then
        timerColor = COLOR_RED
        -- Pulsing effect
        local pulse = math.abs(math.sin(CurTime() * 5)) * 100
        timerColor = Color(255, pulse, pulse)
    elseif Manhunt.LocalEndgameMode then
        timerColor = COLOR_YELLOW
    end
    
    -- Format time
    local timeText = Manhunt.FormatTime(Manhunt.LocalMainTimer)
    
    -- Background
    local textW, textH = surface.GetTextSize(timeText)
    draw.RoundedBox(8, centerX - 100, topY - 10, 200, 70, COLOR_BLACK)
    
    -- Timer
    draw.SimpleText(timeText, "Manhunt_MainTimer", centerX, topY + 10, timerColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    
    -- Label
    draw.SimpleText("TIME REMAINING", "Manhunt_Label", centerX, topY + 50, COLOR_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
end

--[[
    Interval Timer Display
]]--

function Manhunt.DrawIntervalTimer(scrW, scrH)
    local centerX = scrW / 2
    local topY = 110
    
    -- Determine color based on state
    local timerColor = COLOR_BLUE
    if Manhunt.LocalGameState == GAME_STATE_HEADSTART then
        timerColor = COLOR_YELLOW
    elseif Manhunt.LocalEndgameMode then
        timerColor = COLOR_RED
    end
    
    -- Format time
    local timeText = Manhunt.FormatTime(Manhunt.LocalIntervalTimer)
    
    -- Background
    draw.RoundedBox(8, centerX - 100, topY - 10, 200, 50, COLOR_BLACK)
    
    -- Timer
    draw.SimpleText(timeText, "Manhunt_IntervalTimer", centerX, topY, timerColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    
    -- Label
    local labelText = "NEXT PING"
    if Manhunt.LocalGameState == GAME_STATE_HEADSTART then
        labelText = "HEADSTART"
    elseif Manhunt.LocalEndgameMode then
        labelText = "NEXT PING (ENDGAME)"
    end
    
    draw.SimpleText(labelText, "Manhunt_Label", centerX, topY + 25, COLOR_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
end

--[[
    Hunter HUD
]]--

function Manhunt.DrawHunterHUD(scrW, scrH)
    local leftX = 20
    local topY = 200
    
    -- Distance to fugitive
    if IsValid(Manhunt.LocalFugitive) then
        local distance = Manhunt.GetDistanceToFugitive()
        local distText = string.format("%.0f", distance / 12) .. " ft" -- Convert units to feet
        
        draw.RoundedBox(8, leftX, topY, 200, 60, COLOR_BLACK)
        draw.SimpleText("DISTANCE", "Manhunt_Label", leftX + 100, topY + 10, COLOR_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        draw.SimpleText(distText, "Manhunt_Distance", leftX + 100, topY + 30, COLOR_GREEN, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    end
    
    -- Surveillance alert
    if Manhunt.SurveillanceActive then
        local alertY = topY + 80
        draw.RoundedBox(8, leftX, alertY, 250, 50, Color(255, 50, 50, 200))
        
        local pulse = math.abs(math.sin(CurTime() * 8))
        local alertColor = Color(255, 255, 255, 150 + pulse * 105)
        draw.SimpleText("FUGITIVE LOCATION VISIBLE", "Manhunt_Label", leftX + 125, alertY + 25, alertColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    -- Freeze indicator during headstart
    if Manhunt.LocalGameState == GAME_STATE_HEADSTART then
        local freezeY = topY + 150
        draw.RoundedBox(8, leftX, freezeY, 200, 50, Color(100, 150, 255, 200))
        draw.SimpleText("FROZEN", "Manhunt_Alert", leftX + 100, freezeY + 25, COLOR_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    -- Endgame warning
    if Manhunt.LocalEndgameMode then
        local endgameY = scrH - 100
        draw.RoundedBox(8, leftX, endgameY, 350, 60, Color(255, 100, 0, 200))
        
        local pulse = math.abs(math.sin(CurTime() * 4))
        local warnColor = Color(255, 255, 255, 150 + pulse * 105)
        draw.SimpleText("ENDGAME MODE", "Manhunt_Alert", leftX + 175, endgameY + 10, warnColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        draw.SimpleText("Increased Surveillance", "Manhunt_Label", leftX + 175, endgameY + 40, COLOR_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    end
end

--[[
    Fugitive HUD
]]--

function Manhunt.DrawFugitiveHUD(scrW, scrH)
    local leftX = 20
    local topY = 200
    
    -- Speed boost indicator
    if Manhunt.SpeedBoostActive then
        draw.RoundedBox(8, leftX, topY, 200, 60, Color(100, 255, 100, 200))
        
        local pulse = math.abs(math.sin(CurTime() * 6))
        local boostColor = Color(255, 255, 255, 150 + pulse * 105)
        draw.SimpleText("SPEED BOOST", "Manhunt_Alert", leftX + 100, topY + 10, boostColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        draw.SimpleText("ACTIVE", "Manhunt_Label", leftX + 100, topY + 40, COLOR_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    end
    
    -- Survival tip
    local tipY = scrH - 100
    draw.RoundedBox(8, leftX, tipY, 300, 60, COLOR_BLACK)
    draw.SimpleText("STAY HIDDEN", "Manhunt_Label", leftX + 150, tipY + 15, COLOR_GREEN, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    draw.SimpleText("Survive until the timer runs out!", "Manhunt_Label", leftX + 150, tipY + 35, COLOR_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
end

--[[
    Victory Screen
]]--

function Manhunt.DrawVictoryScreen(scrW, scrH)
    if not Manhunt.VictoryWinner then return end
    
    local centerX = scrW / 2
    local centerY = scrH / 2
    
    -- Semi-transparent overlay
    draw.RoundedBox(0, 0, 0, scrW, scrH, Color(0, 0, 0, 180))
    
    -- Winner announcement
    local winnerText = ""
    local winnerColor = COLOR_WHITE
    
    if Manhunt.VictoryWinner == ROLE_HUNTER then
        winnerText = "HUNTER WINS"
        winnerColor = COLOR_RED
    else
        winnerText = "FUGITIVE WINS"
        winnerColor = COLOR_GREEN
    end
    
    -- Animate text
    local timeSinceVictory = CurTime() - (Manhunt.VictoryTime or 0)
    local scale = math.min(1, timeSinceVictory * 2)
    
    draw.SimpleText(winnerText, "Manhunt_Countdown", centerX, centerY - 60, winnerColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    
    -- Reason
    draw.SimpleText(Manhunt.VictoryReason or "", "Manhunt_Alert", centerX, centerY + 20, COLOR_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    
    -- Reset countdown
    local resetTime = 10 - math.floor(timeSinceVictory)
    if resetTime > 0 then
        draw.SimpleText("Resetting in " .. resetTime .. "...", "Manhunt_Label", centerX, centerY + 80, COLOR_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end

--[[
    3D Ping Markers
]]--

function Manhunt.DrawPingMarkers()
    if Manhunt.LocalRole != ROLE_HUNTER then return end
    
    local curTime = CurTime()
    
    -- Update and draw markers
    for i = #Manhunt.PingMarkers, 1, -1 do
        local marker = Manhunt.PingMarkers[i]
        local timeSinceCreation = curTime - marker.time
        
        -- Remove expired markers
        if timeSinceCreation > HUD_CONFIG.PingDuration then
            table.remove(Manhunt.PingMarkers, i)
        else
            -- Fade out alpha
            marker.alpha = 255 * (1 - timeSinceCreation / HUD_CONFIG.PingDuration)
            
            -- Draw 3D marker
            local screenPos = marker.pos:ToScreen()
            
            if screenPos.visible then
                local markerColor = Color(255, 100, 100, marker.alpha)
                local pulseSize = 30 + math.sin(curTime * 5) * 10
                
                -- Draw circle
                draw.NoTexture()
                surface.SetDrawColor(markerColor)
                
                local segments = 32
                local poly = {}
                for j = 0, segments do
                    local angle = math.rad((j / segments) * 360)
                    table.insert(poly, {
                        x = screenPos.x + math.cos(angle) * pulseSize,
                        y = screenPos.y + math.sin(angle) * pulseSize
                    })
                end
                surface.DrawPoly(poly)
                
                -- Draw text
                draw.SimpleText("LAST KNOWN POSITION", "Manhunt_Label", screenPos.x, screenPos.y - 50, markerColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        end
    end
end

print("[Manhunt] HUD system initialized")
