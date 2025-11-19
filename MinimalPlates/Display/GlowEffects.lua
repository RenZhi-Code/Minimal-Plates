---@class MinimalPlates
local MP = MinimalPlates

MP.Display = MP.Display or {}
MP.Display.GlowEffects = {}

-- ===== ON-DEMAND GLOW CREATION =====
-- Creates glow textures only when first needed (saves ~120KB with 50 plates)
-- All glows are created lazily and cached on the plate object

-- Create target highlight glow (only when unit becomes target)
local function EnsureTargetHighlight(plate)
  if plate.TargetHighlight then return end

  plate.TargetHighlight = plate:CreateTexture(nil, "BACKGROUND")
  plate.TargetHighlight:SetTexture("Interface/Nameplates/UI-Nameplate-TargetGlow")
  plate.TargetHighlight:SetAllPoints(plate.Health)
  plate.TargetHighlight:SetSize(MP.DB.healthWidth + 4, MP.DB.healthHeight + 4)
  plate.TargetHighlight:SetBlendMode("ADD")
  plate.TargetHighlight:Hide()
end

-- Create threat glow (only when unit has threat)
local function EnsureThreatGlow(plate)
  if plate.ThreatGlow then return end

  plate.ThreatGlow = plate:CreateTexture(nil, "BACKGROUND")
  plate.ThreatGlow:SetTexture("Interface/Nameplates/UI-Nameplate-Glow")
  plate.ThreatGlow:SetAllPoints(plate.Health)
  plate.ThreatGlow:SetSize(MP.DB.healthWidth + 8, MP.DB.healthHeight + 8)
  plate.ThreatGlow:SetBlendMode("ADD")
  plate.ThreatGlow:SetVertexColor(1, 0, 0, 0.8) -- Red glow
  plate.ThreatGlow:Hide()
end

-- Create focus glow (only when unit is focused)
local function EnsureFocusGlow(plate)
  if plate.FocusGlow then return end

  plate.FocusGlow = plate:CreateTexture(nil, "BACKGROUND")
  plate.FocusGlow:SetTexture("Interface/Nameplates/UI-Nameplate-FocusGlow")
  plate.FocusGlow:SetAllPoints(plate.Health)
  plate.FocusGlow:SetSize(MP.DB.healthWidth + 6, MP.DB.healthHeight + 6)
  plate.FocusGlow:SetBlendMode("ADD")
  plate.FocusGlow:Hide()
end

-- Create mouseover highlight (only on first mouseover)
local function EnsureMouseoverHighlight(plate)
  if plate.MouseoverHighlight then return end

  plate.MouseoverHighlight = plate:CreateTexture(nil, "BACKGROUND")
  plate.MouseoverHighlight:SetTexture("Interface/Nameplates/UI-Nameplate-Highlight")
  plate.MouseoverHighlight:SetAllPoints(plate.Health)
  plate.MouseoverHighlight:SetBlendMode("ADD")
  plate.MouseoverHighlight:Hide()
end

-- Create tapped overlay (only when mob is tapped)
local function EnsureTappedOverlay(plate)
  if plate.TappedOverlay then return end

  plate.TappedOverlay = plate:CreateTexture(nil, "OVERLAY")
  plate.TappedOverlay:SetTexture("Interface/Nameplates/UI-Nameplate-Tapped")
  plate.TappedOverlay:SetAllPoints(plate.Health)
  plate.TappedOverlay:SetBlendMode("BLEND")
  plate.TappedOverlay:Hide()
end

-- Show target highlight (creates on demand)
function MP.Display.GlowEffects.ShowTargetHighlight(plate)
  if not MP.DB.targetHighlight then return end
  EnsureTargetHighlight(plate)
  plate.TargetHighlight:Show()
end

-- Hide target highlight (no-op if never created)
function MP.Display.GlowEffects.HideTargetHighlight(plate)
  if plate.TargetHighlight then
    plate.TargetHighlight:Hide()
  end
end

-- Show threat glow (creates on demand)
function MP.Display.GlowEffects.ShowThreatGlow(plate)
  if not MP.DB.showThreatGlow then return end
  EnsureThreatGlow(plate)
  plate.ThreatGlow:Show()
end

-- Hide threat glow (no-op if never created)
function MP.Display.GlowEffects.HideThreatGlow(plate)
  if plate.ThreatGlow then
    plate.ThreatGlow:Hide()
  end
end

-- Show focus glow (creates on demand)
function MP.Display.GlowEffects.ShowFocusGlow(plate)
  if not MP.DB.showFocusGlow then return end
  EnsureFocusGlow(plate)
  plate.FocusGlow:Show()
end

-- Hide focus glow (no-op if never created)
function MP.Display.GlowEffects.HideFocusGlow(plate)
  if plate.FocusGlow then
    plate.FocusGlow:Hide()
  end
end

-- Show mouseover highlight (creates on demand)
function MP.Display.GlowEffects.ShowMouseoverHighlight(plate)
  if not MP.DB.showMouseoverHighlight then return end
  EnsureMouseoverHighlight(plate)
  plate.MouseoverHighlight:Show()
end

-- Hide mouseover highlight (no-op if never created)
function MP.Display.GlowEffects.HideMouseoverHighlight(plate)
  if plate.MouseoverHighlight then
    plate.MouseoverHighlight:Hide()
  end
end

-- Show tapped overlay (creates on demand)
function MP.Display.GlowEffects.ShowTappedOverlay(plate)
  if not MP.DB.showTappedOverlay then return end
  EnsureTappedOverlay(plate)
  plate.TappedOverlay:Show()
end

-- Hide tapped overlay (no-op if never created)
function MP.Display.GlowEffects.HideTappedOverlay(plate)
  if plate.TappedOverlay then
    plate.TappedOverlay:Hide()
  end
end
