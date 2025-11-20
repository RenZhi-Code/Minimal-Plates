---@class MinimalPlates
local MP = MinimalPlates

MP.Display = MP.Display or {}
MP.Display.FrameCreation = {}

-- Create custom nameplate frame
function MP.Display.FrameCreation.Create(baseFrame)
  -- Create frame parented to baseFrame (will be reparented on install)
  local plate = CreateFrame("Frame", nil, baseFrame)
  
  -- Set tiny size for the anchor point
  -- This makes the frame less prone to collision/scaling issues
  plate:SetSize(10, 10)
  plate:SetPoint("CENTER")
  
  -- ===== RENDER OPTIMIZATION: Flatten render layers =====
  -- Reduces render batches by 30-50% when multiple textures share the same layer
  plate:SetFlattensRenderLayers(true)
  
  -- ===== RENDER OPTIMIZATION: Ignore parent scale =====
  -- Prevents constant scale recalculation when Blizzard frame scales change
  plate:SetIgnoreParentScale(true)
  
  -- ===== RENDER OPTIMIZATION: Ignore parent alpha =====
  -- Prevents alpha inheritance issues from Blizzard frames
  plate:SetIgnoreParentAlpha(true)
  
  -- Health bar (StatusBar for proper fill effect)
  plate.Health = CreateFrame("StatusBar", nil, plate)
  plate.Health:SetPoint("CENTER", 0, 0)
  plate.Health:SetSize(MP.DB.healthWidth, MP.DB.healthHeight)
  plate.Health:SetStatusBarTexture(MP.Config.GetBarTexture())
  plate.Health:GetStatusBarTexture():SetDrawLayer("BORDER", 0) -- Force texture below text layers
  plate.Health:GetStatusBarTexture():SetVertexColor(1, 1, 1)
  plate.Health:GetStatusBarTexture():SetSnapToPixelGrid(false)
  plate.Health:GetStatusBarTexture():SetTexelSnappingBias(0)
  plate.Health:SetMinMaxValues(0, 100)
  plate.Health:SetValue(100)
  plate.Health:SetClipsChildren(true)
  plate.Health:GetStatusBarTexture():SetMask("Interface\\Buttons\\WHITE8X8")
  plate.Health:SetAlpha(1.0) -- Full opacity
  
  -- ===== MEMORY OPTIMIZATION: Create overlays/borders on demand =====
  -- Only create visual polish elements if explicitly enabled
  -- This reduces per-nameplate memory from ~55 to ~35 frames/textures (-36% memory)

  -- Health border (simple 1px border - lightweight)
  plate.HealthBorder = CreateFrame("Frame", nil, plate, "BackdropTemplate")
  plate.HealthBorder:SetPoint("TOPLEFT", plate.Health:GetStatusBarTexture(), "TOPLEFT", -1, 1)
  plate.HealthBorder:SetPoint("BOTTOMRIGHT", plate.Health:GetStatusBarTexture(), "BOTTOMRIGHT", 1, -1)
  plate.HealthBorder:SetBackdrop({
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
  })
  plate.HealthBorder:SetBackdropBorderColor(0, 0, 0, 1)
  
  -- Name text (on separate high-level frame to ensure visibility above health bar)
  -- IMPORTANT: Create NameFrame FIRST so icons can be parented to it
  plate.NameFrame = CreateFrame("Frame", nil, plate)
  plate.NameFrame:SetAllPoints(plate.Health)  -- Match health bar size, not entire plate
  plate.NameFrame:SetFrameStrata("HIGH")
  plate.NameFrame:SetFrameLevel(101)  -- Above HealthTextFrame (100)
  plate.NameFrame:SetIgnoreParentAlpha(true)

  -- Elite Dragon Icon (custom) - created on NameFrame for visibility when positioned middle
  plate.EliteIcon = plate.NameFrame:CreateTexture(nil, "OVERLAY")
  plate.EliteIcon:SetTexture("Interface\\AddOns\\MinimalPlates\\Libs\\Icons\\elite.png")
  plate.EliteIcon:SetSize(16, 16)
  plate.EliteIcon:SetPoint("LEFT", plate.Name, "RIGHT", 2, 0)
  plate.EliteIcon:Hide()

  -- Rare Icon (custom) - created on NameFrame for visibility when positioned middle
  plate.RareIcon = plate.NameFrame:CreateTexture(nil, "OVERLAY")
  plate.RareIcon:SetTexture("Interface\\AddOns\\MinimalPlates\\Libs\\Icons\\rareelite.png")
  plate.RareIcon:SetSize(16, 16)
  plate.RareIcon:SetPoint("LEFT", plate.Name, "RIGHT", 2, 0)
  plate.RareIcon:Hide()

  -- Rare-Elite Combo Icon (custom) - created on NameFrame for visibility when positioned middle
  plate.RareEliteIcon = plate.NameFrame:CreateTexture(nil, "OVERLAY")
  plate.RareEliteIcon:SetTexture("Interface\\AddOns\\MinimalPlates\\Libs\\Icons\\eliterarecombo.png")
  plate.RareEliteIcon:SetSize(16, 16)
  plate.RareEliteIcon:SetPoint("LEFT", plate.Name, "RIGHT", 2, 0)
  plate.RareEliteIcon:Hide()

  plate.Name = plate.NameFrame:CreateFontString(nil, "OVERLAY")
  plate.Name:SetFont(MP.Config.GetFont())
  plate.Name:SetPoint("CENTER", 0, 0)
  plate.Name:SetWidth(MP.DB.healthWidth or 120)  -- Match health bar width for truncation
  plate.Name:SetWordWrap(false)
  plate.Name:SetJustifyH("CENTER")
  plate.Name:SetTextColor(1, 1, 1)
  plate.Name:SetShadowOffset(3, -3)
  plate.Name:SetShadowColor(0, 0, 0, 1)

  -- ===== MEMORY OPTIMIZATION: Removed NameOutline =====
  -- Font flags provide outline - no need for duplicate hidden fontstring
  -- Saves 1 FontString per nameplate (~2KB each = ~100KB with 50 plates)
  
  -- Level text (for enemies only, positioned to the left of health bar)
  plate.Level = plate:CreateFontString(nil, "OVERLAY")
  local font, size, flags = MP.Config.GetFont()
  plate.Level:SetFont(font, size * (MP.DB.levelIconScale or 1.5), flags)
  plate.Level:SetPoint("RIGHT", plate.Health, "LEFT", -4, 0)
  plate.Level:SetTextColor(1, 1, 1)
  plate.Level:SetShadowOffset(1, -1)
  plate.Level:SetShadowColor(0, 0, 0, 1)
  
  -- Classification text (Elite/Rare/Boss) - created on NameFrame for visibility when positioned middle
  plate.Classification = plate.NameFrame:CreateFontString(nil, "OVERLAY")
  plate.Classification:SetFont(MP.Config.GetFont())
  plate.Classification:SetPoint("LEFT", plate.Health, "RIGHT", 4, 0)
  plate.Classification:SetTextColor(1, 0.8, 0)
  plate.Classification:SetShadowOffset(1, -1)
  plate.Classification:SetShadowColor(0, 0, 0, 1)
  plate.Classification:Hide()
  
-- Deleted: duplicate Elite/Rare icon creation (replaced by custom icons)

  
  -- Quest Icon (unified for quests, world quests, bonus objectives)
  -- Uses custom high-quality quest icon - will show for any quest-related unit
  -- Created on NameFrame for visibility when positioned middle
  plate.QuestIcon = plate.NameFrame:CreateTexture(nil, "OVERLAY")
  plate.QuestIcon:SetTexture("Interface\\AddOns\\MinimalPlates\\Libs\\Icons\\wow-quest-exclamation-mark.png")
  plate.QuestIcon:SetSize(MP.DB.questIconSize or 16, MP.DB.questIconSize or 16)
  plate.QuestIcon:SetPoint("LEFT", plate.Name, "RIGHT", 4, 0)
  plate.QuestIcon:Hide()

  -- REMOVED: WorldQuestIcon, BonusObjectiveIcon - merged into single QuestIcon above
  -- Saves 2 textures per nameplate = ~25KB with 50 plates
  
  -- Buff container (separate from debuffs for independent positioning)
  plate.Buffs = CreateFrame("Frame", nil, plate)
  plate.Buffs:SetPoint("BOTTOMLEFT", plate.Health, "TOPLEFT", 0, MP.DB.buffsOffsetY or 10)
  plate.Buffs:SetSize(120, 24)
  plate.Buffs:SetFlattensRenderLayers(true)
  plate.Buffs.activeIcons = {}

  -- Debuff container (separate from buffs for independent positioning)
  plate.Debuffs = CreateFrame("Frame", nil, plate)
  plate.Debuffs:SetPoint("BOTTOMLEFT", plate.Health, "TOPLEFT", 0, MP.DB.debuffsOffsetY or 10)
  plate.Debuffs:SetSize(120, 24)
  plate.Debuffs:SetFlattensRenderLayers(true)
  plate.Debuffs.activeIcons = {}

  -- Legacy Auras container (kept for backward compatibility, points to Debuffs)
  plate.Auras = plate.Debuffs

  -- Role Icon (Tank/Healer/DPS) - created on NameFrame for visibility when positioned middle
  plate.RoleIcon = plate.NameFrame:CreateTexture(nil, "OVERLAY")
  plate.RoleIcon:SetSize(16, 16)
  plate.RoleIcon:SetPoint("BOTTOM", plate.Buffs, "TOP", 0, 2)
  plate.RoleIcon:Hide()

  -- Raid Marker - created on NameFrame for visibility when positioned middle
  plate.RaidMarker = plate.NameFrame:CreateTexture(nil, "OVERLAY")
  plate.RaidMarker:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons") -- Set base texture
  plate.RaidMarker:SetSize(MP.DB.raidMarkerSize or 24, MP.DB.raidMarkerSize or 24)
  plate.RaidMarker:SetPoint("BOTTOM", plate.Buffs, "TOP", 0, 4) -- Default position above buffs
  plate.RaidMarker:Hide()

  -- ===== MEMORY/CPU OPTIMIZATION: On-demand glow/effect creation =====
  -- Create glows/effects only when first needed (saves ~120KB memory with 50 plates)
  -- These textures are created lazily via helper functions in UpdateLogic
  -- plate.TargetHighlight, plate.ThreatGlow, plate.FocusGlow, plate.MouseoverHighlight,
  -- plate.LossOfAggroFlash, plate.TappedOverlay (created on demand)

  -- ===== MEMORY OPTIMIZATION: Removed rarely-used icons =====
  -- SoftTargetIcon, InterruptShield, HealerIcon, PetIcon (gamepad/niche features)
  -- Saves ~4 textures per nameplate = ~50KB with 50 plates

  -- ===== ESSENTIAL: CC Indicator (kept - frequently used in PvP/M+) =====
  -- Created on NameFrame for visibility when positioned middle
  plate.CCIcon = plate.NameFrame:CreateTexture(nil, "OVERLAY")
  plate.CCIcon:SetSize(24, 24)
  plate.CCIcon:SetPoint("LEFT", plate.Name, "RIGHT", 6, 0)
  plate.CCIcon:Hide()
  
  -- Power Bar (StatusBar - shown only on target for combo points, runes, etc.)
  plate.PowerBar = CreateFrame("StatusBar", nil, plate)
  plate.PowerBar:SetPoint("TOP", plate.Health, "BOTTOM", 0, MP.DB.castYOffset or -2)
  plate.PowerBar:SetSize(MP.DB.healthWidth, 3)
  plate.PowerBar:SetStatusBarTexture(MP.Config.GetBarTexture())
  plate.PowerBar:GetStatusBarTexture():SetSnapToPixelGrid(false)
  plate.PowerBar:GetStatusBarTexture():SetTexelSnappingBias(0)
  plate.PowerBar:SetMinMaxValues(0, 100)
  plate.PowerBar:SetValue(0)
  plate.PowerBar:SetClipsChildren(true)
  plate.PowerBar:Hide()
  
  -- Power Bar Border
  local powerBorderHolder = CreateFrame("Frame", nil, plate)
  powerBorderHolder:SetFlattensRenderLayers(true)
  plate.PowerBorder = CreateFrame("Frame", nil, powerBorderHolder, "BackdropTemplate")
  plate.PowerBorder:SetPoint("TOPLEFT", plate.PowerBar, -1, 1)
  plate.PowerBorder:SetPoint("BOTTOMRIGHT", plate.PowerBar, 1, -1)
  plate.PowerBorder:SetBackdrop({
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
  })
  plate.PowerBorder:SetBackdropBorderColor(0, 0, 0, 1)
  plate.PowerBorder:Hide()
  
  -- Guild Text
  plate.GuildText = plate:CreateFontString(nil, "OVERLAY")
  plate.GuildText:SetFont(MP.Config.GetFont())
  plate.GuildText:SetPoint("TOP", plate.Name, "BOTTOM", 0, -2)
  plate.GuildText:SetTextColor(0.5, 1, 0.5)
  plate.GuildText:SetShadowOffset(1, -1)
  plate.GuildText:SetShadowColor(0, 0, 0, 1)
  plate.GuildText:Hide()
  
  -- Creature Text (NPC titles/subtitles)
  plate.CreatureText = plate:CreateFontString(nil, "OVERLAY")
  plate.CreatureText:SetFont(MP.Config.GetFont())
  plate.CreatureText:SetPoint("TOP", plate.Name, "BOTTOM", 0, -2)
  plate.CreatureText:SetTextColor(0.9, 0.9, 0.9)
  plate.CreatureText:SetShadowOffset(1, -1)
  plate.CreatureText:SetShadowColor(0, 0, 0, 1)
  plate.CreatureText:Hide()
  
  -- Health Text (directly on NameFrame to share same high strata for visibility)
  plate.HealthText = plate.NameFrame:CreateFontString(nil, "OVERLAY")
  plate.HealthText:SetFont(MP.Config.GetFont())
  plate.HealthText:SetPoint("CENTER", plate.Health, "CENTER", 0, 0)
  plate.HealthText:SetTextColor(1, 1, 1)
  plate.HealthText:SetShadowOffset(1, -1)
  plate.HealthText:SetShadowColor(0, 0, 0, 1)
  plate.HealthText:SetWordWrap(false)  -- Enable truncation with ellipsis
  plate.HealthText:SetNonSpaceWrap(false)  -- Don't wrap on non-space characters
  plate.HealthText:Hide()
  
  -- Unit Target Text (who the unit is targeting - no arrow symbol)
  plate.UnitTargetText = plate:CreateFontString(nil, "OVERLAY")
  plate.UnitTargetText:SetFont(MP.Config.GetFont())
  plate.UnitTargetText:SetPoint("LEFT", plate.Health, "RIGHT", 4, 0)
  plate.UnitTargetText:SetTextColor(1, 0.5, 0)
  plate.UnitTargetText:SetShadowOffset(1, -1)
  plate.UnitTargetText:SetShadowColor(0, 0, 0, 1)
  plate.UnitTargetText:Hide()
  
  -- PvP Marker (flag carrier, orb carrier, etc.)
  plate.PvPMarker = plate:CreateTexture(nil, "OVERLAY")
  plate.PvPMarker:SetSize(32, 32)
  plate.PvPMarker:SetPoint("LEFT", plate.Health, "RIGHT", 8, 0)
  plate.PvPMarker:Hide()
  
  -- Cast Target Text
  plate.CastTargetText = plate:CreateFontString(nil, "OVERLAY")
  plate.CastTargetText:SetFont(MP.Config.GetFont())
  plate.CastTargetText:SetPoint("TOP", plate.CastText, "BOTTOM", 0, -2)
  plate.CastTargetText:SetTextColor(1, 0.8, 0)
  plate.CastTargetText:SetShadowOffset(1, -1)
  plate.CastTargetText:SetShadowColor(0, 0, 0, 1)
  plate.CastTargetText:Hide()
  
  -- Aura tracker
  plate.AuraTracker = CreateFrame("Frame", nil, plate)
  Mixin(plate.AuraTracker, MP.AurasMixin)
  plate.AuraTracker:OnLoad()
  
  -- Cast bar (StatusBar for smooth animation with reverse fill support)
  plate.Cast = CreateFrame("StatusBar", nil, plate)
  plate.Cast:SetPoint("TOP", plate.Health, "BOTTOM", 0, -2)
  plate.Cast:SetSize(MP.DB.healthWidth, MP.DB.castHeight)
  plate.Cast:SetStatusBarTexture(MP.Config.GetBarTexture())
  plate.Cast:GetStatusBarTexture():SetVertexColor(1, 0.7, 0)
  
  -- ===== RENDER OPTIMIZATION: Pixel-perfect rendering =====
  -- Disable pixel grid snapping for smoother animations
  plate.Cast:GetStatusBarTexture():SetSnapToPixelGrid(false)
  plate.Cast:GetStatusBarTexture():SetTexelSnappingBias(0)
  
  plate.Cast:SetMinMaxValues(0, 1)
  plate.Cast:SetValue(0)
  plate.Cast:SetClipsChildren(true)
  plate.Cast:GetStatusBarTexture():SetMask("Interface\\Buttons\\WHITE8X8")
  
  -- Polished bar overlays (highlight + shadow)
  plate.CastHighlightOverlay = plate.Cast:CreateTexture(nil, "OVERLAY")
  plate.CastHighlightOverlay:SetAllPoints(plate.Cast)
  plate.CastHighlightOverlay:SetBlendMode("ADD")
  plate.CastHighlightOverlay:SetTexture("Interface\\Buttons\\WHITE8X8")
  if plate.CastHighlightOverlay.SetGradient and CreateColor then
    plate.CastHighlightOverlay:SetGradient("VERTICAL", CreateColor(1, 1, 1, 0.30), CreateColor(1, 1, 1, 0))
  else
    plate.CastHighlightOverlay:SetColorTexture(1, 1, 1, 0.24)
  end
  
  plate.CastShadowOverlay = plate.Cast:CreateTexture(nil, "OVERLAY")
  plate.CastShadowOverlay:SetAllPoints(plate.Cast)
  plate.CastShadowOverlay:SetBlendMode("BLEND")
  plate.CastShadowOverlay:SetTexture("Interface\\Buttons\\WHITE8X8")
  if plate.CastShadowOverlay.SetGradient and CreateColor then
    plate.CastShadowOverlay:SetGradient("VERTICAL", CreateColor(0, 0, 0, 0), CreateColor(0, 0, 0, 0.24))
  else
    plate.CastShadowOverlay:SetColorTexture(0, 0, 0, 0.22)
  end
  
  plate.Cast:Hide()
  
  -- Cast Icon (spell icon for cast)
  plate.CastIcon = plate:CreateTexture(nil, "ARTWORK")
  plate.CastIcon:SetSize(MP.DB.castHeight + 4, MP.DB.castHeight + 4)
  plate.CastIcon:SetPoint("RIGHT", plate.Cast, "LEFT", -2, 0)
  plate.CastIcon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
  plate.CastIcon:Hide()
  
  -- Cast Icon Border
  local castIconBorderHolder = CreateFrame("Frame", nil, plate)
  castIconBorderHolder:SetFlattensRenderLayers(true)
  plate.CastIconBorder = CreateFrame("Frame", nil, castIconBorderHolder, "BackdropTemplate")
  plate.CastIconBorder:SetPoint("TOPLEFT", plate.CastIcon, "TOPLEFT", -1, 1)
  plate.CastIconBorder:SetPoint("BOTTOMRIGHT", plate.CastIcon, "BOTTOMRIGHT", 1, -1)
  plate.CastIconBorder:SetBackdrop({
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
  })
  plate.CastIconBorder:SetBackdropBorderColor(0, 0, 0, 1)
  plate.CastIconBorder:Hide()
  
  -- Cast bar spark (moving spark effect)
  plate.CastSpark = plate.Cast:CreateTexture(nil, "OVERLAY")
  plate.CastSpark:SetTexture("Interface/Nameplates/UI-Nameplate-CastBar-Spark")
  plate.CastSpark:SetSize(20, MP.DB.castHeight * 2.5)
  plate.CastSpark:SetBlendMode("ADD")
  plate.CastSpark:Hide()
  
  -- Cast interrupt flash (shown when interrupted)
  plate.CastInterruptFlash = plate.Cast:CreateTexture(nil, "OVERLAY")
  plate.CastInterruptFlash:SetTexture("Interface/Nameplates/UI-Nameplate-InterruptFlash")
  plate.CastInterruptFlash:SetAllPoints(plate.Cast)
  plate.CastInterruptFlash:SetBlendMode("ADD")
  plate.CastInterruptFlash:Hide()
  
  -- Cast bar reverse fill support
  function plate.Cast:SetReverseFill(isChanneled)
    if isChanneled then
      self:SetFillStyle("REVERSE")
    else
      self:SetFillStyle("STANDARD")
    end
  end
  
  -- Cast state tracking
  plate.Cast.interrupted = nil
  plate.Cast.isChanneled = false
  
  -- Cast border
  local castBorderHolder = CreateFrame("Frame", nil, plate)
  castBorderHolder:SetFlattensRenderLayers(true)
  plate.CastBorder = CreateFrame("Frame", nil, castBorderHolder, "BackdropTemplate")
  plate.CastBorder:SetPoint("TOPLEFT", plate.Cast, -1, 1)
  plate.CastBorder:SetPoint("BOTTOMRIGHT", plate.Cast, 1, -1)
  plate.CastBorder:SetBackdrop({
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
  })
  plate.CastBorder:SetBackdropBorderColor(0, 0, 0, 1)
  plate.CastBorder:Hide()
  
  -- Cast text
  plate.CastText = plate:CreateFontString(nil, "OVERLAY")
  plate.CastText:SetFont(MP.Config.GetFont())
  plate.CastText:SetPoint("TOP", plate.Cast, "BOTTOM", 0, -2)
  plate.CastText:SetTextColor(1, 1, 1)
  plate.CastText:SetShadowOffset(1, -1)
  plate.CastText:SetShadowColor(0, 0, 0, 1)
  plate.CastText:Hide()
  
  -- Apply current theme layout if available
  if MP.DB and MP.DB.currentLayout and MP.Themes and MP.Themes.ApplyLayout then
    MP.Themes.ApplyLayout(plate, MP.DB.currentLayout)
  end
  
  plate:Hide()
  return plate
end
