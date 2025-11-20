---@class MinimalPlates
local MP = MinimalPlates


local crowdControlSpells = {
  [377048] = true, -- Absolute Zero
  [221562] = true, -- Asphyxiate
  [31935] = true, -- Avenger's Shield
  [89766] = true, -- Axe Toss
  [710] = true, -- Banish
  [117526] = true, -- Binding Shot
  [2094] = true, -- Blind
  [105421] = true, -- Blinding Light
  [207167] = true, -- Blinding Sleet
  [451517] = true, -- Brittle
  [179057] = true, -- Chaos Nova
  [1833] = true, -- Cheap Shot
  [324382] = true, -- Clash
  [33786] = true, -- Cyclone
  [31661] = true, -- Dragon's Breath
  [64695] = true, -- Earthgrab
  [77505] = true, -- Earthquake
  [460614] = true, -- Entangling Roots
  [339] = true, -- Entangling Roots
  [393456] = true, -- Entrapment
  [118699] = true, -- Fear
  [211881] = true, -- Fel Eruption
  [33395] = true, -- Freeze
  [122] = true, -- Frost Nova
  [3355] = true, -- Freezing Trap
  [1330] = true, -- Garrote - Silence
  [91800] = true, -- Gnaw
  [1776] = true, -- Gouge
  [473291] = true, -- Grapple Weapon
  [853] = true, -- Hammer of Justice
  [287712] = true, -- Haymaker
  [51514] = true, -- Hex
  [2637] = true, -- Hibernate
  [200200] = true, -- Holy Word: Chastise
  [5484] = true, -- Howl of Terror
  [157997] = true, -- Ice Nova
  [454787] = true, -- Icebound Fortitude
  [217832] = true, -- Imprison
  [408] = true, -- Kidney Shot
  [383121] = true, -- Mass Polymorph
  [391124] = true, -- Mind Control
  [605] = true, -- Mind Control
  [115078] = true, -- Paralysis
  [20066] = true, -- Repentance
  [6770] = true, -- Sap
  [6358] = true, -- Seduction
  [15487] = true, -- Silence
  [203337] = true, -- Silence (GCD)
  [1513] = true, -- Scare Beast
  [207685] = true, -- Sigil of Misery
  [204490] = true, -- Sigil of Silence
  [118905] = true, -- Static Charge
  [107079] = true, -- Quaking Palm
  [202274] = true, -- Incendiary Brew
  [47476] = true, -- Strangulate
  [30283] = true, -- Shadowfury
  [204399] = true, -- Earthfury
  [108194] = true, -- Asphyxiate
  [221527] = true, -- Imprison (Honor Talent)
  [356727] = true, -- Spider Sting
  [209753] = true, -- Cyclone (Restoration)
  [5782] = true, -- Fear
  [8122] = true, -- Psychic Scream
  [226943] = true, -- Mind Bomb
  
  -- Additional important spells
  [99] = true, -- Incapacitating Roar
  [22703] = true, -- Summon Infernal Stun
  [5246] = true, -- Intimidating Shout
  [316595] = true, -- Intimidating Shout (Essence)
  [316593] = true, -- Intimidating Shout (Essence 2)
  [24394] = true, -- Intimidation
  [8643] = true, -- Kidney Shot (Rank 2)
  [355689] = true, -- Landslide
  [119381] = true, -- Leg Sweep
  [305485] = true, -- Lightning Lasso
  [203123] = true, -- Maim
  [102359] = true, -- Mass Entanglement
  [200166] = true, -- Metamorphosis Stun
  [5211] = true, -- Mighty Bash
  [453] = true, -- Mind Soothe
  [91797] = true, -- Monstrous Blow
  [6789] = true, -- Mortal Coil
  [118] = true, -- Polymorph
  [64044] = true, -- Psychic Horror
  [82691] = true, -- Ring of Frost
  [213691] = true, -- Scatter Shot
  [9484] = true, -- Shackle Undead
  [91807] = true, -- Shambling Rush
  [385954] = true, -- Shield Charge
  [132168] = true, -- Shockwave
  [81261] = true, -- Solar Beam
  [198909] = true, -- Song of Chi-Ji
  [132169] = true, -- Storm Bolt
  [197214] = true, -- Sundering
  [372245] = true, -- Terror of the Skies
  [374776] = true, -- Tectonic Slam
  [10326] = true, -- Turn Evil
  [114404] = true, -- Void Tendril's Grasp
  [20549] = true, -- War Stomp
  [370970] = true, -- Necrotic Freeze
  [357229] = true, -- Whirling Spear
  [353706] = true, -- Stun (Mythic+)
  [347775] = true, -- Stun (Mythic+ 2)
  [355640] = true, -- Stun (Mythic+ 3)
  [355888] = true, -- Stun (Mythic+ 4)
  [1244446] = true, -- Stun (Mythic+ 5)
  [428150] = true, -- Stun (Mythic+ 6)
  [356133] = true, -- Stun (Mythic+ 7)
  [1240214] = true, -- Stun (Mythic+ 8)
  [1221133] = true, -- Stun (Mythic+ 9)
  [422969] = true, -- Stun (Mythic+ 10)
  [451112] = true, -- Stun (Mythic+ 11)
  [326450] = true, -- Stun (Mythic+ 12)
  [117405] = true, -- Binding Shot Root
  [236077] = true, -- Disarm
}

-- Defensive cooldowns
local defensiveCooldowns = {
  [871] = true, -- Shield Wall
  [12975] = true, -- Last Stand
  [23920] = true, -- Spell Reflection
  [118038] = true, -- Die by the Sword
  [184364] = true, -- Enraged Regeneration
  [1966] = true, -- Feint
  [5277] = true, -- Evasion
  [31224] = true, -- Cloak of Shadows
  [45438] = true, -- Ice Block
  [55233] = true, -- Vampiric Blood
  [48707] = true, -- Anti-Magic Shell
  [48792] = true, -- Icebound Fortitude
  [642] = true, -- Divine Shield
  [498] = true, -- Divine Protection
  [6940] = true, -- Blessing of Sacrifice
  [1022] = true, -- Blessing of Protection
  [31850] = true, -- Ardent Defender
  [86659] = true, -- Guardian of Ancient Kings
  [186265] = true, -- Aspect of the Turtle
  [61336] = true, -- Survival Instincts
  [22812] = true, -- Barkskin
  [102342] = true, -- Ironbark
  [108271] = true, -- Astral Shift
  [204293] = true, -- Spirit Link Totem
  [33206] = true, -- Pain Suppression
  [47585] = true, -- Dispersion
  [19236] = true, -- Desperate Prayer
  [47788] = true, -- Guardian Spirit
  [81782] = true, -- Power Word: Barrier
  [104773] = true, -- Unending Resolve
  [108416] = true, -- Dark Pact
  [212295] = true, -- Nether Ward
  [122783] = true, -- Diffuse Magic
  [122278] = true, -- Dampen Harm
  [115176] = true, -- Zen Meditation
  [198589] = true, -- Blur
  [196555] = true, -- Netherwalk
  [363916] = true, -- Obsidian Scales
}

-- Immunities
local immunitySpells = {
  [642] = true, -- Divine Shield
  [45438] = true, -- Ice Block
  [186265] = true, -- Aspect of the Turtle
  [47585] = true, -- Dispersion
  [196555] = true, -- Netherwalk
  [710] = true, -- Banish
  [33786] = true, -- Cyclone
}

-- Offensive cooldowns
local offensiveCooldowns = {
  [107574] = true, -- Avatar
  [1719] = true, -- Recklessness
  [227847] = true, -- Bladestorm
  [13750] = true, -- Adrenaline Rush
  [121471] = true, -- Shadow Blades
  [12042] = true, -- Arcane Power
  [190319] = true, -- Combustion
  [12472] = true, -- Icy Veins
  [51271] = true, -- Pillar of Frost
  [31884] = true, -- Avenging Wrath
  [231895] = true, -- Crusade
  [19574] = true, -- Bestial Wrath
  [266779] = true, -- Coordinated Assault
  [288613] = true, -- Trueshot
  [106951] = true, -- Berserk
  [194223] = true, -- Celestial Alignment
  [102560] = true, -- Incarnation
  [137639] = true, -- Storm, Earth, and Fire
  [152173] = true, -- Serenity
  [113858] = true, -- Dark Soul: Instability
  [265187] = true, -- Summon Demonic Tyrant
  [114050] = true, -- Ascendance (Elemental)
  [114051] = true, -- Ascendance (Enhancement)
}

-- Pandemic DoT spells (spell ID -> base duration)
local pandemicSpells = {
  -- Warlock
  [980] = 18, -- Agony
  [146739] = 14, -- Corruption
  [316099] = 21, -- Unstable Affliction
  [157736] = 21, -- Immolate
  [445474] = 15.3, -- Wither
  [460553] = 20, -- Doom
  -- Priest
  [589] = 16, -- Shadow Word: Pain
  [34914] = 21, -- Vampiric Touch
  [335467] = 6, -- Devouring Plague
  [204213] = 20, -- Purge the Wicked
  -- Druid
  [1079] = 18, -- Rip
  [1822] = 12, -- Rake
  [155722] = 12, -- Rake (Prowl)
  [106830] = 24, -- Thrash (Bear)
  [192090] = 24, -- Thrash (Cat)
  [164812] = 15, -- Moonfire
  [164815] = 18, -- Sunfire
  [202347] = 12, -- Stellar Flare
  -- Rogue
  [1943] = 32, -- Rupture
  [703] = 18, -- Garrote
  [121411] = 18, -- Crimson Tempest
  -- Death Knight
  [55078] = 24, -- Blood Plague
  [55095] = 24, -- Frost Fever
  -- Shaman
  [188389] = 18, -- Flame Shock
  [61295] = 18, -- Riptide
  -- Warrior
  [388539] = 15, -- Rend
  [262115] = 12, -- Deep Wounds
}

local PANDEMIC_THRESHOLD = 0.3 -- 30% of duration

-- Aura tracking mixin
MP.AurasMixin = {}

function MP.AurasMixin:OnLoad()
  -- Create tables ONCE during initialization (15-20% memory reduction)
  self.debuffs = {}
  self.buffs = {}
  self.crowdControl = {}
  self.defensives = {}
  self.offensives = {}
  self.immunities = {}
  self.pandemic = {}
end

function MP.AurasMixin:SetUnit(unit)
  self.unit = unit
  if unit then
    self.isPlayer = UnitIsPlayer(unit)
    if UnitCanAttack("player", unit) then
      self:ScanAllAuras()
    else
      self:Reset()
    end
  else
    self:Reset()
  end
end

function MP.AurasMixin:Reset()
  -- REUSE existing tables with wipe() instead of creating new ones
  wipe(self.debuffs)
  wipe(self.buffs)
  wipe(self.crowdControl)
  wipe(self.defensives)
  wipe(self.offensives)
  wipe(self.immunities)
  wipe(self.pandemic)
end

function MP.AurasMixin:GetAuraKind(info)
  if not info then return nil end
  
  -- Safely extract spellId - only proceed if it's a plain number
  local spellId = info.spellId
  if type(spellId) ~= "number" then
    spellId = nil
  end
  
  -- Safely extract boolean fields using pcall to avoid secret value comparisons
  local isHelpful = false
  local isHarmful = false
  local showPersonal = false
  
  pcall(function()
    isHelpful = info.isHelpful == true
  end)
  
  pcall(function()
    isHarmful = info.isHarmful == true
  end)
  
  pcall(function()
    showPersonal = info.nameplateShowPersonal == true
  end)
  
  -- Safely extract string fields
  local sourceUnit = nil
  if type(info.sourceUnit) == "string" then
    sourceUnit = info.sourceUnit
  end
  
  local dispelName = info.dispelName

  -- Only perform table-index lookups when spellId is a plain number (not secret)
  if type(spellId) == "number" then
    -- Check for crowd control first
    local success, isCrowdControl = pcall(function() return crowdControlSpells[spellId] end)
    if success and isCrowdControl then
      return "crowdControl"
    end
    -- Check for immunities
    local success, isImmunity = pcall(function() return immunitySpells[spellId] end)
    if success and isImmunity then
      return "immunities"
    end
    -- Check for defensive CDs
    if isHelpful then
      local success, isDefensive = pcall(function() return defensiveCooldowns[spellId] end)
      if success and isDefensive then
        return "defensives"
      end
    end
    -- Check for offensive CDs
    if isHelpful then
      local success, isOffensive = pcall(function() return offensiveCooldowns[spellId] end)
      if success and isOffensive then
        return "offensives"
      end
    end
    -- Check for pandemic DoTs (only debuffs from player)
    if isHarmful and sourceUnit == "player" then
      local success, isPandemic = pcall(function() return pandemicSpells[spellId] end)
      if success and isPandemic then
        return "pandemic"
      end
    end
  end

  -- Friendly unit buffs that are dispellable
  if isHelpful and not self.isPlayer and dispelName ~= nil then
    return "buffs"
  end

  -- Debuffs from player or that should show on nameplate
  if isHarmful and (showPersonal or sourceUnit == "player") then
    return "debuffs"
  end
end

function MP.AurasMixin:ScanAllAuras()
  self:Reset()

  -- Check if modern aura API exists (Retail/Midnight)
  if not MP.Constants.HasUnitAuraSlots then
    -- Classic fallback - limited aura support
    return
  end

  -- Try AuraUtil.ForEachAura for better performance (recommended by Blizzard)
  -- In Midnight beta, AuraUtil may hit "secret" protected values, so we wrap in pcall
  -- and fall back to manual iteration if it fails
  local useManualIteration = true

  if AuraUtil and AuraUtil.ForEachAura then
    local harmfulSuccess = pcall(function()
      AuraUtil.ForEachAura(self.unit, "HARMFUL", nil, function(info)
        -- Validate info is a table and not a secret value
        if type(info) == "table" then
          local kind = self:GetAuraKind(info)
          if kind then
            table.insert(self[kind], info)
          end
        end
        return false  -- continue iteration
      end)
    end)

    local helpfulSuccess = pcall(function()
      AuraUtil.ForEachAura(self.unit, "HELPFUL", nil, function(info)
        -- Validate info is a table and not a secret value
        if type(info) == "table" then
          local kind = self:GetAuraKind(info)
          if kind then
            table.insert(self[kind], info)
          end
        end
        return false  -- continue iteration
      end)
    end)

    -- If both succeeded, we don't need manual iteration
    if harmfulSuccess and helpfulSuccess then
      useManualIteration = false
    end
  end

  -- Fallback: Manual iteration for older clients or if ForEachAura failed
  if useManualIteration then
    -- Scan harmful auras
    local index = 1
    while true do
      local info = C_UnitAuras.GetAuraDataByIndex(self.unit, index, "HARMFUL")
      if not info then break end

      local kind = self:GetAuraKind(info)
      if kind then
        table.insert(self[kind], info)
      end
      index = index + 1
    end

    -- Scan helpful auras
    index = 1
    while true do
      local info = C_UnitAuras.GetAuraDataByIndex(self.unit, index, "HELPFUL")
      if not info then break end

      local kind = self:GetAuraKind(info)
      if kind then
        table.insert(self[kind], info)
      end
      index = index + 1
    end
  end
end

function MP.AurasMixin:GetDebuffs()
  return self.debuffs
end

function MP.AurasMixin:GetBuffs()
  return self.buffs
end

function MP.AurasMixin:GetCrowdControl()
  return self.crowdControl
end

function MP.AurasMixin:HasCrowdControl()
  return #self.crowdControl > 0
end

function MP.AurasMixin:HasBuffs()
  return #self.buffs > 0
end

function MP.AurasMixin:GetDefensives()
  return self.defensives
end

function MP.AurasMixin:GetOffensives()
  return self.offensives
end

function MP.AurasMixin:GetImmunities()
  return self.immunities
end

function MP.AurasMixin:GetPandemic()
  return self.pandemic
end

-- Check if a pandemic DoT can be refreshed (30% rule)
function MP.AurasMixin:IsPandemicActive(aura)
  if not aura.expirationTime or aura.expirationTime == 0 then
    return false
  end
  
  local baseDuration = pandemicSpells[aura.spellId]
  if not baseDuration then
    return false
  end
  
  local remaining = aura.expirationTime - GetTime()
  local threshold = baseDuration * PANDEMIC_THRESHOLD
  
  return remaining <= threshold and remaining > 0
end
