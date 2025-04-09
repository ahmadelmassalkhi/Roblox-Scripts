--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Teams = game:GetService("Teams")
local CoreGui = game:GetService("CoreGui")

--// References
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

--// Settings
local enemyColor = Color3.fromRGB(255, 0, 0)
local teamColor = Color3.fromRGB(0, 0, 255)
local maxDistanceSquared = 1000 * 1000

--// Team Detection
local useTeamColors = Teams and #Teams:GetChildren() > 0

--// Internal
local ESP = {}
local updateConnection
local cleanupDone = false
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
		existing:Destroy()
	end

	local highlight = Instance.new("Highlight")
	highlight.Name = "ESP_Highlight"
	highlight.FillTransparency = 0.5
	highlight.OutlineTransparency = 0
	highlight.Enabled = false
	highlight.Parent = CoreGui -- safer than parenting to Character

	ESP[player] = highlight
	return highlight
end

local function UpdateESP(player)
	local character = player.Character
	if not character or not character:IsDescendantOf(Workspace) then return end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp or not IsValidPosition(hrp.Position) then return end

	local highlight = ESP[player]
	if not highlight then return end

	local distanceSq = (Camera.CFrame.Position - hrp.Position).Magnitude^2
	if distanceSq < maxDistanceSquared then
		highlight.Enabled = true
		highlight.Adornee = hrp

		if useTeamColors and player.Team and LocalPlayer.Team then
			if player.Team == LocalPlayer.Team then
				highlight.FillColor = teamColor
				highlight.OutlineColor = teamColor
			else
				highlight.FillColor = enemyColor
				highlight.OutlineColor = enemyColor
			end
		else
			highlight.FillColor = enemyColor
			highlight.OutlineColor = enemyColor
		end
	else
		highlight.Enabled = false
	end
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
			ESP[player]:Destroy()
			ESP[player] = nil
		end

		local highlight = CreateOrGetHighlight(player)
		highlight.Adornee = hrp
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
		ESP[player]:Destroy()
		ESP[player] = nil
	end
end

--// Strong Cleanup
local function CleanupESP()
	if cleanupDone then return end
	cleanupDone = true

	-- Disconnect updates
	if updateConnection then
		updateConnection:Disconnect()
	end

	-- Disconnect character connections
	for player, conn in pairs(characterConnections) do
		if conn then
			conn:Disconnect()
		end
	end
	table.clear(characterConnections)

	-- Destroy all highlights
	for _, highlight in pairs(ESP) do
		if highlight then
			pcall(function()
				highlight.Adornee = nil -- break link to HRP
				highlight:Destroy()
			end)
		end
	end
	table.clear(ESP)
end

--// Cleanup on Teleport
pcall(function()
	LocalPlayer.OnTeleport:Connect(function()
		pcall(CleanupESP)
	end)
end)

--// Init
for _, player in ipairs(Players:GetPlayers()) do
	OnPlayerAdded(player)
end

Players.PlayerAdded:Connect(OnPlayerAdded)
Players.PlayerRemoving:Connect(OnPlayerRemoving)

--// Main update loop (every other frame)
local updateIndex = 0
updateConnection = RunService.RenderStepped:Connect(function()
	updateIndex += 1
	if updateIndex % 2 ~= 0 then return end

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			UpdateESP(player)
		end
	end
end)
