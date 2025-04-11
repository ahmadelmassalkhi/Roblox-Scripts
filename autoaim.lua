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
	local closestInSight = nil
	local closestBehindWall = nil
	local minDistToCenterInSight = math.huge
	local minDistToCenterBehindWall = math.huge
	local screenCenter = Camera.ViewportSize * 0.5

	-- Loop through all players
	for _, player in ipairs(Players:GetPlayers()) do
		if player == LocalPlayer or not player.Character or IsSameTeam(player) then continue end

		local hrp = player.Character:FindFirstChild("HumanoidRootPart")
		local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
		if not hrp or not humanoid or humanoid.Health <= 0 then continue end

		local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
		if not onScreen then continue end

		local distToCenter = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude

		if IsInSight(hrp) then
			-- If player is in sight
			if distToCenter < minDistToCenterInSight then
				minDistToCenterInSight = distToCenter
				closestInSight = humanoid
			end
		else
			-- If player is behind a wall
			if distToCenter < minDistToCenterBehindWall then
				minDistToCenterBehindWall = distToCenter
				closestBehindWall = humanoid
			end
		end
	end

	-- Prefer in-sight player if flag is set
	if PREFER_PLAYER_INSIGHT then
		if closestInSight then
			return closestInSight  -- Prefer the in-sight target
		end
	end

	-- Return whichever target is closer (either behind wall or in sight)
	if closestInSight and closestBehindWall then
		return minDistToCenterInSight < minDistToCenterBehindWall and closestInSight or closestBehindWall
	end

	-- Fall back to whatever is found (either behind wall or in sight)
	return closestInSight or closestBehindWall
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
