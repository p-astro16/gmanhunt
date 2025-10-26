--[[
    Manhunt Minigame - Shared Initialization
    Loads all required modules for both client and server
]]--

Manhunt = Manhunt or {}

-- Game states
GAME_STATE_IDLE = 0
GAME_STATE_COUNTDOWN = 1
GAME_STATE_HEADSTART = 2
GAME_STATE_ACTIVE = 3
GAME_STATE_ENDED = 4

-- Role definitions
ROLE_NONE = 0
ROLE_HUNTER = 1
ROLE_FUGITIVE = 2

-- Game configuration defaults
Manhunt.Config = {
    GameDuration = 600,        -- 10 minutes default
    PingInterval = 45,         -- 45 seconds between pings
    CountdownTime = 5,         -- 5 second countdown
    EmergencyWeapon = "weapon_pistol", -- Hunter's emergency surveillance weapon
    EmergencyWeaponAmmo = 1,   -- Limited to 1 shot only
    FugitiveItems = {          -- Items given to fugitive at game start
        "arc9_eft_m7290",      -- Smoke grenade
        "arc9_eft_m18",        -- Smoke grenade (green)
    }
}

-- Dynamic endgame threshold (calculated as 20% of game duration at runtime)
Manhunt.EndgameThreshold = 0

-- Server-side loading
if SERVER then
    AddCSLuaFile()
    
    -- Load server modules
    include("manhunt/server/sv_main.lua")
    include("manhunt/server/sv_commands.lua")
    
    -- Add client files for download
    AddCSLuaFile("manhunt/client/cl_main.lua")
    AddCSLuaFile("manhunt/client/cl_hud.lua")
    AddCSLuaFile("manhunt/client/cl_menu.lua")
    AddCSLuaFile("manhunt/surveillance/cl_surveillance.lua")
    
    print("[Manhunt] Server modules loaded successfully")
end

-- Client-side loading
if CLIENT then
    include("manhunt/client/cl_main.lua")
    include("manhunt/client/cl_hud.lua")
    include("manhunt/client/cl_menu.lua")
    include("manhunt/surveillance/cl_surveillance.lua")
    
    print("[Manhunt] Client modules loaded successfully")
    print("[Manhunt] Requires Nexus Library v2 (Workshop ID: 2820026045)")
end

-- Shared utility functions
function Manhunt.FormatTime(seconds)
    local mins = math.floor(seconds / 60)
    local secs = seconds % 60
    return string.format("%02d:%02d", mins, secs)
end

function Manhunt.GetStateString(state)
    if state == GAME_STATE_IDLE then return "Idle"
    elseif state == GAME_STATE_COUNTDOWN then return "Countdown"
    elseif state == GAME_STATE_HEADSTART then return "Headstart"
    elseif state == GAME_STATE_ACTIVE then return "Active"
    elseif state == GAME_STATE_ENDED then return "Ended"
    else return "Unknown"
    end
end

print("[Manhunt] Shared initialization complete")
print("[Manhunt] Press F4 to open menu (or use console: manhunt_menu)")
