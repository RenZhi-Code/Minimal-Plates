---@class MinimalPlates
local MP = MinimalPlates

MP.Display = MP.Display or {}
MP.Display.CastBar = {}

-- Start cast bar animation
function MP.Display.CastBar.Start(plate, unit, isChanneled)
  if not MP.DB.showCastBar then return end
  
  local name, _, texture, startTime, endTime, _, _, notInterruptible
  if isChanneled then
    name, _, texture, startTime, endTime, _, notInterruptible = UnitChannelInfo(unit)
  else
    name, _, texture, startTime, endTime, _, _, notInterruptible = UnitCastingInfo(unit)
  end
  
  if not name then return end
  
  -- Store cast state (wrap arithmetic in pcall for Midnight secret values)
  local success = pcall(function()
    plate.Cast.startTime = startTime / 1000
    plate.Cast.endTime = endTime / 1000
  end)
  
  if not success then
    -- Secret values prevent arithmetic; hide cast bar
    plate.Cast:Hide()
    plate.CastBorder:Hide()
    plate.CastText:Hide()
    return
  end
  
  plate.Cast.isChanneled = isChanneled
  plate.Cast.interrupted = nil
  plate.Cast.notInterruptible = notInterruptible
  
  -- Set reverse fill for channels
  plate.Cast:SetReverseFill(isChanneled)
  
  -- Set initial value (safe, already computed in pcall)
  local duration = plate.Cast.endTime - plate.Cast.startTime
  plate.Cast:SetMinMaxValues(0, duration)
  
  -- Color based on interruptibility
  if notInterruptible then
    local color = MP.DB.nonInterruptibleCastColor or {r = 0.5, g = 0.5, b = 0.5}
    plate.Cast:GetStatusBarTexture():SetVertexColor(color.r, color.g, color.b)
  else
    local color = MP.DB.interruptibleCastColor or {r = 1, g = 0.7, b = 0}
    plate.Cast:GetStatusBarTexture():SetVertexColor(color.r, color.g, color.b)
  end
  
  -- Sync overlays to cast color
  if plate.CastHighlightOverlay and plate.CastShadowOverlay then
    local ok, cr, cg, cb = pcall(function() return plate.Cast:GetStatusBarTexture():GetVertexColor() end)
    if ok and cr then
      if plate.CastHighlightOverlay.SetGradient and CreateColor then
        plate.CastHighlightOverlay:SetGradient("VERTICAL", CreateColor(cr, cg, cb, 0.18), CreateColor(cr, cg, cb, 0))
      else
        plate.CastHighlightOverlay:SetColorTexture(cr, cg, cb, 0.14)
      end
      if plate.CastShadowOverlay.SetGradient and CreateColor then
        plate.CastShadowOverlay:SetGradient("VERTICAL", CreateColor(cr*0.2, cg*0.2, cb*0.2, 0), CreateColor(cr*0.2, cg*0.2, cb*0.2, 0.18))
      else
        plate.CastShadowOverlay:SetColorTexture(cr*0.2, cg*0.2, cb*0.2, 0.16)
      end
    end
  end
  
  -- Show cast bar
  plate.Cast:Show()
  plate.CastBorder:Show()
  plate.CastText:SetText(name)
  plate.CastText:Show()
  -- Position cast text by DB
  plate.CastText:ClearAllPoints()
  do
    local pos = MP.DB.castTextPosition or "bottom"
    local ox = MP.DB.castTextOffsetX or 0
    local oy = MP.DB.castTextOffsetY or 0
    if pos == "none" then
      plate.CastText:Hide()
    elseif pos == "top" then
      plate.CastText:SetPoint("BOTTOM", plate.Cast, "TOP", ox, 2 + oy)
    elseif pos == "left" then
      plate.CastText:SetPoint("RIGHT", plate.Cast, "LEFT", -2 + ox, oy)
    elseif pos == "right" then
      plate.CastText:SetPoint("LEFT", plate.Cast, "RIGHT", 2 + ox, oy)
    else
      plate.CastText:SetPoint("TOP", plate.Cast, "BOTTOM", ox, -2 + oy)
    end
    plate.CastText:SetScale(MP.DB.castTextScale or 1.0)
    plate.CastText:Show()
  end
  
  -- Show cast icon
  if MP.DB.showCastIcon and texture then
    plate.CastIcon:SetTexture(texture)
    plate.CastIcon:Show()
    if plate.CastIconBorder then plate.CastIconBorder:Show() end
    -- Position cast icon by DB
    plate.CastIcon:ClearAllPoints()
    local pos = MP.DB.castIconPosition or "left"
    local ox = MP.DB.castIconOffsetX or 0
    local oy = MP.DB.castIconOffsetY or 0
    if pos == "none" then
      plate.CastIcon:Hide()
      if plate.CastIconBorder then plate.CastIconBorder:Hide() end
    elseif pos == "top" then
      plate.CastIcon:SetPoint("BOTTOM", plate.Cast, "TOP", ox, 2 + oy)
    elseif pos == "left" then
      plate.CastIcon:SetPoint("RIGHT", plate.Cast, "LEFT", -2 + ox, oy)
    elseif pos == "right" then
      plate.CastIcon:SetPoint("LEFT", plate.Cast, "RIGHT", 2 + ox, oy)
    else
      plate.CastIcon:SetPoint("TOP", plate.Cast, "BOTTOM", ox, -2 + oy)
    end
    plate.CastIcon:SetScale(MP.DB.castIconScale or 1.0)
  else
    plate.CastIcon:Hide()
    if plate.CastIconBorder then plate.CastIconBorder:Hide() end
  end
  
  -- Interrupt shield indicator (REMOVED - Memory optimization)
  -- InterruptShield frame removed in FrameCreation.lua for memory savings
  -- This was a niche feature with limited use cases
  
  -- Cast target
  if MP.DB.showCastTarget then
    local targetUnit = unit .. "target"
    if UnitExists(targetUnit) then
      local targetName = UnitName(targetUnit)
      plate.CastTargetText:SetText("→ " .. (targetName or ""))
      plate.CastTargetText:ClearAllPoints()
      local pos = MP.DB.castTargetPosition or "right"
      local ox = MP.DB.castTargetOffsetX or 0
      local oy = MP.DB.castTargetOffsetY or 0
      if pos == "none" then
        plate.CastTargetText:Hide()
      elseif pos == "top" then
        plate.CastTargetText:SetPoint("BOTTOM", plate.Health, "TOP", ox, 2 + oy)
        plate.CastTargetText:SetScale(MP.DB.castTargetScale or 1.0)
        plate.CastTargetText:Show()
      elseif pos == "left" then
        plate.CastTargetText:SetPoint("RIGHT", plate.Health, "LEFT", -2 + ox, oy)
        plate.CastTargetText:SetScale(MP.DB.castTargetScale or 1.0)
        plate.CastTargetText:Show()
      elseif pos == "right" then
        plate.CastTargetText:SetPoint("LEFT", plate.Health, "RIGHT", 2 + ox, oy)
        plate.CastTargetText:SetScale(MP.DB.castTargetScale or 1.0)
        plate.CastTargetText:Show()
      else
        plate.CastTargetText:SetPoint("TOP", plate.Health, "BOTTOM", ox, -2 + oy)
        plate.CastTargetText:SetScale(MP.DB.castTargetScale or 1.0)
        plate.CastTargetText:Show()
      end
    else
      plate.CastTargetText:Hide()
    end
  else
    plate.CastTargetText:Hide()
  end
  
  -- ===== RENDER OPTIMIZATION: Conditional OnUpdate =====
  -- OnUpdate only runs while actively casting, not 24/7
  -- This prevents unnecessary frame updates when not needed
  plate.Cast:SetScript("OnUpdate", function(self)
    if self.interrupted then return end
    
    -- Wrap arithmetic in pcall for Midnight secret values
    local success = pcall(function()
      local currentTime = GetTime()
      local elapsed = currentTime - self.startTime
      local duration = self.endTime - self.startTime
      
      if self.isChanneled then
        -- Channels count down
        local remaining = self.endTime - currentTime
        self:SetValue(math.max(0, remaining))
      else
        -- Casts count up
        self:SetValue(math.min(duration, elapsed))
      end
    end)
    
    if not success then
      -- Secret value arithmetic failed; stop updates
      self:SetScript("OnUpdate", nil)
      return
    end
    
    -- Update cast bar spark position
    if MP.DB.showCastSpark and plate.CastSpark then
      local _, maxValue = self:GetMinMaxValues()
      local progress = self:GetValue() / (maxValue or 1)
      local sparkPosition = (self:GetWidth() * progress) - (plate.CastSpark:GetWidth() / 2)
      plate.CastSpark:SetPoint("LEFT", self, "LEFT", sparkPosition, 0)
      plate.CastSpark:Show()
    end
  end)
  
  -- Show cast spark at start
  if MP.DB.showCastSpark and plate.CastSpark then
    plate.CastSpark:Show()
  end
end

-- Stop cast bar
function MP.Display.CastBar.Stop(plate, unit, interrupted)
  if interrupted then
    -- Show interrupted state for 0.8 seconds
    plate.Cast.interrupted = true
    plate.Cast:GetStatusBarTexture():SetVertexColor(1, 0, 0) -- Red for interrupted
    plate.CastText:SetText("INTERRUPTED")
    
    -- Show interrupt flash
    if MP.DB.showInterruptFlash and plate.CastInterruptFlash then
      plate.CastInterruptFlash:Show()
      -- Store reference to prevent closure from holding entire plate object
      local flashRef = plate.CastInterruptFlash
      C_Timer.After(0.3, function()
        if flashRef and flashRef:IsVisible() then
          flashRef:Hide()
        end
      end)
    end
    
    -- Hide cast spark
    if plate.CastSpark then
      plate.CastSpark:Hide()
    end
    
    -- ===== RENDER OPTIMIZATION: Stop OnUpdate when not casting =====
    -- Prevents wasted CPU cycles on hidden cast bars
    plate.Cast:SetScript("OnUpdate", nil)
    
    -- Timer to hide after 0.8s (store references to prevent closure memory leak)
    local castRef = plate.Cast
    local borderRef = plate.CastBorder
    local textRef = plate.CastText
    local iconRef = plate.CastIcon
    local iconBorderRef = plate.CastIconBorder
    local shieldRef = plate.InterruptShield
    local targetTextRef = plate.CastTargetText

    C_Timer.After(0.8, function()
      if castRef and castRef.interrupted then
        castRef.interrupted = nil
        if castRef:IsVisible() then castRef:Hide() end
        if borderRef then borderRef:Hide() end
        if textRef then textRef:Hide() end
        if iconRef then iconRef:Hide() end
        if iconBorderRef then iconBorderRef:Hide() end
        if shieldRef then shieldRef:Hide() end
        if targetTextRef then targetTextRef:Hide() end
      end
    end)
  else
    -- Normal completion, hide immediately
    plate.Cast:Hide()
    plate.CastBorder:Hide()
    plate.CastText:Hide()
    plate.CastIcon:Hide()
    if plate.CastIconBorder then plate.CastIconBorder:Hide() end
    -- InterruptShield removed for memory optimization
    plate.CastTargetText:Hide()
    if plate.CastSpark then plate.CastSpark:Hide() end
    if plate.CastInterruptFlash then plate.CastInterruptFlash:Hide() end
    
    -- ===== RENDER OPTIMIZATION: Stop OnUpdate when cast completes =====
    plate.Cast:SetScript("OnUpdate", nil)
    plate.Cast.interrupted = nil
  end
end

-- Update cast interruptibility dynamically
function MP.Display.CastBar.UpdateInterruptible(plate, unit)
  if not plate.Cast:IsShown() then return end
  
  local notInterruptible
  if plate.Cast.isChanneled then
    local _, _, _, _, _, _, ni = UnitChannelInfo(unit)
    notInterruptible = ni
  else
    local _, _, _, _, _, _, _, ni = UnitCastingInfo(unit)
    notInterruptible = ni
  end
  
  plate.Cast.notInterruptible = notInterruptible
  
  -- Update color dynamically
  if not plate.Cast.interrupted then
    if notInterruptible then
      local color = MP.DB.nonInterruptibleCastColor or {r = 0.5, g = 0.5, b = 0.5}
      plate.Cast:GetStatusBarTexture():SetVertexColor(color.r, color.g, color.b)
    else
      local color = MP.DB.interruptibleCastColor or {r = 1, g = 0.7, b = 0}
      plate.Cast:GetStatusBarTexture():SetVertexColor(color.r, color.g, color.b)
    end
    -- Sync overlays to cast color
    if plate.CastHighlightOverlay and plate.CastShadowOverlay then
      local ok, cr, cg, cb = pcall(function() return plate.Cast:GetStatusBarTexture():GetVertexColor() end)
      if ok and cr then
        if plate.CastHighlightOverlay.SetGradient and CreateColor then
          plate.CastHighlightOverlay:SetGradient("VERTICAL", CreateColor(cr, cg, cb, 0.18), CreateColor(cr, cg, cb, 0))
        else
          plate.CastHighlightOverlay:SetColorTexture(cr, cg, cb, 0.14)
        end
        if plate.CastShadowOverlay.SetGradient and CreateColor then
          plate.CastShadowOverlay:SetGradient("VERTICAL", CreateColor(cr*0.2, cg*0.2, cb*0.2, 0), CreateColor(cr*0.2, cg*0.2, cb*0.2, 0.18))
        else
          plate.CastShadowOverlay:SetColorTexture(cr*0.2, cg*0.2, cb*0.2, 0.16)
        end
      end
    end
    -- Sync overlays to cast color
    if plate.CastHighlightOverlay and plate.CastShadowOverlay then
      local ok, cr, cg, cb = pcall(function() return plate.Cast:GetStatusBarTexture():GetVertexColor() end)
      if ok and cr then
        plate.CastHighlightOverlay:SetGradientAlpha("VERTICAL", cr, cg, cb, 0.18, cr, cg, cb, 0)
        plate.CastShadowOverlay:SetGradientAlpha("VERTICAL", cr*0.2, cg*0.2, cb*0.2, 0, cr*0.2, cg*0.2, cb*0.2, 0.18)
      end
    end
  end

  -- Update interrupt shield (REMOVED - Memory optimization)
  -- InterruptShield frame removed in FrameCreation.lua for memory savings
end
