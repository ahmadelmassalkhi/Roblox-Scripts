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
local maxDistanceSquared = 1000 * 1000

--// Team Detection
local useTeamColors = Teams and #Teams:GetChildren() > 0

--// Internal
local ESP = {}

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
	highlight.Parent = player.Character

	ESP[player] = highlight
	return highlight
end

local function UpdateESP(player)
	local character = player.Character
	if not character then return end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp or not IsValidPosition(hrp.Position) then return end

	local highlight = ESP[player]
	if not highlight then return end

	local distanceSq = (Camera.CFrame.Position - hrp.Position).Magnitude^2
	if distanceSq < maxDistanceSquared then
		highlight.Enabled = true

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

		CreateOrGetHighlight(player)
	end)
end

local function OnPlayerAdded(player)
	if player == LocalPlayer then return end

	player.CharacterAdded:Connect(function()
		SetupCharacter(player)
	end)

	if player.Character then
		SetupCharacter(player)
	end
end

local function OnPlayerRemoving(player)
	if ESP[player] then
		ESP[player]:Destroy()
		ESP[player] = nil
	end
end

--// Cleanup Function
local function CleanupESP()
	for _, highlight in pairs(ESP) do
		if highlight then
			highlight:Destroy()
		end
	end
	table.clear(ESP)
end

--// Cleanup before teleport
LocalPlayer.OnTeleport:Connect(CleanupESP)

--// Init
for _, player in ipairs(Players:GetPlayers()) do
	OnPlayerAdded(player)
end

Players.PlayerAdded:Connect(OnPlayerAdded)
Players.PlayerRemoving:Connect(OnPlayerRemoving)

--// Main update loop (every other frame for performance)
local updateIndex = 0
RunService.RenderStepped:Connect(function()
	updateIndex += 1
	if updateIndex % 2 ~= 0 then return end

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			UpdateESP(player)
		end
	end
end)

--// Re-execute after teleport (safe)
local teleportScriptURL = "https://raw.githubusercontent.com/ahmadelmassalkhi/Roblox-Scripts/main/ESP.lua"

local execScript = string.format([[
	task.defer(function()
		repeat task.wait() until game:IsLoaded()
		loadstring(game:HttpGet("%s"))()
	end)
]], teleportScriptURL)

if syn and syn.queue_on_teleport then
	syn.queue_on_teleport(execScript)
elseif queue_on_teleport then
	queue_on_teleport(execScript)
end
