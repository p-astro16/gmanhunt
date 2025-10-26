--[[
    Manhunt Minigame - 360° Surveillance System
    Renders fugitive's perspective for the hunter
]]--

-- Surveillance configuration
local SURVEILLANCE_CONFIG = {
    Width = 200,
    Height = 200,
    PosX = 20,
    PosY = 20,
    FOV = 90,
    FarZ = 4096,
    UpdateRate = 0.033, -- ~30 FPS
}

-- Render target
local surveillanceRT = nil
local lastUpdate = 0

--[[
    Initialize Render Target
]]--

local function InitializeSurveillance()
    if surveillanceRT then return end
    
    surveillanceRT = GetRenderTarget("manhunt_surveillance_rt", SURVEILLANCE_CONFIG.Width, SURVEILLANCE_CONFIG.Height)
    print("[Manhunt] Surveillance render target created")
end

--[[
    Render Surveillance View
]]--

local function RenderSurveillanceView()
    if not Manhunt.SurveillanceActive then return end
    if not Manhunt.SurveillancePos then return end
    
    -- Throttle updates
    local curTime = CurTime()
    if curTime - lastUpdate < SURVEILLANCE_CONFIG.UpdateRate then
        return
    end
    lastUpdate = curTime
    
    InitializeSurveillance()
    
    -- Set up view
    local view = {
        origin = Manhunt.SurveillancePos + Vector(0, 0, 64), -- Eye height
        angles = Manhunt.SurveillanceAng or Angle(0, 0, 0),
        fov = SURVEILLANCE_CONFIG.FOV,
        drawviewer = false,
        drawhud = false,
    }
    
    -- Render to texture
    render.PushRenderTarget(surveillanceRT)
    render.Clear(0, 0, 0, 255)
    render.ClearDepth()
    
    render.RenderView(view)
    
    render.PopRenderTarget()
end

--[[
    Draw Surveillance Feed on HUD
]]--

local function DrawSurveillanceFeed()
    if not Manhunt.SurveillanceActive then return end
    if not surveillanceRT then return end
    
    local x = SURVEILLANCE_CONFIG.PosX
    local y = SURVEILLANCE_CONFIG.PosY
    local w = SURVEILLANCE_CONFIG.Width
    local h = SURVEILLANCE_CONFIG.Height
    
    -- Background
    draw.RoundedBox(8, x - 5, y - 30, w + 10, h + 35, Color(0, 0, 0, 220))
    
    -- Title
    local pulse = math.abs(math.sin(CurTime() * 8))
    local titleColor = Color(255, 100, 100, 150 + pulse * 105)
    draw.SimpleText("360° SURVEILLANCE", "Manhunt_Label", x + w / 2, y - 20, titleColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    
    -- Border
    surface.SetDrawColor(255, 100, 100, 255)
    surface.DrawOutlinedRect(x - 2, y - 2, w + 4, h + 4, 2)
    
    -- Render target
    surface.SetDrawColor(255, 255, 255, 255)
    surface.SetMaterial(Material("!manhunt_surveillance_rt"))
    surface.DrawTexturedRect(x, y, w, h)
    
    -- Crosshair overlay
    surface.SetDrawColor(255, 100, 100, 100)
    surface.DrawLine(x + w / 2 - 10, y + h / 2, x + w / 2 + 10, y + h / 2)
    surface.DrawLine(x + w / 2, y + h / 2 - 10, x + w / 2, y + h / 2 + 10)
    
    -- Status indicator
    draw.SimpleText("LIVE", "Manhunt_Label", x + w - 5, y + 5, Color(255, 50, 50), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
end

--[[
    Hooks
]]--

hook.Add("RenderScene", "Manhunt.RenderSurveillance", function()
    if Manhunt.LocalRole != ROLE_HUNTER then return end
    if not Manhunt.SurveillanceActive then return end
    
    RenderSurveillanceView()
end)

hook.Add("HUDPaint", "Manhunt.DrawSurveillance", function()
    if Manhunt.LocalRole != ROLE_HUNTER then return end
    if not Manhunt.SurveillanceActive then return end
    
    DrawSurveillanceFeed()
end)

-- Cleanup
hook.Add("ShutDown", "Manhunt.SurveillanceCleanup", function()
    if surveillanceRT then
        surveillanceRT = nil
    end
end)

print("[Manhunt] 360° surveillance system initialized")
