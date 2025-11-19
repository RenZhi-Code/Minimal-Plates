# MinimalPlates

A clean, minimal nameplate addon inspired by Plater, designed for maximum performance and cross-version compatibility.

## Features

### Core Features
- **Clean Minimal Design** - Sleek, uncluttered nameplates that focus on essential information
- **Cross-Version Support** - Works on Retail, Classic Era, Cataclysm, Wrath, Mists of Pandaria, and Midnight Beta
- **Performance Optimized** - Lightweight design with efficient rendering and secret value handling for Midnight
- **Fully Localized** - Support for 10 languages (EN, DE, FR, ES, IT, KO, PT, RU, CN, TW)

### Visual Customization
- **Custom Textures** - 8 built-in bar textures (Smooth, Smoother, BantoBar, Glaze, Otravi, and more)
- **Font Support** - 7 built-in fonts + custom font installation + LibSharedMedia-3.0 integration
- **Flexible Scaling** - Adjustable nameplate scale (0.5x - 2.0x)
- **Color Coding** - Class colors, threat coloring, and quest NPC highlighting (purple)
- **Elite/Rare Icons** - Custom icons with configurable display styles (Icon + Text, Icon Only, Text Only, None)

### Display Options
- **Enemy Health Bars** - Toggle between health bar mode or name-only mode
- **Friendly NPCs** - Show/hide friendly NPC nameplates
- **Cast Bars** - Interruptible cast tracking with shield indicators
- **Quest Icons** - Visual indicators for quest-related NPCs
- **Raid Markers** - Configurable position and size
- **Level Indicators** - Scaled level display positioned next to health bar
- **Classification Text** - Boss, Elite, Rare, and Rare Elite labels

### Advanced Features
- **Threat Coloring** - Red (tanking), Yellow (transitioning), Green (safe)
- **Quest NPC Detection** - Purple color override for quest givers and related NPCs
- **Absorb Shields** - Visual display of damage absorption effects
- **Power Bars** - Combo points, runes, chi, and other resources on target
- **Target Highlighting** - Scale-based target emphasis
- **Midnight Beta Compatible** - Full support for secret value handling in combat

## Installation

1. Download the latest release
2. Extract to `World of Warcraft\_retail_\Interface\AddOns\` (or your WoW version's AddOns folder)
3. Restart World of Warcraft
4. Type `/mp` to open settings

## Usage

### Slash Commands
- `/mp` - Open settings panel
- `/minimalplates` - Open settings panel

### Settings UI
The standalone settings window provides organized tabs for easy configuration:

**General Tab**
- Enable/Disable addon
- Class colors toggle
- Cast bar visibility
- Enemy health bar mode
- Friendly NPC visibility
- Bar texture selection
- Font and size options
- Health bar dimensions
- Global scale

**Health & Power Tab**
- Health text format (percentage, absolute, both)
- Power bar visibility
- Threat coloring
- Absorb shield display

**Auras & Icons Tab**
- Elite/Rare indicators
- Quest icon display
- Classification text
- Raid marker options
- Level icon scaling

**Advanced Tab**
- Additional customization options
- Performance tweaks
- Debug settings

## Localization

MinimalPlates is fully localized in:
- English (enUS)
- German (deDE)
- French (frFR)
- Spanish (esMX)
- Italian (itIT)
- Korean (koKR)
- Portuguese Brazil (ptBR)
- Russian (ruRU)
- Simplified Chinese (zhCN)
- Traditional Chinese (zhTW)

## Custom Fonts

To add custom fonts:
1. Place `.ttf` or `.otf` font files in `MinimalPlates\Libs\Fonts\`
2. Reload the UI (`/reload`)
3. Fonts will appear in the font dropdown under "Installed Fonts"

## Compatibility

### Supported Versions
- **Retail** (11.0.2+)
- **Midnight Beta** (12.0.0+) - Full secret value support
- **Mists of Pandaria Classic** (10.2.7+)
- **Wrath Classic** (3.4.3+)
- **Cataclysm Classic** (4.4.0+)
- **Classic Era** (1.15.8+)

### Known Issues
- Some Midnight Beta combat values may be hidden due to Blizzard's secret value system
- Rare/Elite detection may vary slightly between WoW versions

## FAQ

**Q: How do I move the nameplates?**  
A: Use Blizzard's built-in nameplate settings (`ESC` → `Interface` → `Names`) to adjust position and distance.

**Q: Why are some health values hidden in Midnight Beta?**  
A: Blizzard's new "secret value" system prevents addons from accessing certain combat data. MinimalPlates gracefully handles this with fallback displays.

**Q: Can I use this with other nameplate addons?**  
A: No, disable other nameplate addons (Plater, KUI, TidyPlates, etc.) to avoid conflicts.

**Q: How do I reset settings?**  
A: Type `/run MinimalPlatesDB = nil` then `/reload`

## Credits

- **Author**: AI Assistant
- **Inspired by**: Plater Nameplates
- **Icon Assets**: Custom elite/rare icons in `Libs/Icons/`
- **Font Support**: LibSharedMedia-3.0 integration

## License

All rights reserved. This addon is provided as-is for personal use in World of Warcraft.

## Support

For bug reports and feature requests, please use the CurseForge or GitHub issue tracker.

## Changelog

### Version 1.0.0
- Initial release
- Cross-version support (Retail, Classic, Midnight)
- 10 language localizations
- Custom elite/rare icons
- Quest NPC detection
- Midnight Beta secret value handling
- Standalone settings UI
- Custom font support
- LibSharedMedia integration
