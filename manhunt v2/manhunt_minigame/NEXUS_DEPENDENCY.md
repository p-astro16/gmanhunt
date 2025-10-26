# Nexus Library v2 Dependency

## What is Nexus Library?

Nexus Library v2 is a modern UI framework for Garry's Mod that provides beautiful, easy-to-use components for creating professional addon interfaces.

## Why Does Manhunt Need It?

The Manhunt minigame uses Nexus Library to provide:
- **Beautiful graphical menus** (F4 key)
- **Easy game configuration** with sliders and dropdowns
- **Professional appearance** with modern styling
- **User-friendly interface** for all skill levels

## How to Install Nexus Library v2

### Method 1: Steam Workshop (Recommended)

1. **Subscribe to Nexus Library v2:**
   - Visit: https://steamcommunity.com/sharedfiles/filedetails/?id=2820026045
   - Click "Subscribe"
   
2. **Restart Garry's Mod**
   - Nexus will automatically download and install

3. **Verify Installation:**
   - Start GMod
   - Check console for: `[Nexus]` messages
   - If you see errors, restart GMod again

### Method 2: Manual Installation

1. **Download from Workshop:**
   - Use a Workshop downloader tool
   - Or copy from another installation

2. **Install:**
   - Place in `garrysmod/addons/nexus_library/`
   - Ensure the folder structure is correct

3. **Verify:**
   - Restart GMod
   - Check console for Nexus loading messages

## What Happens Without Nexus?

If Nexus Library v2 is not installed:
- ❌ The F4 menu will NOT work
- ❌ You'll see Lua errors about "Nexus is nil"
- ❌ GUI configuration will be unavailable
- ✅ Console commands will still work (`manhunt_start` etc.)

## Troubleshooting

### "Nexus" is nil or undefined

**Problem:** Nexus Library is not loaded
**Solution:**
1. Subscribe to Workshop ID: 2820026045
2. Restart Garry's Mod completely
3. Check Workshop downloads are enabled
4. Verify Nexus loads BEFORE Manhunt (console)

### F4 Opens Different Menu

**Problem:** Another addon is using F4
**Solution:**
1. Use `manhunt_menu` console command instead
2. Or unbind F4: `unbind F4` then `bind F4 "manhunt_menu"`

### Menu Looks Broken

**Problem:** Nexus version mismatch
**Solution:**
1. Ensure you have Nexus Library **V2** (not v1)
2. Workshop ID must be: 2820026045
3. Update Nexus if outdated

### Still Having Issues?

**Fallback to Console Commands:**
Even without the GUI, you can use console commands:
```
manhunt_start 600 45 Hunter Fugitive
manhunt_reset
manhunt_stats
```

See INSTALLATION.md for full command reference.

## Nexus Library Features Used

The Manhunt addon uses these Nexus components:

### UIBuilder System
```lua
Nexus.UIBuilder:Start()
    :CreateFrame()
    :AddScrollPanel()
    :AddCategory()
    :AddBlock()
    :AddButton()
    :AddNumSlider()
    :AddComboBox()
    :AddCheckbox()
    :AddText()
    :AddSpacer()
```

### Colors
- `Nexus.Colors.Primary` - Blue buttons
- `Nexus.Colors.Secondary` - Gray buttons
- `Nexus.Colors.Green` - Success/start buttons
- `Nexus.Colors.Red` - Danger/reset buttons

### Scaling
- `Nexus:Scale(value)` - DPI-aware sizing

### Fonts
- `Nexus:GetFont(size)` - Consistent typography

## Credits

**Nexus Library v2** created by Indecisiv3
- Workshop: https://steamcommunity.com/sharedfiles/filedetails/?id=2820026045
- GitHub: https://github.com/Indecisiv3/Nexus-Library

**Manhunt Minigame** uses Nexus under its license terms.

---

**Thank you to the Nexus Library team for creating such a powerful UI framework!** 🙏
