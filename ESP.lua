--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Teams = game:GetService("Teams")

--// References
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

--// Settings
local enemyColor = Color3.fromRGB(255, 0, 0)
local teamColor = Color3.fromRGB(0, 0, 255)
local maxDistanceSquared = 8000 * 8000

--// Team Detection
local useTeamColors = Teams and #Teams:GetChildren() > 0

--// Internal
local ESP = {}
local updateConnection
local cleanupDone = false
local teleporting = false
local characterConnections = {}

--// Helpers
local function IsValidPosition(pos)
	return typeof(pos) == "Vector3"
		and pos.Magnitude < 1e6
		and pos.X == pos.X and pos.Y == pos.Y and pos.Z == pos.Z
end

local function CreateOrGetHighlight(player)
	local existing = ESP[player]
	if existing and existing.Parent then
		return existing
	end
	if existing then
		pcall(function() existing:Destroy() end)
	end

	local highlight = Instance.new("Highlight")
	highlight.Name = "ESP_Highlight"
	highlight.FillTransparency = 0.5
	highlight.OutlineTransparency = 0
	highlight.Enabled = false

	if player.Character and player.Character:IsDescendantOf(Workspace) then
		highlight.Parent = player.Character
	end

	ESP[player] = highlight
	return highlight
end

local function UpdateESP(player)
	pcall(function()
		if teleporting then return end
		local character = player.Character
		if not character then return end

		local hrp = character:FindFirstChild("HumanoidRootPart")
		if not hrp or not IsValidPosition(hrp.Position) then return end

		local camPos = Camera and Camera.CFrame.Position
		if not camPos then return end

		local highlight = ESP[player]
		if not highlight then return end

		local distanceSq = (camPos - hrp.Position).Magnitude^2
		if distanceSq < maxDistanceSquared then
			highlight.Enabled = true

			if useTeamColors and player.Team and LocalPlayer.Team then
				local sameTeam = player.Team == LocalPlayer.Team
				highlight.FillColor = sameTeam and teamColor or enemyColor
				highlight.OutlineColor = sameTeam and teamColor or enemyColor
			else
				highlight.FillColor = enemyColor
				highlight.OutlineColor = enemyColor
			end
		else
			highlight.Enabled = false
		end
	end)
end

local function SetupCharacter(player)
	task.defer(function()
		local character = player.Character
		if not character then return end

		local hrp = character:WaitForChild("HumanoidRootPart", 5)
		if not hrp then return end

		while not character:IsDescendantOf(Workspace) do
			task.wait()
		end

		if ESP[player] then
			pcall(function() ESP[player]:Destroy() end)
			ESP[player] = nil
		end

		local highlight = CreateOrGetHighlight(player)
		if character:IsDescendantOf(Workspace) then
			highlight.Parent = character
		end
	end)
end

local function OnPlayerAdded(player)
	if player == LocalPlayer then return end

	local conn = player.CharacterAdded:Connect(function()
		SetupCharacter(player)
	end)

	characterConnections[player] = conn

	if player.Character then
		SetupCharacter(player)
	end
end

local function OnPlayerRemoving(player)
	if characterConnections[player] then
		characterConnections[player]:Disconnect()
		characterConnections[player] = nil
	end

	if ESP[player] then
		pcall(function() ESP[player]:Destroy() end)
		ESP[player] = nil
	end
end

local function CleanupESP()
	if cleanupDone then return end
	cleanupDone = true

	if updateConnection then
		updateConnection:Disconnect()
		updateConnection = nil
	end

	for player, conn in pairs(characterConnections) do
		if conn then
			conn:Disconnect()
		end
	end
	table.clear(characterConnections)

	for _, highlight in pairs(ESP) do
		if highlight then
			pcall(function()
				highlight.Adornee = nil
				highlight:Destroy()
			end)
		end
	end
	table.clear(ESP)
end

--// Handle Teleport
pcall(function()
	LocalPlayer.OnTeleport:Connect(function()
		teleporting = true
		pcall(CleanupESP)
	end)
end)

--// Init
for _, player in ipairs(Players:GetPlayers()) do
	OnPlayerAdded(player)
end

Players.PlayerAdded:Connect(OnPlayerAdded)
Players.PlayerRemoving:Connect(OnPlayerRemoving)

--// Update loop
local updateIndex = 0
updateConnection = RunService.RenderStepped:Connect(function()
	if teleporting then return end

	updateIndex += 1
	if updateIndex % 2 ~= 0 then return end

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			UpdateESP(player)
		end
	end
end)
