---@class MinimalPlates
local MP = MinimalPlates

-- German (Germany)
MP.L:RegisterLocale("deDE", {
  -- General
  ["Enable MinimalPlates"] = "MinimalPlates aktivieren",
  ["Use Class Colors"] = "Klassenfarben verwenden",
  ["Show Cast Bar"] = "Zauberleiste anzeigen",
  ["Show Enemy Health Bars (uncheck for name-only)"] = "Feindliche Lebensbalken anzeigen (deaktivieren für nur Namen)",
  ["Show Friendly NPCs"] = "Freundliche NPCs anzeigen",
  ["Bar Texture:"] = "Balken-Textur:",
  ["Font:"] = "Schriftart:",
  ["Font Size:"] = "Schriftgröße:",
  ["Health Width:"] = "Lebensbreite:",
  ["Health Height:"] = "Lebenshöhe:",
  ["Scale:"] = "Skalierung:",
  
  -- Features
  ["Advanced Features"] = "Erweiterte Funktionen",
  ["Show Elite/Rare Indicators"] = "Elite/Selten-Anzeigen",
  ["Elite/Rare Style:"] = "Elite/Selten-Stil:",
  ["Icon + Text"] = "Symbol + Text",
  ["Icon Only"] = "Nur Symbol",
  ["Text Only"] = "Nur Text",
  ["None"] = "Keine",
  ["Show Quest Icons"] = "Questsymbole anzeigen",
  ["Show Classification (Elite/Rare/Boss)"] = "Klassifizierung anzeigen (Elite/Selten/Boss)",
  
  -- Classification
  ["Boss"] = "Boss",
  ["Rare Elite"] = "Seltene Elite",
  ["Rare"] = "Selten",
  ["Elite"] = "Elite",
  
  -- Headers
  ["--- Built-in Fonts ---"] = "--- Integrierte Schriftarten ---",
  ["--- Installed Fonts ---"] = "--- Installierte Schriftarten ---",
  ["--- SharedMedia Fonts ---"] = "--- SharedMedia-Schriftarten ---",
  
  -- Settings UI
  ["MinimalPlates Settings"] = "MinimalPlates Einstellungen",
  ["General"] = "Allgemein",
  ["Health & Power"] = "Leben & Energie",
  ["Auras & Icons"] = "Auren & Symbole",
  ["Advanced"] = "Erweitert",
  
  -- Config UI (General > Display Modes)
  ["Display Modes"] = "Anzeige-Modi",
  ["Choose Bar (with health bar), Text (name only), or Hide:"] = "Wählen Sie Leiste (mit Gesundheitsleiste), Text (nur Name) oder Ausblenden:",
  ["Enemy Players"] = "Feindliche Spieler",
  ["Enemy players in PvP and opposing faction."] = "Spieler der gegnerischen Fraktion und PvP-Gegner.",
  ["Enemy NPCs"] = "Feindliche NPCs",
  ["Friendly Players"] = "Verbündete Spieler",
  ["Friendly NPCs"] = "Verbündete NPCs",
  ["Additional Unit Info"] = "Zusätzliche Einheiteninformationen",
  ["Show Creature Text"] = "Kreaturentext anzeigen",
  ["Show NPC titles/subtitles (like 'Innkeeper' or 'Quest Giver')."] = "NPC-Titel/Untertitel anzeigen (z. B. „Gastwirt“ oder „Questgeber“).",
  ["Show Unit Target"] = "Einheit‑Ziel anzeigen",
  ["Show who the unit is currently targeting."] = "Zeigt, wen die Einheit derzeit anvisiert.",
  
  -- Config UI (General > Colors & Effects)
  ["Colors & Effects"] = "Farben & Effekte",
  ["Color schemes, target highlighting, and visual effects like glows and mouseover."] = "Farbschemata, Zielhervorhebung und visuelle Effekte wie Glühen und Mouseover.",
  ["Colors & Highlighting"] = "Farben & Hervorhebung",
  ["Class Colors"] = "Klassenfarben",
  ["Threat Coloring"] = "Bedrohungsfärbung",
  ["Highlight Current Target"] = "Aktuelles Ziel hervorheben",
  ["Target Scale Multiplier"] = "Ziel‑Skalierungsfaktor",
  ["Extra scaling applied to your current target. Makes it easier to see who you're attacking."] = "Zusätzliche Skalierung für das aktuelle Ziel. Erleichtert das Erkennen Ihres Angriffsziels.",
  ["Visual Effects"] = "Visuelle Effekte",
  ["Show Threat Glow"] = "Bedrohungsleuchten anzeigen",
  ["Show Focus Glow"] = "Fokusleuchten anzeigen",
  ["Show Mouseover Highlight"] = "Mouseover‑Hervorhebung anzeigen",
  
  -- Config UI (General > Unit Info & Fade)
  ["Unit Info & Fade"] = "Einheiteninfo & Ausblenden",
  ["Unit information display and non-target fading options."] = "Anzeige der Einheiteninformationen und Optionen zum Ausblenden von Nicht‑Zielen.",
  ["Unit Information"] = "Einheiteninformationen",
  ["Show Level"] = "Level anzeigen",
  ["Show Guild Text"] = "Gildentext anzeigen",
  ["Non-Target Fade"] = "Nicht‑Ziel ausblenden",
  ["Fade Non-Target Plates"] = "Nicht‑Ziel‑Namensplaketten ausblenden",
  ["(More fade options in Advanced tab)"] = "(Weitere Ausblendoptionen im Tab „Erweitert“)",
  ["Non-Target Alpha"] = "Nicht‑Ziel‑Transparenz",
})
