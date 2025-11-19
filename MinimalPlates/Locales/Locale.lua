---@class MinimalPlates
local MP = MinimalPlates

-- Localization system
MP.L = {}
local L = MP.L

-- Default locale (enUS)
local locale = GetLocale()

-- Locale table
local locales = {}

-- Set current locale
function MP.L:SetLocale(loc)
  if locales[loc] then
    for k, v in pairs(locales[loc]) do
      L[k] = v
    end
  end
end

-- Register locale strings
function MP.L:RegisterLocale(loc, strings)
  locales[loc] = strings
  
  -- Auto-apply if this is the current locale
  if loc == locale then
    MP.L:SetLocale(loc)
  end
end

-- Fallback to key if translation missing
setmetatable(L, {
  __index = function(t, k)
    return k
  end
})
