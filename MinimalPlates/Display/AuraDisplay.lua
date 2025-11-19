-- AuraDisplay.lua loaded
---@class MinimalPlates
local MP = MinimalPlates

MP.Display = MP.Display or {}
MP.Display.AuraDisplay = {}

-- ===== PHASE 3: 3-TIER AURA DISPLAY =====
-- Separate displays for Buffs, Debuffs, and Crowd Control
-- Independent positioning, scaling, and direction
-- Priority sorting with auto-enlarge for important auras

-- Update 3-tier aura display
function MP.Display.AuraDisplay.Update(plate)
  if not MP.DB.showAuras then
    -- Release all pooled aura icons
    MP.FramePools.ReleaseAllAuraIcons(plate)
    return
  end
  
  -- Get categorized auras from filter
  local buffs, debuffs, cc = MP.AuraFilter.GetCategorizedAuras(plate)
  
  -- Release previous icons
  MP.FramePools.ReleaseAllAuraIcons(plate)
  
  -- Display each tier separately
  if MP.DB.showBuffs and #buffs > 0 then
    MP.Display.AuraDisplay.DisplayTier(plate, buffs, "buff")
  end
  
  if MP.DB.showDebuffs and #debuffs > 0 then
    MP.Display.AuraDisplay.DisplayTier(plate, debuffs, "debuff")
  end
  
  if MP.DB.showCrowdControl and #cc > 0 then
    MP.Display.AuraDisplay.DisplayTier(plate, cc, "cc")
  end
end

-- Display a single tier of auras
function MP.Display.AuraDisplay.DisplayTier(plate, auras, tierType)
  if not auras or #auras == 0 then return end
  
  -- Get tier-specific settings
  local position = MP.DB[tierType .. "Position"] or "top"
  local scale = MP.DB[tierType .. "Scale"] or 1.0
  local iconSize = 20 * scale
  local iconSpacing = 2
  local maxIcons = 6
  
  -- Create container for this tier if needed
  local containerName = tierType .. "Container"
  if not plate[containerName] then
    plate[containerName] = CreateFrame("Frame", nil, plate)
    plate[containerName]:SetSize(120, 24)
    plate[containerName]:SetFlattensRenderLayers(true)
    plate[containerName].activeIcons = {}
  end
  
  local container = plate[containerName]
  
  -- Position container based on tier type
  container:ClearAllPoints()
  if tierType == "cc" then
    -- CC on left/right of health bar
    if position == "left" then
      container:SetPoint("RIGHT", plate.Health, "LEFT", -4, 0)
    else
      container:SetPoint("LEFT", plate.Health, "RIGHT", 4, 0)
    end
  elseif tierType == "buff" then
    -- Buffs above health bar
    container:SetPoint("BOTTOM", plate.Health, "TOP", 0, 10)
  else
    -- Debuffs above buffs or health bar
    local hasBuffRow = false
    if MP.DB.showBuffs and plate.buffContainer and plate.buffContainer.activeIcons and #plate.buffContainer.activeIcons > 0 then
      hasBuffRow = true
    end
    if hasBuffRow then
      container:SetPoint("BOTTOM", plate.buffContainer, "TOP", 0, 2)
    else
      container:SetPoint("BOTTOM", plate.Health, "TOP", 0, 10)
    end
  end
  
  -- Display icons
  for i = 1, math.min(#auras, maxIcons) do
    local aura = auras[i]
    local icon = MP.FramePools.AcquireAuraIcon(container)
    table.insert(container.activeIcons, icon)
    
    -- Size adjustment for important auras
    local isImportant = MP.AuraFilter.IsImportant(aura.spellId)
    local finalSize = iconSize
    if isImportant and MP.DB.autoEnlargeImportant then
      finalSize = iconSize * (MP.DB.importantAuraScale or 1.3)
    end
    
    icon:SetSize(finalSize, finalSize)
    
    -- Position icon
    icon:ClearAllPoints()
    if position == "left" or position == "right" then
      -- Vertical layout for side positions
      icon:SetPoint("TOP", container, "TOP", 0, -((i - 1) * (finalSize + iconSpacing)))
    else
      -- Horizontal layout for top/bottom
      icon:SetPoint("LEFT", container, "LEFT", (i - 1) * (finalSize + iconSpacing), 0)
    end
    
    -- Set texture
    if icon.texture and aura.icon then
      icon.texture:SetTexture(aura.icon)
    end
    
    -- Stack count
    if aura.applications and aura.applications > 1 then
      if icon.count then
        icon.count:SetText(aura.applications)
        icon.count:Show()
      end
    else
      if icon.count then icon.count:Hide() end
    end
    
    -- Cooldown spiral
    if aura.expirationTime and aura.expirationTime > 0 and icon.cooldown then
      icon.cooldown:SetCooldown(aura.expirationTime - (aura.duration or 0), aura.duration or 0)
      icon.cooldown:Show()
    else
      if icon.cooldown then icon.cooldown:Hide() end
    end
    
    -- Apply styling based on aura type
    MP.Display.AuraDisplay.StyleIcon(icon, aura, tierType)
    
    icon:Show()
  end
end

-- Style aura icon based on type and importance
function MP.Display.AuraDisplay.StyleIcon(icon, aura, tierType)
  if not icon or not aura then return end
  
  local spellId = aura.spellId
  
  -- Check if whitelisted (custom color)
  if MP.AuraFilter.IsWhitelisted(spellId) then
    local whitelistData = MP.DB.auraWhitelist[spellId]
    if whitelistData and whitelistData.color then
      if icon.border then
        icon.border:SetVertexColor(
          whitelistData.color.r or 1,
          whitelistData.color.g or 1,
          whitelistData.color.b or 1,
          1
        )
        icon.border:Show()
      end
      if icon.pandemicGlow then icon.pandemicGlow:Hide() end
      return
    end
  end
  
  -- Apply tier-specific styling
  if tierType == "cc" then
    -- Red border for CC
    if icon.border then
      icon.border:SetVertexColor(1, 0.2, 0.2, 1)
      icon.border:Show()
    end
    if icon.pandemicGlow then icon.pandemicGlow:Hide() end
    
  elseif MP.AuraFilter.IsImmunity(spellId) then
    -- Purple/gold border for immunities
    if icon.border then
      icon.border:SetVertexColor(0.8, 0.4, 1, 1)
      icon.border:Show()
    end
    if icon.pandemicGlow then icon.pandemicGlow:Hide() end
    
  elseif MP.AuraFilter.IsImportantDefensive(spellId) then
    -- Blue border for defensives
    if icon.border then
      icon.border:SetVertexColor(0.2, 0.5, 1, 1)
      icon.border:Show()
    end
    if icon.pandemicGlow then icon.pandemicGlow:Hide() end
    
  elseif MP.AuraFilter.IsImportantOffensive(spellId) then
    -- Yellow border for offensives
    if icon.border then
      icon.border:SetVertexColor(1, 0.8, 0, 1)
      icon.border:Show()
    end
    if icon.pandemicGlow then icon.pandemicGlow:Hide() end
    
  elseif aura.sourceUnit and UnitIsUnit(aura.sourceUnit, "player") then
    -- Pandemic glow for player-cast DoTs
    if plate.AuraTracker and plate.AuraTracker:IsPandemicActive(aura) then
      if icon.pandemicGlow then
        icon.pandemicGlow:SetVertexColor(1, 0.5, 0, 1)
        icon.pandemicGlow:Show()
      end
      if icon.border then icon.border:Hide() end
    else
      -- Green tint for player auras
      if icon.border then
        icon.border:SetVertexColor(0, 1, 0, 0.5)
        icon.border:Show()
      end
      if icon.pandemicGlow then icon.pandemicGlow:Hide() end
    end
    
  else
    -- Standard look
    if icon.border then icon.border:Hide() end
    if icon.pandemicGlow then icon.pandemicGlow:Hide() end
  end
end

-- Clean up tier containers
function MP.Display.AuraDisplay.CleanupContainers(plate)
  if plate.buffContainer then
    MP.FramePools.ReleaseAllAuraIcons(plate.buffContainer)
  end
  if plate.debuffContainer then
    MP.FramePools.ReleaseAllAuraIcons(plate.debuffContainer)
  end
  if plate.ccContainer then
    MP.FramePools.ReleaseAllAuraIcons(plate.ccContainer)
  end
end
