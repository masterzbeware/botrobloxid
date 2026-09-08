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

		if not LocalPlayer then
			return
		end

		--------------------------------------------------
		-- MODULES
		--------------------------------------------------

		local Admin = loadstring(game:HttpGet(
			"https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
		))()

		local Distance = loadstring(game:HttpGet(
			"https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Distance.lua"
		))()

		--------------------------------------------------
		-- GLOBAL VARIABLES
		--------------------------------------------------

		_G.BotVars = _G.BotVars or {}

		local vars = _G.BotVars

		vars.ModeControllers = vars.ModeControllers or {}

		--------------------------------------------------
		-- MODE NAME
		--------------------------------------------------

		local MODE_NAME = "vanguard"

		--------------------------------------------------
		-- BOT ORDER
		--------------------------------------------------

		local botOrder = {

			"11611503633", -- Bot 1
			"11611534165", -- Bot 2
			"11611567975", -- Bot 3
			"11611562042", -- Bot 4
			"11611591921", -- Bot 5
			"11122806815", -- Bot 6
			"11122806817", -- Bot 7
			"11122687468", -- Bot 8
			"11122854402", -- Bot 9

			"BOT10_USER_ID", -- Bot 10
			"BOT11_USER_ID", -- Bot 11
			"BOT12_USER_ID", -- Bot 12
			"BOT13_USER_ID", -- Bot 13
			"BOT14_USER_ID", -- Bot 14
		}

		--------------------------------------------------
		-- CONFIG
		--------------------------------------------------

		local Config = {

			--------------------------------------------------
			-- JARAK DARI PLAYER
			--------------------------------------------------

			FrontDistance = 5,

			--------------------------------------------------
			-- JARAK ANTAR BARIS
			--------------------------------------------------

			RowSpacing = 3,

			--------------------------------------------------
			-- JARAK SAMPING
			--------------------------------------------------

			SideSpacing = 3,

			--------------------------------------------------
			-- JARAK BOT INNER
			--------------------------------------------------

			InnerSpacing = 2,

			--------------------------------------------------
			-- BATAS BERHENTI
			--------------------------------------------------

			StopThreshold = 1.5,

			--------------------------------------------------
			-- UPDATE RATE
			--------------------------------------------------

			UpdateRate = 0.08,
		}

		--------------------------------------------------
		-- STOP MODE LAIN
		--------------------------------------------------

		local function stopOtherModes()

			for modeName, controller in pairs(vars.ModeControllers) do

				if modeName ~= MODE_NAME then

					if controller and controller.Stop then
						pcall(function()
							controller.Stop()
						end)
					end

				end
			end
		end

		--------------------------------------------------
		-- FIND PLAYER
		--------------------------------------------------

		local function getPlayerByUserId(userId)

			userId = tonumber(userId)

			if not userId then
				return nil
			end

			for _, player in ipairs(Players:GetPlayers()) do

				if player.UserId == userId then
					return player
				end

			end

			return nil
		end

		--------------------------------------------------
		-- FIND PLAYER BY NAME
		--------------------------------------------------

		local function getPlayerByName(name)

			if not name then
				return nil
			end

			name = string.lower(name)

			for _, player in ipairs(Players:GetPlayers()) do

				if string.lower(player.Name) == name
					or string.lower(player.DisplayName) == name then

					return player
				end

			end

			return nil
		end

		--------------------------------------------------
		-- GET CHARACTER ROOT
		--------------------------------------------------

		local function getRoot(player)

			if not player then
				return nil
			end

			local character = player.Character

			if not character then
				return nil
			end

			return character:FindFirstChild("HumanoidRootPart")
		end

		--------------------------------------------------
		-- GET BOT ROOT
		--------------------------------------------------

		local function getBotRoot(player)

			if not player then
				return nil
			end

			local character = player.Character

			if not character then
				return nil
			end

			return character:FindFirstChild("HumanoidRootPart")
		end

		--------------------------------------------------
		-- MOVE BOT
		--------------------------------------------------

		local function moveBot(bot, targetPosition)

			local character = bot.Character

			if not character then
				return
			end

			local humanoid = character:FindFirstChildOfClass("Humanoid")
			local hrp = character:FindFirstChild("HumanoidRootPart")

			if not humanoid or not hrp then
				return
			end

			local distance = (hrp.Position - targetPosition).Magnitude

			--------------------------------------------------
			-- MOVE
			--------------------------------------------------

			if distance > Config.StopThreshold then

				humanoid:MoveTo(targetPosition)

			end
		end

		--------------------------------------------------
		-- FACE SAME DIRECTION
		--------------------------------------------------

		local function faceTarget(bot, targetHRP)

			local myHRP = getBotRoot(bot)

			if not myHRP or not targetHRP then
				return
			end

			local targetRotation =
				CFrame.lookAt(
					myHRP.Position,
					myHRP.Position + targetHRP.CFrame.LookVector
				)

			myHRP.CFrame =
				CFrame.new(myHRP.Position)
				* CFrame.Angles(
					0,
					math.atan2(
						-targetRotation.LookVector.X,
						-targetRotation.LookVector.Z
					),
					0
				)
		end

		--------------------------------------------------
		-- FORMATION POSITION
		--------------------------------------------------

		local function getVanguardPosition(index, targetHRP)

			local origin = targetHRP.Position

			local forward = targetHRP.CFrame.LookVector
			local right = targetHRP.CFrame.RightVector

			--------------------------------------------------
			-- DEPTH
			--------------------------------------------------

			local d1 = Config.FrontDistance

			local d2 =
				d1 - Config.RowSpacing

			local d3 =
				d2 - Config.RowSpacing

			local d4 =
				d3 - Config.RowSpacing

			local d5 =
				d4 - Config.RowSpacing

			local d6 =
				d5 - Config.RowSpacing

			local d7 =
				d6 - Config.RowSpacing

			local d8 =
				d7 - Config.RowSpacing

			--------------------------------------------------
			-- BOT 1
			--------------------------------------------------

			if index == 1 then

				return
					origin
					+ forward * d1

			--------------------------------------------------
			-- BOT 2
			--------------------------------------------------

			elseif index == 2 then

				return
					origin
					+ forward * d2
					- right * Config.SideSpacing

			--------------------------------------------------
			-- BOT 3
			--------------------------------------------------

			elseif index == 3 then

				return
					origin
					+ forward * d2
					+ right * Config.SideSpacing

			--------------------------------------------------
			-- BOT 4
			--------------------------------------------------

			elseif index == 4 then

				return
					origin
					+ forward * d3
					- right * (Config.SideSpacing * 1.8)

			--------------------------------------------------
			-- BOT 5
			--------------------------------------------------

			elseif index == 5 then

				return
					origin
					+ forward * d3
					+ right * (Config.SideSpacing * 1.8)

			--------------------------------------------------
			-- BOT 6
			--------------------------------------------------

			elseif index == 6 then

				return
					origin
					+ forward * d4
					- right * (Config.SideSpacing * 2.5)

			--------------------------------------------------
			-- BOT 7
			--------------------------------------------------

			elseif index == 7 then

				return
					origin
					+ forward * d4
					+ right * (Config.SideSpacing * 2.5)

			--------------------------------------------------
			-- BOT 8
			--------------------------------------------------

			elseif index == 8 then

				return
					origin
					+ forward * d5
					- right * (Config.SideSpacing * 1.8)

			--------------------------------------------------
			-- BOT 9
			--------------------------------------------------

			elseif index == 9 then

				return
					origin
					+ forward * d5
					+ right * (Config.SideSpacing * 1.8)

			--------------------------------------------------
			-- BOT 10
			--------------------------------------------------

			elseif index == 10 then

				return
					origin
					+ forward * d5
					- right * Config.InnerSpacing

			--------------------------------------------------
			-- BOT 11
			--------------------------------------------------

			elseif index == 11 then

				return
					origin
					+ forward * d5
					+ right * Config.InnerSpacing

			--------------------------------------------------
			-- BOT 12
			--------------------------------------------------

			elseif index == 12 then

				return
					origin
					+ forward * d6
					- right * Config.InnerSpacing

			--------------------------------------------------
			-- BOT 13
			--------------------------------------------------

			elseif index == 13 then

				return
					origin
					+ forward * d6
					+ right * Config.InnerSpacing

			--------------------------------------------------
			-- BOT 14
			--------------------------------------------------

			elseif index == 14 then

				return
					origin
					+ forward * d7

			end

		end

		--------------------------------------------------
		-- CONTROLLER
		--------------------------------------------------

		local controller = {

			Active = false,

			Target = nil,

			Connection = nil,

			RespawnConnections = {},
		}

		--------------------------------------------------
		-- STOP
		--------------------------------------------------

		function controller.Stop()

			controller.Active = false
			controller.Target = nil

			if controller.Connection then

				controller.Connection:Disconnect()
				controller.Connection = nil

			end

			for _, connection in pairs(controller.RespawnConnections) do

				pcall(function()
					connection:Disconnect()
				end)

			end

			controller.RespawnConnections = {}

			if vars.ActiveMode == MODE_NAME then
				vars.ActiveMode = nil
			end

		end

		--------------------------------------------------
		-- START
		--------------------------------------------------

		function controller.Start(targetPlayer)

			if not targetPlayer then
				return
			end

			--------------------------------------------------
			-- STOP MODE LAIN
			--------------------------------------------------

			stopOtherModes()

			--------------------------------------------------
			-- STOP VANGUARD LAMA
			--------------------------------------------------

			controller.Stop()

			--------------------------------------------------
			-- SET STATE
			--------------------------------------------------

			controller.Active = true
			controller.Target = targetPlayer

			vars.ActiveMode = MODE_NAME

			--------------------------------------------------
			-- BOT RESPAWN HANDLER
			--------------------------------------------------

			for _, userId in ipairs(botOrder) do

				local bot = getPlayerByUserId(userId)

				if bot then

					local connection

					connection = bot.CharacterAdded:Connect(function()

						task.wait(1)

						if not controller.Active then
							return
						end

					end)

					table.insert(
						controller.RespawnConnections,
						connection
					)

				end
			end

			--------------------------------------------------
			-- UPDATE LOOP
			--------------------------------------------------

			controller.Connection =
				RunService.Heartbeat:Connect(function()

					if not controller.Active then
						return
					end

					local target = controller.Target

					if not target then

						controller.Stop()
						return

					end

					--------------------------------------------------
					-- TARGET CHARACTER
					--------------------------------------------------

					local targetHRP = getRoot(target)

					if not targetHRP then
						return
					end

					--------------------------------------------------
					-- CHECK TARGET DISTANCE
					--------------------------------------------------

					local localRoot = getRoot(LocalPlayer)

					if localRoot and target ~= LocalPlayer then

						local distance =
							Distance:GetDistance(
								LocalPlayer.UserId,
								target.UserId
							)

						if distance and distance > 1000 then
							return
						end

					end

					--------------------------------------------------
					-- MOVE EVERY BOT
					--------------------------------------------------

					for index, userId in ipairs(botOrder) do

						local bot =
							getPlayerByUserId(userId)

						if bot then

							--------------------------------------------------
							-- BOT CHARACTER
							--------------------------------------------------

							local botHRP =
								getBotRoot(bot)

							if botHRP then

								--------------------------------------------------
								-- TARGET POSITION
								--------------------------------------------------

								local targetPosition =
									getVanguardPosition(
										index,
										targetHRP
									)

								if targetPosition then

									--------------------------------------------------
									-- MOVE
									--------------------------------------------------

									moveBot(
										bot,
										targetPosition
									)

									--------------------------------------------------
									-- FACE PLAYER
									--------------------------------------------------

									faceTarget(
										bot,
										targetHRP
									)

								end

							end

						end

					end

				end)

			--------------------------------------------------
			-- START MESSAGE
			--------------------------------------------------

			pcall(function()

				local channel =
					TextChatService.TextChannels:FindFirstChild(
						"RBXGeneral"
					)

				if channel then

					channel:SendAsync(
						"Yes, Sir!"
					)

				end

			end)

		end

		--------------------------------------------------
		-- COMMAND HANDLER
		--------------------------------------------------

		local function handleCommand(sender, message)

			if not sender then
				return
			end

			if not message then
				return
			end

			--------------------------------------------------
			-- ONLY ADMIN
			--------------------------------------------------

			if not Admin:IsAdmin(sender) then
				return
			end

			local msg =
				string.lower(
					string.gsub(
						message,
						"^%s*(.-)%s*$",
						"%1"
					)
				)

			--------------------------------------------------
			-- STOP
			--------------------------------------------------

			if msg == "!stop"
				or msg == "!unvanguard" then

				controller.Stop()

				return
			end

			--------------------------------------------------
			-- VANGUARD
			--------------------------------------------------

			if string.sub(
				msg,
				1,
				9
			) == "!vanguard" then

				local targetName =
					string.sub(
						message,
						10
					)

				targetName =
					string.gsub(
						targetName,
						"^%s+",
						""
					)

				--------------------------------------------------
				-- DEFAULT TARGET = ADMIN
				--------------------------------------------------

				local targetPlayer = sender

				--------------------------------------------------
				-- TARGET PLAYER
				--------------------------------------------------

				if targetName ~= "" then

					local found =
						getPlayerByName(
							targetName
						)

					if found then
						targetPlayer = found
					end

				end

				--------------------------------------------------
				-- START
				--------------------------------------------------

				controller.Start(
					targetPlayer
				)

			end

		end

		--------------------------------------------------
		-- TEXT CHAT
		--------------------------------------------------

		local textConnection

		pcall(function()

			textConnection =
				TextChatService.MessageReceived:Connect(
					function(message)

						local textSource =
							message.TextSource

						if not textSource then
							return
						end

						local sender =
							Players:GetPlayerByUserId(
								textSource.UserId
							)

						if not sender then
							return
						end

						handleCommand(
							sender,
							message.Text
						)

					end
				)

		end)

		--------------------------------------------------
		-- OLD CHAT FALLBACK
		--------------------------------------------------

		local chatConnections = {}

		local function connectPlayerChat(player)

			if chatConnections[player] then
				return
			end

			local connection =
				player.Chatted:Connect(
					function(message)

						handleCommand(
							player,
							message
						)

					end
				)

			chatConnections[player] =
				connection

		end

		--------------------------------------------------
		-- EXISTING PLAYERS
		--------------------------------------------------

		for _, player in ipairs(
			Players:GetPlayers()
		) do

			connectPlayerChat(player)

		end

		--------------------------------------------------
		-- NEW PLAYERS
		--------------------------------------------------

		Players.PlayerAdded:Connect(
			function(player)

				connectPlayerChat(
					player
				)

			end
		)

		--------------------------------------------------
		-- LOCAL PLAYER RESPAWN
		--------------------------------------------------

		LocalPlayer.CharacterAdded:Connect(
			function()

				task.wait(1)

				if controller.Active
					and controller.Target then

					--------------------------------------------------
					-- LOOP WILL CONTINUE
					--------------------------------------------------

				end

			end
		)

		--------------------------------------------------
		-- REGISTER CONTROLLER
		--------------------------------------------------

		vars.ModeControllers[MODE_NAME] =
			controller

	end
}