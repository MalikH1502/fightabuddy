-- src/server/DataService.server.luau
-- Owns all sessions. Nothing else touches DataStore directly.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerSession     = require(ReplicatedStorage.Shared.PlayerSession)

local sessions: {[number]: typeof(PlayerSession)} = {}

local function createLeaderstats(player: Player, session)
    local ls    = Instance.new("Folder")
    ls.Name     = "leaderstats"
    ls.Parent   = player

    local money   = Instance.new("IntValue")
    money.Name    = "Money"
    money.Value   = session:Get("money")
    money.Parent  = ls

    local ko      = Instance.new("IntValue")
    ko.Name       = "KO"
    ko.Value      = session:Get("KO")
    ko.Parent     = ls
end

local function onPlayerAdded(player: Player)
    local session = PlayerSession.new(player)
    sessions[player.UserId] = session
    session:Load()
    createLeaderstats(player, session)
end

local function onPlayerRemoving(player: Player)
    local session = sessions[player.UserId]
    if not session then return end
    session:Save()
    session:Destroy()
    sessions[player.UserId] = nil
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Catch players already in when script loads
for _, player in Players:GetPlayers() do
    task.spawn(onPlayerAdded, player)
end

-- Auto-save every 5 minutes without blocking
task.spawn(function()
    while true do
        task.wait(300)
        for _, session in sessions do
            task.spawn(function() session:Save() end)
        end
    end
end)

-- Server shutdown — save everyone synchronously
game:BindToClose(function()
    for _, session in sessions do
        session:Save()
    end
end)

-- Public API for other server scripts
-- Usage: local DataService = require(script)
--        DataService.GetSession(player):AddMoney(50)
local DataService = {}

function DataService.GetSession(player: Player)
    return sessions[player.UserId]
end

return DataService