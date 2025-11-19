---@class MinimalPlates
local MP = MinimalPlates

MP.Display = MP.Display or {}
MP.Display.AuraIcons = {}

-- Update aura icons on a nameplate
function MP.Display.AuraIcons.Update(plate)
  if not MP.DB.showAuras then
    -- Release all pooled aura icons from both containers
    MP.FramePools.ReleaseAllAuraIcons(plate.Buffs)
    MP.FramePools.ReleaseAllAuraIcons(plate.Debuffs)
    return
  end

  -- Release previous icons back to pool
  MP.FramePools.ReleaseAllAuraIcons(plate.Buffs)
  MP.FramePools.ReleaseAllAuraIcons(plate.Debuffs)

  -- Initialize active icons tracking
  if not plate.Buffs.activeIcons then
    plate.Buffs.activeIcons = {}
  end
  if not plate.Debuffs.activeIcons then
    plate.Debuffs.activeIcons = {}
  end

  local buffs = (plate.AuraTracker.GetBuffs and plate.AuraTracker:GetBuffs()) or {}
  local debuffs = plate.AuraTracker:GetDebuffs()
  local pandemic = plate.AuraTracker:GetPandemic()
  local iconSize = 20
  local iconSpacing = 2
  local isStacked = MP.DB.auraStackLayout

  -- Update buff container size and position based on Advanced settings
  local buffsPos = MP.DB.buffsPosition or "top"
  local buffsOffsetY = MP.DB.buffsOffsetY or 10
  local buffsScale = MP.DB.buffsScale or 1.0

  plate.Buffs:ClearAllPoints()
  if buffsPos == "top" then
    plate.Buffs:SetPoint("BOTTOMLEFT", plate.Health, "TOPLEFT", 0, buffsOffsetY)
  elseif buffsPos == "bottom" then
    plate.Buffs:SetPoint("TOPLEFT", plate.Health, "BOTTOMLEFT", 0, buffsOffsetY)
  elseif buffsPos == "none" then
    -- Hide buffs entirely
  else
    -- Default: top
    plate.Buffs:SetPoint("BOTTOMLEFT", plate.Health, "TOPLEFT", 0, buffsOffsetY)
  end
  plate.Buffs:SetScale(buffsScale)

  if isStacked then
    plate.Buffs:SetSize(iconSize, 120) -- Vertical: single column
  else
    plate.Buffs:SetSize(120, iconSize) -- Horizontal: single row
  end

  -- Update debuff container size and position based on Advanced settings
  local debuffsPos = MP.DB.debuffsPosition or "top"
  local debuffsOffsetY = MP.DB.debuffsOffsetY or 10
  local debuffsScale = MP.DB.debuffsScale or 1.0

  plate.Debuffs:ClearAllPoints()
  if debuffsPos == "top" then
    plate.Debuffs:SetPoint("BOTTOMLEFT", plate.Health, "TOPLEFT", 0, debuffsOffsetY)
  elseif debuffsPos == "bottom" then
    plate.Debuffs:SetPoint("TOPLEFT", plate.Health, "BOTTOMLEFT", 0, debuffsOffsetY)
  elseif debuffsPos == "none" then
    -- Hide debuffs entirely
  else
    -- Default: top
    plate.Debuffs:SetPoint("BOTTOMLEFT", plate.Health, "TOPLEFT", 0, debuffsOffsetY)
  end
  plate.Debuffs:SetScale(debuffsScale)

  if isStacked then
    plate.Debuffs:SetSize(iconSize, 120) -- Vertical: single column
  else
    plate.Debuffs:SetSize(120, iconSize) -- Horizontal: single row
  end
  
  -- Helper: Style aura icon based on type
  local function StyleAuraIcon(icon, aura, isPandemic, isDefensive, isOffensive, isImmunity, isCC)
    -- Base border (using Blizzard button border)
    if not icon.border then
      icon.border = icon:CreateTexture(nil, "BORDER")
      icon.border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
      icon.border:SetBlendMode("ADD")
      icon.border:SetAllPoints()
      icon.border:Hide()
    end
    
    -- Pandemic glow (using Blizzard auto cast shine)
    if not icon.pandemicGlow then
      icon.pandemicGlow = icon:CreateTexture(nil, "OVERLAY")
      icon.pandemicGlow:SetTexture("Interface\\SpellActivationOverlay\\IconAlert")
      icon.pandemicGlow:SetTexCoord(0.00781250, 0.50781250, 0.27734375, 0.52734375)
      icon.pandemicGlow:SetBlendMode("ADD")
      icon.pandemicGlow:SetPoint("TOPLEFT", icon, "TOPLEFT", -8, 8)
      icon.pandemicGlow:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 8, -8)
      icon.pandemicGlow:Hide()
    end
    
    -- Apply styling based on aura type
    if isPandemic and plate.AuraTracker:IsPandemicActive(aura) then
      -- Pandemic glow (orange/yellow pulse)
      icon.pandemicGlow:SetVertexColor(1, 0.5, 0, 1)
      icon.pandemicGlow:Show()
      icon.border:Hide()
    elseif isImmunity then
      -- Purple/gold border for immunities
      icon.border:SetVertexColor(0.8, 0.4, 1, 1)
      icon.border:Show()
      icon.pandemicGlow:Hide()
    elseif isCC then
      -- Red border for CC
      icon.border:SetVertexColor(1, 0.2, 0.2, 1)
      icon.border:Show()
      icon.pandemicGlow:Hide()
    elseif isDefensive then
      -- Blue border for defensives
      icon.border:SetVertexColor(0.2, 0.5, 1, 1)
      icon.border:Show()
      icon.pandemicGlow:Hide()
    elseif isOffensive then
      -- Yellow border for offensives
      icon.border:SetVertexColor(1, 0.8, 0, 1)
      icon.border:Show()
      icon.pandemicGlow:Hide()
    else
      -- Standard look
      icon.border:Hide()
      icon.pandemicGlow:Hide()
    end
  end
  
  -- Helper: Acquire icon from pool for a specific container
  local function GetAuraIcon(container)
    local icon = MP.FramePools.AcquireAuraIcon(container)
    table.insert(container.activeIcons, icon)
    icon:SetSize(iconSize, iconSize)
    return icon
  end

  -- Show buffs (if enabled)
  if MP.DB.showBuffs and buffsPos ~= "none" then
    local buffIndex = 1
    for _, aura in ipairs(buffs) do
      if buffIndex > 6 then break end -- Max 6 icons

      local icon = GetAuraIcon(plate.Buffs)
      if isStacked then
        icon:SetPoint("TOP", 0, -((buffIndex - 1) * (iconSize + iconSpacing)))
      else
        icon:SetPoint("LEFT", (buffIndex - 1) * (iconSize + iconSpacing), 0)
      end
      icon.texture:SetTexture(aura.icon)

      if aura.applications and aura.applications > 1 then
        icon.count:SetText(aura.applications)
        icon.count:Show()
      else
        icon.count:Hide()
      end

      if aura.expirationTime and aura.expirationTime > 0 then
        icon.cooldown:SetCooldown(aura.expirationTime - aura.duration, aura.duration)
        icon.cooldown:Show()
      else
        icon.cooldown:Hide()
      end

      StyleAuraIcon(icon, aura, false, false, false, false, false)
      icon:Show()
      buffIndex = buffIndex + 1
    end
  end

  -- Show regular debuffs (if enabled)
  if MP.DB.showDebuffs and debuffsPos ~= "none" then
    local iconIndex = 1
    for _, aura in ipairs(debuffs) do
      if iconIndex > 6 then break end -- Max 6 icons

      local icon = GetAuraIcon(plate.Debuffs)
      if isStacked then
        icon:SetPoint("TOP", 0, -((iconIndex - 1) * (iconSize + iconSpacing)))
      else
        icon:SetPoint("LEFT", (iconIndex - 1) * (iconSize + iconSpacing), 0)
      end
      icon.texture:SetTexture(aura.icon)

      if aura.applications and aura.applications > 1 then
        icon.count:SetText(aura.applications)
        icon.count:Show()
      else
        icon.count:Hide()
      end

      if aura.expirationTime and aura.expirationTime > 0 then
        icon.cooldown:SetCooldown(aura.expirationTime - aura.duration, aura.duration)
        icon.cooldown:Show()
      else
        icon.cooldown:Hide()
      end

      StyleAuraIcon(icon, aura, false, false, false, false, false)
      icon:Show()
      iconIndex = iconIndex + 1
    end

    -- Show pandemic DoTs with glow
    for _, aura in ipairs(pandemic) do
      if iconIndex > 6 then break end

      local icon = GetAuraIcon(plate.Debuffs)
      if isStacked then
        icon:SetPoint("TOP", 0, -((iconIndex - 1) * (iconSize + iconSpacing)))
      else
        icon:SetPoint("LEFT", (iconIndex - 1) * (iconSize + iconSpacing), 0)
      end
      icon.texture:SetTexture(aura.icon)

      if aura.applications and aura.applications > 1 then
        icon.count:SetText(aura.applications)
        icon.count:Show()
      else
        icon.count:Hide()
      end

      if aura.expirationTime and aura.expirationTime > 0 then
        icon.cooldown:SetCooldown(aura.expirationTime - aura.duration, aura.duration)
        icon.cooldown:Show()
      else
        icon.cooldown:Hide()
      end

      StyleAuraIcon(icon, aura, true, false, false, false, false)
      icon:Show()
      iconIndex = iconIndex + 1
    end
  end
end
