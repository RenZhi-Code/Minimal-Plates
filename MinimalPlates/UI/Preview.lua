---@class MinimalPlates
local MP = MinimalPlates

-- ===== TEMPORARILY DISABLED FOR TESTING =====
-- Preview panel commented out to focus on core performance testing
do return end

MP.Preview = {}

local PreviewFrame = nil
local previewPlates = {}
local widgets = {} -- All draggable widgets
local selectedWidgets = {}
local isDragging = false
local snapThreshold = 5 -- Pixel threshold for snapping

-- Expose preview plates for theme capture
function MP.Preview.GetPreviewPlate(i)
  return previewPlates[i]
end

-- Helper: Round to nearest integer
local function Round(num)
  return math.floor(num + 0.5)
end

-- Helper: Check if widget is selected
local function IsSelected(widget)
  for _, w in ipairs(selectedWidgets) do
    if w == widget then return true end
  end
  return false
end

-- Helper: Toggle selection
local function ToggleSelection(widget)
  if IsShiftKeyDown() then
    -- Multi-select with shift
    if IsSelected(widget) then
      -- Remove from selection
      for i, w in ipairs(selectedWidgets) do
        if w == widget then
          table.remove(selectedWidgets, i)
          break
        end
      end
    else
      -- Add to selection
      table.insert(selectedWidgets, widget)
    end
  else
    -- Single select
    if IsSelected(widget) and #selectedWidgets == 1 then
      -- Deselect if only one selected and clicking it again
      selectedWidgets = {}
    else
      selectedWidgets = {widget}
    end
  end
  UpdateSelectionVisuals()
end

-- Update selection visuals
function UpdateSelectionVisuals()
  -- Clear all selection borders
  for _, widget in ipairs(widgets) do
    if widget.selectionBorder then
      widget.selectionBorder:Hide()
    end
  end
  
  -- Show selection borders on selected widgets
  for _, widget in ipairs(selectedWidgets) do
    if not widget.selectionBorder then
      widget.selectionBorder = CreateFrame("Frame", nil, widget, "BackdropTemplate")
      widget.selectionBorder:SetAllPoints()
      widget.selectionBorder:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 2,
      })
      widget.selectionBorder:SetBackdropBorderColor(0, 1, 1, 1) -- Cyan selection
      widget.selectionBorder:SetFrameLevel(widget:GetFrameLevel() + 10)
    end
    widget.selectionBorder:Show()
  end
end

-- Snap position to grid or center
local function SnapPosition(x, y, parentWidth, parentHeight)
  local centerX = parentWidth / 2
  local centerY = parentHeight / 2
  
  local snappedX = x
  local snappedY = y
  
  -- Snap to center horizontally
  if math.abs(x - centerX) < snapThreshold then
    snappedX = centerX
  end
  
  -- Snap to center vertically
  if math.abs(y - centerY) < snapThreshold then
    snappedY = centerY
  end
  
  -- Snap to edges
  if math.abs(x) < snapThreshold then
    snappedX = 0
  elseif math.abs(x - parentWidth) < snapThreshold then
    snappedX = parentWidth
  end
  
  if math.abs(y) < snapThreshold then
    snappedY = 0
  elseif math.abs(y - parentHeight) < snapThreshold then
    snappedY = parentHeight
  end
  
  return Round(snappedX), Round(snappedY)
end

-- Make widget draggable
local function MakeWidgetDraggable(widget, widgetName)
  widget.widgetName = widgetName

  -- Create a draggable overlay handle for non-frame widgets (FontString/Texture)
  local handle = widget.dragHandle
  if not handle then
    handle = CreateFrame("Frame", nil, widget:GetParent(), "BackdropTemplate")
    handle:SetAllPoints(widget)
    handle:EnableMouse(true)
    handle:SetFrameLevel(widget:GetFrameLevel() + 5)
    widget.dragHandle = handle
  end

  handle:SetMovable(true)
  
  local startX, startY
  local cursorStartX, cursorStartY
  local offsets = {} -- Track offsets for multi-select
  
  handle:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" then
      -- Select this widget
      if not IsSelected(widget) then
        ToggleSelection(widget)
      end
      
      -- Start dragging
      isDragging = true
      cursorStartX, cursorStartY = GetCursorPosition()
      local scale = self:GetEffectiveScale()
      cursorStartX = cursorStartX / scale
      cursorStartY = cursorStartY / scale
      
      -- Store starting positions for all selected widgets
      offsets = {}
      for _, w in ipairs(selectedWidgets) do
        local point, relativeTo, relativePoint, xOfs, yOfs = w:GetPoint()
        offsets[w] = {x = xOfs or 0, y = yOfs or 0, point = point, relativePoint = relativePoint}
      end
      
      self:SetScript("OnUpdate", function()
        if isDragging then
          local cursorX, cursorY = GetCursorPosition()
          local scale = self:GetEffectiveScale()
          cursorX = cursorX / scale
          cursorY = cursorY / scale
          
          local deltaX = cursorX - cursorStartX
          local deltaY = cursorY - cursorStartY
          
          -- Move all selected widgets
          for _, w in ipairs(selectedWidgets) do
            local offset = offsets[w]
            if offset then
              local newX = offset.x + deltaX
              local newY = offset.y + deltaY
              
              -- Snap to grid/center
              local parent = w:GetParent()
              local parentWidth = parent:GetWidth()
              local parentHeight = parent:GetHeight()
              newX, newY = SnapPosition(newX + parentWidth/2, newY + parentHeight/2, parentWidth, parentHeight)
              newX = newX - parentWidth/2
              newY = newY - parentHeight/2
              
              w:ClearAllPoints()
              w:SetPoint(offset.point or "CENTER", parent, offset.relativePoint or "CENTER", newX, newY)
              
              -- Keep selection border and handle aligned
              if w.selectionBorder then
                w.selectionBorder:ClearAllPoints()
                w.selectionBorder:SetAllPoints(w)
              end
              if w.dragHandle then
                w.dragHandle:ClearAllPoints()
                w.dragHandle:SetAllPoints(w)
              end
            end
          end
        end
      end)
    elseif button == "RightButton" then
      -- Right-click to toggle selection without dragging
      ToggleSelection(widget)
    end
  end)
  
  handle:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" then
      isDragging = false
      self:SetScript("OnUpdate", nil)
      
      -- Widget moved
    end
  end)
  
  table.insert(widgets, widget)
end

-- Create preview nameplate
local function CreatePreviewPlate(parent, unitType, classification)
  local plate = MP.Display.FrameCreation.Create(parent)
  plate.unit = "player" -- Fake unit for preview

  -- Make ALL elements draggable (from Advanced tab)
  if plate.Health then MakeWidgetDraggable(plate.Health, "Health Bar") end
  if plate.Name then MakeWidgetDraggable(plate.Name, "Name Text") end
  if plate.Level then MakeWidgetDraggable(plate.Level, "Level Text") end
  if plate.Cast then MakeWidgetDraggable(plate.Cast, "Cast Bar") end
  if plate.EliteIcon then MakeWidgetDraggable(plate.EliteIcon, "Elite Icon") end
  if plate.RareIcon then MakeWidgetDraggable(plate.RareIcon, "Rare Icon") end
  if plate.RareEliteIcon then MakeWidgetDraggable(plate.RareEliteIcon, "Rare Elite Icon") end
  if plate.QuestIcon then MakeWidgetDraggable(plate.QuestIcon, "Quest Icon") end
  if plate.RaidMarker then MakeWidgetDraggable(plate.RaidMarker, "Raid Marker") end
  if plate.Classification then MakeWidgetDraggable(plate.Classification, "Classification Text") end
  if plate.GuildText then MakeWidgetDraggable(plate.GuildText, "Guild Text") end
  if plate.CreatureText then MakeWidgetDraggable(plate.CreatureText, "Creature Text") end
  if plate.RoleIcon then MakeWidgetDraggable(plate.RoleIcon, "Role Icon") end
  if plate.CCIcon then MakeWidgetDraggable(plate.CCIcon, "CC Icon") end
  if plate.PowerBar then MakeWidgetDraggable(plate.PowerBar, "Power Bar") end
  if plate.UnitTargetText then MakeWidgetDraggable(plate.UnitTargetText, "Unit Target Text") end
  if plate.PvPMarker then MakeWidgetDraggable(plate.PvPMarker, "PvP Marker") end
  if plate.HealerIcon then MakeWidgetDraggable(plate.HealerIcon, "Healer Icon") end
  if plate.PetIcon then MakeWidgetDraggable(plate.PetIcon, "Pet Icon") end

  -- Aura containers
  if plate.Buffs then MakeWidgetDraggable(plate.Buffs, "Buffs Container") end
  if plate.Debuffs then MakeWidgetDraggable(plate.Debuffs, "Debuffs Container") end
  
  -- Set up fake data based on unit type
  if unitType == "enemy" then
    -- Enemy nameplate preview
    plate.Health:Show()
    plate.HealthBorder:Show()
    plate.Health:SetMinMaxValues(0, 100)
    plate.Health:SetValue(75)

    local r, g, b = 1, 0, 0 -- Red for enemy
    plate.Health:GetStatusBarTexture():SetVertexColor(r, g, b)

    plate.Name:SetText("Enemy Target")
    plate.Name:SetTextColor(1, 0, 0)
    plate.Name:SetPoint("BOTTOM", plate.Health, "TOP", 0, 4)
    plate.Name:Show()

    plate.Level:SetText("80")
    plate.Level:SetTextColor(1, 1, 0)
    plate.Level:Show()

    -- Cast bar preview
    if plate.Cast then
      plate.Cast:Show()
      plate.Cast:SetMinMaxValues(0, 3)
      plate.Cast:SetValue(1.5)
      if plate.CastText then
        plate.CastText:SetText("Fireball")
        plate.CastText:Show()
      end
    end

    -- Raid marker preview
    if plate.RaidMarker then
      SetRaidTargetIconTexture(plate.RaidMarker, 8) -- Skull
      plate.RaidMarker:Show()
    end

    -- Classification icons
    if classification == "elite" then
      if plate.EliteIcon then
        plate.EliteIcon:ClearAllPoints()
        plate.EliteIcon:SetPoint("LEFT", plate.Health, "RIGHT", 4, 0)
        plate.EliteIcon:Show()
      end
      if plate.Classification then
        plate.Classification:SetText("Elite")
        plate.Classification:SetTextColor(1, 0.8, 0)
        plate.Classification:Show()
      end
    elseif classification == "rare" then
      if plate.RareIcon then
        plate.RareIcon:ClearAllPoints()
        plate.RareIcon:SetPoint("LEFT", plate.Health, "RIGHT", 4, 0)
        plate.RareIcon:Show()
      end
      if plate.Classification then
        plate.Classification:SetText("Rare")
        plate.Classification:SetTextColor(0.8, 0.5, 1)
        plate.Classification:Show()
      end
    elseif classification == "rareelite" then
      if plate.RareEliteIcon then
        plate.RareEliteIcon:ClearAllPoints()
        plate.RareEliteIcon:SetPoint("LEFT", plate.Health, "RIGHT", 4, 0)
        plate.RareEliteIcon:Show()
      end
      if plate.Classification then
        plate.Classification:SetText("Rare Elite")
        plate.Classification:SetTextColor(0.8, 0.5, 1)
        plate.Classification:Show()
      end
    end

    -- Power bar (combo points, etc.)
    if plate.PowerBar then
      plate.PowerBar:Show()
      plate.PowerBar:SetMinMaxValues(0, 5)
      plate.PowerBar:SetValue(3)
      plate.PowerBar:GetStatusBarTexture():SetVertexColor(1, 1, 0)
    end

    -- Unit target preview
    if plate.UnitTargetText then
      plate.UnitTargetText:SetText("You")
      plate.UnitTargetText:SetTextColor(1, 0.5, 0)
      plate.UnitTargetText:Show()
    end

    -- CC Icon preview
    if plate.CCIcon then
      plate.CCIcon:SetTexture("Interface\\Icons\\Spell_Frost_FrostNova")
      plate.CCIcon:Show()
    end

    -- Aura containers with fake buffs/debuffs
    if plate.Buffs then
      plate.Buffs:Show()
    end
    if plate.Debuffs then
      plate.Debuffs:Show()
    end
    
  elseif unitType == "friendly" then
    -- Friendly nameplate preview
    plate.Health:Hide()
    plate.HealthBorder:Hide()

    plate.Name:SetText("Friendly NPC")
    plate.Name:SetTextColor(0, 1, 0)
    plate.Name:SetPoint("CENTER")
    plate.Name:Show()

    -- Guild text for friendly players
    if plate.GuildText then
      plate.GuildText:SetText("<Sample Guild>")
      plate.GuildText:SetTextColor(0.5, 1, 0.5)
      plate.GuildText:Show()
    end

    -- Creature text for NPCs
    if plate.CreatureText then
      plate.CreatureText:SetText("Humanoid")
      plate.CreatureText:SetTextColor(0.8, 0.8, 0.8)
      plate.CreatureText:Show()
    end

    -- Role icon (healer/tank)
    if plate.RoleIcon then
      plate.RoleIcon:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES")
      plate.RoleIcon:SetTexCoord(20/64, 39/64, 1/64, 20/64) -- Healer icon
      plate.RoleIcon:Show()
    end

  elseif unitType == "quest" then
    -- Quest NPC preview
    plate.Health:Show()
    plate.HealthBorder:Show()
    plate.Health:SetMinMaxValues(0, 100)
    plate.Health:SetValue(100)

    local r, g, b = 0.8, 0.4, 1 -- Purple for quest
    plate.Health:GetStatusBarTexture():SetVertexColor(r, g, b)

    plate.Name:SetText("Quest NPC")
    plate.Name:SetTextColor(0.8, 0.4, 1)
    plate.Name:SetPoint("BOTTOM", plate.Health, "TOP", 0, 4)
    plate.Name:Show()

    if plate.QuestIcon then
      plate.QuestIcon:SetTexture("Interface\\GossipFrame\\AvailableQuestIcon")
      plate.QuestIcon:Show()
    end

    -- Show creature text
    if plate.CreatureText then
      plate.CreatureText:SetText("Beast")
      plate.CreatureText:Show()
    end
  end
  
  return plate
end

-- Create preview window
-- Theme save/load popups
StaticPopupDialogs["MP_SAVE_THEME"] = {
  text = "Enter theme name:",
  button1 = "Save",
  button2 = "Cancel",
  hasEditBox = true,
  OnAccept = function(self)
    local name = self.editBox:GetText()
    MP.Themes.SaveTheme(name)
  end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
}

StaticPopupDialogs["MP_LOAD_THEME"] = {
  text = "Enter theme name to load:",
  button1 = "Load",
  button2 = "Cancel",
  hasEditBox = true,
  OnAccept = function(self)
    local name = self.editBox:GetText()
    if MP.Themes.LoadTheme(name) and MP.DB and MP.DB.currentLayout then
      for _, plate in ipairs(previewPlates) do
        MP.Themes.ApplyLayout(plate, MP.DB.currentLayout)
      end
    end
  end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
}

function MP.Preview.Show()
  if PreviewFrame then
    PreviewFrame:Show()
    return
  end
  
  -- Main preview frame
  PreviewFrame = CreateFrame("Frame", "MinimalPlatesPreviewFrame", UIParent, "BackdropTemplate")
  PreviewFrame:SetSize(800, 600)
  PreviewFrame:SetPoint("CENTER")
  PreviewFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 8, right = 8, top = 8, bottom = 8 }
  })
  PreviewFrame:SetBackdropColor(0, 0, 0, 0.95)
  PreviewFrame:EnableMouse(true)
  PreviewFrame:SetMovable(true)
  PreviewFrame:RegisterForDrag("LeftButton")
  PreviewFrame:SetScript("OnDragStart", PreviewFrame.StartMoving)
  PreviewFrame:SetScript("OnDragStop", PreviewFrame.StopMovingOrSizing)
  PreviewFrame:SetFrameStrata("FULLSCREEN_DIALOG")
  PreviewFrame:SetClampedToScreen(true)
  
  -- Title
  local title = PreviewFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOP", 0, -15)
  title:SetText("MinimalPlates Preview")
  
  -- Close button
  local closeBtn = CreateFrame("Button", nil, PreviewFrame, "UIPanelCloseButton")
  closeBtn:SetPoint("TOPRIGHT", -5, -5)
  
  -- Info text
  local infoText = PreviewFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  infoText:SetPoint("TOP", title, "BOTTOM", 0, -10)
  infoText:SetText("Left-click to drag | Shift+Click for multi-select | Right-click to select | Auto-snaps to center")
  
  -- Snap guide lines (hidden by default, shown when dragging)
  local centerLineV = PreviewFrame:CreateTexture(nil, "OVERLAY")
  centerLineV:SetColorTexture(0, 1, 1, 0.3) -- Cyan
  centerLineV:SetWidth(1)
  centerLineV:Hide()
  PreviewFrame.centerLineV = centerLineV
  
  local centerLineH = PreviewFrame:CreateTexture(nil, "OVERLAY")
  centerLineH:SetColorTexture(0, 1, 1, 0.3) -- Cyan
  centerLineH:SetHeight(1)
  centerLineH:Hide()
  PreviewFrame.centerLineH = centerLineH
  
  -- Preview area
  local previewArea = CreateFrame("Frame", nil, PreviewFrame)
  previewArea:SetPoint("TOPLEFT", 20, -80)
  previewArea:SetPoint("BOTTOMRIGHT", -20, 100)
  
  -- Create sample nameplates
  local yOffset = -20
  
  -- Enemy nameplate
  local enemyLabel = PreviewFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  enemyLabel:SetPoint("TOPLEFT", previewArea, "TOPLEFT", 10, yOffset)
  enemyLabel:SetText("Enemy:")
  
  local enemyPlate = CreatePreviewPlate(previewArea, "enemy", nil)
  enemyPlate:SetPoint("LEFT", enemyLabel, "RIGHT", 20, 0)
  table.insert(previewPlates, enemyPlate)
  yOffset = yOffset - 80
  
  -- Elite enemy
  local eliteLabel = PreviewFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  eliteLabel:SetPoint("TOPLEFT", previewArea, "TOPLEFT", 10, yOffset)
  eliteLabel:SetText("Elite:")
  
  local elitePlate = CreatePreviewPlate(previewArea, "enemy", "elite")
  elitePlate:SetPoint("LEFT", eliteLabel, "RIGHT", 20, 0)
  table.insert(previewPlates, elitePlate)
  yOffset = yOffset - 80
  
  -- Rare enemy
  local rareLabel = PreviewFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  rareLabel:SetPoint("TOPLEFT", previewArea, "TOPLEFT", 10, yOffset)
  rareLabel:SetText("Rare:")
  
  local rarePlate = CreatePreviewPlate(previewArea, "enemy", "rare")
  rarePlate:SetPoint("LEFT", rareLabel, "RIGHT", 20, 0)
  table.insert(previewPlates, rarePlate)
  yOffset = yOffset - 80
  
  -- Quest NPC
  local questLabel = PreviewFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  questLabel:SetPoint("TOPLEFT", previewArea, "TOPLEFT", 10, yOffset)
  questLabel:SetText("Quest NPC:")
  
  local questPlate = CreatePreviewPlate(previewArea, "quest", nil)
  questPlate:SetPoint("LEFT", questLabel, "RIGHT", 20, 0)
  table.insert(previewPlates, questPlate)
  yOffset = yOffset - 80
  
  -- Friendly NPC
  local friendlyLabel = PreviewFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  friendlyLabel:SetPoint("TOPLEFT", previewArea, "TOPLEFT", 10, yOffset)
  friendlyLabel:SetText("Friendly:")
  
  local friendlyPlate = CreatePreviewPlate(previewArea, "friendly", nil)
  friendlyPlate:SetPoint("LEFT", friendlyLabel, "RIGHT", 20, 0)
  table.insert(previewPlates, friendlyPlate)
  
  -- Refresh button
  local refreshBtn = CreateFrame("Button", nil, PreviewFrame, "UIPanelButtonTemplate")
  refreshBtn:SetSize(120, 25)
  refreshBtn:SetPoint("BOTTOMLEFT", 20, 10)
  refreshBtn:SetText("Refresh Preview")
  refreshBtn:SetScript("OnClick", function()
    MP.Preview.Refresh()
  end)
  
  -- Clear selection button
  local clearBtn = CreateFrame("Button", nil, PreviewFrame, "UIPanelButtonTemplate")
  clearBtn:SetSize(120, 25)
  clearBtn:SetPoint("LEFT", refreshBtn, "RIGHT", 10, 0)
  clearBtn:SetText("Clear Selection")
  clearBtn:SetScript("OnClick", function()
    selectedWidgets = {}
    UpdateSelectionVisuals()
  end)
  
  -- Save Theme button
  local saveBtn = CreateFrame("Button", nil, PreviewFrame, "UIPanelButtonTemplate")
  saveBtn:SetSize(120, 25)
  saveBtn:SetPoint("LEFT", clearBtn, "RIGHT", 10, 0)
  saveBtn:SetText("Save Theme")
  saveBtn:SetScript("OnClick", function()
    if StaticPopup_Show then
      StaticPopup_Show("MP_SAVE_THEME")
    end
  end)
  
  -- Load Theme button
  local loadBtn = CreateFrame("Button", nil, PreviewFrame, "UIPanelButtonTemplate")
  loadBtn:SetSize(120, 25)
  loadBtn:SetPoint("LEFT", saveBtn, "RIGHT", 10, 0)
  loadBtn:SetText("Load Theme")
  loadBtn:SetScript("OnClick", function()
    if StaticPopup_Show then
      StaticPopup_Show("MP_LOAD_THEME")
    end
  end)
  
  -- Settings button
  local settingsBtn = CreateFrame("Button", nil, PreviewFrame, "UIPanelButtonTemplate")
  settingsBtn:SetSize(120, 25)
  settingsBtn:SetPoint("BOTTOMRIGHT", -20, 10)
  settingsBtn:SetText("Open Settings")
  settingsBtn:SetScript("OnClick", function()
    if MP.Settings and MP.Settings.CreateStandaloneUI then
      MP.Settings.CreateStandaloneUI()
    end
  end)
  
  -- Apply current theme layout to preview plates
  if MP.DB and MP.DB.currentLayout and MP.Themes and MP.Themes.ApplyLayout then
    for _, plate in ipairs(previewPlates) do
      MP.Themes.ApplyLayout(plate, MP.DB.currentLayout)
    end
  end
  
  PreviewFrame:Show()
end

-- Refresh preview nameplates
function MP.Preview.Refresh()
  if not PreviewFrame or not PreviewFrame:IsShown() then return end
  
  -- Clear existing plates
  for _, plate in ipairs(previewPlates) do
    plate:Hide()
    plate:SetParent(nil)
  end
  wipe(previewPlates)
  
  -- Recreate plates with current settings
  local previewArea = PreviewFrame:GetChildren()

  -- Preview refreshed
end

-- Hide preview
function MP.Preview.Hide()
  if PreviewFrame then
    PreviewFrame:Hide()
  end
end

-- Add to slash commands
local oldSlashHandler = SlashCmdList["MINIMALPLATES"]
SlashCmdList["MINIMALPLATES"] = function(msg)
  msg = strtrim(msg:lower())
  if msg == "preview" or msg == "test" or msg == "designer" then
    MP.Preview.Show()
  else
    oldSlashHandler(msg)
  end
end
