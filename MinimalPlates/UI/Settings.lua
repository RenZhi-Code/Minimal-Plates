---@class MinimalPlates
local MP = MinimalPlates

-- Initialize settings - No Blizzard panel needed, use standalone UI only
MP.Settings = {}

function MP.Settings.Init()
  -- Initialize SharedMedia for font/texture discovery
  MP.SharedMedia.Initialize()

  -- Settings UI is opened via /mp or /mp config commands
  -- No need for Blizzard Interface Options panel
end
