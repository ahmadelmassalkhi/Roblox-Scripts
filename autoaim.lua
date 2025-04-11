local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local rightClickHeld = false
local currentTarget = nil

local IGNORE_WALLS = false -- true = aimbot through walls, false = only aim at visible targets

local function IsSameTeam(player)
	return LocalPlayer.Team and player.Team and LocalPlayer.Team == player.Team
end

local function IsVisible(targetPos, targetCharacter)
	local origin = Camera.CFrame.Position
	local direction = targetPos - origin
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, targetCharacter, Camera}
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	raycastParams.IgnoreWater = true

	local result = Workspace:Raycast(origin, direction.Unit * direction.Magnitude, raycastParams)
	return not result or result.Instance:IsDescendantOf(targetCharacter)
end

local function GetClosestHumanoid()
	local closest, minDist = nil, math.huge
	local screenCenter = Camera.ViewportSize * 0.5

	for _, player in ipairs(Players:GetPlayers()) do
		if player == LocalPlayer or not player.Character or IsSameTeam(player) then continue end

		local hrp = player.Character:FindFirstChild("HumanoidRootPart")
		local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
		if not hrp or not humanoid or humanoid.Health <= 0 then continue end

		local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
		if not onScreen then continue end

		if not IGNORE_WALLS and not IsVisible(hrp.Position, player.Character) then continue end

		local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
		if dist < minDist then
			minDist = dist
			closest = humanoid
		end
	end

	return closest
end

UserInputService.InputBegan:Connect(function(input, processed)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		rightClickHeld = true
		currentTarget = GetClosestHumanoid()
	end
end)

UserInputService.InputEnded:Connect(function(input, processed)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		rightClickHeld = false
		currentTarget = nil
	end
end)

RunService.RenderStepped:Connect(function()
	if not rightClickHeld then return end

	if not currentTarget or currentTarget.Health <= 0 then
		currentTarget = GetClosestHumanoid()
		if not currentTarget then return end
	end

	local targetHRP = currentTarget.Parent:FindFirstChild("HumanoidRootPart")
	if not targetHRP then return end

	local camPos = Camera.CFrame.Position
	Camera.CFrame = CFrame.new(camPos, targetHRP.Position)
end)


print("YOU DONT HAVE TO CLOSE AND RE-OPEN THE GAME")