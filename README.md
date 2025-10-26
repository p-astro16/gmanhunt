# Manhunt Minigame - Garry's Mod Addon

🎯 Een spannende Manhunt minigame addon voor Garry's Mod waarbij één speler de jager (hunter) is en de ander de voortvluchtige (fugitive). Een intense kat-en-muis spel met tactical gameplay en geavanceerde features! 

🔥 **Solo Mode**: Perfect voor testen - speel tegen jezelf en track je eigen positie!

## 📋 Vereisten

- **Garry's Mod** (natuurlijk!)
- **Geen externe dependencies!** 🎉
  - ✅ Minimap volledig geïntegreerd
  - ✅ Zelfstandige addon - geen extra installaties nodig

## 🚀 Installatie

### Methode 1: Via Steam Workshop (Aanbevolen)
1. Subscribe naar de addon op Steam Workshop
2. Start Garry's Mod opnieuw op
3. Klaar! 🎮

### Methode 2: Handmatige Installatie
1. Download en plaats de `manhunt_minigame` folder in:
   - `steamapps/common/GarrysMod/garrysmod/addons/`
2. Start je server/game opnieuw op

## ✅ Installatie Verificatie
Console moet tonen:
```
[Manhunt] Minigame addon loaded successfully!
[Manhunt] Integrated minimap system loaded
[Manhunt] Server network strings registered
[Manhunt] Client initialized
```

## 🎮 Hoe te gebruiken

### 🚀 Het spel starten

**Alle commands worden via console uitgevoerd (druk `~` om console te openen):**

#### Basis Commands:
```
manhunt_help                                    - Toont alle commands
manhunt_players                                 - Lijst beschikbare spelers  
manhunt_start <tijd> <interval> <hunter_naam>   - Start het spel
manhunt_reset                                   - Reset huidige spel
```

#### Voorbeelden:
```
manhunt_start 300 30 PlayerName    // 5 min game, ping elke 30s
manhunt_start 600 45 PlayerName    // 10 min game, ping elke 45s  
manhunt_start 900 60 PlayerName    // 15 min game, ping elke 60s
manhunt_start 300 30 MijnNaam      // Solo mode (test jezelf)
```

#### Stap-voor-stap:
1. **Controleer spelers:** `manhunt_players`
2. **Start spel:** `manhunt_start 600 45 HunterNaam`
3. **Reset indien nodig:** `manhunt_reset`

### 🎯 Solo Mode
Perfect voor testen! Gebruik je eigen naam als hunter:
```
manhunt_start 300 30 JouwEigenNaam
```
Je speelt tegen jezelf en ziet je eigen positie op de minimap.

Het moderne configuratiepanel bevat:

- **🕐 Total Game Time**: Totale spelduur (60-1800 seconden)
  - Standaard: 300s (5 minuten)
  - Range: 1-30 minuten
  
- **📍 Location Interval**: Hoe vaak hunter locatie ziet (10-300 seconden)
  - Standaard: 30s interval
  - Range: 10 seconden - 5 minuten
  
- **👤 Select Hunter**: Dropdown met alle online spelers
  - Toont real-time player list
  - Auto-refresh elke 2 seconden
  
- **🎯 START GAME**: Begin het spel (alleen admins)
- **🔄 RESET GAME**: Stop huidige spel (alleen admins)
- **📊 Game Status**: Live status indicator

### 🔐 Permissions
- **Iedereen**: Kan deelnemen, panel bekijken
- **Alleen Admins**: Kunnen spel starten/resetten

### Spelregels

**Voor de Hunter:**
- Moet de fugitive doden voordat de tijd op is
- Wordt bevroren tijdens de headstart fase
- Ziet de fugitive locatie op intervals op de minimap
- Kan ping markers plaatsen met de E-toets
- Ziet de afstand tot de fugitive onderaan het scherm

**Voor de Fugitive:**
- Moet overleven tot de tijd op is
- Krijgt een headstart periode
- Ontvangt elke 60 seconden een snelheidsboost van 5 seconden
- Moet zich verstoppen en ontsnappen

## 🎯 Complete Gameplay Features

### ⏱️ Advanced Timer Systeem
- **🕐 Main Timer**: Grote timer bovenaan toont resterende tijd
  - Wordt rood bij <30 seconden voor urgency
- **⏰ Interval Timer**: Kleinere timer voor volgende locatie-update
  - Blauw tijdens normaal spel, geel tijdens headstart
- **⏳ Countdown**: 5-seconden aftelanimatie voor gamestart
  - Grote centrale display met sound-free experience

### 🏃‍♀️ Tactical Headstart Systeem
- **Fugitive Protection**: Eerste interval als headstart
- **Hunter Freeze**: Hunter bevroren met `ply:Freeze(true)`
- **Visual Feedback**: "FROZEN - FUGITIVE HAS HEADSTART" indicator
- **Auto-Release**: Hunter automatisch ontvroren na headstart

### 💨 Dynamic Speed Boost
- **Timing**: Elke 60 seconden automatic trigger
- **Effect**: +20% walk/run speed voor 5 seconden  
- **Visual**: Groene "SPEED BOOST: Xs" indicator onderaan
- **Balance**: Geeft fugitive tactical advantage

### 📍 Strategic Ping System
- **Usage**: Hunter krijgt 1 ping per interval
- **Control**: E-toets om te pingen naar crosshair
- **Visual**: Rode circle markers met fade-out
- **Duration**: 10 seconden zichtbaar voor iedereen
- **Reset**: Nieuwe ping bij elke interval

### 📏 Real-time Distance Tracking
- **Hunter Only**: Ziet afstand tot fugitive (geen richting!)
- **Smart Colors**: 
  - 🔴 Rood: <100m (zeer dichtbij)
  - 🟡 Geel: 100-500m (medium range)  
  - ⚪ Wit: >500m (ver weg)
- **Live Update**: Real-time distance calculation

### 🎊 Victory & End-Game
- **Hunter Victory**: Fugitive elimination via any damage
- **Fugitive Victory**: Survive until timer = 0
- **Epic Victory Screen**: Full-screen overlay met kleuren
- **Auto-Reset**: 10 seconden countdown naar nieuwe game
- **Edge Cases**: Hunter death = game continues

### 📢 Advanced UX Features
- **📱 Mid-game Hints**: Halftime notifications
  - "Halfway there — stay alive!" (Fugitive)
  - "Half time! Keep chasing!" (Hunter)
- **👻 Spectator Mode**: Dode fugitive volgt hunter camera
- **🎨 Modern UI**: Clean, spaced design met hover effects
- **🔄 Live Updates**: Real-time player list, status updates
- **🎯 Integrated Minimap**: Built-in minimap system with player tracking

## 🎨 HUD Elementen

- **Grote timer**: Resterende speltijd (rood als <30 seconden)
- **Interval timer**: Tijd tot volgende locatie (blauw/geel)
- **Afstand indicator**: Voor hunter (onderaan scherm)
- **Speed boost**: Voor fugitive (groen, onderaan)
- **Ping counter**: Voor hunter (links onderaan)
- **Status berichten**: Frozen, hints, etc.
- **Victory screen**: Volledige overlay bij einde

## ⚙️ Technische Details

### Bestanden Structuur
```
manhunt_minigame/
├── lua/
│   ├── autorun/
│   │   └── sh_manhunt.lua          # Shared initialisatie
│   └── manhunt/
│       ├── client/
│       │   ├── cl_main.lua         # Client logica
│       │   ├── cl_hud.lua          # HUD systeem
│       │   └── cl_menu.lua         # Menu integratie
│       ├── server/
│       │   └── sv_main.lua         # Server logica
│       └── vgui/
│           └── manhunt_panel.lua   # Configuratie panel
```

### Console Commands
- `manhunt_menu` - Open configuratie panel

### Admin Rechten
- Alleen admins kunnen het spel starten/resetten
- Alle spelers kunnen deelnemen

## 🐛 Troubleshooting & Debugging

### ❌ Veelvoorkomende Problemen

**🗺️ "Minimap werkt niet"**
- ✅ Check console: `[Manhunt] Integrated minimap...` berichten
- ✅ Herstart Garry's Mod volledig
- ✅ Controleer dat manhunt_minigame correct geïnstalleerd is
- ✅ Minimap toont automatisch tijdens game

**🚫 "Spel start niet"**
- ✅ Minimaal 1 speler vereist (solo mode mogelijk!)
- ✅ Alleen admins kunnen starten
- ✅ Gebruik exacte speler naam uit `manhunt_players`
- ✅ Check console voor error messages

**👻 "Minimap verschijnt niet"**
- ✅ Minimap verschijnt automatisch tijdens spel
- ✅ Alleen hunter ziet minimap tijdens actieve fase
- ✅ Hunter moet correct geselecteerd zijn  
- ✅ Wacht tot interval timer afloopt
- ✅ Check of je daadwerkelijk de hunter bent

**💥 "VGUI Errors"**
- ✅ Herlaad addon: `lua_run include("autorun/sh_manhunt.lua")`
- ✅ Check console voor exacte error line numbers
- ✅ Zorg dat alle files correct geïnstalleerd zijn

### 🔍 Debug Mode

De addon heeft uitgebreide console logging. Check voor:

**✅ Startup Messages:**
```
[Manhunt] Minigame addon loaded successfully!
[Manhunt] Server network strings registered  
[Manhunt] Client initialized
[Manhunt] VGUI Panel registered successfully
```

**✅ Game Flow Messages:**
```
[Manhunt] Play button clicked
[Manhunt] Sending start_game to server...
[Manhunt] Received start_game from PlayerName
[Manhunt] StartGame called
[Manhunt] Broadcasting game start
```

**✅ Runtime Messages:**
- Timer updates (elke 10 seconden)
- Minimap show/hide events
- Victory conditions
- Player validation

### 🛠️ Reset Commands

**Soft Reset:**
```
lua_run include("autorun/sh_manhunt.lua")
```

**Hard Reset:**
```
changelevel gm_construct
```

**Emergency Reset:**
```
manhunt_menu
→ Click RESET GAME
```

## 📝 Licentie

Deze addon is gemaakt voor educatieve doeleinden en vrij gebruik in Garry's Mod.

## 🤝 Credits

- Volledig zelfstandige addon met geïntegreerde minimap
- Gemaakt voor Garry's Mod spelers

---

**Veel plezier met je Manhunt spellen!** 🎮
