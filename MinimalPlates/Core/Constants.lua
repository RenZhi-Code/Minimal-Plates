-- Create global namespace
---@class MinimalPlates
local MP = {}
_G.MinimalPlates = MP

-- Initialize sub-namespaces
MP.Config = {}
MP.Nameplates = {}
MP.ActivePlates = {}
MP.Settings = {}
MP.Constants = {}

-- Version detection
MP.Constants = {
  IsRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE,
  IsMists = WOW_PROJECT_ID == WOW_PROJECT_MISTS_CLASSIC,
  IsEra = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC,
  IsClassic = WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE,
  
  -- Midnight beta detection (11.2.0+)
  IsMidnight = select(4, GetBuildInfo()) >= 120000,
  
  -- Version-specific feature flags
  HasUnitAuraSlots = C_UnitAuras and C_UnitAuras.GetAuraDataByIndex ~= nil,
  HasPvPClassification = UnitPvpClassification ~= nil,
  HasUnitHealthPercent = UnitHealthPercent ~= nil,
  HasPowerBarColor = PowerBarColor ~= nil,
}

-- Helper: Safe abbreviate numbers (backwards compatible)
function MP.Constants.AbbreviateNumbers(value)
  if AbbreviateNumbers then
    return AbbreviateNumbers(value)
  end
  
  -- Fallback for Classic
  if value >= 1000000000 then
    return string.format("%.1fB", value / 1000000000)
  elseif value >= 1000000 then
    return string.format("%.1fM", value / 1000000)
  elseif value >= 1000 then
    return string.format("%.1fK", value / 1000)
  else
    return tostring(value)
  end
end

-- Helper: Safe get power color (backwards compatible)
function MP.Constants.GetPowerColor(powerType)
  if MP.Constants.HasPowerBarColor then
    local info = PowerBarColor[powerType]
    if info then
      return info.r, info.g, info.b
    end
  end
  
  -- Fallback colors
  local colorMap = {
    [0] = {0, 0.5, 1}, -- Mana (blue)
    [1] = {1, 0, 0}, -- Rage (red)
    [2] = {1, 0.5, 0.25}, -- Focus (orange)
    [3] = {1, 1, 0}, -- Energy (yellow)
    [6] = {0, 1, 1}, -- Runic Power (cyan)
  }
  
  local color = colorMap[powerType] or {0, 0.5, 1}
  return color[1], color[2], color[3]
end

-- Helper: Safe get class color (backwards compatible)
function MP.Constants.GetClassColor(class)
  if RAID_CLASS_COLORS and class then
    local color = RAID_CLASS_COLORS[class]
    if color then
      return color.r, color.g, color.b
    end
  end
  return 1, 1, 1 -- Default white
end

-- Helper: Safe unit operations (handles secret values in Midnight)
function MP.Constants.SafeUnitName(unit)
  -- In Midnight, UnitName returns secret values in combat for non-player units
  -- But we're using it for display only (SetText accepts secrets), so this is fine
  return UnitName(unit)
end

function MP.Constants.SafeUnitHealth(unit)
  -- Returns secret value in combat, but StatusBar:SetValue accepts secrets
  return UnitHealth(unit)
end

function MP.Constants.SafeUnitHealthMax(unit)
  -- Returns secret value in combat, but we only use for calculations in untainted code
  return UnitHealthMax(unit)
end
