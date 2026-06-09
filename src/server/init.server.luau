local serverRoot = game:GetService("ServerScriptService")
local playerDataService = serverRoot:FindFirstChild("PlayerDataService")

if not playerDataService then
	local nestedServer = serverRoot:FindFirstChild("Server")
	if nestedServer then
		playerDataService = nestedServer:FindFirstChild("PlayerDataService")
	end
end

assert(playerDataService, "PlayerDataService module not found")
require(playerDataService)
