---@class MinimalPlates
local MP = MinimalPlates

MP.Nameplates = {}

-- Active nameplate tracking
local activePlates = {}

-- Initialize nameplate system
function MP.Nameplates.Init()
  -- Initialize event handling
  MP.NameplateEvents.Init(activePlates)
  
  -- Start update loop
  MP.NameplateEvents.StartUpdateLoop()
end

-- Refresh all nameplates (public API)
function MP.Nameplates.RefreshAll()
  MP.NameplateEvents.RefreshAll()
end
