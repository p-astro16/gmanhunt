--[[
    Manhunt Minigame - 360° Surveillance System
    Renders fugitive's perspective for the hunter
]]--

-- Surveillance configuration
local SURVEILLANCE_CONFIG = {
    Width = 256,
    Height = 256,
    PosX = 20,
    PosY = 20,
    FOV = 90,
    FarZ = 8192,
    UpdateRate = 0.05, -- 20 FPS for better performance
}

-- Render target and material
local surveillanceRT = nil
local surveillanceMat = nil
local lastUpdate = 0
local rtInitialized = false

--[[
    Initialize Render Target
]]--

local function InitializeSurveillance()
    if rtInitialized then return end
    
    -- Create unique render target name
    local rtName = "manhunt_surveillance_" .. math.random(1000, 9999)
    
    -- Create render target with power-of-2 dimensions
    surveillanceRT = GetRenderTarget(rtName, SURVEILLANCE_CONFIG.Width, SURVEILLANCE_CONFIG.Height, true)
    
    if not surveillanceRT then
        print("[Manhunt ERROR] Failed to create render target!")
        return
    end
    
    -- Create material that references the render target
    local matName = "manhunt_surveillance_mat_" .. math.random(1000, 9999)
    surveillanceMat = CreateMaterial(matName, "UnlitGeneric", {
        ["$basetexture"] = rtName,
        ["$nocull"] = 1,
        ["$ignorez"] = 1,
        ["$nolod"] = 1,
    })
    
    if not surveillanceMat then
        print("[Manhunt ERROR] Failed to create material!")
        return
    end
    
    rtInitialized = true
    print("[Manhunt] Surveillance render target initialized: " .. rtName)
end

--[[
    Render Surveillance View
]]--

local function RenderSurveillanceView()
    if not Manhunt.SurveillanceActive then return end
    if not Manhunt.SurveillancePos then return end
    
    -- Initialize if needed
    InitializeSurveillance()
    
    if not rtInitialized or not surveillanceRT then return end
    
    -- Throttle updates
    local curTime = CurTime()
    if curTime - lastUpdate < SURVEILLANCE_CONFIG.UpdateRate then
        return
    end
    lastUpdate = curTime
    
    -- Set up view data
    local viewData = {
        origin = Manhunt.SurveillancePos + Vector(0, 0, 64), -- Eye height
        angles = Manhunt.SurveillanceAng or Angle(0, 0, 0),
        fov = SURVEILLANCE_CONFIG.FOV,
        drawviewer = false,
        drawhud = false,
        drawmonitors = false,
    }
    
    -- Store old RT
    local oldRT = render.GetRenderTarget()
    
    -- Render to texture
    render.PushRenderTarget(surveillanceRT)
    
    -- Clear with a visible color for debugging
    render.Clear(50, 50, 50, 255, true, true)
    
    -- Setup 3D rendering
    cam.Start3D(viewData.origin, viewData.angles, viewData.fov)
    
    -- Render the world
    render.RenderView(viewData)
    
    cam.End3D()
    
    render.PopRenderTarget()
    
    -- Restore old RT
    if oldRT then
        render.SetRenderTarget(oldRT)
    end
end

--[[
    Draw Surveillance Feed on HUD
]]--

local function DrawSurveillanceFeed()
    if not Manhunt.SurveillanceActive then return end
    
    InitializeSurveillance()
    
    if not rtInitialized or not surveillanceMat then 
        -- Draw error message if RT failed
        local x = SURVEILLANCE_CONFIG.PosX
        local y = SURVEILLANCE_CONFIG.PosY
        draw.RoundedBox(8, x, y, 200, 50, Color(255, 0, 0, 200))
        draw.SimpleText("RT FAILED", "Manhunt_Label", x + 100, y + 25, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        return 
    end
    
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
    
    -- Draw the render target
    surface.SetDrawColor(255, 255, 255, 255)
    surface.SetMaterial(surveillanceMat)
    surface.DrawTexturedRect(x, y, w, h)
    
    -- Crosshair overlay
    surface.SetDrawColor(255, 100, 100, 150)
    surface.DrawLine(x + w / 2 - 10, y + h / 2, x + w / 2 + 10, y + h / 2)
    surface.DrawLine(x + w / 2, y + h / 2 - 10, x + w / 2, y + h / 2 + 10)
    
    -- Status indicator
    draw.SimpleText("LIVE", "Manhunt_Label", x + w - 5, y + 5, Color(255, 50, 50), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
    
    -- Debug info
    if GetConVar("developer"):GetInt() > 0 then
        draw.SimpleText("RT OK", "DermaDefault", x + 5, y + h - 15, Color(0, 255, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end
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
    surveillanceRT = nil
    surveillanceMat = nil
    rtInitialized = false
end)

-- Force RT recreation on map change
hook.Add("InitPostEntity", "Manhunt.SurveillanceReset", function()
    surveillanceRT = nil
    surveillanceMat = nil
    rtInitialized = false
    print("[Manhunt] Surveillance system reset for new map")
end)

print("[Manhunt] 360° surveillance system loaded")
