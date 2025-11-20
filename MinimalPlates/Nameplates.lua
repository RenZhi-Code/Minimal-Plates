---@class MinimalPlates
local MP = MinimalPlates

MP.Nameplates = {}

-- Active nameplate tracking
local activePlates = {}

-- Initialize nameplate system
function MP.Nameplates.Init()
  -- Initialize DB cache to prevent nil errors
  if MP.Display and MP.Display.UpdateLogic and MP.Display.UpdateLogic.RefreshDBCache then
    MP.Display.UpdateLogic.RefreshDBCache()
  end
  
  -- Initialize event handling
  MP.NameplateEvents.Init(activePlates)
  
  -- Start update loop
  MP.NameplateEvents.StartUpdateLoop()
end

-- Refresh all nameplates (public API)
function MP.Nameplates.RefreshAll()
  MP.NameplateEvents.RefreshAll()
end
