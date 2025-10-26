# Manhunt Minigame - Developer Documentation

## Architecture Overview

The Manhunt addon is built using a modular architecture with clear separation between client and server logic. The system uses Garry's Mod's networking layer to synchronize game state between all players.

## Core Systems

### 1. Game State Machine

The game operates through five distinct states:

```lua
GAME_STATE_IDLE = 0       -- No game running
GAME_STATE_COUNTDOWN = 1  -- 5-second countdown before start
GAME_STATE_HEADSTART = 2  -- First interval, hunter frozen
GAME_STATE_ACTIVE = 3     -- Main gameplay
GAME_STATE_ENDED = 4      -- Victory screen and reset
```

**State Transitions:**
```
IDLE → COUNTDOWN → HEADSTART → ACTIVE → ENDED → IDLE
```

### 2. Network Architecture

#### Server → Client Messages

| Network String | Data | Purpose |
|---------------|------|---------|
| `manhunt_game_state` | UInt(8) state | Broadcast state changes |
| `manhunt_player_roles` | Entity hunter, Entity fugitive, Bool solo | Assign roles |
| `manhunt_timer_update` | UInt(16) main, UInt(16) interval, UInt(8) countdown, UInt(8) state | Sync timers |
| `manhunt_show_surveillance` | Vector pos, Angle ang | Activate surveillance |
| `manhunt_hide_surveillance` | - | Deactivate surveillance |
| `manhunt_emergency_surveillance` | Vector pos, Angle ang | Emergency weapon trigger |
| `manhunt_endgame_mode` | Bool active | Activate endgame |
| `manhunt_speed_boost` | Bool active | Speed boost events |
| `manhunt_victory` | UInt(8) winner, String reason | Game end |
| `manhunt_ping_marker` | Vector pos | Create 3D marker |

#### Client → Server Messages

| Network String | Data | Purpose |
|---------------|------|---------|
| `manhunt_config_update` | Table config | Settings sync |
| `manhunt_ui_request` | String uiType | Request UI panel |

### 3. Timer System

Three independent timers work together:

#### Main Timer
- **Purpose:** Total game duration countdown
- **Range:** 300-900 seconds (5-15 minutes)
- **Color Logic:**
  - White: Normal (>30s)
  - Red pulsing: Critical (<30s)
  - Yellow: Endgame mode (300s threshold)

#### Interval Timer
- **Purpose:** Countdown to next surveillance ping
- **Range:** 30-60 seconds
- **Behavior:** Halves during endgame mode
- **Color Logic:**
  - Blue: Normal gameplay
  - Yellow: Headstart phase
  - Red: Endgame mode

#### Countdown Timer
- **Purpose:** Game start countdown
- **Duration:** 5 seconds
- **Display:** Large centered numbers

### 4. Surveillance System

#### Render Target System
```lua
-- Create render target (200x200)
surveillanceRT = GetRenderTarget("manhunt_surveillance_rt", width, height)

-- Render view from fugitive's position
render.PushRenderTarget(surveillanceRT)
render.RenderView(view)
render.PopRenderTarget()

-- Display on HUD
surface.SetMaterial(Material("!manhunt_surveillance_rt"))
surface.DrawTexturedRect(x, y, w, h)
```

#### Trigger Conditions
1. **Periodic:** Every interval timer completion
2. **Emergency:** Hunter fires emergency weapon
3. **Duration:** 5 seconds (periodic), 3 seconds (emergency)

#### View Parameters
- **FOV:** 90 degrees
- **Position:** Fugitive eye position (pos + Vector(0,0,64))
- **Angles:** Fugitive eye angles
- **Update Rate:** ~30 FPS (0.033s)

### 5. Role System

```lua
ROLE_NONE = 0      -- Spectator
ROLE_HUNTER = 1    -- Hunter player
ROLE_FUGITIVE = 2  -- Fugitive player
```

**Role Assignment:**
- Server maintains authoritative role assignments
- Client receives role via `manhunt_player_roles` network message
- Solo mode: Player assigned both roles simultaneously

### 6. Victory System

#### Hunter Victory Conditions
```lua
-- ANY damage from hunter to fugitive
hook.Add("EntityTakeDamage", "Manhunt.DamageDetection", function(target, dmginfo)
    if target == Fugitive and dmginfo:GetAttacker() == Hunter then
        EndGame(ROLE_HUNTER, "Hunter eliminated the fugitive")
    end
end)
```

#### Fugitive Victory Conditions
```lua
-- Main timer reaches zero
if MainTimer <= 0 then
    EndGame(ROLE_FUGITIVE, "Survived until time ran out")
end
```

#### Disconnection Handling
```lua
hook.Add("PlayerDisconnected", "Manhunt.PlayerDisconnect", function(ply)
    if ply == Hunter then
        EndGame(ROLE_FUGITIVE, "Hunter disconnected")
    elseif ply == Fugitive then
        EndGame(ROLE_HUNTER, "Fugitive disconnected")
    end
end)
```

## Code Structure

### Server-Side (`sv_main.lua`)

**Key Functions:**

```lua
-- Start a new game
Manhunt.StartGame(duration, interval, hunter, fugitive, soloMode)
    → Returns: (bool success, string message)

-- End current game
Manhunt.EndGame(winner, reason)
    → winner: ROLE_HUNTER or ROLE_FUGITIVE
    → reason: String explanation

-- Reset game to idle
Manhunt.ResetGame()

-- Update game state
Manhunt.UpdateGameState(newState)

-- Main game loop (runs every second)
Manhunt.Think()

-- Trigger surveillance
Manhunt.TriggerSurveillance()

-- Emergency surveillance
Manhunt.EmergencySurveillance(hunter)

-- Speed boost activation
Manhunt.TriggerSpeedBoost()
```

**Game Loop Logic:**
```lua
timer.Create("Manhunt.GameLoop", 1, 0, function()
    Manhunt.Think()
end)
```

### Client-Side (`cl_main.lua`)

**Key Variables:**

```lua
Manhunt.LocalGameState        -- Current game state
Manhunt.LocalMainTimer         -- Synced main timer
Manhunt.LocalIntervalTimer     -- Synced interval timer
Manhunt.LocalCountdownTimer    -- Synced countdown timer
Manhunt.LocalHunter            -- Hunter entity
Manhunt.LocalFugitive          -- Fugitive entity
Manhunt.LocalRole              -- Local player's role
Manhunt.SurveillanceActive     -- Surveillance feed status
Manhunt.PingMarkers            -- Array of 3D markers
```

**Network Receivers:**
- All network messages are handled via `net.Receive()`
- State updates trigger HUD redraws
- Sound effects play on state changes

### HUD System (`cl_hud.lua`)

**Font Definitions:**
```lua
surface.CreateFont("Manhunt_MainTimer", {size = 48, weight = 700})
surface.CreateFont("Manhunt_IntervalTimer", {size = 24, weight = 500})
surface.CreateFont("Manhunt_Countdown", {size = 128, weight = 900})
surface.CreateFont("Manhunt_Distance", {size = 32, weight = 600})
surface.CreateFont("Manhunt_Label", {size = 18, weight = 500})
surface.CreateFont("Manhunt_Alert", {size = 36, weight = 700})
```

**Drawing Functions:**
```lua
Manhunt.DrawCountdown(scrW, scrH)
Manhunt.DrawMainTimer(scrW, scrH)
Manhunt.DrawIntervalTimer(scrW, scrH)
Manhunt.DrawHunterHUD(scrW, scrH)
Manhunt.DrawFugitiveHUD(scrW, scrH)
Manhunt.DrawVictoryScreen(scrW, scrH)
Manhunt.DrawPingMarkers()
```

### Surveillance System (`cl_surveillance.lua`)

**Render Pipeline:**
1. `RenderScene` hook: Render fugitive's view to texture
2. Throttling: Update at ~30 FPS
3. `HUDPaint` hook: Draw texture to screen
4. Overlays: Border, title, crosshair, status

**Performance Optimization:**
- Throttled updates (0.033s interval)
- Small render target (200x200)
- Only active when surveillance triggered
- Auto-cleanup on disconnect

## Extending the Addon

### Adding New Game Modes

1. **Define new state constant:**
```lua
GAME_STATE_CUSTOM = 5
```

2. **Add state handling in `Manhunt.Think()`:**
```lua
if Manhunt.GameState == GAME_STATE_CUSTOM then
    -- Custom logic
end
```

3. **Create network message:**
```lua
util.AddNetworkString("manhunt_custom_mode")
```

4. **Add client receiver:**
```lua
net.Receive("manhunt_custom_mode", function()
    -- Handle custom mode
end)
```

### Adding Custom HUD Elements

```lua
hook.Add("HUDPaint", "MyCustomHUD", function()
    if Manhunt.LocalGameState == GAME_STATE_ACTIVE then
        -- Draw custom element
        draw.SimpleText("Custom Text", "Manhunt_Label", x, y, color)
    end
end)
```

### Creating Custom Commands

**Server-side:**
```lua
concommand.Add("manhunt_custom", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then
        return -- Admin only
    end
    
    -- Custom logic
end)
```

### Hooking into Game Events

```lua
hook.Add("Manhunt.GameStart", "MyAddon.OnGameStart", function(hunter, fugitive, soloMode)
    -- React to game start
end)

hook.Add("Manhunt.GameEnd", "MyAddon.OnGameEnd", function(winner, reason)
    -- React to game end
end)

hook.Add("Manhunt.SurveillanceTriggered", "MyAddon.OnSurveillance", function()
    -- React to surveillance
end)
```

## Performance Considerations

### Network Optimization
- Batch timer updates (1 message per second)
- Use appropriate data types (UInt vs Int)
- Minimize string transmissions
- Only send to relevant players

### Render Optimization
- Small surveillance render target
- Throttled update rate
- Conditional rendering (only when active)
- Efficient font creation (once at startup)

### Memory Management
- Clean up ping markers after expiration
- Remove timers on game end
- Nil references to entities
- Clear render targets on disconnect

## Best Practices

### Error Handling
```lua
-- Always validate entities
if not IsValid(entity) then return end

-- Check game state before operations
if Manhunt.GameState != GAME_STATE_ACTIVE then return end

-- Validate parameters
if not duration or duration < 300 or duration > 900 then
    return false, "Invalid duration"
end
```

### Debug Output
```lua
if Manhunt.Debug then
    print("[Manhunt DEBUG] " .. message)
end
```

### Network Message Safety
```lua
-- Server → Client
net.Start("manhunt_example")
if IsValid(targetPlayer) then
    net.Send(targetPlayer)
else
    net.Broadcast()
end

-- Client → Server
net.Start("manhunt_request")
net.SendToServer()
```

## Testing Checklist

- [ ] Solo mode starts correctly
- [ ] Multiplayer roles assigned properly
- [ ] Countdown displays and functions
- [ ] Headstart freezes hunter
- [ ] Surveillance activates on interval
- [ ] Emergency weapon triggers surveillance
- [ ] Endgame mode activates at 5:00
- [ ] Interval timer halves in endgame
- [ ] Speed boost activates periodically
- [ ] Distance tracking accurate
- [ ] 3D ping markers appear and fade
- [ ] Hunter victory on damage
- [ ] Fugitive victory on timeout
- [ ] Disconnect handling works
- [ ] Victory screen displays
- [ ] Auto-reset after 10 seconds
- [ ] All console commands work
- [ ] Statistics track correctly

## API Reference

### Global Table: `Manhunt`

**Server Variables:**
```lua
Manhunt.GameState      -- Current game state
Manhunt.MainTimer      -- Seconds remaining
Manhunt.IntervalTimer  -- Seconds to next ping
Manhunt.Hunter         -- Hunter entity
Manhunt.Fugitive       -- Fugitive entity
Manhunt.SoloMode       -- Boolean
Manhunt.EndgameMode    -- Boolean
Manhunt.Stats          -- Statistics table
```

**Client Variables:**
```lua
Manhunt.LocalGameState        -- Local game state
Manhunt.LocalRole             -- Local player role
Manhunt.SurveillanceActive    -- Boolean
Manhunt.PingMarkers           -- Array of markers
```

**Shared Functions:**
```lua
Manhunt.FormatTime(seconds)           → "MM:SS"
Manhunt.GetStateString(state)         → "Idle"|"Countdown"|...
```

**Server Functions:**
```lua
Manhunt.StartGame(duration, interval, hunter, fugitive, solo) → (bool, string)
Manhunt.EndGame(winner, reason)
Manhunt.ResetGame()
Manhunt.UpdateGameState(newState)
Manhunt.BroadcastRoles()
Manhunt.BroadcastTimers()
Manhunt.TriggerSurveillance()
Manhunt.EmergencySurveillance(hunter)
Manhunt.TriggerSpeedBoost()
```

**Client Functions:**
```lua
Manhunt.GetDistanceToFugitive()       → number
Manhunt.IsLocalPlayerInGame()         → boolean
Manhunt.OpenMainMenu()
Manhunt.OpenConfigMenu()
Manhunt.OpenSettingsMenu()
```

## Troubleshooting Development Issues

### Issue: Network messages not received
**Check:**
- `util.AddNetworkString()` on server
- `AddCSLuaFile()` for client files
- Correct `net.Send()` target

### Issue: Surveillance feed black/broken
**Check:**
- Render target initialization
- Valid fugitive position/angles
- Map lighting
- Render hooks order

### Issue: Timers desync
**Check:**
- Server tick rate
- Network latency
- Timer broadcast frequency
- Client interpolation

### Issue: Hooks not firing
**Check:**
- Hook name spelling
- Hook priority/order
- Game state conditions
- Entity validity

## Future Development Roadmap

### Phase 1: Core Enhancement
- [ ] Full Nexus Library UI integration
- [ ] Persistent statistics database
- [ ] Configuration file system
- [ ] Custom map support

### Phase 2: Feature Expansion
- [ ] Multiple hunters/fugitives
- [ ] Team modes
- [ ] Spectator mode
- [ ] Replay system

### Phase 3: Polish
- [ ] Achievement system
- [ ] Leaderboards
- [ ] Custom sound packs
- [ ] Theme customization

### Phase 4: Advanced Features
- [ ] AI fugitive/hunter
- [ ] Powerups and abilities
- [ ] Map-specific mechanics
- [ ] Workshop integration

## Contributing Guidelines

1. **Code Style:**
   - Indent with tabs
   - Comment complex logic
   - Use descriptive variable names
   - Follow existing patterns

2. **Testing:**
   - Test solo and multiplayer
   - Verify all game states
   - Check edge cases
   - Performance profiling

3. **Documentation:**
   - Update this file for API changes
   - Add inline comments
   - Update README.md
   - Write example code

4. **Pull Requests:**
   - Clear description
   - Link to issues
   - Include testing steps
   - Follow commit conventions

## License

MIT License - See LICENSE file for full text

---

**Version:** 1.0.0  
**Last Updated:** 2025-10-26  
**Maintainer:** [Your Name]
