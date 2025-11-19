-- AuraFilter.lua loaded
---@class MinimalPlates
local MP = MinimalPlates

MP.AuraFilter = {}

-- ===== PHASE 3: ADVANCED AURA SYSTEM =====
-- 3-Tier Filtering: Buffs, Debuffs, Crowd Control
-- Whitelist/Blacklist support
-- Priority sorting

-- Crowd Control spell IDs (comprehensive list)
local CC_SPELLS = {
  -- Stuns
  [408] = true,     -- Kidney Shot
  [1833] = true,    -- Cheap Shot
  [5211] = true,    -- Bash
  [30283] = true,   -- Shadowfury
  [89766] = true,   -- Axe Toss (Felguard)
  [118905] = true,  -- Static Charge (Capacitor Totem)
  [119381] = true,  -- Leg Sweep
  [119072] = true,  -- Holy Wrath
  [853] = true,     -- Hammer of Justice
  [355689] = true,  -- Landslide (Earth Shock)
  [385149] = true,  -- Shattering Throw
  
  -- Incapacitates
  [2637] = true,    -- Hibernate
  [6770] = true,    -- Sap
  [20066] = true,   -- Repentance
  [51514] = true,   -- Hex
  [118699] = true,  -- Fear
  [5782] = true,    -- Fear (Warlock)
  [8122] = true,    -- Psychic Scream
  [5484] = true,    -- Howl of Terror
  [105421] = true,  -- Blinding Light
  [217832] = true,  -- Imprison
  
  -- Silences
  [1330] = true,    -- Garrote - Silence
  [47476] = true,   -- Strangulate
  [15487] = true,   -- Silence (Priest)
  [31935] = true,   -- Avenger's Shield
  
  -- Disarms
  [236077] = true,  -- Disarm
  [209749] = true,  -- Faerie Swarm
  
  -- Roots
  [339] = true,     -- Entangling Roots
  [117526] = true,  -- Binding Shot
  [122] = true,     -- Frost Nova
  [33395] = true,   -- Freeze (Water Elemental)
  [117405] = true,  -- Binding Shot (DoT)
  
  -- Disorients
  [31661] = true,   -- Dragon's Breath
  [207685] = true,  -- Sigil of Misery
  [207167] = true,  -- Blinding Sleet
  
  -- Polymorphs
  [118] = true,     -- Polymorph
  [61305] = true,   -- Polymorph: Black Cat
  [28272] = true,   -- Polymorph: Pig
  [161353] = true,  -- Polymorph: Polar Bear
  [126819] = true,  -- Polymorph: Porcupine
  [61721] = true,   -- Polymorph: Rabbit
  [61780] = true,   -- Polymorph: Turkey
  [28271] = true,   -- Polymorph: Turtle
}

-- Important defensive cooldowns
local IMPORTANT_DEFENSIVES = {
  [871] = true,     -- Shield Wall
  [61336] = true,   -- Survival Instincts
  [47585] = true,   -- Dispersion
  [33206] = true,   -- Pain Suppression
  [498] = true,     -- Divine Protection
  [642] = true,     -- Divine Shield
  [45438] = true,   -- Ice Block
  [31224] = true,   -- Cloak of Shadows
  [104773] = true,  -- Unending Resolve
  [186265] = true,  -- Aspect of the Turtle
  [118038] = true,  -- Die by the Sword
  [1022] = true,    -- Blessing of Protection
}

-- Important offensive cooldowns
local IMPORTANT_OFFENSIVES = {
  [12472] = true,   -- Icy Veins
  [190319] = true,  -- Combustion
  [19574] = true,   -- Bestial Wrath
  [13750] = true,   -- Adrenaline Rush
  [51271] = true,   -- Pillar of Frost
  [31884] = true,   -- Avenging Wrath
  [1719] = true,    -- Recklessness
  [107574] = true,  -- Avatar
}

-- Immunities
local IMMUNITIES = {
  [642] = true,     -- Divine Shield
  [45438] = true,   -- Ice Block
  [186265] = true,  -- Aspect of the Turtle
  [31224] = true,   -- Cloak of Shadows (magic immunity)
  [47585] = true,   -- Dispersion
}

-- Initialize aura filter database
function MP.AuraFilter.Initialize()
  MP.DB.auraWhitelist = MP.DB.auraWhitelist or {}
  MP.DB.auraBlacklist = MP.DB.auraBlacklist or {}
  
  -- Aura display settings
  MP.DB.showBuffs = MP.DB.showBuffs ~= false
  MP.DB.showDebuffs = MP.DB.showDebuffs ~= false
  MP.DB.showCrowdControl = MP.DB.showCrowdControl ~= false
  
  -- Separate positioning for 3-tier system
  MP.DB.buffsPosition = MP.DB.buffsPosition or "top"
  MP.DB.debuffsPosition = MP.DB.debuffsPosition or "top"
  MP.DB.ccPosition = MP.DB.ccPosition or "left"
  
  -- Separate scaling
  MP.DB.buffsScale = MP.DB.buffsScale or 1.0
  MP.DB.debuffsScale = MP.DB.debuffsScale or 1.0
  MP.DB.ccScale = MP.DB.ccScale or 1.2  -- CC slightly larger
  
  -- Auto-enlarge important auras
  MP.DB.autoEnlargeImportant = MP.DB.autoEnlargeImportant ~= false
  MP.DB.importantAuraScale = MP.DB.importantAuraScale or 1.3
  
  -- Filter modes
  MP.DB.onlyShowWhitelisted = MP.DB.onlyShowWhitelisted or false
  MP.DB.hideBlacklisted = MP.DB.hideBlacklisted ~= false
  
  -- Priority: Player debuffs, CC, Important, All others
  MP.DB.priorityOrder = MP.DB.priorityOrder or {"player", "cc", "important", "others"}
end

-- Check if aura is crowd control
function MP.AuraFilter.IsCrowdControl(spellId)
  return CC_SPELLS[spellId] == true
end

-- Check if aura is important defensive
function MP.AuraFilter.IsImportantDefensive(spellId)
  return IMPORTANT_DEFENSIVES[spellId] == true
end

-- Check if aura is important offensive
function MP.AuraFilter.IsImportantOffensive(spellId)
  return IMPORTANT_OFFENSIVES[spellId] == true
end

-- Check if aura is immunity
function MP.AuraFilter.IsImmunity(spellId)
  return IMMUNITIES[spellId] == true
end

-- Check if aura is important (any category)
function MP.AuraFilter.IsImportant(spellId)
  return MP.AuraFilter.IsImportantDefensive(spellId) 
      or MP.AuraFilter.IsImportantOffensive(spellId)
      or MP.AuraFilter.IsImmunity(spellId)
end

-- Check if aura is whitelisted
function MP.AuraFilter.IsWhitelisted(spellId)
  return MP.DB.auraWhitelist[spellId] ~= nil
end

-- Check if aura is blacklisted
function MP.AuraFilter.IsBlacklisted(spellId)
  return MP.DB.auraBlacklist[spellId] ~= nil
end

-- Add spell to whitelist
function MP.AuraFilter.AddToWhitelist(spellId, name, icon, color)
  if not spellId or type(spellId) ~= "number" then return false end
  
  MP.DB.auraWhitelist[spellId] = {
    name = name or ("Spell " .. spellId),
    icon = icon,
    color = color,
    addedTime = time(),
  }
  
  -- Remove from blacklist if present
  MP.DB.auraBlacklist[spellId] = nil
  
  return true
end

-- Add spell to blacklist
function MP.AuraFilter.AddToBlacklist(spellId, name)
  if not spellId or type(spellId) ~= "number" then return false end
  
  MP.DB.auraBlacklist[spellId] = {
    name = name or ("Spell " .. spellId),
    addedTime = time(),
  }
  
  -- Remove from whitelist if present
  MP.DB.auraWhitelist[spellId] = nil
  
  return true
end

-- Remove from whitelist
function MP.AuraFilter.RemoveFromWhitelist(spellId)
  MP.DB.auraWhitelist[spellId] = nil
end

-- Remove from blacklist
function MP.AuraFilter.RemoveFromBlacklist(spellId)
  MP.DB.auraBlacklist[spellId] = nil
end

-- Filter aura based on settings
function MP.AuraFilter.ShouldShow(aura, unit)
  if not aura or not aura.spellId then return false end
  
  local spellId = aura.spellId
  
  -- Blacklist takes priority
  if MP.DB.hideBlacklisted and MP.AuraFilter.IsBlacklisted(spellId) then
    return false
  end
  
  -- Whitelist mode: only show whitelisted
  if MP.DB.onlyShowWhitelisted then
    return MP.AuraFilter.IsWhitelisted(spellId)
  end
  
  -- Show if whitelisted
  if MP.AuraFilter.IsWhitelisted(spellId) then
    return true
  end
  
  -- Show important auras
  if MP.AuraFilter.IsImportant(spellId) then
    return true
  end
  
  -- Show player-cast debuffs
  if aura.sourceUnit and UnitIsUnit(aura.sourceUnit, "player") then
    return true
  end
  
  -- Default: show all (unless whitelist-only mode)
  return true
end

-- Get aura priority (lower = higher priority)
function MP.AuraFilter.GetPriority(aura)
  if not aura or not aura.spellId then return 999 end
  
  local spellId = aura.spellId
  
  -- Priority 1: Whitelisted
  if MP.AuraFilter.IsWhitelisted(spellId) then
    return 1
  end
  
  -- Priority 2: Player-cast
  if aura.sourceUnit and UnitIsUnit(aura.sourceUnit, "player") then
    return 2
  end
  
  -- Priority 3: Crowd Control
  if MP.AuraFilter.IsCrowdControl(spellId) then
    return 3
  end
  
  -- Priority 4: Immunities
  if MP.AuraFilter.IsImmunity(spellId) then
    return 4
  end
  
  -- Priority 5: Important defensives/offensives
  if MP.AuraFilter.IsImportant(spellId) then
    return 5
  end
  
  -- Priority 6: Everything else
  return 6
end

-- Categorize aura into tier
function MP.AuraFilter.GetTier(aura)
  if not aura or not aura.spellId then return "none" end
  
  local spellId = aura.spellId
  
  -- Tier 1: Crowd Control (highest priority)
  if MP.AuraFilter.IsCrowdControl(spellId) then
    return "cc"
  end
  
  -- Tier 2: Buffs (helpful)
  if aura.isHelpful then
    return "buff"
  end
  
  -- Tier 3: Debuffs (harmful)
  if aura.isHarmful then
    return "debuff"
  end
  
  return "none"
end

-- Sort auras by priority
function MP.AuraFilter.SortAuras(auras)
  table.sort(auras, function(a, b)
    local priorityA = MP.AuraFilter.GetPriority(a)
    local priorityB = MP.AuraFilter.GetPriority(b)
    
    if priorityA ~= priorityB then
      return priorityA < priorityB
    end
    
    -- Same priority: sort by expiration time (soonest first)
    if a.expirationTime and b.expirationTime then
      return a.expirationTime < b.expirationTime
    end
    
    return false
  end)
  
  return auras
end

-- Get filtered and categorized auras
function MP.AuraFilter.GetCategorizedAuras(plate)
  local buffs = {}
  local debuffs = {}
  local cc = {}
  
  if not plate or not plate.AuraTracker then return buffs, debuffs, cc end
  
  -- Get all debuffs
  local allDebuffs = plate.AuraTracker:GetDebuffs() or {}
  
  for _, aura in ipairs(allDebuffs) do
    if MP.AuraFilter.ShouldShow(aura, plate.unit) then
      local tier = MP.AuraFilter.GetTier(aura)
      
      if tier == "cc" and MP.DB.showCrowdControl then
        table.insert(cc, aura)
      elseif tier == "debuff" and MP.DB.showDebuffs then
        table.insert(debuffs, aura)
      elseif tier == "buff" and MP.DB.showBuffs then
        table.insert(buffs, aura)
      end
    end
  end
  
  -- Sort each category
  MP.AuraFilter.SortAuras(buffs)
  MP.AuraFilter.SortAuras(debuffs)
  MP.AuraFilter.SortAuras(cc)
  
  return buffs, debuffs, cc
end
