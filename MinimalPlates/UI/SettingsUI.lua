---@class MinimalPlates
local MP = MinimalPlates
local H = MP.UIHelpers

-- Safety check: Ensure UIHelpers is loaded
if not H then
  error("MinimalPlates: UIHelpers not loaded! Check TOC file order.")
  return
end

local L = H.LAYOUT
if not L then
  error("MinimalPlates: UIHelpers.LAYOUT not found!")
  return
end

-- Localize globals for performance
local CreateFrame = CreateFrame
local UIDropDownMenu_SetWidth = UIDropDownMenu_SetWidth
local UIDropDownMenu_Initialize = UIDropDownMenu_Initialize
local UIDropDownMenu_CreateInfo = UIDropDownMenu_CreateInfo
local UIDropDownMenu_AddButton = UIDropDownMenu_AddButton
local UIDropDownMenu_SetText = UIDropDownMenu_SetText
local StaticPopup_Show = StaticPopup_Show
local pairs, ipairs = pairs, ipairs

-- Common dropdown options (defined once for reuse)
local DROPDOWN_OPTIONS = {
  DisplayMode = {
    {text="Bar", value="bar"},
    {text="Text Only", value="text"},
    {text="Hide", value="hide"}
  },
  Position = {
    {text="Top", value="top"},
    {text="Middle", value="middle"},
    {text="Left", value="left"},
    {text="Right", value="right"},
    {text="Bottom", value="bottom"},
    {text="Hide", value="none"}
  },
  HealthTextFormat = {
    {text="Percentage", value="percentage"},
    {text="Absolute", value="absolute"},
    {text="Both", value="both"}
  },
  EliteIconStyle = {
    {text="Icon + Text", value="both"},
    {text="Icon Only", value="icon"},
    {text="Text Only", value="text"},
    {text="None", value="none"}
  },
  FontOutline = {
    {text="None", value="NONE"},
    {text="Outline", value="OUTLINE"},
    {text="Thick Outline", value="THICKOUTLINE"},
    {text="Monochrome", value="MONOCHROME"},
    {text="Outline + Monochrome", value="OUTLINE,MONOCHROME"},
    {text="Thick Outline + Monochrome", value="THICKOUTLINE,MONOCHROME"}
  }
}

-- Create standalone settings window
local SettingsFrame = nil

-- Static Popup Dialogs for Profile Management
StaticPopupDialogs["MP_NEW_PROFILE"] = {
  text = "Enter new profile name:",
  button1 = "Create",
  button2 = "Cancel",
  hasEditBox = true,
  OnAccept = function(self)
    local name = self.EditBox:GetText()
    if MP.Profiles.CreateProfile(name, true) then
      if SettingsFrame then SettingsFrame:Hide() end
      MP.Settings.CreateStandaloneUI()
    end
  end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

StaticPopupDialogs["MP_COPY_PROFILE"] = {
  text = "Enter name for copied profile:",
  button1 = "Copy",
  button2 = "Cancel",
  hasEditBox = true,
  OnAccept = function(self)
    local name = self.EditBox:GetText()
    if MP.Profiles.CopyProfile(MP.Profiles.GetCurrentProfile(), name) then
      if SettingsFrame then SettingsFrame:Hide() end
      MP.Settings.CreateStandaloneUI()
    end
  end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

StaticPopupDialogs["MP_DELETE_PROFILE"] = {
  text = "Delete current profile?",
  button1 = "Delete",
  button2 = "Cancel",
  OnAccept = function()
    if MP.Profiles.DeleteProfile(MP.Profiles.GetCurrentProfile()) then
      if SettingsFrame then SettingsFrame:Hide() end
      MP.Settings.CreateStandaloneUI()
    end
  end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

StaticPopupDialogs["MP_RENAME_PROFILE"] = {
  text = "Enter new name for current profile:",
  button1 = "Rename",
  button2 = "Cancel",
  hasEditBox = true,
  OnAccept = function(self)
    local newName = self.EditBox:GetText()
    if MP.Profiles.RenameProfile(MP.Profiles.GetCurrentProfile(), newName) then
      if SettingsFrame then SettingsFrame:Hide() end
      MP.Settings.CreateStandaloneUI()
    end
  end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

StaticPopupDialogs["MP_RESET_PROFILE"] = {
  text = "Reset current profile to defaults?",
  button1 = "Reset",
  button2 = "Cancel",
  OnAccept = function()
    MP.Profiles.ResetProfile()
  end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

StaticPopupDialogs["MP_EXPORT_PROFILE"] = {
  text = "Copy this string to share your profile:",
  button1 = "Close",
  hasEditBox = true,
  OnShow = function(self, data)
    local exportString = MP.ExportProfile(MP.Profiles.GetCurrentProfile())
    if exportString then
      self.EditBox:SetText(exportString)
      self.EditBox:HighlightText()
      self.EditBox:SetFocus()
    else
      self.EditBox:SetText("Error: Could not export profile")
    end
  end,
  EditBoxOnEscapePressed = function(self)
    self:GetParent():Hide()
  end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

StaticPopupDialogs["MP_IMPORT_PROFILE"] = {
  text = "Paste profile string:",
  button1 = "Import",
  button2 = "Cancel",
  hasEditBox = true,
  OnAccept = function(self)
    local importString = self.EditBox:GetText()
    local currentProfile = MP.Profiles.GetCurrentProfile()
    local success, err = MP.ImportProfile(currentProfile, importString)
    
    if success then
      print("|cff00ff00[MinimalPlates]|r Profile imported successfully!")
      if SettingsFrame then SettingsFrame:Hide() end
      MP.Settings.CreateStandaloneUI()
    else
      print("|cffff0000[MinimalPlates]|r Import failed: " .. (err or "Unknown error"))
    end
  end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

-- Helper: Create scrollable panel
local function CreateScrollablePanel(parent, height)
  local scrollFrame = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
  scrollFrame:SetPoint("TOPLEFT", 10, -80)
  scrollFrame:SetPoint("BOTTOMRIGHT", -26, 60)

  local content = CreateFrame("Frame", nil, scrollFrame)
  content:SetSize(760, height or 1600)
  scrollFrame:SetScrollChild(content)
  
  -- Store reference to scrollFrame on content for visibility management
  content.scrollFrame = scrollFrame

  return content
end

-- Helper: Create basic panel
local function CreatePanel(parent)
  local panel = CreateFrame("Frame", nil, parent)
  panel:SetPoint("TOPLEFT", 10, -80)
  panel:SetPoint("BOTTOMRIGHT", -10, 60)
  panel:Hide()
  return panel
end

-- ============================================================================
-- TAB 1: GENERAL (Sub-Tabbed)
-- ============================================================================

-- General Sub-Tab 1: Basic Settings
local function CreateGeneralBasicSubTab(parent)
  local panel = CreateScrollablePanel(parent, 600)
  local y = -10

  -- Quick intro
  local intro = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  intro:SetPoint("TOPLEFT", L.LEFT_COLUMN_X, y)
  intro:SetText("Essential nameplate settings. Turn the addon on/off and adjust global scaling.")
  intro:SetTextColor(0.7, 0.7, 0.7)
  intro:SetWidth(550)
  intro:SetJustifyH("LEFT")
  y = y - 35

  H.CreateHeader(panel, "Basic Settings", L.LEFT_COLUMN_X, y)
  y = y - L.HEADER_SPACING

  H.CreateCheckbox(panel, "Enable MinimalPlates", "enabled", L.LEFT_COLUMN_X, y, nil,
    "Turn the addon on or off. When disabled, Blizzard's default nameplates are used.")
  y = y - L.OPTION_SPACING

  H.CreateSlider(panel, "Nameplate Scale", "scale", 0.5, 2.0, 0.1, L.LEFT_COLUMN_X, y, nil,
    "Global scale for all nameplates. 1.0 is default size.")
  y = y - 60

  H.CreateSlider(panel, "Max Distance", "nameplateMaxDistance", 20, 60, 1, L.LEFT_COLUMN_X, y, nil,
    "Maximum distance at which nameplates are visible (in yards).", function(val) return string.format("%d", val) end)
  y = y - 60

  return panel
end

-- General Sub-Tab 2: Display Modes
local function CreateGeneralDisplayModesSubTab(parent)
  local panel = CreateScrollablePanel(parent, 600)
  local y = -10

  local intro = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  intro:SetPoint("TOPLEFT", L.LEFT_COLUMN_X, y)
  intro:SetText("Choose how different types of units are displayed: Bar (with health bar), Text (name only), or Hide.")
  intro:SetTextColor(0.7, 0.7, 0.7)
  intro:SetWidth(550)
  intro:SetJustifyH("LEFT")
  y = y - 35

  H.CreateHeader(panel, MP.L["Display Modes"], L.LEFT_COLUMN_X, y)
  y = y - L.HEADER_SPACING

  local modeHelp = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  modeHelp:SetPoint("TOPLEFT", L.LEFT_COLUMN_X, y)
  modeHelp:SetText(MP.L["Choose Bar (with health bar), Text (name only), or Hide:"])
  modeHelp:SetTextColor(0.7, 0.7, 0.7)
  modeHelp:SetWidth(300)
  y = y - 25

  H.CreateDropdown(panel, MP.L["Enemy Players"], "enemyPlayerMode", DROPDOWN_OPTIONS.DisplayMode, L.LEFT_COLUMN_X, y, 150, nil, MP.L["Enemy players in PvP and opposing faction."])
  y = y - 50

  H.CreateDropdown(panel, MP.L["Enemy NPCs"], "enemyNPCMode", DROPDOWN_OPTIONS.DisplayMode, L.LEFT_COLUMN_X, y, 150, nil, MP.L["Enemy NPCs and monsters you fight."])
  y = y - 50

  H.CreateDropdown(panel, MP.L["Friendly Players"], "friendlyPlayerMode", DROPDOWN_OPTIONS.DisplayMode, L.LEFT_COLUMN_X, y, 150, nil, MP.L["Friendly players from your faction."])
  y = y - 50

  H.CreateDropdown(panel, MP.L["Friendly NPCs"], "friendlyNPCMode", DROPDOWN_OPTIONS.DisplayMode, L.LEFT_COLUMN_X, y, 150, nil, MP.L["Friendly NPCs like quest givers and vendors."])
  y = y - 70

  H.CreateHeader(panel, MP.L["Additional Unit Info"], L.LEFT_COLUMN_X, y)
  y = y - L.HEADER_SPACING

  H.CreateCheckbox(panel, MP.L["Show Creature Text"], "showCreatureText", L.LEFT_COLUMN_X, y, nil,
    MP.L["Show NPC titles/subtitles (like 'Innkeeper' or 'Quest Giver')."])
  y = y - L.OPTION_SPACING

  H.CreateCheckbox(panel, MP.L["Show Unit Target"], "showUnitTarget", L.LEFT_COLUMN_X, y, nil,
    MP.L["Show who the unit is currently targeting."])
  y = y - L.OPTION_SPACING + 10

  return panel
end

-- General Sub-Tab 3: Colors & Effects
local function CreateGeneralColorsSubTab(parent)
  local panel = CreateScrollablePanel(parent, 800)
  local y = -10

  local intro = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  intro:SetPoint("TOPLEFT", L.LEFT_COLUMN_X, y)
  intro:SetText(MP.L["Color schemes, target highlighting, and visual effects like glows and mouseover."])
  intro:SetTextColor(0.7, 0.7, 0.7)
  intro:SetWidth(550)
  intro:SetJustifyH("LEFT")
  y = y - 35

  -- LEFT COLUMN
  H.CreateHeader(panel, MP.L["Colors & Highlighting"], L.LEFT_COLUMN_X, y)
  y = y - L.HEADER_SPACING

  H.CreateCheckbox(panel, MP.L["Class Colors"], "classColors", L.LEFT_COLUMN_X, y, nil,
    MP.L["Color player nameplates by their class (Warrior=tan, Mage=blue, etc.)."])
  y = y - L.OPTION_SPACING

  H.CreateCheckbox(panel, MP.L["Threat Coloring"], "threatColoring", L.LEFT_COLUMN_X, y, nil,
    MP.L["Change nameplate color based on threat status (green=safe, yellow=warning, red=aggro)."])
  y = y - L.OPTION_SPACING

  H.CreateCheckbox(panel, MP.L["Highlight Current Target"], "targetHighlight", L.LEFT_COLUMN_X, y, nil,
    MP.L["Make your current target stand out visually."])
  y = y - L.OPTION_SPACING

  H.CreateSlider(panel, MP.L["Target Scale Multiplier"], "targetScale", 1.0, 2.0, 0.1, L.LEFT_COLUMN_X, y, nil,
    MP.L["Extra scaling applied to your current target. Makes it easier to see who you're attacking."])
  y = y - 60

  -- RIGHT COLUMN
  local yRight = -35

  H.CreateHeader(panel, MP.L["Visual Effects"], L.RIGHT_COLUMN_X, yRight)
  yRight = yRight - L.HEADER_SPACING

  H.CreateCheckbox(panel, MP.L["Show Threat Glow"], "showThreatGlow", L.RIGHT_COLUMN_X, yRight, nil,
    MP.L["Red glow around nameplates when you have threat/aggro."])
  yRight = yRight - L.OPTION_SPACING

  H.CreateCheckbox(panel, MP.L["Show Focus Glow"], "showFocusGlow", L.RIGHT_COLUMN_X, yRight, nil,
    MP.L["Special glow effect on your focus target."])
  yRight = yRight - L.OPTION_SPACING

  H.CreateCheckbox(panel, MP.L["Show Mouseover Highlight"], "showMouseoverHighlight", L.RIGHT_COLUMN_X, yRight, nil,
    MP.L["Highlight nameplates when you mouse over them."])
  yRight = yRight - L.OPTION_SPACING

  return panel
end

-- General Sub-Tab 4: Unit Info & Fade
local function CreateGeneralUnitInfoSubTab(parent)
  local panel = CreateScrollablePanel(parent, 800)
  local y = -10

  local intro = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  intro:SetPoint("TOPLEFT", L.LEFT_COLUMN_X, y)
  intro:SetText(MP.L["Unit information display and non-target fading options."])
  intro:SetTextColor(0.7, 0.7, 0.7)
  intro:SetWidth(550)
  intro:SetJustifyH("LEFT")
  y = y - 35

  -- LEFT COLUMN
  H.CreateHeader(panel, MP.L["Unit Information"], L.LEFT_COLUMN_X, y)
  y = y - L.HEADER_SPACING

  H.CreateCheckbox(panel, MP.L["Show Level"], "showLevel", L.LEFT_COLUMN_X, y, nil,
    MP.L["Display unit level number."])
  y = y - L.OPTION_SPACING

  H.CreateCheckbox(panel, MP.L["Show Guild Text"], "showGuildText", L.LEFT_COLUMN_X, y, nil,
    MP.L["Show guild name under player names."])
  y = y - L.OPTION_SPACING + 10

  -- RIGHT COLUMN
  local yRight = -35

  H.CreateHeader(panel, MP.L["Non-Target Fade"], L.RIGHT_COLUMN_X, yRight)
  yRight = yRight - L.HEADER_SPACING

  H.CreateCheckbox(panel, MP.L["Fade Non-Target Plates"], "fadeNonTarget", L.RIGHT_COLUMN_X, yRight, nil,
    MP.L["Reduce opacity of nameplates that aren't your target."])
  yRight = yRight - L.OPTION_SPACING

  local fadeNote = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  fadeNote:SetPoint("TOPLEFT", L.RIGHT_COLUMN_X, yRight)
  fadeNote:SetText("|cff888888" .. MP.L["(More fade options in Advanced tab)"] .. "|r")
  fadeNote:SetWidth(280)
  yRight = yRight - 20

  H.CreateSlider(panel, MP.L["Non-Target Alpha"], "nonTargetAlpha", 0.1, 1.0, 0.05, L.RIGHT_COLUMN_X, yRight, nil,
    MP.L["Opacity for faded nameplates (0.1=very transparent, 1.0=fully visible)."])
  yRight = yRight - 60

  return panel
end

-- Main General Tab with Sub-Tabs
local function CreateGeneralTab(parent)
  local container = CreateFrame("Frame", nil, parent)
  container:SetAllPoints()
  container:Hide()

  -- Sub-tab buttons
  local subTabs = {
    {name = MP.L["Basic"], panel = nil, createFunc = CreateGeneralBasicSubTab},
    {name = MP.L["Display Modes"], panel = nil, createFunc = CreateGeneralDisplayModesSubTab},
    {name = MP.L["Colors & Effects"], panel = nil, createFunc = CreateGeneralColorsSubTab},
    {name = MP.L["Unit Info & Fade"], panel = nil, createFunc = CreateGeneralUnitInfoSubTab},
  }

  local subTabButtons = {}
  local subTabWidth = 120

  for i, subTab in ipairs(subTabs) do
    local btn = CreateFrame("Button", nil, container, "UIPanelButtonTemplate")
    btn:SetSize(subTabWidth, 25)
    btn:SetPoint("TOPLEFT", 10 + (i - 1) * (subTabWidth + 5), -80)
    btn:SetText(subTab.name)

    btn:SetScript("OnClick", function()
      -- Hide all sub-tab panels
      for j, st in ipairs(subTabs) do
        if st.panel then
          if st.panel.scrollFrame then
            st.panel.scrollFrame:Hide()
          else
            st.panel:Hide()
          end
        end
        subTabButtons[j]:Enable()
      end

      -- Create and show selected sub-tab
      if not subTab.panel then
        subTab.panel = subTab.createFunc(container)
        -- Position scrollFrame below sub-tab buttons
        if subTab.panel.scrollFrame then
          subTab.panel.scrollFrame:ClearAllPoints()
          subTab.panel.scrollFrame:SetPoint("TOPLEFT", 10, -115)
          subTab.panel.scrollFrame:SetPoint("BOTTOMRIGHT", -26, 10)
        end
      end

      if subTab.panel.scrollFrame then
        subTab.panel.scrollFrame:Show()
      else
        subTab.panel:Show()
      end

      btn:Disable()
    end)

    subTabButtons[i] = btn
  end

  -- Show first sub-tab by default
  subTabs[1].panel = subTabs[1].createFunc(container)
  if subTabs[1].panel.scrollFrame then
    subTabs[1].panel.scrollFrame:ClearAllPoints()
    subTabs[1].panel.scrollFrame:SetPoint("TOPLEFT", 10, -115)
    subTabs[1].panel.scrollFrame:SetPoint("BOTTOMRIGHT", -26, 10)
    subTabs[1].panel.scrollFrame:Show()
  else
    subTabs[1].panel:Show()
  end
  subTabButtons[1]:Disable()

  return container
end

-- ============================================================================
-- TAB 2: APPEARANCE (Sub-Tabbed)
-- ============================================================================

-- Appearance Sub-Tab 1: Health Bars
local function CreateAppearanceHealthBarsSubTab(parent)
  local panel = CreateScrollablePanel(parent, 600)
  local y = -10

  local intro = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  intro:SetPoint("TOPLEFT", L.LEFT_COLUMN_X, y)
  intro:SetText("Customize health bar dimensions, health text display, and bar texture style.")
  intro:SetTextColor(0.7, 0.7, 0.7)
  intro:SetWidth(550)
  intro:SetJustifyH("LEFT")
  y = y - 35

  H.CreateHeader(panel, "Health Bar Dimensions", L.LEFT_COLUMN_X, y)
  y = y - L.HEADER_SPACING

  H.CreateSlider(panel, "Health Bar Width", "healthWidth", 60, 200, 5, L.LEFT_COLUMN_X, y, nil,
    "Width of health bars in pixels.")
  y = y - 50

  H.CreateSlider(panel, "Health Bar Height", "healthHeight", 4, 20, 1, L.LEFT_COLUMN_X, y, nil,
    "Height of health bars in pixels.")
  y = y - 60

  H.CreateHeader(panel, "Health Text Display", L.LEFT_COLUMN_X, y)
  y = y - L.HEADER_SPACING

  H.CreateCheckbox(panel, "Show Health Text", "showHealthText", L.LEFT_COLUMN_X, y, nil,
    "Display health percentage or absolute values on health bars.")
  y = y - L.OPTION_SPACING

  H.CreateDropdown(panel, "Health Text Format", "healthTextFormat", DROPDOWN_OPTIONS.HealthTextFormat, L.LEFT_COLUMN_X, y, 150, nil, "How to display health numbers.")
  y = y - 60

  H.CreateHeader(panel, "Bar Texture", L.LEFT_COLUMN_X, y)
  y = y - L.HEADER_SPACING

  -- Bar Texture
  local barTextures = MP.SharedMedia and MP.SharedMedia.GetAllStatusBars and MP.SharedMedia.GetAllStatusBars() or {
    {name = "Smooth", path = "Interface\\AddOns\\MinimalPlates\\Textures\\Smooth"},
    {name = "Smoother", path = "Interface\\AddOns\\MinimalPlates\\Textures\\Smoother"},
    {name = "Smooth v2", path = "Interface\\AddOns\\MinimalPlates\\Textures\\Smoothv2"},
    {name = "BantoBar", path = "Interface\\AddOns\\MinimalPlates\\Textures\\BantoBar"},
    {name = "Glaze", path = "Interface\\AddOns\\MinimalPlates\\Textures\\Glaze"},
    {name = "Otravi", path = "Interface\\AddOns\\MinimalPlates\\Textures\\Otravi"},
    {name = "Bar", path = "Interface\\AddOns\\MinimalPlates\\Textures\\bar"},
    {name = "Blizzard", path = "Interface\\Buttons\\WHITE8X8"},
  }

  local texOptions = {}
  for _, tex in ipairs(barTextures) do
    table.insert(texOptions, {text = tex.name, value = tex.key or tex.path})
  end

  H.CreateDropdown(panel, "Bar Texture", "barTexture", texOptions, L.LEFT_COLUMN_X, y, 200, nil,
    "Visual style of health/cast bars.")
  y = y - 65

  H.CreateHeader(panel, "Classification Scaling", L.LEFT_COLUMN_X, y)
  y = y - L.HEADER_SPACING

  H.CreateCheckbox(panel, "Enable Classification Scaling", "classificationScale", L.LEFT_COLUMN_X, y, nil,
    "Make elite and boss nameplates larger than normal units.")
  y = y - L.OPTION_SPACING

  H.CreateSlider(panel, "Elite Scale", "eliteScale", 1.0, 2.0, 0.05, L.LEFT_COLUMN_X, y, nil,
    "Scale multiplier for elite units (1.1 = 10% larger).", function(val) return string.format("%.2f", val) end)
  y = y - 50

  H.CreateSlider(panel, "Boss Scale", "bossScale", 1.0, 2.5, 0.05, L.LEFT_COLUMN_X, y, nil,
    "Scale multiplier for boss units (1.25 = 25% larger).", function(val) return string.format("%.2f", val) end)
  y = y - 60

  return panel
end

-- Appearance Sub-Tab 2: Cast Bars
local function CreateAppearanceCastBarsSubTab(parent)
  local panel = CreateScrollablePanel(parent, 800)
  local y = -10

  local intro = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  intro:SetPoint("TOPLEFT", L.LEFT_COLUMN_X, y)
  intro:SetText("Configure cast bar display, visual effects, and colors for interruptible/non-interruptible casts.")
  intro:SetTextColor(0.7, 0.7, 0.7)
  intro:SetWidth(550)
  intro:SetJustifyH("LEFT")
  y = y - 35

  -- LEFT COLUMN
  H.CreateHeader(panel, "Cast Bar Settings", L.LEFT_COLUMN_X, y)
  y = y - L.HEADER_SPACING

  H.CreateCheckbox(panel, "Show Cast Bar", "showCastBar", L.LEFT_COLUMN_X, y, nil,
    "Display enemy cast bars to see what spells they're casting.")
  y = y - L.OPTION_SPACING

  H.CreateSlider(panel, "Cast Bar Height", "castHeight", 4, 16, 1, L.LEFT_COLUMN_X, y, nil,
    "Height of cast bars in pixels.")
  y = y - 60

  H.CreateHeader(panel, "Cast Bar Visual Effects", L.LEFT_COLUMN_X, y)
  y = y - L.HEADER_SPACING

  H.CreateCheckbox(panel, "Show Cast Icon", "showCastIcon", L.LEFT_COLUMN_X, y, nil,
    "Show spell icon next to cast bar.")
  y = y - L.OPTION_SPACING

  H.CreateCheckbox(panel, "Show Cast Spark", "showCastSpark", L.LEFT_COLUMN_X, y, nil,
    "Animated spark showing cast progress.")
  y = y - L.OPTION_SPACING

  H.CreateCheckbox(panel, "Show Interrupt Flash", "showInterruptFlash", L.LEFT_COLUMN_X, y, nil,
    "Flash effect when a cast is interrupted.")
  y = y - L.OPTION_SPACING

  H.CreateCheckbox(panel, "Show Cast Target", "showCastTarget", L.LEFT_COLUMN_X, y, nil,
    "Show who the enemy is casting at.")
  y = y - L.OPTION_SPACING + 10

  -- RIGHT COLUMN
  local yRight = -35

  H.CreateHeader(panel, "Cast Bar Colors", L.RIGHT_COLUMN_X, yRight)
  yRight = yRight - L.HEADER_SPACING

  H.CreateColorPicker(panel, "Interruptible Cast Color", "interruptibleCastColor", L.RIGHT_COLUMN_X, yRight,
    "Color for casts you can interrupt.")
  yRight = yRight - 35

  H.CreateColorPicker(panel, "Non-Interruptible Cast Color", "nonInterruptibleCastColor", L.RIGHT_COLUMN_X, yRight,
    "Color for casts you cannot interrupt.")
  yRight = yRight - 35

  H.CreateColorPicker(panel, "Quest NPC Color", "questNPCColor", L.RIGHT_COLUMN_X, yRight,
    "Color for NPCs with available quests.")
  yRight = yRight - 40

  return panel
end

-- Appearance Sub-Tab 3: Power Bars
local function CreateAppearancePowerBarsSubTab(parent)
  local panel = CreateScrollablePanel(parent, 400)
  local y = -10

  local intro = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  intro:SetPoint("TOPLEFT", L.LEFT_COLUMN_X, y)
  intro:SetText("Configure power bar (mana/energy/rage) display for your target.")
  intro:SetTextColor(0.7, 0.7, 0.7)
  intro:SetWidth(550)
  intro:SetJustifyH("LEFT")
  y = y - 35

  H.CreateHeader(panel, "Power Bar Settings", L.LEFT_COLUMN_X, y)
  y = y - L.HEADER_SPACING

  H.CreateCheckbox(panel, "Show Power Bar on Target", "showPowerBar", L.LEFT_COLUMN_X, y, nil,
    "Display mana/energy/rage bar on your current target.")
  y = y - L.OPTION_SPACING + 10

  return panel
end

-- Appearance Sub-Tab 4: Text & Fonts
local function CreateAppearanceTextFontsSubTab(parent)
  local panel = CreateScrollablePanel(parent, 600)
  local y = -10

  local intro = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  intro:SetPoint("TOPLEFT", L.LEFT_COLUMN_X, y)
  intro:SetText("Customize font size, font family, and text outline style for all nameplate text.")
  intro:SetTextColor(0.7, 0.7, 0.7)
  intro:SetWidth(550)
  intro:SetJustifyH("LEFT")
  y = y - 35

  H.CreateHeader(panel, "Font Settings", L.LEFT_COLUMN_X, y)
  y = y - L.HEADER_SPACING

  H.CreateSlider(panel, "Font Size", "fontSize", 8, 24, 1, L.LEFT_COLUMN_X, y, nil,
    "Size of all text on nameplates.", function(val) return string.format("%d", val) end)
  y = y - 60

  -- Font dropdown
  local fonts = MP.SharedMedia and MP.SharedMedia.GetAllFonts and MP.SharedMedia.GetAllFonts() or {}
  local fontOptions = {}
  for _, font in ipairs(fonts) do
    if not font.isHeader then
      table.insert(fontOptions, {text = font.name, value = font.path})
    end
  end

  if #fontOptions > 0 then
    H.CreateDropdown(panel, "Font", "font", fontOptions, L.LEFT_COLUMN_X, y, 200, nil,
      "Font family for nameplate text.")
    y = y - 50
  end

  H.CreateDropdown(panel, "Font Outline", "fontFlags", DROPDOWN_OPTIONS.FontOutline, L.LEFT_COLUMN_X, y, 200, nil, "Text outline style for better readability.")
  y = y - 55

  return panel
end

-- Appearance Sub-Tab 5: Visual Effects
local function CreateAppearanceVisualEffectsSubTab(parent)
  local panel = CreateScrollablePanel(parent, 400)
  local y = -10

  local intro = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  intro:SetPoint("TOPLEFT", L.LEFT_COLUMN_X, y)
  intro:SetText("Visual feedback effects and overlays for nameplate states.")
  intro:SetTextColor(0.7, 0.7, 0.7)
  intro:SetWidth(550)
  intro:SetJustifyH("LEFT")
  y = y - 35

  H.CreateHeader(panel, "Visual Effects", L.LEFT_COLUMN_X, y)
  y = y - L.HEADER_SPACING

  H.CreateCheckbox(panel, "Show Tapped Overlay", "showTappedOverlay", L.LEFT_COLUMN_X, y, nil,
    "Grey overlay on units that are tapped (killed/tagged by someone else).")
  y = y - L.OPTION_SPACING

  H.CreateCheckbox(panel, "Show Loss of Aggro Flash", "showLossOfAggroFlash", L.LEFT_COLUMN_X, y, nil,
    "White flash when you lose threat (useful for tanks).")
  y = y - L.OPTION_SPACING + 10

  return panel
end

-- Main Appearance Tab with Sub-Tabs
local function CreateAppearanceTab(parent)
  local container = CreateFrame("Frame", nil, parent)
  container:SetAllPoints()
  container:Hide()

  -- Sub-tab buttons
  local subTabs = {
    {name = "Health Bars", panel = nil, createFunc = CreateAppearanceHealthBarsSubTab},
    {name = "Cast Bars", panel = nil, createFunc = CreateAppearanceCastBarsSubTab},
    {name = "Power Bars", panel = nil, createFunc = CreateAppearancePowerBarsSubTab},
    {name = "Text & Fonts", panel = nil, createFunc = CreateAppearanceTextFontsSubTab},
    {name = "Visual Effects", panel = nil, createFunc = CreateAppearanceVisualEffectsSubTab},
  }

  local subTabButtons = {}
  local subTabWidth = 105

  for i, subTab in ipairs(subTabs) do
    local btn = CreateFrame("Button", nil, container, "UIPanelButtonTemplate")
    btn:SetSize(subTabWidth, 25)
    btn:SetPoint("TOPLEFT", 10 + (i - 1) * (subTabWidth + 5), -80)
    btn:SetText(subTab.name)

    btn:SetScript("OnClick", function()
      -- Hide all sub-tab panels
      for j, st in ipairs(subTabs) do
        if st.panel then
          if st.panel.scrollFrame then
            st.panel.scrollFrame:Hide()
          else
            st.panel:Hide()
          end
        end
        subTabButtons[j]:Enable()
      end

      -- Create and show selected sub-tab
      if not subTab.panel then
        subTab.panel = subTab.createFunc(container)
        -- Position scrollFrame below sub-tab buttons
        if subTab.panel.scrollFrame then
          subTab.panel.scrollFrame:ClearAllPoints()
          subTab.panel.scrollFrame:SetPoint("TOPLEFT", 10, -115)
          subTab.panel.scrollFrame:SetPoint("BOTTOMRIGHT", -26, 10)
        end
      end

      if subTab.panel.scrollFrame then
        subTab.panel.scrollFrame:Show()
      else
        subTab.panel:Show()
      end

      btn:Disable()
    end)

    subTabButtons[i] = btn
  end

  -- Show first sub-tab by default
  subTabs[1].panel = subTabs[1].createFunc(container)
  if subTabs[1].panel.scrollFrame then
    subTabs[1].panel.scrollFrame:ClearAllPoints()
    subTabs[1].panel.scrollFrame:SetPoint("TOPLEFT", 10, -115)
    subTabs[1].panel.scrollFrame:SetPoint("BOTTOMRIGHT", -26, 10)
    subTabs[1].panel.scrollFrame:Show()
  else
    subTabs[1].panel:Show()
  end
  subTabButtons[1]:Disable()

  return container
end

-- ============================================================================
-- TAB 3: ICONS & LAYOUT (Sub-Tabbed)
-- ============================================================================

-- Icons & Layout Sub-Tab 1: General Icon Settings
local function CreateIconsGeneralSubTab(parent)
  local panel = CreateScrollablePanel(parent, 400)
  local y = -10

  local intro = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  intro:SetPoint("TOPLEFT", L.LEFT_COLUMN_X, y)
  intro:SetText("Master toggle and base size for all icons on nameplates.")
  intro:SetTextColor(0.7, 0.7, 0.7)
  intro:SetWidth(550)
  intro:SetJustifyH("LEFT")
  y = y - 35

  H.CreateHeader(panel, "General Icon Settings", L.LEFT_COLUMN_X, y)
  y = y - L.HEADER_SPACING

  H.CreateCheckbox(panel, "Show Icons", "showIcons", L.LEFT_COLUMN_X, y, nil,
    "Master toggle for all icons (quest, raid markers, role icons, etc.).")
  y = y - L.OPTION_SPACING

  H.CreateSlider(panel, "Icon Height", "iconHeight", 12, 48, 2, L.LEFT_COLUMN_X, y, nil,
    "Base size for all icons in pixels.", function(val) return string.format("%d", val) end)
  y = y - 60

  return panel
end

-- Icons & Layout Sub-Tab 2: Quest & Classification
local function CreateIconsQuestSubTab(parent)
  local panel = CreateScrollablePanel(parent, 600)
  local y = -10

  local intro = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  intro:SetPoint("TOPLEFT", L.LEFT_COLUMN_X, y)
  intro:SetText("Quest icons and elite/rare classification icons.")
  intro:SetTextColor(0.7, 0.7, 0.7)
  intro:SetWidth(550)
  intro:SetJustifyH("LEFT")
  y = y - 35

  H.CreateHeader(panel, "Quest & Classification Icons", L.LEFT_COLUMN_X, y)
  y = y - L.HEADER_SPACING

  H.CreateCheckbox(panel, "Show Elite/Rare Icons", "showEliteBorder", L.LEFT_COLUMN_X, y, nil,
    "Display special icons for elite, rare, and rare elite units.")
  y = y - L.OPTION_SPACING

  H.CreateCheckbox(panel, "Show Quest Icons", "showQuestIcon", L.LEFT_COLUMN_X, y, nil,
    "Yellow ! icon for units with available quests.")
  y = y - L.OPTION_SPACING

  H.CreateCheckbox(panel, "Show World Quest Icon", "showWorldQuestIcon", L.LEFT_COLUMN_X, y, nil,
    "Special icon for world quest objectives.")
  y = y - L.OPTION_SPACING

  H.CreateSlider(panel, "Quest Icon Size", "questIconSize", 8, 32, 2, L.LEFT_COLUMN_X, y, nil,
    "Size of quest icons in pixels.", function(val) return string.format("%d", val) end)
  y = y - 55

  return panel
end

-- Icons & Layout Sub-Tab 3: Role & Status
local function CreateIconsRoleSubTab(parent)
  local panel = CreateScrollablePanel(parent, 600)
  local y = -10

  local intro = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  intro:SetPoint("TOPLEFT", L.LEFT_COLUMN_X, y)
  intro:SetText("Role icons (tank/healer/DPS), healer identification, pet icons, and arena numbering.")
  intro:SetTextColor(0.7, 0.7, 0.7)
  intro:SetWidth(550)
  intro:SetJustifyH("LEFT")
  y = y - 35

  H.CreateHeader(panel, "Role & Status Icons", L.LEFT_COLUMN_X, y)
  y = y - L.HEADER_SPACING

  H.CreateCheckbox(panel, "Show Role Icons", "showRoleIcons", L.LEFT_COLUMN_X, y, nil,
    "Tank/Healer/DPS icons for players in your group.")
  y = y - L.OPTION_SPACING

  H.CreateCheckbox(panel, "Show Healer Icon", "showHealerIcon", L.LEFT_COLUMN_X, y, nil,
    "Special icon to identify healers.")
  y = y - L.OPTION_SPACING

  H.CreateCheckbox(panel, "Show Pet Icon", "showPetIcon", L.LEFT_COLUMN_X, y, nil,
    "Icon indicating the unit is a pet.")
  y = y - L.OPTION_SPACING

  H.CreateCheckbox(panel, "Show Arena ID", "showArenaID", L.LEFT_COLUMN_X, y, nil,
    "Show 1-5 numbering for arena opponents.")
  y = y - L.OPTION_SPACING

  H.CreateSlider(panel, "Level Icon Scale", "levelIconScale", 1.0, 3.0, 0.1, L.LEFT_COLUMN_X, y, nil,
    "Size of level text/icon.", function(val) return string.format("%.1f", val) end)
  y = y - 55

  return panel
end

-- Icons & Layout Sub-Tab 4: Markers
local function CreateIconsMarkersSubTab(parent)
  local panel = CreateScrollablePanel(parent, 600)
  local y = -10

  local intro = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  intro:SetPoint("TOPLEFT", L.LEFT_COLUMN_X, y)
  intro:SetText("Raid target markers (Skull, Cross, Square, etc.) and PvP objective markers.")
  intro:SetTextColor(0.7, 0.7, 0.7)
  intro:SetWidth(550)
  intro:SetJustifyH("LEFT")
  y = y - 35

  H.CreateHeader(panel, "Raid & PvP Markers", L.LEFT_COLUMN_X, y)
  y = y - L.HEADER_SPACING

  H.CreateCheckbox(panel, "Show Raid Markers", "showRaidMarkers", L.LEFT_COLUMN_X, y, nil,
    "Skull, Cross, Square, etc. raid target markers.")
  y = y - L.OPTION_SPACING

  H.CreateSlider(panel, "Raid Marker Size", "raidMarkerSize", 16, 48, 2, L.LEFT_COLUMN_X, y, nil,
    "Size of raid markers in pixels.", function(val) return string.format("%d", val) end)
  y = y - 50

  H.CreateCheckbox(panel, "Show PvP Markers", "showPvPMarker", L.LEFT_COLUMN_X, y, nil,
    "Flag carrier and orb icons in battlegrounds.")
  y = y - L.OPTION_SPACING + 10

  return panel
end

-- Icons & Layout Sub-Tab 5: Auras & Debuffs
local function CreateIconsAurasSubTab(parent)
  local panel = CreateScrollablePanel(parent, 1200)
  local y = -10

  local intro = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  intro:SetPoint("TOPLEFT", L.LEFT_COLUMN_X, y)
  intro:SetText("Configure aura display, filtering, and size scaling using the 3-tier aura system.")
  intro:SetTextColor(0.7, 0.7, 0.7)
  intro:SetWidth(550)
  intro:SetJustifyH("LEFT")
  y = y - 35

  -- LEFT COLUMN
  H.CreateHeader(panel, "Aura Display", L.LEFT_COLUMN_X, y)
  y = y - L.HEADER_SPACING - 5

  H.CreateCheckbox(panel, "Show Aura Icons", "showAuras", L.LEFT_COLUMN_X, y, nil,
    "Display auras on nameplates using the 3-tier system.")
  y = y - L.OPTION_SPACING + 5

  H.CreateCheckbox(panel, "Show Buffs", "showBuffs", L.LEFT_COLUMN_X, y, nil,
    "Display beneficial auras (buffs).")
  y = y - L.OPTION_SPACING + 5

  H.CreateCheckbox(panel, "Show Debuffs", "showDebuffs", L.LEFT_COLUMN_X, y, nil,
    "Display harmful auras (debuffs).")
  y = y - L.OPTION_SPACING + 5

  H.CreateCheckbox(panel, "Show Crowd Control", "showCrowdControl", L.LEFT_COLUMN_X, y, nil,
    "Display CC effects separately (stuns, roots, etc.).")
  y = y - L.OPTION_SPACING + 5

  H.CreateCheckbox(panel, "Stack Auras Vertically", "auraStackLayout", L.LEFT_COLUMN_X, y, nil,
    "Arrange aura icons vertically instead of horizontally.")
  y = y - L.OPTION_SPACING + 25

  -- RIGHT COLUMN
  local yRight = -45

  H.CreateHeader(panel, "Aura Filtering", L.RIGHT_COLUMN_X, yRight)
  yRight = yRight - L.HEADER_SPACING - 5

  H.CreateCheckbox(panel, "Auto-Enlarge Important", "autoEnlargeImportant", L.RIGHT_COLUMN_X, yRight, nil,
    "Automatically enlarge important auras (defensives, immunities).")
  yRight = yRight - L.OPTION_SPACING + 5

  H.CreateSlider(panel, "Important Aura Scale", "importantAuraScale", 1.0, 2.5, 0.1, L.RIGHT_COLUMN_X, yRight, nil,
    "Scale multiplier for important auras.", function(val) return string.format("%.1f", val) end)
  yRight = yRight - 55

  H.CreateCheckbox(panel, "Only Show Whitelisted", "onlyShowWhitelisted", L.RIGHT_COLUMN_X, yRight, nil,
    "Only display auras on your whitelist. Use /mp whitelist <spellID>")
  yRight = yRight - L.OPTION_SPACING + 5

  H.CreateCheckbox(panel, "Hide Blacklisted", "hideBlacklisted", L.RIGHT_COLUMN_X, yRight, nil,
    "Hide auras on your blacklist. Use /mp blacklist <spellID>")
  yRight = yRight - L.OPTION_SPACING + 15

  local filterInfo = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  filterInfo:SetPoint("TOPLEFT", L.RIGHT_COLUMN_X, yRight)
  filterInfo:SetText("|cff888888Use /mp whitelist and /mp blacklist commands\nto manage aura filters.|r")
  filterInfo:SetJustifyH("LEFT")
  filterInfo:SetWidth(280)
  yRight = yRight - 50

  H.CreateCheckbox(panel, "Show CC Indicator", "showCCIndicator", L.RIGHT_COLUMN_X, yRight, nil,
    "Large icon when target is crowd controlled.")
  yRight = yRight - L.OPTION_SPACING

  H.CreateCheckbox(panel, "Show Interrupt Indicator", "showInterruptIndicator", L.RIGHT_COLUMN_X, yRight, nil,
    "Shield icon when cast cannot be interrupted.")
  yRight = yRight - L.OPTION_SPACING + 30

  -- Aura Positioning Section
  H.CreateHeader(panel, "Aura Positioning", L.RIGHT_COLUMN_X, yRight)
  yRight = yRight - L.HEADER_SPACING - 5

  H.CreatePositionControl(panel, "Buffs", "buffsPosition", "buffsOffsetY", "buffsScale", L.RIGHT_COLUMN_X, yRight,
    "Position above/below bar, height, and scale for buff icons.")
  yRight = yRight - 75

  H.CreatePositionControl(panel, "Debuffs", "debuffsPosition", "debuffsOffsetY", "debuffsScale", L.RIGHT_COLUMN_X, yRight,
    "Position above/below bar, height, and scale for debuff icons.")
  yRight = yRight - 75

  H.CreatePositionControl(panel, "Crowd Control", "ccPosition", "ccOffsetY", "ccScale", L.RIGHT_COLUMN_X, yRight,
    "Position left/right, height, and scale for CC icons.")
  yRight = yRight - 80

  return panel
end

-- Icons & Layout Sub-Tab 6: Positioning
local function CreateIconsPositioningSubTab(parent)
  local panel = CreateScrollablePanel(parent, 600)
  local y = -10

  local intro = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  intro:SetPoint("TOPLEFT", L.LEFT_COLUMN_X, y)
  intro:SetText("Adjust vertical spacing between nameplate elements (name, auras, cast bar).")
  intro:SetTextColor(0.7, 0.7, 0.7)
  intro:SetWidth(550)
  intro:SetJustifyH("LEFT")
  y = y - 35

  H.CreateHeader(panel, "Element Positioning", L.LEFT_COLUMN_X, y)
  y = y - L.HEADER_SPACING

  local posInfo = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  posInfo:SetPoint("TOPLEFT", L.LEFT_COLUMN_X, y)
  posInfo:SetText("|cff888888Adjust vertical spacing between nameplate elements.|r")
  posInfo:SetJustifyH("LEFT")
  posInfo:SetWidth(280)
  y = y - 25

  H.CreateSlider(panel, "Name Y Offset", "nameYOffset", -20, 20, 1, L.LEFT_COLUMN_X, y, nil,
    "Vertical offset for name text relative to health bar.", function(val) return string.format("%d", val) end)
  y = y - 50

  H.CreateSlider(panel, "Aura Y Offset", "auraYOffset", 0, 30, 1, L.LEFT_COLUMN_X, y, nil,
    "Vertical spacing between health bar and aura icons.", function(val) return string.format("%d", val) end)
  y = y - 50

  H.CreateSlider(panel, "Cast Bar Y Offset", "castYOffset", -10, 10, 1, L.LEFT_COLUMN_X, y, nil,
    "Vertical spacing between health bar and cast bar.", function(val) return string.format("%d", val) end)
  y = y - 55

  return panel
end

-- Main Icons & Layout Tab with Sub-Tabs
local function CreateIconsTab(parent)
  local container = CreateFrame("Frame", nil, parent)
  container:SetAllPoints()
  container:Hide()

  -- Sub-tab buttons
  local subTabs = {
    {name = "General", panel = nil, createFunc = CreateIconsGeneralSubTab},
    {name = "Quest & Class", panel = nil, createFunc = CreateIconsQuestSubTab},
    {name = "Role & Status", panel = nil, createFunc = CreateIconsRoleSubTab},
    {name = "Markers", panel = nil, createFunc = CreateIconsMarkersSubTab},
    {name = "Auras & Debuffs", panel = nil, createFunc = CreateIconsAurasSubTab},
    {name = "Positioning", panel = nil, createFunc = CreateIconsPositioningSubTab},
  }

  local subTabButtons = {}
  local subTabWidth = 100

  for i, subTab in ipairs(subTabs) do
    local btn = CreateFrame("Button", nil, container, "UIPanelButtonTemplate")
    btn:SetSize(subTabWidth, 25)
    btn:SetPoint("TOPLEFT", 10 + (i - 1) * (subTabWidth + 5), -80)
    btn:SetText(subTab.name)

    btn:SetScript("OnClick", function()
      -- Hide all sub-tab panels
      for j, st in ipairs(subTabs) do
        if st.panel then
          if st.panel.scrollFrame then
            st.panel.scrollFrame:Hide()
          else
            st.panel:Hide()
          end
        end
        subTabButtons[j]:Enable()
      end

      -- Create and show selected sub-tab
      if not subTab.panel then
        subTab.panel = subTab.createFunc(container)
        -- Position scrollFrame below sub-tab buttons
        if subTab.panel.scrollFrame then
          subTab.panel.scrollFrame:ClearAllPoints()
          subTab.panel.scrollFrame:SetPoint("TOPLEFT", 10, -115)
          subTab.panel.scrollFrame:SetPoint("BOTTOMRIGHT", -26, 10)
        end
      end

      if subTab.panel.scrollFrame then
        subTab.panel.scrollFrame:Show()
      else
        subTab.panel:Show()
      end

      btn:Disable()
    end)

    subTabButtons[i] = btn
  end

  -- Show first sub-tab by default
  subTabs[1].panel = subTabs[1].createFunc(container)
  if subTabs[1].panel.scrollFrame then
    subTabs[1].panel.scrollFrame:ClearAllPoints()
    subTabs[1].panel.scrollFrame:SetPoint("TOPLEFT", 10, -115)
    subTabs[1].panel.scrollFrame:SetPoint("BOTTOMRIGHT", -26, 10)
    subTabs[1].panel.scrollFrame:Show()
  else
    subTabs[1].panel:Show()
  end
  subTabButtons[1]:Disable()

  return container
end

-- ============================================================================
-- TAB 4: ADVANCED (with Sub-Tabs)
-- ============================================================================

-- Sub-Tab 1: Element Positions
local function CreateAdvancedPositionsSubTab(parent)
  local panel = CreateScrollablePanel(parent, 2000)
  local y = -10

  local intro = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  intro:SetPoint("TOPLEFT", L.LEFT_COLUMN_X, y)
  intro:SetText("Configure position, height (Y offset), and scale for every nameplate element.")
  intro:SetTextColor(0.7, 0.7, 0.7)
  intro:SetWidth(550)
  intro:SetJustifyH("LEFT")
  y = y - 30

  -- LEFT COLUMN - Text Elements
  H.CreateHeader(panel, "Text Elements", L.LEFT_COLUMN_X, y)
  y = y - 30

  H.CreatePositionControl(panel, "Name", "namePosition", "nameYOffset", "nameScale", L.LEFT_COLUMN_X, y,
    "Position, height (Y offset), and scale for name text.")
  y = y - 70

  H.CreatePositionControl(panel, "Level", "levelPosition", "levelOffsetY", "levelScale", L.LEFT_COLUMN_X, y,
    "Position, height (Y offset), and scale for level text/icon.")
  y = y - 70

  H.CreatePositionControl(panel, "Guild Text", "guildTextPosition", "guildTextOffsetY", "guildTextScale", L.LEFT_COLUMN_X, y,
    "Position, height, and scale for player guild text.", "guildTextOffsetX")
  y = y - 95

  H.CreatePositionControl(panel, "Creature Text", "creatureTextPosition", "creatureTextOffsetY", "creatureTextScale", L.LEFT_COLUMN_X, y,
    "Position, height, and scale for NPC titles/subtitles.", "creatureTextOffsetX")
  y = y - 95

  H.CreatePositionControl(panel, "Unit Target Text", "unitTargetPosition", "unitTargetOffsetY", "unitTargetScale", L.LEFT_COLUMN_X, y,
    "Position, height, and scale for 'Unit is targeting' text.")
  y = y - 70

  H.CreatePositionControl(panel, "Cast Text", "castTextPosition", "castTextOffsetY", "castTextScale", L.LEFT_COLUMN_X, y,
    "Position, height, and scale for the cast text below/above the bar.")
  y = y - 70

  H.CreatePositionControl(panel, "Cast Target Text", "castTargetPosition", "castTargetOffsetY", "castTargetScale", L.LEFT_COLUMN_X, y,
    "Position, height, and scale for 'Casting at' text.")
  y = y - 75

  -- RIGHT COLUMN - Icons & Markers
  local yRight = -35
  H.CreateHeader(panel, "Icons & Markers", L.RIGHT_COLUMN_X, yRight)
  yRight = yRight - 30

  H.CreatePositionControl(panel, "Class Icon", "classIconPosition", "classIconOffsetY", "classIconScale", L.RIGHT_COLUMN_X, yRight,
    "Position, height, and scale for elite/rare icons.")
  yRight = yRight - 70

  H.CreatePositionControl(panel, "Role Icon", "roleIconPosition", "roleIconOffsetY", "roleIconScale", L.RIGHT_COLUMN_X, yRight,
    "Position, height, and scale for tank/healer icons.")
  yRight = yRight - 70

  H.CreatePositionControl(panel, "Pet Icon", "petIconPosition", "petIconOffsetY", "petIconScale", L.RIGHT_COLUMN_X, yRight,
    "Position, height, and scale for pet indicator.")
  yRight = yRight - 70

  H.CreatePositionControl(panel, "Cast Icon", "castIconPosition", "castIconOffsetY", "castIconScale", L.RIGHT_COLUMN_X, yRight,
    "Position, height, and scale for the cast spell icon.")
  yRight = yRight - 70

  H.CreatePositionControl(panel, "Healer Icon", "healerIconPosition", "healerIconOffsetY", "healerIconScale", L.RIGHT_COLUMN_X, yRight,
    "Position, height, and scale for healer indicator.")
  yRight = yRight - 70

  H.CreatePositionControl(panel, "CC Icon", "ccIconPosition", "ccIconOffsetY", "ccIconScale", L.RIGHT_COLUMN_X, yRight,
    "Position, height, and scale for crowd control indicator.")
  yRight = yRight - 70

  H.CreatePositionControl(panel, "Interrupt Shield", "interruptShieldPosition", "interruptShieldOffsetY", "interruptShieldScale", L.RIGHT_COLUMN_X, yRight,
    "Position, height, and scale for interrupt shield icon.")
  yRight = yRight - 70

  H.CreatePositionControl(panel, "Raid Marker", "raidMarkerPosition", "raidMarkerOffsetY", "raidMarkerScale", L.RIGHT_COLUMN_X, yRight,
    "Position, height, and scale for raid target markers.")
  yRight = yRight - 70

  H.CreatePositionControl(panel, "PvP Marker", "pvpMarkerPosition", "pvpMarkerOffsetY", "pvpMarkerScale", L.RIGHT_COLUMN_X, yRight,
    "Position, height, and scale for PvP markers.")
  yRight = yRight - 70

  H.CreatePositionControl(panel, "Quest Icon", "questIconPosition", "questIconOffsetY", "questIconScale", L.RIGHT_COLUMN_X, yRight,
    "Position, height, and scale for quest icon.")
  yRight = yRight - 70

  H.CreatePositionControl(panel, "World Quest Icon", "worldQuestIconPosition", "worldQuestIconOffsetY", "worldQuestIconScale", L.RIGHT_COLUMN_X, yRight,
    "Position, height, and scale for world quest icon.")
  yRight = yRight - 70

  H.CreatePositionControl(panel, "Bonus Objective Icon", "bonusObjectiveIconPosition", "bonusObjectiveIconOffsetY", "bonusObjectiveIconScale", L.RIGHT_COLUMN_X, yRight,
    "Position, height, and scale for bonus objective icon.")
  yRight = yRight - 70

  return panel
end

-- ============================================================================
-- TAB 4: ADVANCED (with sub-tabs)
-- ============================================================================
-- Sub-Tab 1: Positions (dropdown-based, cleaner layout)
local function CreateAdvancedPositionsSubTab_Simple(parent)
  local panel = CreateScrollablePanel(parent, 2200)
  local y = -10

  local intro = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  intro:SetPoint("TOPLEFT", L.LEFT_COLUMN_X, y)
  intro:SetText("Configure position for every nameplate element using dropdown menus.")
  intro:SetTextColor(0.7, 0.7, 0.7)
  intro:SetWidth(550)
  intro:SetJustifyH("LEFT")
  y = y - 35

  -- LEFT COLUMN - Text Elements
  H.CreateHeader(panel, "Text Elements", L.LEFT_COLUMN_X, y)
  y = y - 25

  H.CreateDropdown(panel, "Name", "namePosition", DROPDOWN_OPTIONS.Position, L.LEFT_COLUMN_X, y, 150, nil, "Position for name text.")
  y = y - 45

  H.CreateDropdown(panel, "Level", "levelPosition", DROPDOWN_OPTIONS.Position, L.LEFT_COLUMN_X, y, 150, nil, "Position for level text/icon.")
  y = y - 45

  H.CreateDropdown(panel, "Guild Text", "guildTextPosition", DROPDOWN_OPTIONS.Position, L.LEFT_COLUMN_X, y, 150, nil, "Position for player guild text.")
  y = y - 45

  H.CreateDropdown(panel, "Creature Text", "creatureTextPosition", DROPDOWN_OPTIONS.Position, L.LEFT_COLUMN_X, y, 150, nil, "Position for NPC titles/subtitles.")
  y = y - 45

  H.CreateDropdown(panel, "Unit Target Text", "unitTargetPosition", DROPDOWN_OPTIONS.Position, L.LEFT_COLUMN_X, y, 150, nil, "Position for 'Unit is targeting' text.")
  y = y - 45

  H.CreateDropdown(panel, "Cast Target Text", "castTargetPosition", DROPDOWN_OPTIONS.Position, L.LEFT_COLUMN_X, y, 150, nil, "Position for 'Casting at' text.")
  y = y - 50

  -- Icons & Markers
  H.CreateHeader(panel, "Icons & Markers", L.LEFT_COLUMN_X, y)
  y = y - 25

  H.CreateDropdown(panel, "Class Icon", "classIconPosition", DROPDOWN_OPTIONS.Position, L.LEFT_COLUMN_X, y, 150, nil, "Position for elite/rare icons.")
  y = y - 45

  H.CreateDropdown(panel, "Role Icon", "roleIconPosition", DROPDOWN_OPTIONS.Position, L.LEFT_COLUMN_X, y, 150, nil, "Position for tank/healer icons.")
  y = y - 45

  H.CreateDropdown(panel, "Pet Icon", "petIconPosition", DROPDOWN_OPTIONS.Position, L.LEFT_COLUMN_X, y, 150, nil, "Position for pet indicator.")
  y = y - 45

  H.CreateDropdown(panel, "Healer Icon", "healerIconPosition", DROPDOWN_OPTIONS.Position, L.LEFT_COLUMN_X, y, 150, nil, "Position for healer indicator.")
  y = y - 45

  H.CreateDropdown(panel, "CC Icon", "ccIconPosition", DROPDOWN_OPTIONS.Position, L.LEFT_COLUMN_X, y, 150, nil, "Position for crowd control indicator.")
  y = y - 45

  H.CreateDropdown(panel, "Interrupt Shield", "interruptShieldPosition", DROPDOWN_OPTIONS.Position, L.LEFT_COLUMN_X, y, 150, nil, "Position for interrupt shield icon.")
  y = y - 45

  H.CreateDropdown(panel, "Raid Marker", "raidMarkerPosition", DROPDOWN_OPTIONS.Position, L.LEFT_COLUMN_X, y, 150, nil, "Position for raid target markers.")
  y = y - 45

  H.CreateDropdown(panel, "PvP Marker", "pvpMarkerPosition", DROPDOWN_OPTIONS.Position, L.LEFT_COLUMN_X, y, 150, nil, "Position for PvP markers.")
  y = y - 45

  H.CreateDropdown(panel, "Quest Icon", "questIconPosition", DROPDOWN_OPTIONS.Position, L.LEFT_COLUMN_X, y, 150, nil, "Position for quest icon.")
  y = y - 45

  H.CreateDropdown(panel, "World Quest Icon", "worldQuestIconPosition", DROPDOWN_OPTIONS.Position, L.LEFT_COLUMN_X, y, 150, nil, "Position for world quest icon.")
  y = y - 45

  H.CreateDropdown(panel, "Bonus Objective Icon", "bonusObjectiveIconPosition", DROPDOWN_OPTIONS.Position, L.LEFT_COLUMN_X, y, 150, nil, "Position for bonus objective icon.")
  y = y - 50

  -- RIGHT COLUMN - Cast Elements
  local yRight = -35
  H.CreateHeader(panel, "Cast Elements", L.RIGHT_COLUMN_X, yRight)
  yRight = yRight - 25

  H.CreateDropdown(panel, "Cast Icon", "castIconPosition", DROPDOWN_OPTIONS.Position, L.RIGHT_COLUMN_X, yRight, 150, nil, "Position for the cast spell icon.")
  yRight = yRight - 45

  H.CreateDropdown(panel, "Cast Text", "castTextPosition", DROPDOWN_OPTIONS.Position, L.RIGHT_COLUMN_X, yRight, 150, nil, "Position for the cast text.")
  yRight = yRight - 45

  return panel
end

-- Sub-Tab 2: Fade & Effects
local function CreateAdvancedFadeSubTab(parent)
  local panel = CreateScrollablePanel(parent, 900)
  local y = -10

  local intro = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  intro:SetPoint("TOPLEFT", L.LEFT_COLUMN_X, y)
  intro:SetText("Advanced fade settings, visual effects, and classification scaling.")
  intro:SetTextColor(0.7, 0.7, 0.7)
  intro:SetWidth(550)
  intro:SetJustifyH("LEFT")
  y = y - 35

  -- LEFT COLUMN
  H.CreateHeader(panel, "Advanced Fade Settings", L.LEFT_COLUMN_X, y)
  y = y - 25

  H.CreateCheckbox(panel, "Only Fade When Targeted", "fadeOnlyWhenTargeted", L.LEFT_COLUMN_X, y, nil,
    "Only apply fading when you actually have a target selected.")
  y = y - L.OPTION_SPACING

  H.CreateCheckbox(panel, "Keep Focus Full Alpha", "keepFocusFullAlpha", L.LEFT_COLUMN_X, y, nil,
    "Don't fade your focus target even if it's not your current target.")
  y = y - L.OPTION_SPACING

  H.CreateCheckbox(panel, "Keep Casting Full Alpha", "keepCastingFullAlpha", L.LEFT_COLUMN_X, y, nil,
    "Keep units at full opacity when they're casting (important interrupts).")
  y = y - L.OPTION_SPACING + 10

  return panel
end

-- Sub-Tab 3: Stacking & Layout
local function CreateAdvancedStackingSubTab(parent)
  local panel = CreateScrollablePanel(parent, 600)
  local y = -10

  local intro = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  intro:SetPoint("TOPLEFT", L.LEFT_COLUMN_X, y)
  intro:SetText("Nameplate stacking, spacing, and additional unit information.")
  intro:SetTextColor(0.7, 0.7, 0.7)
  intro:SetWidth(550)
  intro:SetJustifyH("LEFT")
  y = y - 35

  -- LEFT COLUMN
  H.CreateHeader(panel, "Nameplate Stacking", L.LEFT_COLUMN_X, y)
  y = y - 25

  H.CreateSlider(panel, "Vertical Overlap", "nameplateOverlapV", 0.05, 1.1, 0.05, L.LEFT_COLUMN_X, y,
    function() MP.Config.ApplyStackingCVars() end,
    "Controls how tightly nameplates stack vertically (lower = tighter).", function(val) return string.format("%.2f", val) end)
  y = y - 50

  H.CreateSlider(panel, "Horizontal Overlap", "nameplateOverlapH", 0.05, 1.0, 0.05, L.LEFT_COLUMN_X, y,
    function() MP.Config.ApplyStackingCVars() end,
    "Controls horizontal nameplate spacing.", function(val) return string.format("%.2f", val) end)
  y = y - 60

  return panel
end

-- Sub-Tab 4: Accessibility
local function CreateAdvancedAccessibilitySubTab(parent)
  local panel = CreateScrollablePanel(parent, 400)
  local y = -10

  local intro = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  intro:SetPoint("TOPLEFT", L.LEFT_COLUMN_X, y)
  intro:SetText("Accessibility options for easier interaction with nameplates.")
  intro:SetTextColor(0.7, 0.7, 0.7)
  intro:SetWidth(550)
  intro:SetJustifyH("LEFT")
  y = y - 35

  H.CreateHeader(panel, "Accessibility", L.LEFT_COLUMN_X, y)
  y = y - 25

  H.CreateCheckbox(panel, "Expanded Click Area", "expandedClickArea", L.LEFT_COLUMN_X, y, nil,
    "Larger clickable area for easier targeting.")
  y = y - L.OPTION_SPACING

  H.CreateCheckbox(panel, "Show Soft-Target Icon", "showSoftTargetIcon", L.LEFT_COLUMN_X, y, nil,
    "Show gamepad/controller soft-target cursor.")
  y = y - L.OPTION_SPACING + 10

  return panel
end

-- Main Advanced Tab (with sub-tabs)
local function CreateAdvancedTab(parent)
  local container = CreateFrame("Frame", nil, parent)
  container:SetAllPoints()
  container:Hide()

  -- Sub-tab buttons
  local subTabs = {
    {name = "Positions", panel = nil, createFunc = CreateAdvancedPositionsSubTab},
    {name = "Fade & Effects", panel = nil, createFunc = CreateAdvancedFadeSubTab},
    {name = "Stacking", panel = nil, createFunc = CreateAdvancedStackingSubTab},
    {name = "Accessibility", panel = nil, createFunc = CreateAdvancedAccessibilitySubTab},
  }

  local subTabButtons = {}
  local subTabWidth = 100

  for i, subTab in ipairs(subTabs) do
    local btn = CreateFrame("Button", nil, container, "UIPanelButtonTemplate")
    btn:SetSize(subTabWidth, 25)
    btn:SetPoint("TOPLEFT", 10 + (i - 1) * (subTabWidth + 5), -80)
    btn:SetText(subTab.name)
    subTabButtons[i] = btn

    btn:SetScript("OnClick", function()
      -- Hide all sub-tab panels
      for j, st in ipairs(subTabs) do
        if st.panel then
          st.panel:Hide()
          if st.panel.scrollFrame then st.panel.scrollFrame:Hide() end
        end
        subTabButtons[j]:Enable()
      end

      -- Create panel if needed
      if not subTab.panel then
        subTab.panel = subTab.createFunc(container)
        if subTab.panel.scrollFrame then
          subTab.panel.scrollFrame:ClearAllPoints()
          subTab.panel.scrollFrame:SetPoint("TOPLEFT", 10, -115)
          subTab.panel.scrollFrame:SetPoint("BOTTOMRIGHT", -26, 10)
        end
      end

      -- Show this panel
      subTab.panel:Show()
      if subTab.panel.scrollFrame then
        subTab.panel.scrollFrame:Show()
      end
      btn:Disable()
    end)
  end

  -- Show first sub-tab by default
  if subTabs[1] then
    subTabs[1].panel = subTabs[1].createFunc(container)
    if subTabs[1].panel.scrollFrame then
      subTabs[1].panel.scrollFrame:ClearAllPoints()
      subTabs[1].panel.scrollFrame:SetPoint("TOPLEFT", 10, -115)
      subTabs[1].panel.scrollFrame:SetPoint("BOTTOMRIGHT", -26, 10)
    end
    subTabs[1].panel:Show()
    if subTabs[1].panel.scrollFrame then
      subTabs[1].panel.scrollFrame:Show()
    end
    subTabButtons[1]:Disable()
  end

  return container
end

-- ============================================================================
-- TAB 5: PROFILES & THEMES
-- ============================================================================
local function CreateProfilesTab(parent)
  local panel = CreatePanel(parent)
  local y = -10

  H.CreateHeader(panel, "Profile Management", L.LEFT_COLUMN_X, y)
  y = y - 30

  -- Current profile display
  local currentProfileLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  currentProfileLabel:SetPoint("TOPLEFT", L.LEFT_COLUMN_X, y)
  currentProfileLabel:SetText("Current Profile: " .. MP.Profiles.GetCurrentProfile())
  y = y - 30

  -- Profile dropdown
  local profileDropdown = CreateFrame("Frame", "MPProfileDropdown", panel, "UIDropDownMenuTemplate")
  profileDropdown:SetPoint("TOPLEFT", L.LEFT_COLUMN_X, y + 5)
  UIDropDownMenu_SetWidth(profileDropdown, 150)

  local function UpdateProfileDropdown()
    UIDropDownMenu_Initialize(profileDropdown, function(self, level)
      local profiles = MP.Profiles.GetProfileList()
      for _, profileName in ipairs(profiles) do
        local info = UIDropDownMenu_CreateInfo()
        info.text = profileName
        info.func = function()
          MP.Profiles.LoadProfile(profileName)
          UIDropDownMenu_SetText(profileDropdown, profileName)
          currentProfileLabel:SetText("Current Profile: " .. profileName)
        end
        info.checked = MP.Profiles.GetCurrentProfile() == profileName
        UIDropDownMenu_AddButton(info, level)
      end
    end)
    UIDropDownMenu_SetText(profileDropdown, MP.Profiles.GetCurrentProfile())
  end
  UpdateProfileDropdown()
  y = y - 40

  -- Profile action buttons
  local saveBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  saveBtn:SetSize(92, 25)
  saveBtn:SetPoint("TOPLEFT", L.LEFT_COLUMN_X, y)
  saveBtn:SetText("Save")
  saveBtn:SetScript("OnClick", function()
    MP.Profiles.SaveProfile(MP.Profiles.GetCurrentProfile())
  end)

  local newBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  newBtn:SetSize(92, 25)
  newBtn:SetPoint("LEFT", saveBtn, "RIGHT", 10, 0)
  newBtn:SetText("New")
  newBtn:SetScript("OnClick", function()
    StaticPopup_Show("MP_NEW_PROFILE")
  end)

  local copyBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  copyBtn:SetSize(92, 25)
  copyBtn:SetPoint("LEFT", newBtn, "RIGHT", 10, 0)
  copyBtn:SetText("Copy")
  copyBtn:SetScript("OnClick", function()
    StaticPopup_Show("MP_COPY_PROFILE")
  end)

  y = y - 35

  local deleteBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  deleteBtn:SetSize(92, 25)
  deleteBtn:SetPoint("TOPLEFT", L.LEFT_COLUMN_X, y)
  deleteBtn:SetText("Delete")
  deleteBtn:SetScript("OnClick", function()
    StaticPopup_Show("MP_DELETE_PROFILE")
  end)

  local renameBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  renameBtn:SetSize(92, 25)
  renameBtn:SetPoint("LEFT", deleteBtn, "RIGHT", 10, 0)
  renameBtn:SetText("Rename")
  renameBtn:SetScript("OnClick", function()
    StaticPopup_Show("MP_RENAME_PROFILE")
  end)

  local resetBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  resetBtn:SetSize(92, 25)
  resetBtn:SetPoint("LEFT", renameBtn, "RIGHT", 10, 0)
  resetBtn:SetText("Reset")
  resetBtn:SetScript("OnClick", function()
    StaticPopup_Show("MP_RESET_PROFILE")
  end)

  y = y - 50

  -- Import/Export section
  H.CreateHeader(panel, "Import/Export", L.LEFT_COLUMN_X, y)
  y = y - 30

  local exportBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  exportBtn:SetSize(140, 25)
  exportBtn:SetPoint("TOPLEFT", L.LEFT_COLUMN_X, y)
  exportBtn:SetText("Export Profile")
  exportBtn:SetScript("OnClick", function()
    local exported = MP.Profiles.ExportProfile(MP.Profiles.GetCurrentProfile())
    if exported then
      StaticPopup_Show("MP_EXPORT_PROFILE", nil, nil, exported)
    end
  end)

  local importBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  importBtn:SetSize(140, 25)
  importBtn:SetPoint("LEFT", exportBtn, "RIGHT", 10, 0)
  importBtn:SetText("Import Profile")
  importBtn:SetScript("OnClick", function()
    StaticPopup_Show("MP_IMPORT_PROFILE")
  end)

  return panel
end

-- ============================================================================
-- MAIN SETTINGS FRAME
-- ============================================================================
function MP.Settings.CreateStandaloneUI()
  -- CreateStandaloneUI called

  if SettingsFrame then
    -- Reusing existing SettingsFrame
    SettingsFrame:Show()
    return
  end

  -- Creating new SettingsFrame

  -- Main frame (wider to accommodate preview panel)
  SettingsFrame = CreateFrame("Frame", "MinimalPlatesSettingsFrame", UIParent, "BackdropTemplate")
  SettingsFrame:SetSize(1100, 560)
  SettingsFrame:SetPoint("CENTER")
  SettingsFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 8, right = 8, top = 8, bottom = 8 }
  })
  SettingsFrame:SetBackdropColor(0, 0, 0, 0.9)
  SettingsFrame:EnableMouse(true)
  SettingsFrame:SetMovable(true)
  SettingsFrame:RegisterForDrag("LeftButton")
  SettingsFrame:SetScript("OnDragStart", SettingsFrame.StartMoving)
  SettingsFrame:SetScript("OnDragStop", SettingsFrame.StopMovingOrSizing)
  SettingsFrame:SetFrameStrata("DIALOG")
  SettingsFrame:SetClampedToScreen(true)

  -- Preview Panel on the right
  local previewPanel = CreateFrame("Frame", nil, SettingsFrame, "BackdropTemplate")
  previewPanel:SetPoint("TOPRIGHT", -15, -75)
  previewPanel:SetSize(260, 470)
  previewPanel:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
  })
  previewPanel:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
  previewPanel:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

  local previewTitle = previewPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  previewTitle:SetPoint("TOP", 0, -8)
  previewTitle:SetText("Preview")
  previewTitle:SetTextColor(1, 0.82, 0)

  -- Store reference for later updates
  SettingsFrame.previewPanel = previewPanel

  -- Title
  local title = SettingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOP", 0, -15)
  title:SetText("MinimalPlates Settings")

  -- Close button
  local closeBtn = CreateFrame("Button", nil, SettingsFrame, "UIPanelCloseButton")
  closeBtn:SetPoint("TOPRIGHT", -5, -5)

  -- Tab definitions (Icons merged with Positioning for better UX)
  local tabs = {
    {name = "General", panel = nil, createFunc = CreateGeneralTab},
    {name = "Appearance", panel = nil, createFunc = CreateAppearanceTab},
    -- Icons & Layout tab removed - redundant with Advanced tab
    {name = "Advanced", panel = nil, createFunc = CreateAdvancedTab},
    {name = "Profiles", panel = nil, createFunc = CreateProfilesTab}
  }

  local tabButtons = {}

  -- Create tab buttons
  for i, tab in ipairs(tabs) do
    local btn = CreateFrame("Button", nil, SettingsFrame, "UIPanelButtonTemplate")
    btn:SetSize(L.TAB_WIDTH, 25)
    btn:SetPoint("TOPLEFT", 10 + ((i-1) * (L.TAB_WIDTH + 8)), -45)
    btn:SetText(tab.name)
    btn.tabIndex = i

    btn:SetScript("OnClick", function(self)
      -- Hide all panels AND their scroll frames
      for _, t in ipairs(tabs) do
        if t.panel then
          t.panel:Hide()
          -- Also hide the scrollFrame if it exists
          if t.panel.scrollFrame then
            t.panel.scrollFrame:Hide()
          end
        end
      end
      -- Show selected panel AND its scroll frame
      if tabs[self.tabIndex].panel then
        tabs[self.tabIndex].panel:Show()
        -- Also show the scrollFrame if it exists
        if tabs[self.tabIndex].panel.scrollFrame then
          tabs[self.tabIndex].panel.scrollFrame:Show()
        end
      end
      -- Update button states
      for _, b in ipairs(tabButtons) do
        if b == self then
          b:Disable()
        else
          b:Enable()
        end
      end
    end)

    tabButtons[i] = btn
  end

  -- Create panels
  for i, tab in ipairs(tabs) do
    tabs[i].panel = tab.createFunc(SettingsFrame)
  end

  -- Hide all panels first
  for i, tab in ipairs(tabs) do
    if tab.panel then
      tab.panel:Hide()
      if tab.panel.scrollFrame then
        tab.panel.scrollFrame:Hide()
      end
    end
  end

  -- Show first tab by default
  if tabs[1].panel then
    tabs[1].panel:Show()
    if tabs[1].panel.scrollFrame then
      tabs[1].panel.scrollFrame:Show()
    end
  end
  tabButtons[1]:Disable()

  -- Create preview nameplates with ALL Advanced tab elements
  local function CreatePreviewNameplate(parent, yOffset, isEnemy, isPlayer, unitName, healthPct)
    local plate = CreateFrame("Frame", nil, parent)
    plate:SetSize(220, 120)  -- Increased to show cast bars + power bars
    plate:SetPoint("TOP", 0, yOffset)

    local mode
    if isEnemy then
      mode = isPlayer and (MP.DB.enemyPlayerMode or "bar") or (MP.DB.enemyNPCMode or "bar")
    else
      mode = isPlayer and (MP.DB.friendlyPlayerMode or "text") or (MP.DB.friendlyNPCMode or "text")
    end

    local font, size, flags = MP.Config.GetFont()

    if mode == "bar" then
      -- Health bar
      local health = CreateFrame("StatusBar", nil, plate)
      health:SetPoint("CENTER", 0, 0)
      health:SetSize(MP.DB.healthWidth or 120, MP.DB.healthHeight or 8)
      health:SetStatusBarTexture(MP.Config.GetBarTexture())
      health:SetMinMaxValues(0, 100)
      health:SetValue(healthPct)
      health:SetStatusBarColor(isEnemy and 1 or 0, isEnemy and 0 or 1, 0)

      local bg = health:CreateTexture(nil, "BACKGROUND")
      bg:SetAllPoints(health)
      bg:SetColorTexture(0, 0, 0, 0.5)

      local border = CreateFrame("Frame", nil, plate, "BackdropTemplate")
      border:SetPoint("TOPLEFT", health, -1, 1)
      border:SetPoint("BOTTOMRIGHT", health, 1, -1)
      border:SetBackdrop({edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
      border:SetBackdropBorderColor(0, 0, 0, 1)

      -- Name text
      local name = health:CreateFontString(nil, "OVERLAY")
      name:SetPoint("BOTTOM", health, "TOP", 0, MP.DB.nameYOffset or 4)
      name:SetFont(font, size, flags)
      name:SetText(unitName)
      name:SetTextColor(1, 1, 1)
      plate.Name = name

      -- Level (enemies only)
      if isEnemy and MP.DB.showLevel then
        local level = plate:CreateFontString(nil, "OVERLAY")
        level:SetFont(font, size * (MP.DB.levelIconScale or 1.5), flags)
        level:SetPoint("RIGHT", health, "LEFT", -4, 0)
        level:SetText("??")
        level:SetTextColor(1, 0.3, 0.3)
      end

      -- Elite/Rare icons
      if MP.DB.showEliteBorder and isEnemy then
        local icon = plate:CreateTexture(nil, "OVERLAY")
        icon:SetSize(16, 16)
        icon:SetPoint("LEFT", name, "RIGHT", 2, 0)
        icon:SetTexture(isPlayer and "Interface\\AddOns\\MinimalPlates\\Libs\\Icons\\rareelite.png"
                                 or "Interface\\AddOns\\MinimalPlates\\Libs\\Icons\\elite.png")
      end

      -- Quest icon
      if MP.DB.showQuestIcon and not isPlayer then
        local quest = plate:CreateTexture(nil, "OVERLAY")
        quest:SetTexture("Interface/Nameplates/UI-Nameplate-QuestIcon")
        quest:SetSize(MP.DB.questIconSize or 16, MP.DB.questIconSize or 16)
        quest:SetPoint("LEFT", name, "RIGHT", MP.DB.showEliteBorder and 20 or 4, 0)
      end

      -- Raid marker
      if MP.DB.showRaidMarker then
        local marker = plate:CreateTexture(nil, "OVERLAY")
        marker:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
        marker:SetSize(MP.DB.raidMarkerSize or 24, MP.DB.raidMarkerSize or 24)
        marker:SetPoint("BOTTOM", health, "TOP", 0, (MP.DB.nameYOffset or 4) + size + 10)
        SetRaidTargetIconTexture(marker, 8)  -- Skull
      end

      -- Guild/Creature text
      if isPlayer and MP.DB.showGuildText then
        local guild = plate:CreateFontString(nil, "OVERLAY")
        guild:SetFont(font, size - 2, flags)
        guild:SetPoint("TOP", name, "BOTTOM", 0, -2)
        guild:SetText("<Guild>")
        guild:SetTextColor(0.5, 1, 0.5)
      elseif not isPlayer and MP.DB.showCreatureText then
        local creature = plate:CreateFontString(nil, "OVERLAY")
        creature:SetFont(font, size - 2, flags)
        creature:SetPoint("TOP", name, "BOTTOM", 0, -2)
        creature:SetText("<Title>")
        creature:SetTextColor(0.9, 0.9, 0.9)
      end

      -- Cast bar
      if MP.DB.showCastBar then
        local cast = CreateFrame("StatusBar", nil, plate)
        cast:SetPoint("TOP", health, "BOTTOM", 0, MP.DB.castYOffset or -2)
        cast:SetSize(MP.DB.healthWidth or 120, MP.DB.castHeight or 8)
        cast:SetStatusBarTexture(MP.Config.GetBarTexture())
        cast:SetStatusBarColor(1, 0.7, 0)
        cast:SetMinMaxValues(0, 1)
        cast:SetValue(0.6)

        local castBorder = CreateFrame("Frame", nil, plate, "BackdropTemplate")
        castBorder:SetPoint("TOPLEFT", cast, -1, 1)
        castBorder:SetPoint("BOTTOMRIGHT", cast, 1, -1)
        castBorder:SetBackdrop({edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
        castBorder:SetBackdropBorderColor(0, 0, 0, 1)

        if MP.DB.showCastIcon then
          local icon = plate:CreateTexture(nil, "ARTWORK")
          icon:SetSize(MP.DB.castHeight + 4, MP.DB.castHeight + 4)
          icon:SetPoint("RIGHT", cast, "LEFT", -2, 0)
          icon:SetTexture("Interface\\Icons\\Spell_Fire_FlameBolt")
          icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
        end
      end

      -- Power bar
      if MP.DB.showPowerBar and isEnemy then
        local castHeight = MP.DB.showCastBar and (MP.DB.castHeight or 8) or 0
        local castOffset = MP.DB.showCastBar and (MP.DB.castYOffset or -2) or 0
        local power = CreateFrame("StatusBar", nil, plate)
        power:SetPoint("TOP", health, "BOTTOM", 0, castOffset - castHeight - 2)
        power:SetSize(MP.DB.healthWidth or 120, 3)
        power:SetStatusBarTexture(MP.Config.GetBarTexture())
        power:SetStatusBarColor(0, 0.5, 1)
        power:SetMinMaxValues(0, 100)
        power:SetValue(80)

        local powerBorder = CreateFrame("Frame", nil, plate, "BackdropTemplate")
        powerBorder:SetPoint("TOPLEFT", power, -1, 1)
        powerBorder:SetPoint("BOTTOMRIGHT", power, 1, -1)
        powerBorder:SetBackdrop({edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
        powerBorder:SetBackdropBorderColor(0, 0, 0, 1)
      end

      -- Health text
      if MP.DB.showHealthText then
        local healthText = health:CreateFontString(nil, "OVERLAY")
        healthText:SetPoint("CENTER", health, 0, 0)
        healthText:SetFont(font, size, flags)
        healthText:SetText(string.format("%d%%", healthPct))
        healthText:SetTextColor(1, 1, 1)
      end

      plate.Health = health
    elseif mode == "text" then
      local name = plate:CreateFontString(nil, "OVERLAY")
      name:SetPoint("CENTER", 0, 0)
      name:SetFont(font, size, flags)
      name:SetText(unitName)
      name:SetTextColor(isEnemy and 1 or 0, isEnemy and 0 or 1, 0)
      plate.Name = name
    elseif mode == "hide" then
      local name = plate:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
      name:SetPoint("CENTER", 0, 0)
      name:SetFont(font, size - 2, flags)
      name:SetText("(Hidden)")
      name:SetTextColor(0.5, 0.5, 0.5)
    end

    return plate
  end

  -- Create 4 preview plates showing all display mode combinations (increased spacing for new height)
  local enemyPlayerPlate = CreatePreviewNameplate(previewPanel, -40, true, true, "Enemy Player", 75)
  local enemyNPCPlate = CreatePreviewNameplate(previewPanel, -170, true, false, "Enemy NPC", 85)
  local friendlyPlayerPlate = CreatePreviewNameplate(previewPanel, -300, false, true, "Friendly Player", 100)
  local friendlyNPCPlate = CreatePreviewNameplate(previewPanel, -430, false, false, "Friendly NPC", 95)

  -- Store references for updates
  SettingsFrame.previewPlates = {enemyPlayerPlate, enemyNPCPlate, friendlyPlayerPlate, friendlyNPCPlate}

  -- CRITICAL: Clean up preview frames when settings window closes to prevent memory leaks
  SettingsFrame:SetScript("OnHide", function(self)
    if self.previewPlates then
      for _, plate in ipairs(self.previewPlates) do
        if plate.Health then
          plate.Health:Hide()
          plate.Health:SetParent(nil)
        end
        if plate.Cast then
          plate.Cast:Hide()
          plate.Cast:SetParent(nil)
        end
        if plate.PowerBar then
          plate.PowerBar:Hide()
          plate.PowerBar:SetParent(nil)
        end
        plate:Hide()
        plate:SetParent(nil)
      end
      wipe(self.previewPlates)
    end
  end)

  SettingsFrame:Show()
end

-- Refresh preview nameplates when settings change
function MP.Settings.RefreshPreview()
  if not SettingsFrame or not SettingsFrame:IsShown() or not SettingsFrame.previewPlates then
    return
  end

  -- Debug: Print to verify refresh is being called
  print("[MinimalPlates] Preview refreshing...")

  -- Properly destroy old preview plates to prevent memory leaks
  for _, plate in ipairs(SettingsFrame.previewPlates) do
    -- Explicitly destroy child frames created in CreatePreviewNameplate
    if plate.Health then
      plate.Health:Hide()
      plate.Health:SetParent(nil)
    end
    if plate.Cast then
      plate.Cast:Hide()
      plate.Cast:SetParent(nil)
    end
    if plate.PowerBar then
      plate.PowerBar:Hide()
      plate.PowerBar:SetParent(nil)
    end
    -- Hide and unparent the main plate frame
    plate:Hide()
    plate:SetParent(nil)
  end
  wipe(SettingsFrame.previewPlates)

  local previewPanel = SettingsFrame.previewPanel
  if not previewPanel then return end

  -- Create new preview nameplates with ALL Advanced tab elements
  local function CreatePreviewNameplate(parent, yOffset, isEnemy, isPlayer, unitName, healthPct)
    local plate = CreateFrame("Frame", nil, parent)
    plate:SetSize(220, 120)  -- Increased to show cast bars + power bars
    plate:SetPoint("TOP", 0, yOffset)

    local mode
    if isEnemy then
      mode = isPlayer and (MP.DB.enemyPlayerMode or "bar") or (MP.DB.enemyNPCMode or "bar")
    else
      mode = isPlayer and (MP.DB.friendlyPlayerMode or "text") or (MP.DB.friendlyNPCMode or "text")
    end

    local font, size, flags = MP.Config.GetFont()

    if mode == "bar" then
      -- Health bar
      local health = CreateFrame("StatusBar", nil, plate)
      health:SetPoint("CENTER", 0, 0)
      health:SetSize(MP.DB.healthWidth or 120, MP.DB.healthHeight or 8)
      health:SetStatusBarTexture(MP.Config.GetBarTexture())
      health:SetMinMaxValues(0, 100)
      health:SetValue(healthPct)
      health:SetStatusBarColor(isEnemy and 1 or 0, isEnemy and 0 or 1, 0)

      local bg = health:CreateTexture(nil, "BACKGROUND")
      bg:SetAllPoints(health)
      bg:SetColorTexture(0, 0, 0, 0.5)

      local border = CreateFrame("Frame", nil, plate, "BackdropTemplate")
      border:SetPoint("TOPLEFT", health, -1, 1)
      border:SetPoint("BOTTOMRIGHT", health, 1, -1)
      border:SetBackdrop({edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
      border:SetBackdropBorderColor(0, 0, 0, 1)

      -- Name text
      local name = health:CreateFontString(nil, "OVERLAY")
      name:SetPoint("BOTTOM", health, "TOP", 0, MP.DB.nameYOffset or 4)
      name:SetFont(font, size, flags)
      name:SetText(unitName)
      name:SetTextColor(1, 1, 1)
      plate.Name = name

      -- Level (enemies only)
      if isEnemy and MP.DB.showLevel then
        local level = plate:CreateFontString(nil, "OVERLAY")
        level:SetFont(font, size * (MP.DB.levelIconScale or 1.5), flags)
        level:SetPoint("RIGHT", health, "LEFT", -4, 0)
        level:SetText("??")
        level:SetTextColor(1, 0.3, 0.3)
      end

      -- Elite/Rare icons
      if MP.DB.showEliteBorder and isEnemy then
        local icon = plate:CreateTexture(nil, "OVERLAY")
        icon:SetSize(16, 16)
        icon:SetPoint("LEFT", name, "RIGHT", 2, 0)
        icon:SetTexture(isPlayer and "Interface\\AddOns\\MinimalPlates\\Libs\\Icons\\rareelite.png"
                                 or "Interface\\AddOns\\MinimalPlates\\Libs\\Icons\\elite.png")
      end

      -- Quest icon
      if MP.DB.showQuestIcon and not isPlayer then
        local quest = plate:CreateTexture(nil, "OVERLAY")
        quest:SetTexture("Interface/Nameplates/UI-Nameplate-QuestIcon")
        quest:SetSize(MP.DB.questIconSize or 16, MP.DB.questIconSize or 16)
        quest:SetPoint("LEFT", name, "RIGHT", MP.DB.showEliteBorder and 20 or 4, 0)
      end

      -- Raid marker
      if MP.DB.showRaidMarker then
        local marker = plate:CreateTexture(nil, "OVERLAY")
        marker:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
        marker:SetSize(MP.DB.raidMarkerSize or 24, MP.DB.raidMarkerSize or 24)
        marker:SetPoint("BOTTOM", health, "TOP", 0, (MP.DB.nameYOffset or 4) + size + 10)
        SetRaidTargetIconTexture(marker, 8)  -- Skull
      end

      -- Guild/Creature text
      if isPlayer and MP.DB.showGuildText then
        local guild = plate:CreateFontString(nil, "OVERLAY")
        guild:SetFont(font, size - 2, flags)
        guild:SetPoint("TOP", name, "BOTTOM", 0, -2)
        guild:SetText("<Guild>")
        guild:SetTextColor(0.5, 1, 0.5)
      elseif not isPlayer and MP.DB.showCreatureText then
        local creature = plate:CreateFontString(nil, "OVERLAY")
        creature:SetFont(font, size - 2, flags)
        creature:SetPoint("TOP", name, "BOTTOM", 0, -2)
        creature:SetText("<Title>")
        creature:SetTextColor(0.9, 0.9, 0.9)
      end

      -- Cast bar
      if MP.DB.showCastBar then
        local cast = CreateFrame("StatusBar", nil, plate)
        cast:SetPoint("TOP", health, "BOTTOM", 0, MP.DB.castYOffset or -2)
        cast:SetSize(MP.DB.healthWidth or 120, MP.DB.castHeight or 8)
        cast:SetStatusBarTexture(MP.Config.GetBarTexture())
        cast:SetStatusBarColor(1, 0.7, 0)
        cast:SetMinMaxValues(0, 1)
        cast:SetValue(0.6)

        local castBorder = CreateFrame("Frame", nil, plate, "BackdropTemplate")
        castBorder:SetPoint("TOPLEFT", cast, -1, 1)
        castBorder:SetPoint("BOTTOMRIGHT", cast, 1, -1)
        castBorder:SetBackdrop({edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
        castBorder:SetBackdropBorderColor(0, 0, 0, 1)

        if MP.DB.showCastIcon then
          local icon = plate:CreateTexture(nil, "ARTWORK")
          icon:SetSize(MP.DB.castHeight + 4, MP.DB.castHeight + 4)
          icon:SetPoint("RIGHT", cast, "LEFT", -2, 0)
          icon:SetTexture("Interface\\Icons\\Spell_Fire_FlameBolt")
          icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
        end
      end

      -- Power bar
      if MP.DB.showPowerBar and isEnemy then
        local castHeight = MP.DB.showCastBar and (MP.DB.castHeight or 8) or 0
        local castOffset = MP.DB.showCastBar and (MP.DB.castYOffset or -2) or 0
        local power = CreateFrame("StatusBar", nil, plate)
        power:SetPoint("TOP", health, "BOTTOM", 0, castOffset - castHeight - 2)
        power:SetSize(MP.DB.healthWidth or 120, 3)
        power:SetStatusBarTexture(MP.Config.GetBarTexture())
        power:SetStatusBarColor(0, 0.5, 1)
        power:SetMinMaxValues(0, 100)
        power:SetValue(80)

        local powerBorder = CreateFrame("Frame", nil, plate, "BackdropTemplate")
        powerBorder:SetPoint("TOPLEFT", power, -1, 1)
        powerBorder:SetPoint("BOTTOMRIGHT", power, 1, -1)
        powerBorder:SetBackdrop({edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
        powerBorder:SetBackdropBorderColor(0, 0, 0, 1)
      end

      -- Health text
      if MP.DB.showHealthText then
        local healthText = health:CreateFontString(nil, "OVERLAY")
        healthText:SetPoint("CENTER", health, 0, 0)
        healthText:SetFont(font, size, flags)
        healthText:SetText(string.format("%d%%", healthPct))
        healthText:SetTextColor(1, 1, 1)
      end

      plate.Health = health
    elseif mode == "text" then
      local name = plate:CreateFontString(nil, "OVERLAY")
      name:SetPoint("CENTER", 0, 0)
      name:SetFont(font, size, flags)
      name:SetText(unitName)
      name:SetTextColor(isEnemy and 1 or 0, isEnemy and 0 or 1, 0)
      plate.Name = name
    elseif mode == "hide" then
      local name = plate:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
      name:SetPoint("CENTER", 0, 0)
      name:SetFont(font, size - 2, flags)
      name:SetText("(Hidden)")
      name:SetTextColor(0.5, 0.5, 0.5)
    end

    return plate
  end

  -- Create 4 preview plates (increased spacing for new height)
  local enemyPlayerPlate = CreatePreviewNameplate(previewPanel, -40, true, true, "Enemy Player", 75)
  local enemyNPCPlate = CreatePreviewNameplate(previewPanel, -170, true, false, "Enemy NPC", 85)
  local friendlyPlayerPlate = CreatePreviewNameplate(previewPanel, -300, false, true, "Friendly Player", 100)
  local friendlyNPCPlate = CreatePreviewNameplate(previewPanel, -430, false, false, "Friendly NPC", 95)

  -- Update stored references
  SettingsFrame.previewPlates = {enemyPlayerPlate, enemyNPCPlate, friendlyPlayerPlate, friendlyNPCPlate}
end
