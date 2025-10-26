--[[
    Manhunt Minigame - Menu Interface
    Complete Nexus Library UI implementation
]]--

-- Main menu state
Manhunt.UI = Manhunt.UI or {}
Manhunt.UI.CurrentFrame = nil
Manhunt.UI.SelectedHunter = nil
Manhunt.UI.SelectedFugitive = nil
Manhunt.UI.GameDuration = 600
Manhunt.UI.PingInterval = 45

--[[
    Main Menu - Game Configuration
]]--
function Manhunt.OpenMainMenu()
    print("[Manhunt] Opening main menu...")
    
    -- Close existing frame
    if IsValid(Manhunt.UI.CurrentFrame) then
        Manhunt.UI.CurrentFrame:Remove()
    end
    
    -- Get player list for dropdown
    local playerList = {}
    for _, ply in ipairs(player.GetAll()) do
        table.insert(playerList, ply:Nick())
    end
    
    -- Create main UI
    local mainUI = Nexus.UIBuilder:Start({debug = false})
        :CreateFrame({
            title = "Manhunt Configuration",
            icon = "bkG9Y5p", -- Hunter icon
            size = {
                w = Nexus:Scale(600),
                h = Nexus:Scale(550),
            },
            darken = true,
            id = "manhunt_main_menu",
        })
        
        :AddScrollPanel()
        
        -- Game Status Section
        :AddCategory({
            title = "Current Game Status",
            size = {h = Nexus:Scale(120)},
        })
        
        :AddBlock({
            size = {h = Nexus:Scale(80)},
            padding = Nexus:Scale(10),
        })
        
        :AddText({
            text = "State: " .. Manhunt.GetStateString(Manhunt.LocalGameState),
            align = TEXT_ALIGN_LEFT,
        })
        
        :AddText({
            text = "Time Remaining: " .. Manhunt.FormatTime(Manhunt.LocalMainTimer),
            align = TEXT_ALIGN_LEFT,
        })
        
        :AddText({
            text = "Hunter: " .. (IsValid(Manhunt.LocalHunter) and Manhunt.LocalHunter:Nick() or "None"),
            align = TEXT_ALIGN_LEFT,
        })
        
        :AddText({
            text = "Fugitive: " .. (IsValid(Manhunt.LocalFugitive) and Manhunt.LocalFugitive:Nick() or "None"),
            align = TEXT_ALIGN_LEFT,
        })
        
        :BackupParent() -- Exit block
        :BackupParent() -- Exit category
        
        -- Game Settings Section
        :AddCategory({
            title = "Game Settings",
            size = {h = Nexus:Scale(250)},
        })
        
        :AddBlock({
            size = {h = Nexus:Scale(210)},
            padding = Nexus:Scale(10),
        })
        
        :AddText({
            text = "Game Duration: " .. math.floor(Manhunt.UI.GameDuration / 60) .. ":" .. string.format("%02d", Manhunt.UI.GameDuration % 60),
            align = TEXT_ALIGN_LEFT,
        })
        
        :AddNumSlider({
            size = {h = Nexus:Scale(30)},
            value = Manhunt.UI.GameDuration,
            max = 3600,
            onChange = function(value)
                Manhunt.UI.GameDuration = math.max(10, math.floor(value))
            end,
        })
        
        :AddSpacer()
        
        :AddText({
            text = "Ping Interval: " .. Manhunt.UI.PingInterval .. " seconds",
            align = TEXT_ALIGN_LEFT,
        })
        
        :AddNumSlider({
            size = {h = Nexus:Scale(30)},
            value = Manhunt.UI.PingInterval,
            max = 60,
            onChange = function(value)
                Manhunt.UI.PingInterval = math.max(5, math.floor(value))
            end,
        })
        
        :AddSpacer()
        
        -- Quick Presets
        :AddText({
            text = "Quick Presets:",
            align = TEXT_ALIGN_LEFT,
        })
        
        :AddButton({
            text = "Quick Game (5 min, 30s)",
            size = {h = Nexus:Scale(30)},
            color = Nexus.Colors.Primary,
            DoClick = function()
                Manhunt.UI.GameDuration = 300
                Manhunt.UI.PingInterval = 30
                Manhunt.OpenMainMenu() -- Refresh
            end,
        })
        
        :AddButton({
            text = "Standard (10 min, 45s)",
            size = {h = Nexus:Scale(30)},
            color = Nexus.Colors.Secondary,
            DoClick = function()
                Manhunt.UI.GameDuration = 600
                Manhunt.UI.PingInterval = 45
                Manhunt.OpenMainMenu() -- Refresh
            end,
        })
        
        :AddButton({
            text = "Marathon (15 min, 60s)",
            size = {h = Nexus:Scale(30)},
            color = Nexus.Colors.Green,
            DoClick = function()
                Manhunt.UI.GameDuration = 900
                Manhunt.UI.PingInterval = 60
                Manhunt.OpenMainMenu() -- Refresh
            end,
        })
        
        :BackupParent() -- Exit block
        :BackupParent() -- Exit category
        
        -- Player Selection
        :AddCategory({
            title = "Player Selection",
            size = {h = Nexus:Scale(180)},
        })
        
        :AddBlock({
            size = {h = Nexus:Scale(140)},
            padding = Nexus:Scale(10),
        })
        
        :AddText({
            text = "Hunter: " .. (Manhunt.UI.SelectedHunter or "Select player..."),
            align = TEXT_ALIGN_LEFT,
        })
        
        :AddComboBox({
            size = {
                w = Nexus:Scale(560),
                h = Nexus:Scale(30),
            },
            text = "Select Hunter",
        })
    
    -- Add player choices for hunter
    for _, name in ipairs(playerList) do
        mainUI:AddChoice(name, function()
            Manhunt.UI.SelectedHunter = name
            Manhunt.OpenMainMenu() -- Refresh
        end)
    end
    
    mainUI:BackupParent() -- Exit combobox
        
        :AddSpacer()
        
        :AddText({
            text = "Fugitive: " .. (Manhunt.UI.SelectedFugitive or "Solo Mode"),
            align = TEXT_ALIGN_LEFT,
        })
        
        :AddComboBox({
            size = {
                w = Nexus:Scale(560),
                h = Nexus:Scale(30),
            },
            text = "Select Fugitive (Optional)",
        })
    
    -- Add solo mode option
    mainUI:AddChoice("Solo Mode", function()
        Manhunt.UI.SelectedFugitive = nil
        Manhunt.OpenMainMenu() -- Refresh
    end)
    
    -- Add player choices for fugitive
    for _, name in ipairs(playerList) do
        mainUI:AddChoice(name, function()
            Manhunt.UI.SelectedFugitive = name
            Manhunt.OpenMainMenu() -- Refresh
        end)
    end
    
    mainUI:BackupParent() -- Exit combobox
        :BackupParent() -- Exit block
        :BackupParent() -- Exit category
        
        -- Action Buttons
        :AddSpacer()
        
        :AddButton({
            text = "START GAME",
            size = {h = Nexus:Scale(40)},
            color = Nexus.Colors.Green,
            DoClick = function()
                -- Validate selection
                if not Manhunt.UI.SelectedHunter then
                    chat.AddText(Color(255, 100, 100), "[Manhunt] ", Color(255, 255, 255), "Please select a hunter!")
                    return
                end
                
                -- Send start command to server
                LocalPlayer():ConCommand(string.format("manhunt_start %d %d %s %s", 
                    Manhunt.UI.GameDuration,
                    Manhunt.UI.PingInterval,
                    Manhunt.UI.SelectedHunter,
                    Manhunt.UI.SelectedFugitive or ""
                ))
                
                -- Close menu
                if IsValid(Manhunt.UI.CurrentFrame) then
                    Manhunt.UI.CurrentFrame:Remove()
                end
            end,
        })
        
        :AddButton({
            text = "RESET GAME",
            size = {h = Nexus:Scale(35)},
            color = Nexus.Colors.Red,
            DoClick = function()
                LocalPlayer():ConCommand("manhunt_reset")
                
                if IsValid(Manhunt.UI.CurrentFrame) then
                    Manhunt.UI.CurrentFrame:Remove()
                end
            end,
        })
        
        :AddButton({
            text = "View Statistics",
            size = {h = Nexus:Scale(35)},
            color = Nexus.Colors.Primary,
            DoClick = function()
                Manhunt.OpenStatisticsMenu()
            end,
        })
        
        :AddButton({
            text = "Settings",
            size = {h = Nexus:Scale(35)},
            color = Nexus.Colors.Secondary,
            DoClick = function()
                Manhunt.OpenSettingsMenu()
            end,
        })
    
    -- Store frame reference
    Manhunt.UI.CurrentFrame = mainUI:GetLastPanel()
    
    print("[Manhunt] Main menu opened")
end

--[[
    Config Menu (Admin)
]]--
function Manhunt.OpenConfigMenu()
    if not LocalPlayer():IsAdmin() then
        chat.AddText(Color(255, 100, 100), "[Manhunt] ", Color(255, 255, 255), "Admin only!")
        return
    end
    
    Manhunt.OpenMainMenu()
end

--[[
    Settings Menu
]]--
function Manhunt.OpenSettingsMenu()
    print("[Manhunt] Opening settings menu...")
    
    -- Close existing frame
    if IsValid(Manhunt.UI.CurrentFrame) then
        Manhunt.UI.CurrentFrame:Remove()
    end
    
    local settingsUI = Nexus.UIBuilder:Start({debug = false})
        :CreateFrame({
            title = "Manhunt Settings",
            icon = "zNjyB2M", -- Settings icon
            size = {
                w = Nexus:Scale(500),
                h = Nexus:Scale(400),
            },
            darken = true,
            id = "manhunt_settings_menu",
        })
        
        :AddScrollPanel()
        
        -- HUD Settings
        :AddCategory({
            title = "HUD Settings",
            size = {h = Nexus:Scale(150)},
        })
        
        :AddBlock({
            size = {h = Nexus:Scale(110)},
            padding = Nexus:Scale(10),
        })
        
        :AddCheckbox({
            text = "Show Main Timer",
            size = {h = Nexus:Scale(30)},
            state = true,
            stateChanged = function(state)
                -- TODO: Store in cookie/convars
                print("[Manhunt] Show timer:", state)
            end,
        })
        
        :AddCheckbox({
            text = "Show Surveillance Feed",
            size = {h = Nexus:Scale(30)},
            state = true,
            stateChanged = function(state)
                print("[Manhunt] Show surveillance:", state)
            end,
        })
        
        :AddCheckbox({
            text = "Show 3D Ping Markers",
            size = {h = Nexus:Scale(30)},
            state = true,
            stateChanged = function(state)
                print("[Manhunt] Show markers:", state)
            end,
        })
        
        :BackupParent() -- Exit block
        :BackupParent() -- Exit category
        
        -- Audio Settings
        :AddCategory({
            title = "Audio Settings",
            size = {h = Nexus:Scale(100)},
        })
        
        :AddBlock({
            size = {h = Nexus:Scale(60)},
            padding = Nexus:Scale(10),
        })
        
        :AddCheckbox({
            text = "Enable Sound Effects",
            size = {h = Nexus:Scale(30)},
            state = true,
            stateChanged = function(state)
                print("[Manhunt] Sound effects:", state)
            end,
        })
        
        :BackupParent()
        :BackupParent()
        
        -- Action Buttons
        :AddSpacer()
        
        :AddButton({
            text = "Back to Main Menu",
            size = {h = Nexus:Scale(35)},
            color = Nexus.Colors.Primary,
            DoClick = function()
                Manhunt.OpenMainMenu()
            end,
        })
        
        :AddButton({
            text = "Close",
            size = {h = Nexus:Scale(35)},
            color = Nexus.Colors.Secondary,
            DoClick = function()
                if IsValid(Manhunt.UI.CurrentFrame) then
                    Manhunt.UI.CurrentFrame:Remove()
                end
            end,
        })
    
    Manhunt.UI.CurrentFrame = settingsUI:GetLastPanel()
end

--[[
    Statistics Menu
]]--
function Manhunt.OpenStatisticsMenu()
    print("[Manhunt] Opening statistics menu...")
    
    -- Close existing frame
    if IsValid(Manhunt.UI.CurrentFrame) then
        Manhunt.UI.CurrentFrame:Remove()
    end
    
    -- Request stats from server (for now we show placeholder)
    local statsUI = Nexus.UIBuilder:Start({debug = false})
        :CreateFrame({
            title = "Manhunt Statistics",
            icon = "3kM9L2p", -- Stats icon
            size = {
                w = Nexus:Scale(450),
                h = Nexus:Scale(350),
            },
            darken = true,
            id = "manhunt_stats_menu",
        })
        
        :AddScrollPanel()
        
        :AddCategory({
            title = "Server Statistics",
            size = {h = Nexus:Scale(200)},
        })
        
        :AddBlock({
            size = {h = Nexus:Scale(160)},
            padding = Nexus:Scale(10),
        })
        
        :AddText({
            text = "Games Played: Loading...",
            align = TEXT_ALIGN_LEFT,
        })
        
        :AddText({
            text = "Hunter Wins: Loading...",
            align = TEXT_ALIGN_LEFT,
        })
        
        :AddText({
            text = "Fugitive Wins: Loading...",
            align = TEXT_ALIGN_LEFT,
        })
        
        :AddText({
            text = "Win Rate (Hunter): Loading...",
            align = TEXT_ALIGN_LEFT,
        })
        
        :AddText({
            text = "Win Rate (Fugitive): Loading...",
            align = TEXT_ALIGN_LEFT,
        })
        
        :AddText({
            text = "Average Game Duration: Loading...",
            align = TEXT_ALIGN_LEFT,
        })
        
        :BackupParent()
        :BackupParent()
        
        :AddSpacer()
        
        :AddButton({
            text = "Refresh Stats",
            size = {h = Nexus:Scale(35)},
            color = Nexus.Colors.Green,
            DoClick = function()
                LocalPlayer():ConCommand("manhunt_stats")
            end,
        })
        
        :AddButton({
            text = "Back to Main Menu",
            size = {h = Nexus:Scale(35)},
            color = Nexus.Colors.Primary,
            DoClick = function()
                Manhunt.OpenMainMenu()
            end,
        })
        
        :AddButton({
            text = "Close",
            size = {h = Nexus:Scale(35)},
            color = Nexus.Colors.Secondary,
            DoClick = function()
                if IsValid(Manhunt.UI.CurrentFrame) then
                    Manhunt.UI.CurrentFrame:Remove()
                end
            end,
        })
    
    Manhunt.UI.CurrentFrame = statsUI:GetLastPanel()
end

-- Bind to F4 key (optional)
hook.Add("PlayerButtonDown", "Manhunt.OpenMenuKey", function(ply, button)
    if button == KEY_F4 and ply == LocalPlayer() then
        Manhunt.OpenMainMenu()
    end
end)

print("[Manhunt] Nexus UI menu system loaded")
