# Copilot Instructions for Shop_Aura SourcePawn Plugin

## Repository Overview

This repository contains a SourcePawn plugin for SourceMod that provides visual aura effects for players as part of a Shop system. The plugin allows players to purchase and customize colored aura effects that appear around their character in Source engine games.

**Core Purpose**: A Shop module that grants visual aura effects with customizable colors, including rainbow effects and client preference management.

## Project Structure

```
addons/sourcemod/
├── scripting/
│   └── Shop_Aura.sp          # Main plugin source code
└── configs/
    └── shop/
        └── aura_colors.txt   # Aura color definitions and shop items

.github/
├── workflows/
│   └── ci.yml               # GitHub Actions CI/CD pipeline
└── copilot-instructions.md  # This file

sourceknight.yaml            # Build system configuration
.gitignore                   # Git ignore patterns
```

## Language & Platform Specifics

- **Language**: SourcePawn (Source engine scripting language)
- **Platform**: SourceMod 1.11.0+ (game server modification framework)
- **Compiler**: SourcePawn Compiler (spcomp) via sourceknight build system
- **Target Games**: Source engine games (CS:GO, CS2, TF2, etc.)

## Dependencies

This plugin requires several dependencies that are automatically managed by sourceknight:

1. **SourceMod 1.11.0+** - Core scripting platform
2. **Shop-Core** - Base shop system (https://github.com/srcdslab/sm-plugin-Shop-Core)
3. **MultiColors** - Chat color formatting (https://github.com/srcdslab/sm-plugin-MultiColors)

Dependencies are defined in `sourceknight.yaml` and automatically downloaded during build.

## Build System

### Primary Build Tool: sourceknight
- Modern SourceMod build system
- Configuration in `sourceknight.yaml`
- Handles dependency management automatically
- Supports both local and CI builds

### Build Commands
```bash
# Install sourceknight (if not available)
pip install sourceknight

# Build the plugin
sourceknight build

# Clean build artifacts
sourceknight clean
```

### CI/CD Pipeline
- GitHub Actions workflow in `.github/workflows/ci.yml`
- Automatically builds on push/PR to main/master
- Creates releases and packages
- Uses `maxime1907/action-sourceknight@v1` action

## Code Style & Standards

### SourcePawn-Specific Guidelines
```sourcepawn
#pragma semicolon 1           // ALWAYS include - enforces semicolons
#pragma newdecls required     // ALWAYS include - enforces new syntax
```

### Naming Conventions
- **Global variables**: Prefix with `g_` (e.g., `g_iClientColor`, `g_hTimer`)
- **Functions**: PascalCase (e.g., `SetClientAura`, `OnEquipItem`)
- **Local variables**: camelCase (e.g., `iClient`, `sBuffer`)
- **Constants**: UPPER_CASE (e.g., `MAXPLAYERS`)

### Memory Management
```sourcepawn
// OLD WAY (avoid in new code)
Handle g_hKeyValues;
if (g_hKeyValues != INVALID_HANDLE) 
    CloseHandle(g_hKeyValues);

// PREFERRED WAY
Handle g_hKeyValues;
delete g_hKeyValues;  // Safe to call on null handles
```

### Best Practices for This Plugin
1. **Timers**: Always store timer handles and clean up properly
2. **Client Disconnection**: Always clean up client-specific data
3. **Memory**: Use `delete` instead of `CloseHandle` where possible
4. **Client Validation**: Always validate client indices and connection state
5. **Event Handling**: Properly hook/unhook events

## Plugin Architecture

### Core Components

1. **Shop Integration**: Implements Shop-Core callbacks for item management
2. **Visual Effects**: Uses TE (Temp Entity) system for beam ring effects  
3. **Client Preferences**: Saves visibility settings using SourceMod cookies
4. **Configuration**: KeyValues-based color configuration system
5. **Timer System**: Repeating timers for continuous aura effects

### Key Functions

- `Shop_Started()` - Registers items with shop system
- `OnEquipItem()` - Handles item purchases/activation
- `SetClientAura()` - Starts aura effect for client
- `Timer_Beacon()` - Renders aura effects continuously
- `Event_OnPlayerSpawn()` - Restores aura after respawn

### Configuration System

The `aura_colors.txt` file defines available aura colors:
```
"color_id" {
    "name"      "Display Name"
    "color"     "R G B A"        // RGBA values 0-255
    "price"     "2500"           // Shop price
    "sellprice" "750"            // Optional sell price
    "duration"  "0"              // 0 = permanent, >0 = seconds
}
```

## Common Patterns & APIs

### Client Management
```sourcepawn
// Always validate clients
if (!IsClientInGame(client) || !IsPlayerAlive(client))
    return;

// Check for real players (not bots)
if (IsFakeClient(client))
    return;
```

### SourceMod Events
```sourcepawn
// Hook events in OnPluginStart()
HookEvent("player_spawn", Event_OnPlayerSpawn);

// Event callback signature
public void Event_OnPlayerSpawn(Handle hEvent, const char[] sName, bool bSilent) {
    int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
    // Handle event...
}
```

### Timer Management
```sourcepawn
// Create repeating timer
g_hTimer[client] = CreateTimer(0.1, Timer_Beacon, client, TIMER_REPEAT);

// Clean up timer
if (g_hTimer[client] != INVALID_HANDLE) {
    KillTimer(g_hTimer[client]);
    g_hTimer[client] = INVALID_HANDLE;
}
```

### KeyValues Configuration
```sourcepawn
// Load configuration
Handle kv = CreateKeyValues("SectionName");
FileToKeyValues(kv, configPath);

// Navigate and read values
if (KvJumpToKey(kv, "itemname")) {
    int price = KvGetNum(kv, "price", 0);
    KvGetString(kv, "name", buffer, sizeof(buffer));
}
```

## Testing & Validation

### Local Testing
1. Set up a local SourceMod test server
2. Compile plugin: `sourceknight build`
3. Copy to `addons/sourcemod/plugins/`
4. Load via `sm plugins load Shop_Aura`
5. Test with shop commands

### Manual Testing Checklist
- [ ] Plugin loads without errors
- [ ] Shop integration works (items appear in shop)
- [ ] Aura effects render correctly
- [ ] Client preferences save/load properly
- [ ] Memory cleanup on client disconnect
- [ ] ConVar changes take effect
- [ ] Configuration file parsing

### Common Issues
- **Timer leaks**: Always clean up timers on client disconnect
- **Memory leaks**: Use `delete` instead of deprecated handle functions
- **Client validation**: Check IsClientInGame() before client operations
- **Effect visibility**: Ensure clients have visibility preferences set

## Plugin-Specific Guidelines

### When Modifying Aura Effects
- Always test both aura styles (wide expanding vs thin wave)
- Validate color ranges (0-255 for RGBA)
- Consider performance impact of timer frequency
- Test with multiple clients for network efficiency

### Configuration Changes
- Update `aura_colors.txt` for new colors/items
- Maintain KeyValues structure integrity
- Test price/duration validation
- Ensure color names are unique identifiers

### Shop Integration
- Follow Shop-Core callback patterns
- Handle item toggle states properly
- Implement proper category management
- Use Shop_ToggleClientCategoryOff() for exclusivity

### Performance Considerations
- Timer frequency impacts server performance
- Minimize client loops in timer callbacks
- Cache frequently accessed data
- Use efficient TE (Temp Entity) calls

## Common SourcePawn Gotchas

1. **Array bounds**: Always validate array access with proper bounds checking
2. **String buffers**: Use `sizeof(buffer)` not hardcoded sizes
3. **Handle management**: Modern SourcePawn prefers `delete` over `CloseHandle`
4. **Client loops**: Use `MaxClients` constant, not magic numbers
5. **Event memory**: Events automatically clean up, don't close event handles

## Debugging Tips

1. **Enable debug logging**: Use `LogMessage()` for troubleshooting
2. **Check error logs**: Monitor `addons/sourcemod/logs/errors_*.log`
3. **Memory debugging**: Use `sm_dump_handles` to check for leaks
4. **Live reload**: Use `sm plugins reload Shop_Aura` for quick testing
5. **ConVar inspection**: Use `sm_cvar list` to verify ConVar states

When working on this plugin, prioritize minimal changes, proper memory management, and maintaining compatibility with the existing Shop ecosystem.