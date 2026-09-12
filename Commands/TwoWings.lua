return {
	Execute = function()

		--------------------------------------------------
		-- SERVICES
		--------------------------------------------------

		local Players = game:GetService("Players")
		local RunService = game:GetService("RunService")
		local TextChatService = game:GetService("TextChatService")
		local ReplicatedStorage = game:GetService("ReplicatedStorage")

		local LocalPlayer = Players.LocalPlayer

		--------------------------------------------------
		-- MODULES
		--------------------------------------------------

		local Admin = loadstring(
			game:HttpGet(
				"https://raw.githubusercontent.com/..."
			)
		)()

		local Distance = loadstring(
			game:HttpGet(
				"https://raw.githubusercontent.com/..."
			)
		)()

		--------------------------------------------------
		-- CONFIG
		--------------------------------------------------

		local botIds = {
			"11611503633",
			"11611534165",
			"11611567975",
			"11611562042",
			"11611591921",
			"11122806815",
			"11122806817",
			"11122687468",
			"11122854402",
			"11641280895",
			"11641342530"
		}

		local sideSpacing = 2.5
		local stopThreshold = 1.5

		--------------------------------------------------
		-- MODE CONTROLLER
		--------------------------------------------------

		_G.BotVars = _G.BotVars or {}
		_G.BotVars.ModeControllers = _G.BotVars.ModeControllers or {}

		--------------------------------------------------
		-- GET CHARACTER
		--------------------------------------------------

		local function getCharacter()
			local character = LocalPlayer.Character

			if not character then
				return nil
			end

			local humanoid = character:FindFirstChildOfClass("Humanoid")
			local hrp = character:FindFirstChild("HumanoidRootPart")

			if not humanoid or not hrp then
				return nil
			end

			return character, humanoid, hrp
		end

		--------------------------------------------------
		-- GET FOLLOW DISTANCE
		--------------------------------------------------

		local function getFollowDistance(botUserId, targetUserId)

			local defaultDistance = 2

			-- Admin mendapatkan jarak lebih jauh
			if Admin and Admin.IsAdmin then
				local success, result = pcall(function()
					return Admin:IsAdmin(targetUserId)
				end)

				if success and result then
					defaultDistance = 3
				end
			end

			-- Distance module override
			if Distance then
				local success, result = pcall(function()
					return Distance:GetDistance(
						tostring(botUserId),
						tostring(targetUserId)
					)
				end)

				if success and typeof(result) == "number" then
					return result
				end
			end

			return defaultDistance
		end

		--------------------------------------------------
		-- FORMATION
		--------------------------------------------------

		local function getFormationOffset(index, distance)

			if index == 1 then

				-- B1
				-- Tepat di belakang player
				return Vector3.new(
					0,
					0,
					-distance
				)

			elseif index == 2 then

				-- B2
				-- Kiri B1
				return Vector3.new(
					-sideSpacing,
					0,
					-(distance * 2)
				)

			elseif index == 3 then

				-- B3
				-- Kanan B1
				return Vector3.new(
					sideSpacing,
					0,
					-(distance * 2)
				)

			elseif index == 4 then

				-- B4
				-- Tepat di belakang B2
				return Vector3.new(
					-sideSpacing,
					0,
					-(distance * 3)
				)

			elseif index == 5 then

				-- B5
				-- Tepat di belakang B3
				return Vector3.new(
					sideSpacing,
					0,
					-(distance * 3)
				)

			elseif index == 6 then

				-- B6
				-- Tepat di belakang B4
				return Vector3.new(
					-sideSpacing,
					0,
					-(distance * 4)
				)

			elseif index == 7 then

				-- B7
				-- Di sebelah kiri B6
				return Vector3.new(
					-(sideSpacing * 2),
					0,
					-(distance * 4)
				)

			elseif index == 8 then

				-- B8
				-- Di sebelah kiri B7
				return Vector3.new(
					-(sideSpacing * 3),
					0,
					-(distance * 4)
				)

			elseif index == 9 then

				-- B9
				-- Tepat di belakang B5
				return Vector3.new(
					sideSpacing,
					0,
					-(distance * 4)
				)

			elseif index == 10 then

				-- B10
				-- Di sebelah kanan B9
				return Vector3.new(
					sideSpacing * 2,
					0,
					-(distance * 4)
				)

			elseif index == 11 then

				-- B11
				-- Di sebelah kanan B10
				return Vector3.new(
					sideSpacing * 3,
					0,
					-(distance * 4)
				)
			end

			return Vector3.zero
		end

		--------------------------------------------------
		-- GET BOT PLAYER
		--------------------------------------------------

		local function getBotPlayer(userId)

			local targetId = tonumber(userId)

			if not targetId then
				return nil
			end

			return Players:GetPlayerByUserId(targetId)
		end

		--------------------------------------------------
		-- MOVE BOT
		--------------------------------------------------

		local function moveBot(botPlayer, targetHRP, index)

			if not botPlayer then
				return
			end

			local character = botPlayer.Character

			if not character then
				return
			end

			local humanoid = character:FindFirstChildOfClass("Humanoid")
			local hrp = character:FindFirstChild("HumanoidRootPart")

			if not humanoid or not hrp then
				return
			end

			if humanoid.Health <= 0 then
				return
			end

			--------------------------------------------------
			-- DISTANCE
			--------------------------------------------------

			local distance = getFollowDistance(
				botPlayer.UserId,
				LocalPlayer.UserId
			)

			--------------------------------------------------
			-- FORMATION OFFSET
			--------------------------------------------------

			local offset = getFormationOffset(
				index,
				distance
			)

			--------------------------------------------------
			-- WORLD POSITION
			--------------------------------------------------

			local targetPosition =
				targetHRP.Position
				+ targetHRP.CFrame.RightVector * offset.X
				+ targetHRP.CFrame.UpVector * offset.Y
				+ targetHRP.CFrame.LookVector * offset.Z

			--------------------------------------------------
			-- DISTANCE TO TARGET
			--------------------------------------------------

			local difference =
				targetPosition - hrp.Position

			local magnitude =
				difference.Magnitude

			--------------------------------------------------
			-- STOP IF CLOSE ENOUGH
			--------------------------------------------------

			if magnitude <= stopThreshold then
				humanoid:Move(Vector3.zero)
				return
			end

			--------------------------------------------------
			-- MOVE
			--------------------------------------------------

			local direction =
				difference.Unit

			humanoid:Move(direction)

		end

		--------------------------------------------------
		-- START TWO WINGS
		--------------------------------------------------

		local function startTwoWings()

			if _G.BotVars.ModeControllers.twowings then
				return
			end

			_G.BotVars.ModeControllers.twowings = true

			local connection

			connection = RunService.Heartbeat:Connect(function()

				--------------------------------------------------
				-- CHECK MODE
				--------------------------------------------------

				if not _G.BotVars.ModeControllers.twowings then

					if connection then
						connection:Disconnect()
					end

					return
				end

				--------------------------------------------------
				-- GET LOCAL PLAYER
				--------------------------------------------------

				local character, humanoid, targetHRP =
					getCharacter()

				if not character or not humanoid or not targetHRP then
					return
				end

				if humanoid.Health <= 0 then
					return
				end

				--------------------------------------------------
				-- MOVE ALL BOTS
				--------------------------------------------------

				for index, userId in ipairs(botIds) do

					local botPlayer =
						getBotPlayer(userId)

					if botPlayer then

						moveBot(
							botPlayer,
							targetHRP,
							index
						)

					end

				end

			end)

		end

		--------------------------------------------------
		-- STOP TWO WINGS
		--------------------------------------------------

		local function stopTwoWings()

			_G.BotVars.ModeControllers.twowings = nil

		end

		--------------------------------------------------
		-- COMMAND
		--------------------------------------------------

		local function handleCommand(message)

			local command =
				message:lower()

			if command == "!twowings" then

				startTwoWings()

			elseif command == "!stoptwowings" then

				stopTwoWings()

			end

		end

		--------------------------------------------------
		-- CHAT LISTENER
		--------------------------------------------------

		if TextChatService.ChatVersion
			== Enum.ChatVersion.TextChatService then

			TextChatService.MessageReceived:Connect(function(message)

				if message.TextSource
					and message.TextSource.UserId
					== LocalPlayer.UserId then

					handleCommand(message.Text)

				end

			end)

		end

	end
}