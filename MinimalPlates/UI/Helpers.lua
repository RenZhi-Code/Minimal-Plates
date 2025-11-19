---@class MinimalPlates
local MP = MinimalPlates

MP.UIHelpers = {}

-- Localize globals for performance
local CreateFrame = CreateFrame
local GameTooltip = GameTooltip
local ColorPickerFrame = ColorPickerFrame
local pairs, ipairs = pairs, ipairs
local tostring, tonumber = tostring, tonumber
local string_format = string.format

-- Dropdown API compatibility (handles both old and new WoW APIs)
local UIDropDownMenu_SetWidth = UIDropDownMenu_SetWidth or (function() end)
local UIDropDownMenu_Initialize = UIDropDownMenu_Initialize or (function() end)
local UIDropDownMenu_CreateInfo = UIDropDownMenu_CreateInfo or (function() return {} end)
local UIDropDownMenu_AddButton = UIDropDownMenu_AddButton or (function() end)
local UIDropDownMenu_SetText = UIDropDownMenu_SetText or (function() end)
local hasLegacyDropdowns = (UIDropDownMenu_SetWidth ~= nil)

-- Layout constants
local LAYOUT = {
  TAB_WIDTH = 80,  -- Reduced from 92 to fit 6 tabs
  TAB_SPACING = 88,
  LEFT_COLUMN_X = 20,
  RIGHT_COLUMN_X = 400,
  DROPDOWN_WIDTH = 150,
  SLIDER_WIDTH = 200,
  SECTION_SPACING = 20,  -- Increased from 15 for better section separation
  OPTION_SPACING = 40,   -- Increased from 30 for better spacing between options
  HEADER_SPACING = 35,   -- Increased from 30 for more space after headers
}

-- Throttle mechanism for RefreshAll() calls
local refreshThrottle = {
  timer = nil,
  delay = 0.05  -- 50ms throttle (20 updates/sec max)
}

local function ThrottledRefresh()
  if refreshThrottle.timer then
    refreshThrottle.timer:Cancel()
  end

  refreshThrottle.timer = C_Timer.NewTimer(refreshThrottle.delay, function()
    -- Refresh DB cache before updating nameplates (15-25% CPU reduction)
    if MP.Display and MP.Display.UpdateLogic and MP.Display.UpdateLogic.RefreshDBCache then
      MP.Display.UpdateLogic.RefreshDBCache()
    end
    
    if MP.Nameplates and MP.Nameplates.RefreshAll then
      MP.Nameplates.RefreshAll()
    end
    -- Also refresh preview if it's visible
    if MP.Preview and MP.Preview.Refresh then
      MP.Preview.Refresh()
    end
    -- Refresh settings UI preview if visible
    if MP.Settings and MP.Settings.RefreshPreview then
      MP.Settings.RefreshPreview()
    end
    refreshThrottle.timer = nil
  end)
end

-- Initialize cache when Helpers module loads (after DB is ready)
if MP.DB and MP.Display and MP.Display.UpdateLogic and MP.Display.UpdateLogic.RefreshDBCache then
  MP.Display.UpdateLogic.RefreshDBCache()
end

-- CVar helper functions
local function SetCVarBool(name, val)
  if C_CVar and C_CVar.SetCVar then
    C_CVar.SetCVar(name, val and "1" or "0")
  elseif SetCVar then
    SetCVar(name, val and "1" or "0")
  end
end

local function SetCVarNumber(name, val)
  if C_CVar and C_CVar.SetCVar then
    C_CVar.SetCVar(name, tostring(val))
  elseif SetCVar then
    SetCVar(name, tostring(val))
  end
end

-- Create a section header
function MP.UIHelpers.CreateHeader(parent, text, x, y)
  local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  header:SetPoint("TOPLEFT", x or LAYOUT.LEFT_COLUMN_X, y)
  header:SetText(text)
  header:SetTextColor(1, 0.82, 0) -- Gold color
  return header
end

-- Create a checkbox with tooltip support
function MP.UIHelpers.CreateCheckbox(parent, label, dbKey, x, y, callback, tooltip)
  local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
  cb:SetPoint("TOPLEFT", x or LAYOUT.LEFT_COLUMN_X, y)
  cb.text = cb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  cb.text:SetPoint("LEFT", cb, "RIGHT", 5, 0)
  cb.text:SetText(label)
  cb:SetChecked(MP.DB[dbKey])

  cb:SetScript("OnClick", function(self)
    MP.DB[dbKey] = self:GetChecked()
    ThrottledRefresh()
    if callback then callback(self:GetChecked()) end
  end)

  -- Tooltip support
  if tooltip then
    cb:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetText(label, 1, 1, 1)
      GameTooltip:AddLine(tooltip, nil, nil, nil, true)
      GameTooltip:Show()
    end)
    cb:SetScript("OnLeave", function(self)
      GameTooltip:Hide()
    end)
  end

  return cb
end

-- Create a slider with tooltip support
function MP.UIHelpers.CreateSlider(parent, label, dbKey, min, max, step, x, y, callback, tooltip, format)
  local slider = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
  slider:SetPoint("TOPLEFT", x or LAYOUT.LEFT_COLUMN_X, y)
  slider:SetWidth(LAYOUT.SLIDER_WIDTH)
  slider:SetMinMaxValues(min, max)
  slider:SetValueStep(step)
  slider:SetValue(MP.DB[dbKey] or min)
  slider:SetObeyStepOnDrag(true)

  slider.Text:SetText(label)
  slider.Low:SetText(tostring(min))
  slider.High:SetText(tostring(max))

  slider.Value = slider:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  slider.Value:SetPoint("TOP", slider, "BOTTOM", 0, 0)

  local formatFunc = format or function(val) return string.format("%.1f", val) end
  slider.Value:SetText(formatFunc(slider:GetValue()))

  slider:SetScript("OnValueChanged", function(self, value)
    self.Value:SetText(formatFunc(value))
    MP.DB[dbKey] = value
    ThrottledRefresh()
    if callback then callback(value) end
  end)

  -- Tooltip support
  if tooltip then
    slider:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetText(label, 1, 1, 1)
      GameTooltip:AddLine(tooltip, nil, nil, nil, true)
      GameTooltip:Show()
    end)
    slider:SetScript("OnLeave", function(self)
      GameTooltip:Hide()
    end)
  end

  return slider
end

-- Create a dropdown menu (compatible with both old and new WoW APIs)
function MP.UIHelpers.CreateDropdown(parent, label, dbKey, options, x, y, width, callback, tooltip)
  local container = CreateFrame("Frame", nil, parent)
  local labelText = nil
  local dropdown

  if label then
    labelText = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    labelText:SetPoint("TOPLEFT", x or LAYOUT.LEFT_COLUMN_X, y)
    labelText:SetText(label)
  end

  -- Simple button-based dropdown for modern WoW (Midnight/TWW+)
  dropdown = CreateFrame("Button", nil, container, "UIPanelButtonTemplate")
  dropdown:SetSize(width or LAYOUT.DROPDOWN_WIDTH, 22)

  if label then
    dropdown:SetPoint("TOPLEFT", x or LAYOUT.LEFT_COLUMN_X, y - 20)
    container:SetSize(width or LAYOUT.DROPDOWN_WIDTH, 42)
  else
    dropdown:SetPoint("TOPLEFT", x or LAYOUT.LEFT_COLUMN_X, y)
    container:SetSize(width or LAYOUT.DROPDOWN_WIDTH, 22)
  end

  container:SetPoint("TOPLEFT", 0, 0)

  local function setTextByValue(value)
    for _, opt in ipairs(options) do
      if opt.value == value then
        dropdown:SetText(opt.text)
        return
      end
    end
  end

  -- Create a simple menu on click
  dropdown:SetScript("OnClick", function(self)
    if not self.menu then
      self.menu = CreateFrame("Frame", nil, self, "BackdropTemplate")
      self.menu:SetFrameStrata("DIALOG")
      self.menu:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
      })
      self.menu:SetBackdropColor(0, 0, 0, 0.95)
      self.menu:SetPoint("TOP", self, "BOTTOM", 0, -2)
      self.menu:SetWidth(self:GetWidth())
      self.menu:Hide()

      local buttons = {}
      for i, opt in ipairs(options) do
        local btn = CreateFrame("Button", nil, self.menu)
        btn:SetSize(self:GetWidth() - 8, 20)
        btn:SetPoint("TOP", 0, -4 - (i-1) * 20)
        btn:SetNormalFontObject("GameFontNormal")
        btn:SetHighlightFontObject("GameFontHighlight")
        btn:SetText(opt.text)

        btn:SetScript("OnClick", function()
          MP.DB[dbKey] = opt.value
          setTextByValue(opt.value)
          ThrottledRefresh()
          if callback then callback(opt.value) end
          self.menu:Hide()
        end)

        btn:SetScript("OnEnter", function(b)
          b:SetAlpha(0.8)
        end)
        btn:SetScript("OnLeave", function(b)
          b:SetAlpha(1.0)
        end)

        table.insert(buttons, btn)
      end

      self.menu:SetHeight(8 + #options * 20)
    end

    if self.menu:IsShown() then
      self.menu:Hide()
    else
      self.menu:Show()
    end
  end)

  setTextByValue(MP.DB[dbKey])

  -- Tooltip support
  if tooltip and dropdown then
    dropdown:SetScript("OnEnter", function()
      GameTooltip:SetOwner(dropdown, "ANCHOR_RIGHT")
      GameTooltip:SetText(label or "Option", 1, 1, 1)
      GameTooltip:AddLine(tooltip, nil, nil, nil, true)
      GameTooltip:Show()
    end)
    dropdown:SetScript("OnLeave", function()
      GameTooltip:Hide()
    end)
  end

  return container, labelText
end

-- Create a position control (dropdown + offset + scale)
function MP.UIHelpers.CreatePositionControl(parent, label, posKey, offsetKey, scaleKey, x, y, tooltip, offsetXKey)
  local container = CreateFrame("Frame", nil, parent)
  container:SetPoint("TOPLEFT", x or LAYOUT.LEFT_COLUMN_X, y)
  container:SetSize(320, 80)

  -- Label
  local labelText = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  labelText:SetPoint("TOPLEFT", 0, 0)
  labelText:SetText(label)

  -- Position dropdown (button-based with red/yellow styling)
  local posDD = CreateFrame("Button", nil, container, "UIPanelButtonTemplate")
  posDD:SetPoint("TOPLEFT", 0, -18)
  posDD:SetSize(80, 22)

  local posOptions = {
    {text="Top", value="top"},
    {text="Middle", value="middle"},
    {text="Left", value="left"},
    {text="Right", value="right"},
    {text="Bottom", value="bottom"},
    {text="Hide", value="none"}
  }

  local function setTextByValue(value)
    local map = { top = "Top", middle = "Middle", left = "Left", right = "Right", bottom = "Bottom", none = "Hide" }
    posDD:SetText(map[value] or "Top")
  end

  -- Create dropdown menu
  posDD:SetScript("OnClick", function(self)
    if not self.menu then
      self.menu = CreateFrame("Frame", nil, self, "BackdropTemplate")
      self.menu:SetFrameStrata("DIALOG")
      self.menu:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
      })
      self.menu:SetBackdropColor(0, 0, 0, 0.95)
      self.menu:SetPoint("TOP", self, "BOTTOM", 0, -2)
      self.menu:SetWidth(self:GetWidth())
      self.menu:Hide()

      local buttons = {}
      for i, opt in ipairs(posOptions) do
        local btn = CreateFrame("Button", nil, self.menu)
        btn:SetSize(self:GetWidth() - 8, 20)
        btn:SetPoint("TOP", 0, -4 - (i-1) * 20)
        btn:SetNormalFontObject("GameFontNormal")
        btn:SetHighlightFontObject("GameFontHighlight")
        btn:SetText(opt.text)

        btn:SetScript("OnClick", function()
          MP.DB[posKey] = opt.value
          setTextByValue(opt.value)
          ThrottledRefresh()
          self.menu:Hide()
        end)

        btn:SetScript("OnEnter", function(b)
          b:SetAlpha(0.8)
        end)
        btn:SetScript("OnLeave", function(b)
          b:SetAlpha(1.0)
        end)

        table.insert(buttons, btn)
      end

      self.menu:SetHeight(8 + #posOptions * 20)
    end

    if self.menu:IsShown() then
      self.menu:Hide()
    else
      self.menu:Show()
    end
  end)

  setTextByValue(MP.DB[posKey] or "top")

  -- Offset slider (compact width for cleaner layout, more spacing from dropdown)
  local offsetSlider = CreateFrame("Slider", nil, container, "OptionsSliderTemplate")
  offsetSlider:SetPoint("TOPLEFT", 125, -18)
  offsetSlider:SetWidth(70)
  offsetSlider:SetMinMaxValues(-30, 30)
  offsetSlider:SetValueStep(1)
  offsetSlider:SetValue(MP.DB[offsetKey] or 0)
  offsetSlider.Text:SetText("Height")
  offsetSlider.Low:SetText("-30")
  offsetSlider.High:SetText("30")
  offsetSlider:SetScript("OnValueChanged", function(self, value)
    MP.DB[offsetKey] = value
    ThrottledRefresh()
  end)

  -- Scale slider (compact width for cleaner layout)
  local scaleSlider = CreateFrame("Slider", nil, container, "OptionsSliderTemplate")
  scaleSlider:SetPoint("TOPLEFT", 220, -18)
  scaleSlider:SetWidth(70)
  scaleSlider:SetMinMaxValues(0.5, 2.0)
  scaleSlider:SetValueStep(0.1)
  scaleSlider:SetValue(MP.DB[scaleKey] or 1.0)
  scaleSlider.Text:SetText("Scale")
  scaleSlider.Low:SetText("0.5")
  scaleSlider.High:SetText("2.0")
  scaleSlider:SetScript("OnValueChanged", function(self, value)
    MP.DB[scaleKey] = value
    ThrottledRefresh()
  end)

  -- Optional X offset slider (placed on second row for spacing)
  if offsetXKey then
    local xSlider = CreateFrame("Slider", nil, container, "OptionsSliderTemplate")
    xSlider:SetPoint("TOPLEFT", 125, -45)
    xSlider:SetWidth(70)
    xSlider:SetMinMaxValues(-30, 30)
    xSlider:SetValueStep(1)
    xSlider:SetValue(MP.DB[offsetXKey] or 0)
    xSlider.Text:SetText("Left/Right")
    xSlider.Low:SetText("-30")
    xSlider.High:SetText("30")
    xSlider:SetScript("OnValueChanged", function(self, value)
      MP.DB[offsetXKey] = value
      ThrottledRefresh()
    end)
  end

  -- Tooltip
  if tooltip then
    labelText:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetText(label, 1, 1, 1)
      GameTooltip:AddLine(tooltip, nil, nil, nil, true)
      GameTooltip:Show()
    end)
    labelText:SetScript("OnLeave", function(self)
      GameTooltip:Hide()
    end)
  end

  return container
end

-- Create a color picker button
function MP.UIHelpers.CreateColorPicker(parent, label, dbKey, x, y, tooltip)
  local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  button:SetSize(140, 25)
  button:SetPoint("TOPLEFT", x or LAYOUT.LEFT_COLUMN_X, y)
  button:SetText(label)

  -- Make button text white for readability
  local buttonText = button:GetFontString()
  if buttonText then
    buttonText:SetTextColor(1, 1, 1)  -- White text
  end

  -- Color swatch preview
  local swatch = button:CreateTexture(nil, "OVERLAY")
  swatch:SetSize(16, 16)
  swatch:SetPoint("LEFT", button, "LEFT", 5, 0)

  local function updateSwatch()
    if MP.DB[dbKey] then
      swatch:SetColorTexture(MP.DB[dbKey].r, MP.DB[dbKey].g, MP.DB[dbKey].b)
    end
  end
  updateSwatch()

  button:SetScript("OnClick", function()
    ColorPickerFrame:SetupColorPickerAndShow({
      r = MP.DB[dbKey].r,
      g = MP.DB[dbKey].g,
      b = MP.DB[dbKey].b,
      swatchFunc = function()
        local r, g, b = ColorPickerFrame:GetColorRGB()
        MP.DB[dbKey].r = r
        MP.DB[dbKey].g = g
        MP.DB[dbKey].b = b
        updateSwatch()
        ThrottledRefresh()
      end,
      cancelFunc = function(previousValues)
        MP.DB[dbKey].r = previousValues.r
        MP.DB[dbKey].g = previousValues.g
        MP.DB[dbKey].b = previousValues.b
        updateSwatch()
        ThrottledRefresh()
      end
    })
  end)

  -- Tooltip
  if tooltip then
    button:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetText(label, 1, 1, 1)
      GameTooltip:AddLine(tooltip, nil, nil, nil, true)
      GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function(self)
      GameTooltip:Hide()
    end)
  end

  return button
end

-- Create a collapsible section
function MP.UIHelpers.CreateCollapsibleSection(parent, title, x, y, initiallyExpanded)
  local section = CreateFrame("Frame", nil, parent)
  section:SetPoint("TOPLEFT", x or LAYOUT.LEFT_COLUMN_X, y)
  section:SetSize(340, 25)

  local isExpanded = initiallyExpanded ~= false

  -- Header button
  local header = CreateFrame("Button", nil, section)
  header:SetSize(340, 20)
  header:SetPoint("TOPLEFT", 0, 0)

  local icon = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  icon:SetPoint("LEFT", 0, 0)
  icon:SetText(isExpanded and "[-]" or "[+]")

  local text = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  text:SetPoint("LEFT", icon, "RIGHT", 5, 0)
  text:SetText(title)
  text:SetTextColor(1, 0.82, 0)

  -- Content container
  local content = CreateFrame("Frame", nil, section)
  content:SetPoint("TOPLEFT", 0, -25)
  content:SetSize(340, 1)
  content:SetShown(isExpanded)

  header:SetScript("OnClick", function()
    isExpanded = not isExpanded
    icon:SetText(isExpanded and "[-]" or "[+]")
    content:SetShown(isExpanded)
  end)

  section.content = content
  section.header = header

  return section
end

-- Create CVar checkbox (mirrors Blizzard CVar)
function MP.UIHelpers.CreateCVarCheckbox(parent, label, dbKey, cvarName, x, y, tooltip)
  return MP.UIHelpers.CreateCheckbox(parent, label, dbKey, x, y, function(checked)
    SetCVarBool(cvarName, checked)
  end, tooltip)
end

-- Create CVar slider (mirrors Blizzard CVar)
function MP.UIHelpers.CreateCVarSlider(parent, label, dbKey, cvarName, min, max, step, x, y, tooltip, format)
  return MP.UIHelpers.CreateSlider(parent, label, dbKey, min, max, step, x, y, function(value)
    SetCVarNumber(cvarName, value)
  end, tooltip, format)
end

-- Constants
MP.UIHelpers.LAYOUT = LAYOUT
