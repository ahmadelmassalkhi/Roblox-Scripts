--// Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

--// References
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

--// Settings
local maxDistance = 1000 -- max aim range
local aimSmoothness = 0.3 -- lower is snappier
local rightClickActive = false

--// Highlight Tracking
local currentTarget = nil
local currentHighlight = nil

--// Utility Functions
local function IsOnScreen(worldPos)
	local screenPos, onScreen = Camera:WorldToViewportPoint(worldPos)
	return onScreen, screenPos
end

local function IsVisible(origin, target)
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Blacklist
	rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
	local result = Workspace:Raycast(origin, (target - origin), rayParams)
	return not result or result.Instance:IsDescendantOf(Players)
end

local function GetClosestTarget()
	local closest
	local smallestDist = math.huge
	local cameraPos = Camera.CFrame.Position

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character then
			local hrp = player.Character:FindFirstChild("HumanoidRootPart")
			local humanoid = player.Character:FindFirstChildOfClass("Humanoid")

			if hrp and humanoid and humanoid.Health > 0 then
				local onScreen, screenPos = IsOnScreen(hrp.Position)
				if onScreen then
					local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
					local dist = (screenCenter - Vector2.new(screenPos.X, screenPos.Y)).Magnitude

					if dist < smallestDist then
						if IsVisible(cameraPos, hrp.Position) then
							smallestDist = dist
							closest = hrp
						end
					end
				end
			end
		end
	end

	return closest
end

local function AimAt(target)
	if not target then
		if currentHighlight then
			currentHighlight:Destroy()
			currentHighlight = nil
			currentTarget = nil
		end
		return
	end

	-- Visual highlight
	if target.Parent ~= currentTarget then
		if currentHighlight then
			currentHighlight:Destroy()
		end

		local highlight = Instance.new("Highlight")
		highlight.Name = "AutoAim_Highlight"
		highlight.Adornee = target.Parent
		highlight.FillColor = Color3.fromRGB(255, 255, 0)
		highlight.OutlineColor = Color3.fromRGB(255, 170, 0)
		highlight.FillTransparency = 0.5
		highlight.OutlineTransparency = 0
		highlight.Parent = target.Parent

		currentHighlight = highlight
		currentTarget = target.Parent
	end

	-- Aim at target
	local cameraCF = Camera.CFrame
	local targetDirection = (target.Position - cameraCF.Position).Unit
	local newCFrame = CFrame.lookAt(cameraCF.Position, cameraCF.Position + targetDirection)
	Camera.CFrame = cameraCF:Lerp(newCFrame, aimSmoothness)
end

--// Input Handlers
UserInputService.InputBegan:Connect(function(input, processed)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		rightClickActive = true
	end
end)

UserInputService.InputEnded:Connect(function(input, processed)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		rightClickActive = false

		-- Cleanup highlight
		if currentHighlight then
			currentHighlight:Destroy()
			currentHighlight = nil
			currentTarget = nil
		end
	end
end)

--// Main Loop
RunService.RenderStepped:Connect(function()
	if not rightClickActive then return end
	if Camera.CameraType ~= Enum.CameraType.Custom then return end
	if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end

	local target = GetClosestTarget()
	AimAt(target)
end)
