---@class MinimalPlates
local MP = MinimalPlates

MP.FramePools = {}

-- ===== FRAME POOLING SYSTEM =====
-- Significantly reduces CPU usage by reusing frames instead of creating/destroying them
-- Based on BetterBlizzPlates and Platynator patterns

-- Initialize all frame pools
function MP.FramePools.Init()
  -- Pool for aura icons (most frequently created/destroyed)
  MP.FramePools.AuraPool = CreateFramePool("Frame")
  
  -- Pool for icon overlays (borders, glows, etc.)
  MP.FramePools.TexturePool = CreateObjectPool(
    function() return MP.FramePools._CreatePooledTexture() end,
    function(texture) texture:Hide() end
  )
  
  -- Pool for cooldown frames
  MP.FramePools.CooldownPool = CreateFramePool("Cooldown", nil, "CooldownFrameTemplate")
  
  -- Pool for font strings (counts, text overlays)
  MP.FramePools.FontStringPool = CreateObjectPool(
    function() return MP.FramePools._CreatePooledFontString() end,
    function(fontString) fontString:Hide() end
  )
end

-- Helper: Create pooled texture
function MP.FramePools._CreatePooledTexture()
  local frame = CreateFrame("Frame")
  frame:SetSize(1, 1)
  local texture = frame:CreateTexture(nil, "ARTWORK")
  texture:SetAllPoints(frame)
  texture.parentFrame = frame
  return texture
end

-- Helper: Create pooled font string  
function MP.FramePools._CreatePooledFontString()
  local frame = CreateFrame("Frame")
  frame:SetSize(1, 1)
  local fontString = frame:CreateFontString(nil, "OVERLAY")
  fontString.parentFrame = frame
  return fontString
end

-- ===== AURA ICON POOLING =====
-- Optimized aura icon creation using frame pools

-- Create an aura icon from the pool
function MP.FramePools.AcquireAuraIcon(parent)
  local icon = MP.FramePools.AuraPool:Acquire()
  icon:SetParent(parent)
  icon:Show()
  
  -- Ensure sub-elements exist
  if not icon.texture then
    icon.texture = icon:CreateTexture(nil, "ARTWORK")
    icon.texture:SetAllPoints()
    icon.texture:SetTexCoord(0.1, 0.9, 0.1, 0.9) -- Standard icon crop
  end
  
  if not icon.border then
    icon.border = icon:CreateTexture(nil, "BORDER")
    icon.border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    icon.border:SetBlendMode("ADD")
    icon.border:SetAllPoints()
  end
  
  if not icon.pandemicGlow then
    icon.pandemicGlow = icon:CreateTexture(nil, "OVERLAY")
    icon.pandemicGlow:SetTexture("Interface\\SpellActivationOverlay\\IconAlert")
    icon.pandemicGlow:SetTexCoord(0.00781250, 0.50781250, 0.27734375, 0.52734375)
    icon.pandemicGlow:SetBlendMode("ADD")
    icon.pandemicGlow:SetPoint("TOPLEFT", icon, "TOPLEFT", -8, 8)
    icon.pandemicGlow:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 8, -8)
  end
  
  if not icon.cooldown then
    icon.cooldown = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate")
    icon.cooldown:SetAllPoints()
    icon.cooldown:SetDrawEdge(false)
    icon.cooldown:SetHideCountdownNumbers(false)
  end
  
  if not icon.count then
    icon.count = icon:CreateFontString(nil, "OVERLAY")
    icon.count:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    icon.count:SetPoint("BOTTOMRIGHT", 2, -2)
    icon.count:SetTextColor(1, 1, 1)
  end
  
  -- Reset state
  icon:ClearAllPoints()
  icon.texture:SetTexture(nil)
  icon.border:Hide()
  icon.pandemicGlow:Hide()
  icon.cooldown:Hide()
  icon.count:Hide()
  
  return icon
end

-- Release an aura icon back to the pool
function MP.FramePools.ReleaseAuraIcon(icon)
  if icon then
    icon:Hide()
    icon:ClearAllPoints()
    icon:SetParent(nil)
    MP.FramePools.AuraPool:Release(icon)
  end
end

-- Release all aura icons for a nameplate
function MP.FramePools.ReleaseAllAuraIcons(plate)
  if plate and plate.Auras and plate.Auras.activeIcons then
    for _, icon in ipairs(plate.Auras.activeIcons) do
      MP.FramePools.ReleaseAuraIcon(icon)
    end
    plate.Auras.activeIcons = {}
  end
end

-- ===== PERFORMANCE STATS =====
-- Track pool usage for debugging

function MP.FramePools.GetStats()
  local stats = {
    auraPoolSize = MP.FramePools.AuraPool and MP.FramePools.AuraPool:GetNumActive() or 0,
    cooldownPoolSize = MP.FramePools.CooldownPool and MP.FramePools.CooldownPool:GetNumActive() or 0,
  }
  return stats
end

-- Print pool statistics
function MP.FramePools.PrintStats()
  local stats = MP.FramePools.GetStats()
  print("|cffff00ff[MinimalPlates Frame Pools]|r")
  print(string.format("  Aura Icons Active: %d", stats.auraPoolSize))
  print(string.format("  Cooldowns Active: %d", stats.cooldownPoolSize))
end
