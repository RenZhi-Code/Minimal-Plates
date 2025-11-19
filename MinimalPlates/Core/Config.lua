---@class MinimalPlates
local MP = MinimalPlates

function MP.Config.Init()
  -- No longer sets protected CVars. Addon controls visuals internally.
  -- Nameplate scale is applied via plate:SetScale(MP.DB.scale) in UpdateLogic.
  -- Leave CVars untouched to avoid ADDON_ACTION_BLOCKED.

  -- CRITICAL: Ensure Blizzard shows nameplates (required for addon to work)
  if C_CVar and C_CVar.SetCVar then
    C_CVar.SetCVar("nameplateShowEnemies", "1")  -- Must be enabled

    -- Midnight (11.1+) uses different CVars for friendly players
    if C_CVar.GetCVarInfo("nameplateShowFriendlyPlayers") ~= nil then
      -- Midnight CVars
      C_CVar.SetCVar("nameplateShowFriendlyPlayers", "1")  -- Show friendly players (includes opposing faction in sanctuaries!)
      C_CVar.SetCVar("nameplateShowFriendlyNpcs", "1")     -- Show friendly NPCs
    else
      -- Classic/Retail CVars
      C_CVar.SetCVar("nameplateShowEnemyPlayers", "1")
      C_CVar.SetCVar("nameplateShowEnemyMinus", "1")
      C_CVar.SetCVar("nameplateShowFriends", "1")
      C_CVar.SetCVar("nameplateShowFriendlyNPCs", "1")
    end

    C_CVar.SetCVar("nameplateShowAll", "1")  -- Always show nameplates
  elseif SetCVar then
    SetCVar("nameplateShowEnemies", "1")
    SetCVar("nameplateShowEnemyPlayers", "1")
    SetCVar("nameplateShowEnemyMinus", "1")
    SetCVar("nameplateShowFriends", "1")
    SetCVar("nameplateShowFriendlyNPCs", "1")
    SetCVar("nameplateShowAll", "1")
  end

  -- Nameplate max distance (show plates as far as client allows)
  local maxDist = tostring(MP.DB.nameplateMaxDistance or 60)
  if C_CVar and C_CVar.SetCVar then
    C_CVar.SetCVar("nameplateMaxDistance", maxDist)
  elseif SetCVar then
    SetCVar("nameplateMaxDistance", maxDist)
  end

  -- Apply stacking/overlap CVars
  MP.Config.ApplyStackingCVars()
end

-- Apply nameplate stacking CVars
function MP.Config.ApplyStackingCVars()
  if C_CVar and C_CVar.SetCVar then
    -- Vertical overlap (controls stacking - lower = tighter stack)
    C_CVar.SetCVar("nameplateOverlapV", tostring(MP.DB.nameplateOverlapV or 0.5))
    -- Horizontal overlap
    C_CVar.SetCVar("nameplateOverlapH", tostring(MP.DB.nameplateOverlapH or 0.8))
  end
end

-- Color helper - Uses Blizzard's exact nameplate hostility classification logic
function MP.Config.GetUnitColor(unit)
  if not unit then return 1, 1, 1 end

  local isPlayer = UnitIsPlayer(unit)
  
  -- ===== BLIZZARD'S EXACT NAMEPLATE LOGIC =====
  -- Step 1: Check if unit can be attacked (handles sanctuaries, War Mode, phasing, etc.)
  local canAttack = UnitCanAttack("player", unit)
  
  if canAttack then
    -- HOSTILE - Can attack this unit
    -- For players: Use class colors if enabled, otherwise red
    if isPlayer and MP.DB.classColors then
      local _, class = UnitClass(unit)
      if class then
        local color = RAID_CLASS_COLORS[class]
        return color.r, color.g, color.b
      end
    end
    return 1, 0, 0 -- Red (hostile)
  end
  
  -- Step 2: Cannot attack - check reaction to determine friendly vs neutral
  local reaction = UnitReaction(unit, "player")
  
  if reaction and reaction >= 5 then
    -- FRIENDLY - Green
    if isPlayer and MP.DB.classColors then
      local _, class = UnitClass(unit)
      if class then
        local color = RAID_CLASS_COLORS[class]
        return color.r, color.g, color.b
      end
    end
    return 0, 1, 0 -- Green (friendly)
  else
    -- NEUTRAL - Yellow (includes opposing faction in sanctuaries/neutral zones)
    return 1, 1, 0 -- Yellow (neutral)
  end
end

-- Font helper
function MP.Config.GetFont()
  -- Use ARIALN for reliability across all WoW versions (Retail, Classic, Midnight)
  local font = MP.DB.font or "Fonts\\ARIALN.TTF"
  local size = MP.DB.fontSize or 12
  local flags = MP.DB.fontFlags or "NONE"
  
  -- In Midnight, SLUG flag is automatically applied by client
  -- Don't manually add it to avoid "Font not set" errors
  if flags == "NONE" then
    flags = ""
  end
  
  return font, size, flags
end

-- Texture helper
function MP.Config.GetBarTexture()
  return MP.SharedMedia and MP.SharedMedia.GetBarTexturePath and MP.SharedMedia.GetBarTexturePath(MP.DB.barTexture) or (MP.DB.barTexture or "Interface\\Buttons\\WHITE8X8")
end
