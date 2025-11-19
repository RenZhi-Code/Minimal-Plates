---@class MinimalPlates
local MP = MinimalPlates

MP.Themes = {}

-- Theme storage structure:
-- MinimalPlatesDB.themes = {
--   ["ThemeName"] = {
--     layout = {
--       Health = { point = "CENTER", relativePoint = "CENTER", x = 0, y = 0, width = 120, height = 10 },
--       Name = { point = "BOTTOM", relativePoint = "TOP", relativeTo = "Health", x = 0, y = 4 },
--       Level = { point = "RIGHT", relativePoint = "LEFT", relativeTo = "Health", x = -4, y = 0 },
--       Cast = { point = "TOP", relativePoint = "BOTTOM", relativeTo = "Health", x = 0, y = -2, width = 120, height = 8 },
--       EliteIcon = { point = "LEFT", relativePoint = "RIGHT", relativeTo = "Name", x = 2, y = 0, size = 16 },
--       -- ... etc for all widgets
--     },
--     settings = { -- All MP.DB settings (fonts, colors, toggles, etc) }
--   }
-- }

-- Deep copy helper
local function DeepCopy(orig)
  local orig_type = type(orig)
  local copy
  if orig_type == 'table' then
    copy = {}
    for orig_key, orig_value in next, orig, nil do
      copy[DeepCopy(orig_key)] = DeepCopy(orig_value)
    end
    setmetatable(copy, DeepCopy(getmetatable(orig)))
  else
    copy = orig
  end
  return copy
end

-- Initialize theme storage
function MP.Themes.Initialize()
  if not MinimalPlatesDB.themes then
    MinimalPlatesDB.themes = {}
  end
  
  if not MinimalPlatesDB.currentTheme then
    MinimalPlatesDB.currentTheme = "Default"
  end
  
  -- Create default theme if it doesn't exist
  if not MinimalPlatesDB.themes["Default"] then
    MP.Themes.SaveTheme("Default", true)
  end
end

-- Get current theme name
function MP.Themes.GetCurrentTheme()
  return MinimalPlatesDB.currentTheme or "Default"
end

-- Get list of all theme names
function MP.Themes.GetThemeList()
  local themes = {}
  if MinimalPlatesDB and MinimalPlatesDB.themes then
    for name, _ in pairs(MinimalPlatesDB.themes) do
      table.insert(themes, name)
    end
  end
  table.sort(themes)
  return themes
end

-- Capture current widget layout from a preview plate
function MP.Themes.CaptureLayout(plate)
  local layout = {}
  
  -- Helper to get anchor info
  local function GetAnchor(frame)
    if not frame then return nil end
    
    local numPoints = frame:GetNumPoints()
    if numPoints == 0 then return nil end
    
    local point, relativeTo, relativePoint, x, y = frame:GetPoint(1)
    
    -- Get relative frame name
    local relativeToName = nil
    if relativeTo then
      if relativeTo == plate then
        relativeToName = "plate"
      elseif relativeTo == plate.Health then
        relativeToName = "Health"
      elseif relativeTo == plate.Name then
        relativeToName = "Name"
      elseif relativeTo == plate.Cast then
        relativeToName = "Cast"
      -- Add more as needed
      end
    end
    
    local anchor = {
      point = point,
      relativePoint = relativePoint,
      relativeTo = relativeToName,
      x = x or 0,
      y = y or 0
    }
    
    -- Get size if applicable
    if frame.GetWidth and frame.GetHeight then
      anchor.width = frame:GetWidth()
      anchor.height = frame:GetHeight()
    end
    
    if frame.GetSize then
      local w, h = frame:GetSize()
      anchor.size = w -- For square elements like icons
    end
    
    return anchor
  end
  
  -- Capture each widget's position
  if plate.Health then
    layout.Health = GetAnchor(plate.Health)
  end
  
  if plate.Name then
    layout.Name = GetAnchor(plate.Name)
  end
  
  if plate.Level then
    layout.Level = GetAnchor(plate.Level)
  end
  
  if plate.Cast then
    layout.Cast = GetAnchor(plate.Cast)
  end
  
  if plate.EliteIcon then
    layout.EliteIcon = GetAnchor(plate.EliteIcon)
  end
  
  if plate.RareIcon then
    layout.RareIcon = GetAnchor(plate.RareIcon)
  end
  
  if plate.RareEliteIcon then
    layout.RareEliteIcon = GetAnchor(plate.RareEliteIcon)
  end
  
  if plate.RaidMarker then
    layout.RaidMarker = GetAnchor(plate.RaidMarker)
  end
  
  if plate.PowerBar then
    layout.PowerBar = GetAnchor(plate.PowerBar)
  end
  
  if plate.Classification then
    layout.Classification = GetAnchor(plate.Classification)
  end
  
  return layout
end

-- Apply layout to a widget
function MP.Themes.ApplyLayoutToWidget(widget, widgetName, layout, plate)
  if not widget or not layout or not layout[widgetName] then return end
  
  local anchor = layout[widgetName]
  
  -- Get relative frame
  local relativeTo = plate
  if anchor.relativeTo == "Health" then
    relativeTo = plate.Health
  elseif anchor.relativeTo == "Name" then
    relativeTo = plate.Name
  elseif anchor.relativeTo == "Cast" then
    relativeTo = plate.Cast
  end
  
  -- Clear and set new position
  widget:ClearAllPoints()
  widget:SetPoint(anchor.point, relativeTo, anchor.relativePoint, anchor.x, anchor.y)
  
  -- Apply size
  if anchor.width and anchor.height and widget.SetSize then
    widget:SetSize(anchor.width, anchor.height)
  elseif anchor.size and widget.SetSize then
    widget:SetSize(anchor.size, anchor.size)
  end
end

-- Apply full layout to a nameplate
function MP.Themes.ApplyLayout(plate, layout)
  if not plate or not layout then return end
  
  -- Apply to each widget
  MP.Themes.ApplyLayoutToWidget(plate.Health, "Health", layout, plate)
  MP.Themes.ApplyLayoutToWidget(plate.Name, "Name", layout, plate)
  MP.Themes.ApplyLayoutToWidget(plate.Level, "Level", layout, plate)
  MP.Themes.ApplyLayoutToWidget(plate.Cast, "Cast", layout, plate)
  MP.Themes.ApplyLayoutToWidget(plate.EliteIcon, "EliteIcon", layout, plate)
  MP.Themes.ApplyLayoutToWidget(plate.RareIcon, "RareIcon", layout, plate)
  MP.Themes.ApplyLayoutToWidget(plate.RareEliteIcon, "RareEliteIcon", layout, plate)
  MP.Themes.ApplyLayoutToWidget(plate.RaidMarker, "RaidMarker", layout, plate)
  MP.Themes.ApplyLayoutToWidget(plate.PowerBar, "PowerBar", layout, plate)
  MP.Themes.ApplyLayoutToWidget(plate.Classification, "Classification", layout, plate)
end

-- Save current layout and settings as a theme
function MP.Themes.SaveTheme(themeName, captureFromDefaults)
  if not themeName or themeName == "" then
    print("|cffff0000[MinimalPlates]|r Theme name cannot be empty")
    return false
  end
  
  local theme = {
    layout = {},
    settings = {}
  }
  
  if captureFromDefaults then
    -- Use hardcoded default layout (for initial Default theme)
    theme.layout = {
      Health = { point = "CENTER", relativePoint = "CENTER", relativeTo = "plate", x = 0, y = 0, width = 120, height = 10 },
      Name = { point = "BOTTOM", relativePoint = "TOP", relativeTo = "Health", x = 0, y = 4 },
      Level = { point = "RIGHT", relativePoint = "LEFT", relativeTo = "Health", x = -4, y = 0 },
      Cast = { point = "TOP", relativePoint = "BOTTOM", relativeTo = "Health", x = 0, y = -2, width = 120, height = 8 },
      EliteIcon = { point = "LEFT", relativePoint = "RIGHT", relativeTo = "Name", x = 2, y = 0, size = 16 },
      RareIcon = { point = "LEFT", relativePoint = "RIGHT", relativeTo = "Name", x = 2, y = 0, size = 16 },
      RareEliteIcon = { point = "LEFT", relativePoint = "RIGHT", relativeTo = "Name", x = 2, y = 0, size = 16 },
    }
  else
    -- Capture from Preview if available; otherwise use current applied layout if present
    if MP.Preview and MP.Preview.GetPreviewPlate then
      local previewPlate = MP.Preview.GetPreviewPlate(1) -- Get first preview plate
      if previewPlate then
        theme.layout = MP.Themes.CaptureLayout(previewPlate)
      end
    end
    -- Fallback to currently applied layout
    if (not theme.layout or next(theme.layout) == nil) and MP.DB and MP.DB.currentLayout then
      theme.layout = DeepCopy(MP.DB.currentLayout)
    end
  end
  
  -- Copy all current settings
  theme.settings = DeepCopy(MP.DB)
  
  -- Save theme
  MinimalPlatesDB.themes[themeName] = theme
  
  print("|cff00ff00[MinimalPlates]|r Theme '" .. themeName .. "' saved!")
  return true
end

-- Load a theme
function MP.Themes.LoadTheme(themeName)
  if not MinimalPlatesDB.themes[themeName] then
    print("|cffff0000[MinimalPlates]|r Theme '" .. themeName .. "' not found")
    return false
  end
  
  local theme = MinimalPlatesDB.themes[themeName]
  
  -- Apply settings
  if theme.settings then
    for k, v in pairs(theme.settings) do
      MP.DB[k] = DeepCopy(v)
    end
  end
  
  -- Store layout for application during nameplate updates
  MP.DB.currentLayout = theme.layout
  
  -- Set current theme
  MinimalPlatesDB.currentTheme = themeName
  
  -- Refresh all nameplates
  if MP.Nameplates and MP.Nameplates.RefreshAll then
    MP.Nameplates.RefreshAll()
  end
  
  print("|cff00ff00[MinimalPlates]|r Theme '" .. themeName .. "' loaded!")
  return true
end

-- Delete a theme
function MP.Themes.DeleteTheme(themeName)
  if themeName == "Default" then
    print("|cffff0000[MinimalPlates]|r Cannot delete Default theme")
    return false
  end
  
  if not MinimalPlatesDB.themes[themeName] then
    print("|cffff0000[MinimalPlates]|r Theme '" .. themeName .. "' not found")
    return false
  end
  
  MinimalPlatesDB.themes[themeName] = nil
  
  -- If deleting current theme, switch to Default
  if MinimalPlatesDB.currentTheme == themeName then
    MP.Themes.LoadTheme("Default")
  end
  
  print("|cff00ff00[MinimalPlates]|r Theme '" .. themeName .. "' deleted")
  return true
end

-- Copy a theme
function MP.Themes.CopyTheme(sourceName, targetName)
  if not MinimalPlatesDB.themes[sourceName] then
    print("|cffff0000[MinimalPlates]|r Source theme '" .. sourceName .. "' not found")
    return false
  end
  
  if not targetName or targetName == "" then
    print("|cffff0000[MinimalPlates]|r Target theme name cannot be empty")
    return false
  end
  
  MinimalPlatesDB.themes[targetName] = DeepCopy(MinimalPlatesDB.themes[sourceName])
  
  print("|cff00ff00[MinimalPlates]|r Theme '" .. sourceName .. "' copied to '" .. targetName .. "'")
  return true
end

-- Export theme to string
function MP.Themes.ExportTheme(themeName)
  if not MinimalPlatesDB.themes[themeName] then
    print("|cffff0000[MinimalPlates]|r Theme '" .. themeName .. "' not found")
    return nil
  end
  
  local theme = MinimalPlatesDB.themes[themeName]
  local serialized = MP.Themes.Serialize(theme)
  
  return serialized
end

-- Import theme from string
function MP.Themes.ImportTheme(themeName, dataString)
  if not themeName or themeName == "" then
    print("|cffff0000[MinimalPlates]|r Theme name cannot be empty")
    return false
  end
  
  local theme = MP.Themes.Deserialize(dataString)
  if not theme then
    print("|cffff0000[MinimalPlates]|r Failed to import theme - invalid data")
    return false
  end
  
  MinimalPlatesDB.themes[themeName] = theme
  
  print("|cff00ff00[MinimalPlates]|r Theme '" .. themeName .. "' imported!")
  return true
end

-- Simple serialization (uses Lua table syntax)
function MP.Themes.Serialize(data)
  local function serializeTable(val, depth)
    depth = depth or 0
    if depth > 10 then return "nil" end -- Prevent infinite recursion
    
    local result = "{"
    local first = true
    
    for k, v in pairs(val) do
      if not first then result = result .. "," end
      first = false
      
      -- Key
      if type(k) == "string" then
        result = result .. '["' .. k .. '"]='
      else
        result = result .. "[" .. k .. "]="
      end
      
      -- Value
      if type(v) == "table" then
        result = result .. serializeTable(v, depth + 1)
      elseif type(v) == "string" then
        result = result .. '"' .. v:gsub('"', '\\"') .. '"'
      elseif type(v) == "number" or type(v) == "boolean" then
        result = result .. tostring(v)
      else
        result = result .. "nil"
      end
    end
    
    result = result .. "}"
    return result
  end
  
  return serializeTable(data)
end

-- Deserialize from string
function MP.Themes.Deserialize(str)
  if not str or str == "" then return nil end
  
  local func = loadstring("return " .. str)
  if not func then return nil end
  
  local success, result = pcall(func)
  if not success then return nil end
  
  return result
end
