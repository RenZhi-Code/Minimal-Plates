---@class MinimalPlates
local MP = MinimalPlates

-- LibSharedMedia-3.0 Integration
-- This module provides integration with LibSharedMedia-3.0 to allow using fonts
-- from other addons that register with LSM

MP.SharedMedia = {}

local LSM

-- Check if LibSharedMedia-3.0 is available
function MP.SharedMedia.Initialize()
  -- Try to load LibSharedMedia-3.0 via LibStub
  if LibStub then
    local success, result = pcall(LibStub, "LibSharedMedia-3.0")
    if success and result then
      LSM = result
      -- LibSharedMedia-3.0 found via LibStub
      return
    end
  end
  
  -- Try to use global SharedMedia if available (custom implementation)
  if SharedMedia and SharedMedia.GetAllFonts then
    -- Using global SharedMedia
    -- Don't set LSM, we'll use SharedMedia directly
    return
  end

  -- No SharedMedia found, using built-in fonts only
end

-- Check if LSM is available
function MP.SharedMedia.IsAvailable()
  return LSM ~= nil
end

-- Get all available fonts (built-in + LSM)
function MP.SharedMedia.GetAllFonts()
  -- Try global SharedMedia first (custom implementation)
  if SharedMedia and SharedMedia.GetAllFonts then
    local fonts = SharedMedia.GetAllFonts()
    if fonts and #fonts > 0 then
      -- Got fonts from global SharedMedia
      return fonts
    end
  end
  
  local fonts = {}

  -- Built-in WoW fonts
  local builtInFonts = {
    {name = "Friz Quadrata", path = "Fonts\\FRIZQT__.TTF"},
    {name = "Arial", path = "Fonts\\ARIALN.TTF"},
    {name = "Morpheus", path = "Fonts\\MORPHEUS.TTF"},
    {name = "Skurri", path = "Fonts\\skurri.TTF"},
    {name = "Friends", path = "Fonts\\FRIENDS.TTF"},
    {name = "Blizzard Global", path = "Fonts\\blei00d.TTF"},
    {name = "Nimrod MT", path = "Fonts\\NIM_____.ttf"},
  }
  
  -- Custom installed fonts
  local installedFonts = {
    {name = "Accidental Presidency", path = "Interface\\AddOns\\MinimalPlates\\Libs\\Fonts\\Accidental Presidency.ttf"},
    {name = "Carlito", path = "Interface\\AddOns\\MinimalPlates\\Libs\\Fonts\\Carlito-Regular.ttf"},
    {name = "El Messiri", path = "Interface\\AddOns\\MinimalPlates\\Libs\\Fonts\\ElMessiri-VariableFont_wght.ttf"},
    {name = "Forced Square", path = "Interface\\AddOns\\MinimalPlates\\Libs\\Fonts\\FORCED SQUARE.ttf"},
    {name = "Harry Potter", path = "Interface\\AddOns\\MinimalPlates\\Libs\\Fonts\\HARRYP__.TTF"},
    {name = "Noto Naskh Arabic", path = "Interface\\AddOns\\MinimalPlates\\Libs\\Fonts\\NotoNaskhArabic-Regular.ttf"},
    {name = "Nueva Std Cond", path = "Interface\\AddOns\\MinimalPlates\\Libs\\Fonts\\Nueva Std Cond.ttf"},
    {name = "Oswald", path = "Interface\\AddOns\\MinimalPlates\\Libs\\Fonts\\Oswald-Regular.ttf"},
    {name = "Trash Hand", path = "Interface\\AddOns\\MinimalPlates\\Libs\\Fonts\\TrashHand.TTF"},
    {name = "Ubuntu Arabic", path = "Interface\\AddOns\\MinimalPlates\\Libs\\Fonts\\Ubuntu Arabic Regular.otf"},
  }
  
  -- Add built-in fonts with header
  table.insert(fonts, {name = MP.L["--- Built-in Fonts ---"], path = nil, isHeader = true})
  for _, font in ipairs(builtInFonts) do
    table.insert(fonts, font)
  end
  
  -- Add installed fonts with header
  if #installedFonts > 0 then
    table.insert(fonts, {name = MP.L["--- Installed Fonts ---"], path = nil, isHeader = true})
    for _, font in ipairs(installedFonts) do
      table.insert(fonts, font)
    end
  end

  -- Add LSM fonts if available
  if LSM then
    local lsmFonts = LSM:List("font")
    local lsmFontsAdded = false
    -- LSM returned fonts
    for _, fontName in ipairs(lsmFonts) do
      -- Check if this font is already in our lists
      local isDuplicate = false
      for _, builtInFont in ipairs(builtInFonts) do
        if builtInFont.name == fontName then
          isDuplicate = true
          break
        end
      end
      if not isDuplicate then
        for _, installedFont in ipairs(installedFonts) do
          if installedFont.name == fontName then
            isDuplicate = true
            break
          end
        end
      end

      if not isDuplicate then
        -- Add header before first LSM font
        if not lsmFontsAdded then
          table.insert(fonts, {name = MP.L["--- SharedMedia Fonts ---"], path = nil, isHeader = true})
          lsmFontsAdded = true
        end
        
        local fontPath = LSM:Fetch("font", fontName)
        table.insert(fonts, {
          name = fontName,
          path = fontPath
        })
      end
    end
  else
    -- Using built-in fonts
  end

  return fonts
end

-- Statusbar textures (built-in + LSM)
function MP.SharedMedia.GetAllStatusBars()
  local bars = {
    {name = "Smooth", path = "Interface\\AddOns\\MinimalPlates\\Textures\\Smooth"},
    {name = "Smoother", path = "Interface\\AddOns\\MinimalPlates\\Textures\\Smoother"},
    {name = "Smooth v2", path = "Interface\\AddOns\\MinimalPlates\\Textures\\Smoothv2"},
    {name = "BantoBar", path = "Interface\\AddOns\\MinimalPlates\\Textures\\BantoBar"},
    {name = "Glaze", path = "Interface\\AddOns\\MinimalPlates\\Textures\\Glaze"},
    {name = "Otravi", path = "Interface\\AddOns\\MinimalPlates\\Textures\\Otravi"},
    {name = "Bar", path = "Interface\\AddOns\\MinimalPlates\\Textures\\bar"},
    {name = "Blizzard", path = "Interface\\Buttons\\WHITE8X8"},
  }
  if LSM then
    local lsmBars = LSM:List("statusbar")
    for _, barName in ipairs(lsmBars) do
      local ok, texPath = pcall(LSM.Fetch, LSM, "statusbar", barName)
      if ok and texPath then
        table.insert(bars, { name = barName, key = barName, path = texPath })
      end
    end
  end
  return bars
end

-- Resolve statusbar texture by name or path
function MP.SharedMedia.GetBarTexturePath(value)
  if type(value) == "string" then
    if value:find("\\") then
      return value
    end
    if LSM then
      local ok, texPath = pcall(LSM.Fetch, LSM, "statusbar", value)
      if ok and texPath then
        return texPath
      end
    end
  end
  return "Interface\\Buttons\\WHITE8X8"
end

-- Get font file path (with fallback)
function MP.SharedMedia.GetFontPath(fontPath)
  -- If it's already a path, return it
  if fontPath and (fontPath:match("%.TTF$") or fontPath:match("%.ttf$")) then
    return fontPath
  end
  
  -- Try to fetch from LSM by name
  if LSM and fontPath then
    local success, result = pcall(LSM.Fetch, LSM, "font", fontPath)
    if success and result then
      return result
    end
  end

  -- Default fallback
  return "Fonts\\FRIZQT__.TTF"
end

-- Register callback for when LSM fonts are added/removed
function MP.SharedMedia.RegisterCallback(callback)
  if LSM then
    LSM.RegisterCallback(MP.SharedMedia, "LibSharedMedia_Registered", function(_, mediaType, key)
      if mediaType == "font" then
        callback()
      end
    end)
  end
end
