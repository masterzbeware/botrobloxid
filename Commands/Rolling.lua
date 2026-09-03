--// Rolling.lua

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

--==================================================
-- CONFIG
--==================================================

local Admin = loadstring(game:HttpGet(
	"https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
))()

local Distance = loadstring(game:HttpGet(
	"https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Distance.lua"
))()

--==================================================
-- BOT ORDER
--==================================================

local botOrder = {
	"11611503633", -- BOT 1
	"11611534165", -- BOT 2
	"11611567975", -- BOT 3
	"11611562042", -- BOT 4
	"11611591921", -- BOT 5
	"11122806815", -- BOT 6
	"11122806817", -- BOT 7
	"11122687468", -- BOT 8
	"11122854402", -- BOT 9
}

--==================================================
-- CONFIG FORMATION
--==================================================

local sideSpacing = 2.5
local rowSpacing = 3

local moveSpeed = 10
local stopThreshold = 1.5

local centerOffset = 0

local rollingDelay = 0.35
local arriveDelay = 0.15

--==================================================
-- GLOBAL
--==================================================

_G.BotVars = _G.BotVars or {}
_G.BotVars.ModeControllers = _G.BotVars.ModeControllers or {}

local running = false
local heartbeatConnection = nil

local rollingCoroutine = nil

--==================================================
-- BOT INDEX
--==================================================

local function getMyIndex()
	local userId = tostring(LocalPlayer.UserId)

	for index, id in ipairs(botOrder) do
		if id == userId then
			return index
		end
	end

	return nil
end

local myIndex = getMyIndex()

if not myIndex then
	return
end

--==================================================
-- CHARACTER
--==================================================

local character
local humanoid
local rootPart

local function updateCharacter()
	character = LocalPlayer.Character

	if not character then
		return false
	end

	humanoid = character:FindFirstChildOfClass("Humanoid")
	rootPart = character:FindFirstChild("HumanoidRootPart")

	if not humanoid or not rootPart then
		return false
	end

	humanoid.AutoRotate = true

	return true
end

updateCharacter()

--==================================================
-- CHAT
--==================================================

local function sendChat(message)
	pcall(function()
		local textChannels = TextChatService:FindFirstChild("TextChannels")

		if textChannels then
			local general = textChannels:FindFirstChild("RBXGeneral")

			if general then
				general:SendAsync(message)
				return
			end
		end

		local defaultChat = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")

		if defaultChat then
			local sayMessageRequest = defaultChat:FindFirstChild("SayMessageRequest")

			if sayMessageRequest then
				sayMessageRequest:FireServer(message, "All")
			end
		end
	end)
end

--==================================================
-- DISTANCE
--==================================================

local function getBotDistance(player)
	local distance = 1

	if Admin:IsAdmin(player) then
		distance = 1
	end

	pcall(function()
		if Distance and Distance.GetDistance then
			local value = Distance:GetDistance(
				tostring(LocalPlayer.UserId),
				tostring(player.UserId)
			)

			if typeof(value) == "number" then
				distance = value
			end
		end
	end)

	return distance
end

--==================================================
-- FIND PLAYER TARGET
--==================================================

local function getTargetPlayer()
	local closestPlayer = nil
	local closestDistance = math.huge

	if not rootPart then
		return nil
	end

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			local targetCharacter = player.Character

			if targetCharacter then
				local targetRoot =
					targetCharacter:FindFirstChild("HumanoidRootPart")

				if targetRoot then
					local distance =
						(rootPart.Position - targetRoot.Position).Magnitude

					if distance < closestDistance then
						closestDistance = distance
						closestPlayer = player
					end
				end
			end
		end
	end

	return closestPlayer
end

--==================================================
-- FORMATION POSITION
--==================================================

local function getFormationPosition(index, targetRoot, distance)
	if not targetRoot then
		return nil
	end

	--==================================================
	-- CURRENT ROLLING POSITIONS
	--
	-- LEFT:
	-- BOT 1
	-- BOT 3
	-- BOT 5
	-- BOT 7
	--
	-- RIGHT:
	-- BOT 2
	-- BOT 4
	-- BOT 6
	-- BOT 8
	--
	-- BOT 9:
	-- RIGHT / PALING BELAKANG
	--==================================================

	local row
	local side

	if index == 9 then
		row = 5
		side = 1
	else
		row = math.ceil(index / 2)

		if index % 2 == 1 then
			side = -1
		else
			side = 1
		end
	end

	local backDistance =
		distance +
		((row - 1) * rowSpacing)

	local backOffset =
		targetRoot.CFrame.LookVector *
		-backDistance

	local sideOffset =
		targetRoot.CFrame.RightVector *
		(sideSpacing * side)

	return targetRoot.Position
		+ backOffset
		+ sideOffset
end

--==================================================
-- CENTER POSITION
--==================================================

local function getCenterPosition(targetRoot, distance)
	if not targetRoot then
		return nil
	end

	local backDistance = distance + centerOffset

	return targetRoot.Position
		- targetRoot.CFrame.LookVector * backDistance
end

--==================================================
-- MOVE TO POSITION
--==================================================

local function moveToPosition(position)
	if not position then
		return false
	end

	if not updateCharacter() then
		return false
	end

	while running and rootPart and humanoid do
		local currentPosition = rootPart.Position
		local difference = position - currentPosition

		local magnitude = difference.Magnitude

		if magnitude <= stopThreshold then
			humanoid:Move(Vector3.zero, false)
			return true
		end

		local direction = difference.Unit

		humanoid:Move(direction, false)

		RunService.Heartbeat:Wait()

		if not rootPart or not humanoid then
			break
		end
	end

	return false
end

--==================================================
-- MOVE TO FORMATION POSITION
--==================================================

local function moveToFormation(index, targetPlayer)
	if not targetPlayer then
		return false
	end

	local targetCharacter = targetPlayer.Character

	if not targetCharacter then
		return false
	end

	local targetRoot =
		targetCharacter:FindFirstChild("HumanoidRootPart")

	if not targetRoot then
		return false
	end

	local distance = getBotDistance(targetPlayer)

	local position =
		getFormationPosition(
			index,
			targetRoot,
			distance
		)

	return moveToPosition(position)
end

--==================================================
-- ROLLING SEQUENCE
--==================================================

local function executeLeftRolling(targetPlayer)
	if not targetPlayer then
		return
	end

	-- BOT 1 keluar dari posisi depan
	if myIndex == 1 then
		local targetRoot =
			targetPlayer.Character
			and targetPlayer.Character:FindFirstChild("HumanoidRootPart")

		if not targetRoot then
			return
		end

		local distance = getBotDistance(targetPlayer)

		-- Bergerak ke tengah
		local centerPosition =
			getCenterPosition(targetRoot, distance)

		moveToPosition(centerPosition)

		task.wait(arriveDelay)

		-- Lalu menuju posisi belakang BOT 7
		moveToFormation(7, targetPlayer)

		return
	end

	-- BOT 3 maju mengisi posisi BOT 1
	if myIndex == 3 then
		task.wait(rollingDelay)

		moveToFormation(1, targetPlayer)

		return
	end

	-- BOT 5 maju mengisi posisi BOT 3
	if myIndex == 5 then
		task.wait(rollingDelay * 2)

		moveToFormation(3, targetPlayer)

		return
	end

	-- BOT 7 maju mengisi posisi BOT 5
	if myIndex == 7 then
		task.wait(rollingDelay * 3)

		moveToFormation(5, targetPlayer)

		return
	end

	-- BOT 9 maju mengisi posisi BOT 7
	if myIndex == 9 then
		task.wait(rollingDelay * 4)

		moveToFormation(7, targetPlayer)

		return
	end
end

local function executeRightRolling(targetPlayer)
	if not targetPlayer then
		return
	end

	-- BOT 2 keluar dari posisi depan
	if myIndex == 2 then
		local targetRoot =
			targetPlayer.Character
			and targetPlayer.Character:FindFirstChild("HumanoidRootPart")

		if not targetRoot then
			return
		end

		local distance = getBotDistance(targetPlayer)

		-- Bergerak ke tengah
		local centerPosition =
			getCenterPosition(targetRoot, distance)

		moveToPosition(centerPosition)

		task.wait(arriveDelay)

		-- Lalu ke belakang BOT 9
		local position =
			getFormationPosition(
				9,
				targetRoot,
				distance
			)

		moveToPosition(position)

		return
	end

	-- BOT 4 maju mengisi BOT 2
	if myIndex == 4 then
		task.wait(rollingDelay)

		moveToFormation(2, targetPlayer)

		return
	end

	-- BOT 6 maju mengisi BOT 4
	if myIndex == 6 then
		task.wait(rollingDelay * 2)

		moveToFormation(4, targetPlayer)

		return
	end

	-- BOT 8 maju mengisi BOT 6
	if myIndex == 8 then
		task.wait(rollingDelay * 3)

		moveToFormation(6, targetPlayer)

		return
	end
end

--==================================================
-- CONTINUOUS FOLLOW
--==================================================

local function followFormation(targetPlayer)
	if not targetPlayer then
		return
	end

	while running do
		if not updateCharacter() then
			task.wait(0.5)
			continue
		end

		local targetCharacter = targetPlayer.Character

		if not targetCharacter then
			task.wait(0.5)
			continue
		end

		local targetRoot =
			targetCharacter:FindFirstChild("HumanoidRootPart")

		if not targetRoot then
			task.wait(0.5)
			continue
		end

		local distance = getBotDistance(targetPlayer)

		local position =
			getFormationPosition(
				myIndex,
				targetRoot,
				distance
			)

		if position then
			local difference =
				position - rootPart.Position

			if difference.Magnitude > stopThreshold then
				humanoid:Move(
					difference.Unit,
					false
				)
			else
				humanoid:Move(
					Vector3.zero,
					false
				)
			end
		end

		RunService.Heartbeat:Wait()
	end
end

--==================================================
-- NORMAL ROLLING
--==================================================

local function startRolling()
	if running then
		return
	end

	running = true

	rollingCoroutine = task.spawn(function()
		while running do
			local targetPlayer = getTargetPlayer()

			if not targetPlayer then
				task.wait(1)
				continue
			end

			--==================================================
			-- LEFT SIDE ROLL
			--==================================================

			if myIndex == 1
				or myIndex == 3
				or myIndex == 5
				or myIndex == 7
				or myIndex == 9 then

				executeLeftRolling(targetPlayer)

			--==================================================
			-- RIGHT SIDE ROLL
			--==================================================

			elseif myIndex == 2
				or myIndex == 4
				or myIndex == 6
				or myIndex == 8 then

				executeRightRolling(targetPlayer)
			end

			task.wait(rollingDelay)

			--==================================================
			-- FOLLOW CURRENT POSITION
			--==================================================

			followFormation(targetPlayer)

			task.wait(0.5)
		end
	end)
end

--==================================================
-- STOP
--==================================================

local function stopRolling()
	running = false

	if humanoid then
		humanoid:Move(Vector3.zero, false)
	end

	if rollingCoroutine then
		task.cancel(rollingCoroutine)
		rollingCoroutine = nil
	end
end

--==================================================
-- STOP OTHER MODES
--==================================================

local function stopOtherModes()
	if not _G.BotVars.ModeControllers then
		return
	end

	for modeName, stopFunction in pairs(
		_G.BotVars.ModeControllers
	) do
		if modeName ~= "Rolling" then
			pcall(stopFunction)
		end
	end
end

--==================================================
-- REGISTER MODE
--==================================================

_G.BotVars.ModeControllers.Rolling = stopRolling

--==================================================
-- CHAT COMMAND
--==================================================

local function handleCommand(message)
	if not Admin:IsAdmin(LocalPlayer) then
		return
	end

	local msg = message:lower()

	if msg == "!rolling" then
		stopOtherModes()
		startRolling()
		sendChat("Rolling formation aktif.")

	elseif msg == "!stop" then
		stopRolling()
	end
end

--==================================================
-- TEXT CHAT
--==================================================

pcall(function()
	TextChatService.MessageReceived:Connect(function(message)
		if message.TextSource then
			local senderUserId =
				message.TextSource.UserId

			if senderUserId == LocalPlayer.UserId then
				handleCommand(message.Text)
			end
		end
	end)
end)

--==================================================
-- CHARACTER RESPAWN
--==================================================

LocalPlayer.CharacterAdded:Connect(function()
	task.wait(1)

	updateCharacter()

	if running then
		stopRolling()

		task.wait(0.5)

		startRolling()
	end
end)

--==================================================
-- START
--==================================================

startRolling()