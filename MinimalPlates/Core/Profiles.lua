---@class MinimalPlates
local MP = MinimalPlates

MP.Profiles = {}

-- Profile constants
local CURRENT_PROFILE_KEY = "currentProfile"
local DEFAULT_PROFILE_NAME = "Default"

-- Deep copy table
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

-- Get current profile name
function MP.Profiles.GetCurrentProfile()
  return MinimalPlatesDB[CURRENT_PROFILE_KEY] or DEFAULT_PROFILE_NAME
end

-- Get list of all profile names
function MP.Profiles.GetProfileList()
  local profiles = {}
  if MinimalPlatesDB and MinimalPlatesDB.profiles then
    for name, _ in pairs(MinimalPlatesDB.profiles) do
      table.insert(profiles, name)
    end
  end
  table.sort(profiles)
  return profiles
end

-- Check if profile exists
function MP.Profiles.ProfileExists(name)
  return MinimalPlatesDB.profiles and MinimalPlatesDB.profiles[name] ~= nil
end

-- Save current settings to a profile
function MP.Profiles.SaveProfile(name)
  if not name or name == "" then
    print("|cffff0000[MinimalPlates]|r Profile name cannot be empty")
    return false
  end
  
  -- Initialize profiles table if needed
  MinimalPlatesDB.profiles = MinimalPlatesDB.profiles or {}
  
  -- Get current settings (exclude profiles and currentProfile keys)
  local settings = {}
  for k, v in pairs(MinimalPlatesDB) do
    if k ~= "profiles" and k ~= CURRENT_PROFILE_KEY then
      settings[k] = DeepCopy(v)
    end
  end
  
  -- Save profile
  MinimalPlatesDB.profiles[name] = settings
  MinimalPlatesDB[CURRENT_PROFILE_KEY] = name
  
  print("|cff00ff00[MinimalPlates]|r Profile '" .. name .. "' saved successfully")
  return true
end

-- Load a profile
function MP.Profiles.LoadProfile(name)
  if not MP.Profiles.ProfileExists(name) then
    print("|cffff0000[MinimalPlates]|r Profile '" .. name .. "' does not exist")
    return false
  end
  
  local profile = MinimalPlatesDB.profiles[name]
  
  -- Clear current settings (except profiles)
  for k in pairs(MinimalPlatesDB) do
    if k ~= "profiles" and k ~= CURRENT_PROFILE_KEY then
      MinimalPlatesDB[k] = nil
    end
  end
  
  -- Load profile settings
  for k, v in pairs(profile) do
    MinimalPlatesDB[k] = DeepCopy(v)
  end
  
  -- Update current profile
  MinimalPlatesDB[CURRENT_PROFILE_KEY] = name
  
  -- Reinitialize with new settings
  MP.DB = MinimalPlatesDB
  if MP.Config and MP.Config.Init then
    MP.Config.Init()
  end
  if MP.Nameplates and MP.Nameplates.RefreshAll then
    MP.Nameplates.RefreshAll()
  end
  
  print("|cff00ff00[MinimalPlates]|r Profile '" .. name .. "' loaded successfully")
  return true
end

-- Create a new profile (copy from current or default)
function MP.Profiles.CreateProfile(name, copyFromCurrent)
  if not name or name == "" then
    print("|cffff0000[MinimalPlates]|r Profile name cannot be empty")
    return false
  end
  
  if MP.Profiles.ProfileExists(name) then
    print("|cffff0000[MinimalPlates]|r Profile '" .. name .. "' already exists")
    return false
  end
  
  MinimalPlatesDB.profiles = MinimalPlatesDB.profiles or {}
  
  if copyFromCurrent then
    -- Copy current settings
    MP.Profiles.SaveProfile(name)
  else
    -- Create empty profile with defaults
    MinimalPlatesDB.profiles[name] = {}
  end
  
  print("|cff00ff00[MinimalPlates]|r Profile '" .. name .. "' created")
  return true
end

-- Delete a profile
function MP.Profiles.DeleteProfile(name)
  if name == DEFAULT_PROFILE_NAME then
    print("|cffff0000[MinimalPlates]|r Cannot delete the Default profile")
    return false
  end
  
  if not MP.Profiles.ProfileExists(name) then
    print("|cffff0000[MinimalPlates]|r Profile '" .. name .. "' does not exist")
    return false
  end
  
  MinimalPlatesDB.profiles[name] = nil
  
  -- If deleted profile was active, switch to Default
  if MP.Profiles.GetCurrentProfile() == name then
    if MP.Profiles.ProfileExists(DEFAULT_PROFILE_NAME) then
      MP.Profiles.LoadProfile(DEFAULT_PROFILE_NAME)
    else
      MinimalPlatesDB[CURRENT_PROFILE_KEY] = DEFAULT_PROFILE_NAME
    end
  end
  
  print("|cff00ff00[MinimalPlates]|r Profile '" .. name .. "' deleted")
  return true
end

-- Copy profile
function MP.Profiles.CopyProfile(sourceName, targetName)
  if not MP.Profiles.ProfileExists(sourceName) then
    print("|cffff0000[MinimalPlates]|r Source profile '" .. sourceName .. "' does not exist")
    return false
  end
  
  if not targetName or targetName == "" then
    print("|cffff0000[MinimalPlates]|r Target profile name cannot be empty")
    return false
  end
  
  if MP.Profiles.ProfileExists(targetName) then
    print("|cffff0000[MinimalPlates]|r Target profile '" .. targetName .. "' already exists")
    return false
  end
  
  MinimalPlatesDB.profiles = MinimalPlatesDB.profiles or {}
  MinimalPlatesDB.profiles[targetName] = DeepCopy(MinimalPlatesDB.profiles[sourceName])
  
  print("|cff00ff00[MinimalPlates]|r Profile '" .. sourceName .. "' copied to '" .. targetName .. "'")
  return true
end

-- Rename profile
function MP.Profiles.RenameProfile(oldName, newName)
  if not MP.Profiles.ProfileExists(oldName) then
    print("|cffff0000[MinimalPlates]|r Profile '" .. oldName .. "' does not exist")
    return false
  end
  
  if not newName or newName == "" then
    print("|cffff0000[MinimalPlates]|r New profile name cannot be empty")
    return false
  end
  
  if MP.Profiles.ProfileExists(newName) then
    print("|cffff0000[MinimalPlates]|r Profile '" .. newName .. "' already exists")
    return false
  end
  
  -- Copy profile data
  MinimalPlatesDB.profiles[newName] = MinimalPlatesDB.profiles[oldName]
  MinimalPlatesDB.profiles[oldName] = nil
  
  -- Update current profile if renamed
  if MP.Profiles.GetCurrentProfile() == oldName then
    MinimalPlatesDB[CURRENT_PROFILE_KEY] = newName
  end
  
  print("|cff00ff00[MinimalPlates]|r Profile '" .. oldName .. "' renamed to '" .. newName .. "'")
  return true
end

-- Reset current profile to defaults
function MP.Profiles.ResetProfile()
  local currentProfile = MP.Profiles.GetCurrentProfile()
  
  -- Clear current settings
  for k in pairs(MinimalPlatesDB) do
    if k ~= "profiles" and k ~= CURRENT_PROFILE_KEY then
      MinimalPlatesDB[k] = nil
    end
  end
  
  -- Reinitialize defaults
  MP.DB = MinimalPlatesDB
  if MP.Config and MP.Config.Init then
    MP.Config.Init()
  end
  
  -- Save reset profile
  MP.Profiles.SaveProfile(currentProfile)
  
  if MP.Nameplates and MP.Nameplates.RefreshAll then
    MP.Nameplates.RefreshAll()
  end
  
  print("|cff00ff00[MinimalPlates]|r Profile '" .. currentProfile .. "' reset to defaults")
  return true
end

-- Initialize default profile if none exists
function MP.Profiles.Initialize()
  MinimalPlatesDB.profiles = MinimalPlatesDB.profiles or {}
  
  -- Create Default profile if it doesn't exist
  if not MP.Profiles.ProfileExists(DEFAULT_PROFILE_NAME) then
    MP.Profiles.SaveProfile(DEFAULT_PROFILE_NAME)
  end
  
  -- Ensure current profile is set
  if not MinimalPlatesDB[CURRENT_PROFILE_KEY] then
    MinimalPlatesDB[CURRENT_PROFILE_KEY] = DEFAULT_PROFILE_NAME
  end
end

-- Export profile to string (for sharing)
function MP.Profiles.ExportProfile(name)
  if not MP.Profiles.ProfileExists(name) then
    print("|cffff0000[MinimalPlates]|r Profile '" .. name .. "' does not exist")
    return nil
  end
  
  local profile = MinimalPlatesDB.profiles[name]
  local serialized = MP.Profiles.Serialize(profile)
  
  return serialized
end

-- Import profile from string
function MP.Profiles.ImportProfile(name, dataString)
  if not name or name == "" then
    print("|cffff0000[MinimalPlates]|r Profile name cannot be empty")
    return false
  end
  
  if not dataString or dataString == "" then
    print("|cffff0000[MinimalPlates]|r Import data cannot be empty")
    return false
  end
  
  local success, profile = pcall(MP.Profiles.Deserialize, dataString)
  if not success or not profile then
    print("|cffff0000[MinimalPlates]|r Failed to import profile: Invalid data")
    return false
  end
  
  MinimalPlatesDB.profiles = MinimalPlatesDB.profiles or {}
  MinimalPlatesDB.profiles[name] = profile
  
  print("|cff00ff00[MinimalPlates]|r Profile '" .. name .. "' imported successfully")
  return true
end

-- Simple serialization (basic table to string)
function MP.Profiles.Serialize(tbl)
  local function serialize_value(v)
    local t = type(v)
    if t == "string" then
      return string.format("%q", v)
    elseif t == "number" or t == "boolean" then
      return tostring(v)
    elseif t == "table" then
      local result = "{"
      for key, value in pairs(v) do
        result = result .. "[" .. serialize_value(key) .. "]=" .. serialize_value(value) .. ","
      end
      return result .. "}"
    else
      return "nil"
    end
  end
  
  return serialize_value(tbl)
end

-- Simple deserialization (string to table)
function MP.Profiles.Deserialize(str)
  local func = loadstring("return " .. str)
  if func then
    return func()
  end
  return nil
end
