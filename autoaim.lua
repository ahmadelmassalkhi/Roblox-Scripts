--// Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

--// Variables
local rightClickHeld = false
local currentTarget = nil
local renderConnection = nil
local inputBeganConn, inputEndedConn = nil, nil
local PREFER_PLAYER_INSIGHT = true  -- Flag to prefer players in sight

--// Functions
local function IsSameTeam(player)
	return LocalPlayer.Team and player.Team and LocalPlayer.Team == player.Team
end

local function IsInSight(hrp)
	local ray = Ray.new(Camera.CFrame.Position, (hrp.Position - Camera.CFrame.Position).Unit * 500)
	local hitPart = Workspace:FindPartOnRay(ray, LocalPlayer.Character, false, true)
	return hitPart == hrp
end

local function GetClosestHumanoid()
	local closest, minDist = nil, math.huge
	local screenCenter = Camera.ViewportSize * 0.5
	local closestDistToCenter = math.huge
	local closestInSight = nil
	local closestBehindWall = nil

	for _, player in ipairs(Players:GetPlayers()) do
		if player == LocalPlayer or not player.Character or IsSameTeam(player) then continue end

		local hrp = player.Character:FindFirstChild("HumanoidRootPart")
		local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
		if not hrp or not humanoid or humanoid.Health <= 0 then continue end

		local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
		if not onScreen then continue end

		local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
		if PREFER_PLAYER_INSIGHT then
			if IsInSight(hrp) then
				if dist < closestDistToCenter then
					closestDistToCenter = dist
					closestInSight = humanoid
				end
			else
				if dist < minDist then
					minDist = dist
					closestBehindWall = humanoid
				end
			end
		else
			if dist < minDist then
				minDist = dist
				closest = humanoid
			end
		end
	end

	if PREFER_PLAYER_INSIGHT then
		if closestInSight then
			return closestInSight  -- Prefer the in-sight target
		else
			return closestBehindWall  -- Fall back to the behind-wall target
		end
	end

	return closest  -- Default to closest if no preference
end

--// Input handlers
inputBeganConn = UserInputService.InputBegan:Connect(function(input, processed)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		rightClickHeld = true
		currentTarget = GetClosestHumanoid()
	end
end)

inputEndedConn = UserInputService.InputEnded:Connect(function(input, processed)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		rightClickHeld = false
		currentTarget = nil
	end
end)

--// Aimbot render loop
renderConnection = RunService.RenderStepped:Connect(function()
	if not rightClickHeld or not currentTarget then return end

	local targetHRP = currentTarget.Parent and currentTarget.Parent:FindFirstChild("HumanoidRootPart")
	if not targetHRP then return end

	local camPos = Camera.CFrame.Position
	Camera.CFrame = CFrame.new(camPos, targetHRP.Position)
end)

--// Cleanup on teleport or session end
LocalPlayer.OnTeleport:Connect(function()
	if renderConnection then
		renderConnection:Disconnect()
		renderConnection = nil
	end
	if inputBeganConn then
		inputBeganConn:Disconnect()
		inputBeganConn = nil
	end
	if inputEndedConn then
		inputEndedConn:Disconnect()
		inputEndedConn = nil
	end
	currentTarget = nil
	rightClickHeld = false
end)
