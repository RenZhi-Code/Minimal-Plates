---@class MinimalPlates
local MP = MinimalPlates

-- ===== PROFILE SERIALIZATION (NO EXTERNAL DEPENDENCIES) =====
-- Simple Lua table serializer for profile import/export
local function SerializeValue(val, indent)
  indent = indent or 0
  local t = type(val)
  
  if t == "number" then
    return tostring(val)
  elseif t == "boolean" then
    return val and "true" or "false"
  elseif t == "string" then
    return string.format("%q", val)
  elseif t == "table" then
    local lines = {}
    local spaces = string.rep(" ", indent)
    table.insert(lines, "{")
    
    for k, v in pairs(val) do
      local key
      if type(k) == "number" then
        key = "[" .. k .. "]"
      else
        key = "[" .. string.format("%q", k) .. "]"
      end
      table.insert(lines, spaces .. "  " .. key .. " = " .. SerializeValue(v, indent + 2) .. ",")
    end
    
    table.insert(lines, spaces .. "}")
    return table.concat(lines, "\n")
  else
    return "nil"
  end
end

function MP.ExportProfile(profileName)
  local profile = MinimalPlatesDB.profiles[profileName]
  if not profile then
    return nil, "Profile not found"
  end
  
  -- Serialize the profile table
  local serialized = "return " .. SerializeValue(profile)
  
  -- Base64 encode (simple version)
  local b64chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
  local encoded = serialized:gsub('.', function(x)
    local r, b = '', x:byte()
    for i = 8, 1, -1 do
      r = r .. (b % 2 ^ i - b % 2 ^ (i - 1) > 0 and '1' or '0')
    end
    return r
  end)
  encoded = encoded:gsub('%d%d%d?%d?%d?%d?', function(x)
    if #x < 6 then return '' end
    local c = 0
    for i = 1, 6 do
      c = c + (x:sub(i, i) == '1' and 2 ^ (6 - i) or 0)
    end
    return b64chars:sub(c + 1, c + 1)
  end)
  encoded = encoded .. ({'', '==', '='})[#serialized % 3 + 1]
  
  return "MP1:" .. encoded
end

function MP.ImportProfile(profileName, importString)
  if not importString or not importString:match("^MP1:") then
    return false, "Invalid import string format"
  end
  
  -- Strip prefix
  local encoded = importString:sub(5)
  
  -- Base64 decode (simple version)
  local b64chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
  encoded = encoded:gsub('[^' .. b64chars .. '=]', '')
  local decoded = encoded:gsub('.', function(x)
    if x == '=' then return '' end
    local r, f = '', b64chars:find(x) - 1
    for i = 6, 1, -1 do
      r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and '1' or '0')
    end
    return r
  end)
  decoded = decoded:gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
    if #x ~= 8 then return '' end
    local c = 0
    for i = 1, 8 do
      c = c + (x:sub(i, i) == '1' and 2 ^ (8 - i) or 0)
    end
    return string.char(c)
  end)
  
  -- Deserialize
  local success, profile = pcall(loadstring(decoded))
  if not success or type(profile) ~= "table" then
    return false, "Failed to decode profile data"
  end
  
  -- Save imported profile
  MinimalPlatesDB.profiles[profileName] = profile
  return true
end

-- ===== PERFORMANCE TESTING FUNCTION =====
function MP.RunPerformanceTest()
  local iterations = 1000
  local startTime = debugprofilestop()

  -- Simulate full update cycle
  for i = 1, iterations do
    if MP.ActivePlates then
      for baseFrame, plate in pairs(MP.ActivePlates) do
        if plate.unit and UnitExists(plate.unit) then
          MP.Display.UpdateLogic.Update(plate, plate.unit)
        end
      end
    end
  end

  local elapsed = debugprofilestop() - startTime
  local avgPerUpdate = elapsed / iterations
  local numPlates = 0
  if MP.ActivePlates then
    for _ in pairs(MP.ActivePlates) do numPlates = numPlates + 1 end
  end

  print("|cff00ff00[MinimalPlates Performance Test]|r")
  print(string.format("  Total time: %.2f ms", elapsed))
  print(string.format("  Iterations: %d", iterations))
  print(string.format("  Active plates: %d", numPlates))
  print(string.format("  Avg per cycle: %.3f ms", avgPerUpdate))
  if numPlates > 0 then
    print(string.format("  Avg per plate: %.3f ms", avgPerUpdate / numPlates))
  end
end

-- Create hidden frame for Blizzard nameplates (like Platynator)
-- This is more reliable than Hide() + SetAlpha(0)
MP.HiddenFrame = CreateFrame("Frame")
MP.HiddenFrame:Hide()

-- Initialize
local function OnAddonLoaded(self, event, addonName)
  if addonName ~= "MinimalPlates" then
    return
  end

  -- Load saved variables
  MinimalPlatesDB = MinimalPlatesDB or {}
  MP.DB = MinimalPlatesDB
  
  -- Initialize profile system
  if MP.Profiles and MP.Profiles.Initialize then
    MP.Profiles.Initialize()
  end
  
  -- Initialize theme system
  if MP.Themes and MP.Themes.Initialize then
    MP.Themes.Initialize()
  end
  
  -- Set defaults
  MP.DB.enabled = MP.DB.enabled ~= false
  MP.DB.scale = MP.DB.scale or 1.0
  MP.DB.showFriendly = MP.DB.showFriendly ~= false
  MP.DB.showEnemy = MP.DB.showEnemy ~= false
  MP.DB.showFriendlyNPC = MP.DB.showFriendlyNPC ~= false
  MP.DB.healthHeight = MP.DB.healthHeight or 8
  MP.DB.healthWidth = MP.DB.healthWidth or 120
  MP.DB.castHeight = MP.DB.castHeight or 6
  MP.DB.fontSize = MP.DB.fontSize or 12
  MP.DB.showCastBar = MP.DB.showCastBar ~= false
  MP.DB.showCastIcon = MP.DB.showCastIcon ~= false
  MP.DB.classColors = MP.DB.classColors ~= false
  MP.DB.showEnemyHealthBar = MP.DB.showEnemyHealthBar ~= false -- Show enemy health bars by default
  
  -- Blizzard CVar mirror defaults
  local function GetCVarBoolSafe(name)
    if C_CVar and C_CVar.GetCVar then
      local v = C_CVar.GetCVar(name)
      return v == "1"
    elseif GetCVarBool then
      return GetCVarBool(name)
    elseif GetCVar then
      local v = GetCVar(name)
      return v == "1"
    end
    return false
  end
  MP.DB.blizzShowFriends = (MP.DB.blizzShowFriends ~= nil) and MP.DB.blizzShowFriends or GetCVarBoolSafe("nameplateShowFriends")
  MP.DB.blizzShowEnemies = (MP.DB.blizzShowEnemies ~= nil) and MP.DB.blizzShowEnemies or GetCVarBoolSafe("nameplateShowEnemies")
  MP.DB.blizzShowFriendlyBuffs = (MP.DB.blizzShowFriendlyBuffs ~= nil) and MP.DB.blizzShowFriendlyBuffs or GetCVarBoolSafe("nameplateShowFriendlyBuffs")
  MP.DB.blizzShowDebuffsOnFriendly = (MP.DB.blizzShowDebuffsOnFriendly ~= nil) and MP.DB.blizzShowDebuffsOnFriendly or GetCVarBoolSafe("nameplateShowDebuffsOnFriendly")
  MP.DB.blizzResourceOnTarget = (MP.DB.blizzResourceOnTarget ~= nil) and MP.DB.blizzResourceOnTarget or GetCVarBoolSafe("nameplateResourceOnTarget")
  MP.DB.blizzPersonalClickThrough = (MP.DB.blizzPersonalClickThrough ~= nil) and MP.DB.blizzPersonalClickThrough or GetCVarBoolSafe("NameplatePersonalClickThrough")
  MP.DB.blizzVertScale = MP.DB.blizzVertScale or tonumber((C_CVar and C_CVar.GetCVar and C_CVar.GetCVar("NamePlateVerticalScale")) or (GetCVar and GetCVar("NamePlateVerticalScale")) or 1) or 1
  MP.DB.blizzHorzScale = MP.DB.blizzHorzScale or tonumber((C_CVar and C_CVar.GetCVar and C_CVar.GetCVar("NamePlateHorizontalScale")) or (GetCVar and GetCVar("NamePlateHorizontalScale")) or 1) or 1
  
  -- Unit display modes
  MP.DB.friendlyNPCMode = MP.DB.friendlyNPCMode or "text"   -- "bar" or "text"
  MP.DB.enemyNPCMode = MP.DB.enemyNPCMode or "bar"         -- "bar" or "text"
  MP.DB.friendlyPlayerMode = MP.DB.friendlyPlayerMode or "text" -- "bar" or "text"
  MP.DB.enemyPlayerMode = MP.DB.enemyPlayerMode or "bar"       -- "bar" or "text"
  MP.DB.barTexture = MP.DB.barTexture or "Interface\\AddOns\\MinimalPlates\\Textures\\Smooth"
  MP.DB.font = MP.DB.font or "Fonts\\ARIALN.TTF" -- Reliable across all versions
  MP.DB.fontFlags = MP.DB.fontFlags or "NONE" -- Font flags: NONE, OUTLINE, THICKOUTLINE, MONOCHROME
  
  -- Phase 1 & 2 features
  MP.DB.showEliteBorder = MP.DB.showEliteBorder ~= false
  MP.DB.eliteIconStyle = MP.DB.eliteIconStyle or "both" -- "icon", "text", "both", "none"
  MP.DB.showQuestIcon = MP.DB.showQuestIcon ~= false
  MP.DB.questIconSize = MP.DB.questIconSize or 16
  MP.DB.levelIconScale = MP.DB.levelIconScale or 1.5

  -- Positioning offsets
  MP.DB.nameYOffset = MP.DB.nameYOffset or 4  -- Name text Y offset from health bar
  MP.DB.auraYOffset = MP.DB.auraYOffset or 10 -- Aura icons Y offset from health bar
  MP.DB.castYOffset = MP.DB.castYOffset or -2 -- Cast bar Y offset from health bar
  MP.DB.showClassification = MP.DB.showClassification ~= false
  MP.DB.targetHighlight = MP.DB.targetHighlight ~= false
  MP.DB.targetScale = MP.DB.targetScale or 1.2
  MP.DB.threatColoring = MP.DB.threatColoring ~= false
  MP.DB.fadeNonTarget = MP.DB.fadeNonTarget or false
  MP.DB.nonTargetAlpha = MP.DB.nonTargetAlpha or 0.5
  MP.DB.showRoleIcons = MP.DB.showRoleIcons ~= false
  MP.DB.showRaidMarkers = MP.DB.showRaidMarkers ~= false
  MP.DB.raidMarkerSize = MP.DB.raidMarkerSize or 24
  MP.DB.raidMarkerPosition = MP.DB.raidMarkerPosition or "top" -- "top", "left", "right", "bottom"
  MP.DB.classIconPosition = MP.DB.classIconPosition or "right"
  MP.DB.questIconPosition = MP.DB.questIconPosition or "right"
  MP.DB.levelPosition = MP.DB.levelPosition or "left"
  MP.DB.roleIconPosition = MP.DB.roleIconPosition or "top"
  MP.DB.petIconPosition = MP.DB.petIconPosition or "left"
  MP.DB.worldQuestIconPosition = MP.DB.worldQuestIconPosition or "right"
  MP.DB.bonusObjectiveIconPosition = MP.DB.bonusObjectiveIconPosition or "right"
  MP.DB.healerIconPosition = MP.DB.healerIconPosition or "right"
  MP.DB.unitTargetPosition = MP.DB.unitTargetPosition or "right"
  MP.DB.pvpMarkerPosition = MP.DB.pvpMarkerPosition or "right"
  MP.DB.castTargetPosition = MP.DB.castTargetPosition or "right"
  -- Additional element positions
  MP.DB.raidMarkerPosition = MP.DB.raidMarkerPosition or "top"
  MP.DB.levelPosition = MP.DB.levelPosition or "left"
  MP.DB.namePosition = MP.DB.namePosition or "top"
  MP.DB.petIconPosition = MP.DB.petIconPosition or "right"
  MP.DB.classIconPosition = MP.DB.classIconPosition or "right"
  MP.DB.castIconPosition = MP.DB.castIconPosition or "left"
  MP.DB.castTextPosition = MP.DB.castTextPosition or "bottom"
  MP.DB.guildTextPosition = MP.DB.guildTextPosition or "bottom"
  MP.DB.creatureTextPosition = MP.DB.creatureTextPosition or "bottom"
  -- Missing vertical offsets/scales
  MP.DB.bonusObjectiveIconOffsetY = MP.DB.bonusObjectiveIconOffsetY or 0
  MP.DB.castTargetOffsetY = MP.DB.castTargetOffsetY or 0
  MP.DB.nameScale = MP.DB.nameScale or 1.0
  MP.DB.castIconOffsetY = MP.DB.castIconOffsetY or 0
  MP.DB.castIconScale = MP.DB.castIconScale or 1.0
  MP.DB.castTextOffsetY = MP.DB.castTextOffsetY or 0
  MP.DB.castTextScale = MP.DB.castTextScale or 1.0
  MP.DB.guildTextOffsetY = MP.DB.guildTextOffsetY or 0
  MP.DB.guildTextOffsetX = MP.DB.guildTextOffsetX or 0
  MP.DB.guildTextScale = MP.DB.guildTextScale or 1.0
  MP.DB.creatureTextOffsetY = MP.DB.creatureTextOffsetY or 0
  MP.DB.creatureTextOffsetX = MP.DB.creatureTextOffsetX or 0
  MP.DB.creatureTextScale = MP.DB.creatureTextScale or 1.0
  
  -- Position vertical offsets (pixels)
  MP.DB.raidMarkerOffsetY = MP.DB.raidMarkerOffsetY or 0
  MP.DB.classIconOffsetY = MP.DB.classIconOffsetY or 0
  MP.DB.questIconOffsetY = MP.DB.questIconOffsetY or 0
  MP.DB.roleIconOffsetY = MP.DB.roleIconOffsetY or 0
  MP.DB.levelOffsetY = MP.DB.levelOffsetY or 0
  MP.DB.petIconOffsetY = MP.DB.petIconOffsetY or 0
  MP.DB.interruptShieldOffsetY = MP.DB.interruptShieldOffsetY or 0
  MP.DB.healerIconOffsetY = MP.DB.healerIconOffsetY or 0
  MP.DB.ccIconOffsetY = MP.DB.ccIconOffsetY or 0
  MP.DB.pvpMarkerOffsetY = MP.DB.pvpMarkerOffsetY or 0
  MP.DB.unitTargetOffsetY = MP.DB.unitTargetOffsetY or 0
  MP.DB.worldQuestIconOffsetY = MP.DB.worldQuestIconOffsetY or 0
  MP.DB.raidMarkerOffsetX = MP.DB.raidMarkerOffsetX or 0
  MP.DB.classIconOffsetX = MP.DB.classIconOffsetX or 0
  MP.DB.questIconOffsetX = MP.DB.questIconOffsetX or 0
  MP.DB.roleIconOffsetX = MP.DB.roleIconOffsetX or 0
  MP.DB.levelOffsetX = MP.DB.levelOffsetX or 0
  MP.DB.petIconOffsetX = MP.DB.petIconOffsetX or 0
  MP.DB.interruptShieldOffsetX = MP.DB.interruptShieldOffsetX or 0
  MP.DB.healerIconOffsetX = MP.DB.healerIconOffsetX or 0
  MP.DB.ccIconOffsetX = MP.DB.ccIconOffsetX or 0
  MP.DB.pvpMarkerOffsetX = MP.DB.pvpMarkerOffsetX or 0
  MP.DB.unitTargetOffsetX = MP.DB.unitTargetOffsetX or 0
  MP.DB.worldQuestIconOffsetX = MP.DB.worldQuestIconOffsetX or 0
  MP.DB.bonusObjectiveIconOffsetX = MP.DB.bonusObjectiveIconOffsetX or 0
  MP.DB.castTargetOffsetX = MP.DB.castTargetOffsetX or 0
  MP.DB.castTargetScale = MP.DB.castTargetScale or 1.0

  MP.DB.raidMarkerScale = MP.DB.raidMarkerScale or 1.0
  MP.DB.classIconScale = MP.DB.classIconScale or 1.0
  MP.DB.questIconScale = MP.DB.questIconScale or 1.0
  MP.DB.roleIconScale = MP.DB.roleIconScale or 1.0
  MP.DB.levelScale = MP.DB.levelScale or 1.0
  MP.DB.petIconScale = MP.DB.petIconScale or 1.0
  MP.DB.interruptShieldScale = MP.DB.interruptShieldScale or 1.0
  MP.DB.healerIconScale = MP.DB.healerIconScale or 1.0
  MP.DB.ccIconScale = MP.DB.ccIconScale or 1.0
  MP.DB.pvpMarkerScale = MP.DB.pvpMarkerScale or 1.0
  MP.DB.unitTargetScale = MP.DB.unitTargetScale or 1.0
  MP.DB.worldQuestIconScale = MP.DB.worldQuestIconScale or 1.0
  MP.DB.bonusObjectiveIconScale = MP.DB.bonusObjectiveIconScale or 1.0
  MP.DB.showAuras = MP.DB.showAuras ~= false
  MP.DB.auraStackLayout = MP.DB.auraStackLayout ~= false
  
  -- Non-target nameplate fade settings
  MP.DB.fadeNonTarget = MP.DB.fadeNonTarget or false  -- Off by default
  MP.DB.nonTargetAlpha = MP.DB.nonTargetAlpha or 0.5  -- 50% opacity when faded
  MP.DB.fadeOnlyWhenTargeted = MP.DB.fadeOnlyWhenTargeted ~= false  -- Only fade when you have a target
  MP.DB.keepFocusFullAlpha = MP.DB.keepFocusFullAlpha ~= false  -- Keep focus at full opacity
  MP.DB.keepCastingFullAlpha = MP.DB.keepCastingFullAlpha ~= false  -- Keep casting units visible
  
  -- Nameplate stacking/overlap settings
  MP.DB.nameplateOverlapV = MP.DB.nameplateOverlapV or 0.5  -- Vertical overlap (stacking)
  MP.DB.nameplateOverlapH = MP.DB.nameplateOverlapH or 0.8  -- Horizontal overlap
  MP.DB.showCCIndicator = MP.DB.showCCIndicator ~= false
  MP.DB.showInterruptIndicator = MP.DB.showInterruptIndicator ~= false
  MP.DB.showPowerBar = MP.DB.showPowerBar or false
  MP.DB.showGuildText = MP.DB.showGuildText or false
  MP.DB.showCreatureText = MP.DB.showCreatureText ~= false
  MP.DB.showLevel = MP.DB.showLevel ~= false
  -- Cast bar colors
  MP.DB.interruptibleCastColor = MP.DB.interruptibleCastColor or {r = 1, g = 0.7, b = 0} -- Orange
  MP.DB.nonInterruptibleCastColor = MP.DB.nonInterruptibleCastColor or {r = 0.5, g = 0.5, b = 0.5} -- Gray
  MP.DB.questNPCColor = MP.DB.questNPCColor or {r = 0.6, g = 0.2, b = 1} -- Purple
  
  
  -- Comprehensive Blizzard nameplate features
  MP.DB.showThreatGlow = MP.DB.showThreatGlow ~= false -- Red glow on aggro
  MP.DB.showFocusGlow = MP.DB.showFocusGlow ~= false -- Glow on focus target
  MP.DB.showMouseoverHighlight = MP.DB.showMouseoverHighlight ~= false -- Mouseover highlight
  MP.DB.showCastSpark = MP.DB.showCastSpark ~= false -- Moving spark on cast bar
  MP.DB.showInterruptFlash = MP.DB.showInterruptFlash ~= false -- Flash on interrupt
  MP.DB.showHealerIcon = MP.DB.showHealerIcon or false -- Healer role indicator
  MP.DB.showPetIcon = MP.DB.showPetIcon or false -- Pet unit indicator
  MP.DB.showTappedOverlay = MP.DB.showTappedOverlay ~= false -- Grey overlay for tapped mobs
  MP.DB.showWorldQuestIcon = MP.DB.showWorldQuestIcon ~= false -- World quest indicator
  MP.DB.showBonusObjectiveIcon = MP.DB.showBonusObjectiveIcon ~= false -- Bonus objective indicator
  
  -- New Blizzard-inspired features
  MP.DB.showLossOfAggroFlash = MP.DB.showLossOfAggroFlash ~= false -- White flash when losing threat (tank feature)
  MP.DB.showSoftTargetIcon = MP.DB.showSoftTargetIcon ~= false -- Gamepad soft-target cursor
  MP.DB.classificationScale = MP.DB.classificationScale ~= false -- Scale elites/bosses larger
  MP.DB.eliteScale = MP.DB.eliteScale or 1.1 -- 10% larger for elites
  MP.DB.bossScale = MP.DB.bossScale or 1.25 -- 25% larger for bosses
  MP.DB.expandedClickArea = MP.DB.expandedClickArea ~= false -- Better targeting hitbox

  -- Additional positioning defaults for new UI
  MP.DB.ccIconPosition = MP.DB.ccIconPosition or "top"
  MP.DB.interruptShieldPosition = MP.DB.interruptShieldPosition or "top"
  
  -- ===== PHASE 2: TEST MODES =====
  -- Test modes for easier configuration without needing live targets
  MP.DB.testModeTargetHighlight = MP.DB.testModeTargetHighlight or false
  MP.DB.testModeThreatGlow = MP.DB.testModeThreatGlow or false
  MP.DB.testModeCastBar = MP.DB.testModeCastBar or false
  MP.DB.testModeAuras = MP.DB.testModeAuras or false
  MP.DB.testModeClassColors = MP.DB.testModeClassColors or false
  
  -- ===== PHASE 3: ADVANCED AURA SYSTEM =====
  -- 3-Tier Aura Display defaults (initialized in AuraFilter.Initialize, but set safe defaults)
  MP.DB.showBuffs = MP.DB.showBuffs ~= false
  MP.DB.showDebuffs = MP.DB.showDebuffs ~= false
  MP.DB.showCrowdControl = MP.DB.showCrowdControl ~= false
  
  -- Tier scaling
  MP.DB.buffsScale = MP.DB.buffsScale or 1.0
  MP.DB.debuffsScale = MP.DB.debuffsScale or 1.0
  MP.DB.ccScale = MP.DB.ccScale or 1.5  -- CC icons larger by default
  
  -- Tier positioning
  MP.DB.buffsPosition = MP.DB.buffsPosition or "top"
  MP.DB.debuffsPosition = MP.DB.debuffsPosition or "top"
  MP.DB.ccPosition = MP.DB.ccPosition or "left"
  
  MP.DB.buffsOffsetY = MP.DB.buffsOffsetY or 0
  MP.DB.debuffsOffsetY = MP.DB.debuffsOffsetY or 0
  MP.DB.ccOffsetY = MP.DB.ccOffsetY or 0
  
  -- Aura filtering
  MP.DB.autoEnlargeImportant = MP.DB.autoEnlargeImportant ~= false
  MP.DB.importantAuraScale = MP.DB.importantAuraScale or 1.3
  MP.DB.onlyShowWhitelisted = MP.DB.onlyShowWhitelisted or false
  MP.DB.hideBlacklisted = MP.DB.hideBlacklisted or false
  
  -- ===== PHASE 5: COMPETITIVE FEATURES =====
  -- Arena ID
  MP.DB.showArenaID = MP.DB.showArenaID ~= false
  
  -- Role Indicators  
  MP.DB.showRoleIcons = MP.DB.showRoleIcons ~= false
  MP.DB.roleIconPosition = MP.DB.roleIconPosition or "left"
  MP.DB.roleIconOffsetX = MP.DB.roleIconOffsetX or 0
  MP.DB.roleIconOffsetY = MP.DB.roleIconOffsetY or 0
  MP.DB.roleIconScale = MP.DB.roleIconScale or 1.0
  
  -- NPC Custom Colors (whitelist specific NPCs with custom colors)
  MP.DB.npcColors = MP.DB.npcColors or {}
  -- Format: ["NPC Name"] = {r = 1.0, g = 0.5, b = 0.0}
  MP.DB.useNPCColors = MP.DB.useNPCColors ~= false

  -- Initialize systems
  local success, err = pcall(function()
    MP.Config.Init()
  end)
  if not success then
    print("|cffff0000[MinimalPlates]|r ERROR in Config.Init(): " .. tostring(err))
  end
  
  -- Initialize frame pools (performance optimization)
  success, err = pcall(function()
    if MP.FramePools and MP.FramePools.Init then
      MP.FramePools.Init()
    end
  end)
  if not success then
    print("|cffff0000[MinimalPlates]|r ERROR in FramePools.Init(): " .. tostring(err))
  end
  
  -- Initialize aura filter system (Phase 3: Advanced Aura System)
  success, err = pcall(function()
    if MP.AuraFilter and MP.AuraFilter.Initialize then
      MP.AuraFilter.Initialize()
    end
  end)
  if not success then
    print("|cffff0000[MinimalPlates]|r ERROR in AuraFilter.Initialize(): " .. tostring(err))
  end
  
  success, err = pcall(function()
    MP.Settings.Init()
  end)
  if not success then
    print("|cffff0000[MinimalPlates]|r ERROR in Settings.Init(): " .. tostring(err))
  end
  
  success, err = pcall(function()
    MP.Nameplates.Init()
  end)
  if not success then
    print("|cffff0000[MinimalPlates]|r ERROR in Nameplates.Init(): " .. tostring(err))
  end
  
  -- Register slash commands
  SLASH_MINIMALPLATES1 = "/mp"
  SLASH_MINIMALPLATES2 = "/minimalplates"
  SlashCmdList["MINIMALPLATES"] = function(msg)
    msg = strtrim(msg:lower())
    if msg == "config" or msg == "settings" or msg == "" then
      -- Open standalone settings UI
      if MP.Settings and MP.Settings.CreateStandaloneUI then
        MP.Settings.CreateStandaloneUI()
      else
        print("|cffff0000[MinimalPlates]|r Settings UI not loaded. Try /reload")
      end
    elseif msg == "reset" then
      MinimalPlatesDB = nil
      print("|cff00ff00[MinimalPlates]|r Settings reset! Type |cffaaaaaa/reload|r to apply.")
    elseif msg == "toggle" then
      MP.DB.enabled = not MP.DB.enabled
      print("|cff00ff00[MinimalPlates]|r " .. (MP.DB.enabled and "Enabled" or "Disabled"))
      MP.Nameplates.RefreshAll()
    elseif msg == "class" then
      MP.DB.classColors = not MP.DB.classColors
      print("|cff00ff00[MinimalPlates]|r Class colors " .. (MP.DB.classColors and "enabled" or "disabled"))
      MP.Nameplates.RefreshAll()
    elseif msg == "threat" then
      MP.DB.threatColoring = not MP.DB.threatColoring
      print("|cff00ff00[MinimalPlates]|r Threat coloring " .. (MP.DB.threatColoring and "enabled" or "disabled"))
      MP.Nameplates.RefreshAll()
    elseif msg == "auras" then
      MP.DB.showAuras = not MP.DB.showAuras
      print("|cff00ff00[MinimalPlates]|r Aura icons " .. (MP.DB.showAuras and "enabled" or "disabled"))
      MP.Nameplates.RefreshAll()
    elseif msg:match("^scale%s+") then
      local scale = tonumber(msg:match("^scale%s+([%d%.]+)"))
      if scale and scale >= 0.5 and scale <= 2.0 then
        MP.DB.scale = scale
        print("|cff00ff00[MinimalPlates]|r Scale set to " .. string.format("%.1f", scale))
        -- Removed SetCVar call to avoid protected function taint; addon scales frames internally
        MP.Nameplates.RefreshAll()
      else
        print("|cffff0000[MinimalPlates]|r Scale must be between 0.5 and 2.0")
      end
    elseif msg == "diag" then
      local function gc(name)
        local v = (C_CVar and C_CVar.GetCVar and C_CVar.GetCVar(name)) or (GetCVar and GetCVar(name)) or "nil"
        print("|cff00ff00[MinimalPlates]|r " .. name .. " = " .. tostring(v))
      end
      gc("nameplateShowAll")
      gc("nameplateShowFriends")
      gc("nameplateShowFriendlyNPCs")
      gc("nameplateShowEnemies")
      gc("nameplateShowEnemyPlayers")
      gc("nameplateShowEnemyMinus")
      gc("nameplateMaxDistance")
      local bf = C_NamePlate and C_NamePlate.GetNamePlateForUnit and C_NamePlate.GetNamePlateForUnit("target")
      print("|cff00ff00[MinimalPlates]|r target has nameplate = " .. tostring(bf ~= nil))
      local unitMode = MP.DB.enemyPlayerMode
      print("|cff00ff00[MinimalPlates]|r enemyPlayerMode = " .. tostring(unitMode))

      if MP.FramePools and MP.FramePools.PrintStats then
        MP.FramePools.PrintStats()
      else
        print("|cffff0000[MinimalPlates]|r Frame pools not initialized")
      end
    elseif msg == "events" then
      if MP.NameplateEvents and MP.NameplateEvents.PrintEventStats then
        MP.NameplateEvents.PrintEventStats()
      else
        print("|cffff0000[MinimalPlates]|r Event system not initialized")
      end
    elseif msg:match("^whitelist%s+") then
      local spellId = tonumber(msg:match("^whitelist%s+(%d+)"))
      if spellId then
        local name = GetSpellInfo(spellId)
        if MP.AuraFilter.AddToWhitelist(spellId, name) then
          print("|cff00ff00[MinimalPlates]|r Added spell " .. spellId .. " (" .. (name or "Unknown") .. ") to whitelist")
        else
          print("|cffff0000[MinimalPlates]|r Failed to add spell to whitelist")
        end
      else
        print("|cffff0000[MinimalPlates]|r Usage: /mp whitelist <spellId>")
      end
    elseif msg:match("^blacklist%s+") then
      local spellId = tonumber(msg:match("^blacklist%s+(%d+)"))
      if spellId then
        local name = GetSpellInfo(spellId)
        if MP.AuraFilter.AddToBlacklist(spellId, name) then
          print("|cff00ff00[MinimalPlates]|r Added spell " .. spellId .. " (" .. (name or "Unknown") .. ") to blacklist")
        else
          print("|cffff0000[MinimalPlates]|r Failed to add spell to blacklist")
        end
      else
        print("|cffff0000[MinimalPlates]|r Usage: /mp blacklist <spellId>")
      end
    elseif msg:match("^removewhite%s+") then
      local spellId = tonumber(msg:match("^removewhite%s+(%d+)"))
      if spellId then
        MP.AuraFilter.RemoveFromWhitelist(spellId)
        print("|cff00ff00[MinimalPlates]|r Removed spell " .. spellId .. " from whitelist")
      else
        print("|cffff0000[MinimalPlates]|r Usage: /mp removewhite <spellId>")
      end
    elseif msg:match("^removeblack%s+") then
      local spellId = tonumber(msg:match("^removeblack%s+(%d+)"))
      if spellId then
        MP.AuraFilter.RemoveFromBlacklist(spellId)
        print("|cff00ff00[MinimalPlates]|r Removed spell " .. spellId .. " from blacklist")
      else
        print("|cffff0000[MinimalPlates]|r Usage: /mp removeblack <spellId>")
      end
    elseif msg == "perf" or msg == "performance" then
      MP.RunPerformanceTest()
      
      if MP.FramePools and MP.FramePools.PrintStats then
        print("|cff00ff00[Frame Pool Stats]|r")
        MP.FramePools.PrintStats()
      end
      
      if MP.NameplateEvents and MP.NameplateEvents.PrintEventStats then
        print("|cff00ff00[Event Stats]|r")
        MP.NameplateEvents.PrintEventStats()
      end
    else
      print("|cff00ff00[MinimalPlates]|r Unknown command. Type |cffaaaaaa/mp help|r for commands")
    end
  end
  
  -- Version info
  local versionStr = "MinimalPlates Loaded!"
  if MP.Constants.IsMidnight then
    versionStr = versionStr .. " (Midnight Beta)"
  elseif MP.Constants.IsRetail then
    versionStr = versionStr .. " (Retail)"
  elseif MP.Constants.IsMists then
    versionStr = versionStr .. " (Mists Classic)"
  elseif MP.Constants.IsEra then
    versionStr = versionStr .. " (Classic Era)"
  end
  print("|cff00ff00" .. versionStr .. "|r Type |cffaaaaaa/mp|r for settings")
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", OnAddonLoaded)
-- Event handler registered
