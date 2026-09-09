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
		-- GLOBAL MODE SYSTEM
		--------------------------------------------------

		_G.BotVars = _G.BotVars or {}

		_G.BotVars.ModeControllers =
			_G.BotVars.ModeControllers or {}

		local vars = _G.BotVars

		--------------------------------------------------
		-- LOAD ADMIN
		--------------------------------------------------

		local Admin = loadstring(game:HttpGet(
			"https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
		))()

		--------------------------------------------------
		-- LOAD DISTANCE
		--------------------------------------------------

		local Distance = loadstring(game:HttpGet(
			"https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Distance.lua"
		))()

		--------------------------------------------------
		-- CHARACTER
		--------------------------------------------------

		local humanoid
		local myHRP

		--------------------------------------------------
		-- STATE
		--------------------------------------------------

		local arrowActive = false
		local arrowConnection = nil
		local targetPlayer = nil

		--------------------------------------------------
		-- BOT ORDER
		--------------------------------------------------
		-- BOT 1 - BOT 11 IKUT FORMASI
		-- BOT 12 - BOT 14 TIDAK IKUT
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
			"11641280895", -- Bot 10
			"11641342530", -- Bot 11

		}

		--------------------------------------------------
		-- ARROW FORMATION SETTINGS
		--------------------------------------------------

		-- Jarak dasar dari Player
		local baseDistance = 5

		-- Jarak antar bot yang berada pada batang panah
		local bodySpacing = 3

		-- Jarak kiri / kanan kepala panah
		local sideSpacing = 3

		-- Jarak kiri / kanan bagian bawah kepala panah
		local lowerSideSpacing = 2

		-- Jarak minimum sebelum dianggap sampai
		local stopThreshold = 1.5

		--------------------------------------------------
		-- UPDATE CHARACTER
		--------------------------------------------------

		local function updateCharacter()

			local character =
				LocalPlayer.Character
				or LocalPlayer.CharacterAdded:Wait()

			humanoid =
				character:WaitForChild("Humanoid")

			myHRP =
				character:WaitForChild("HumanoidRootPart")

			humanoid.AutoRotate = true

		end

		updateCharacter()

		--------------------------------------------------
		-- SEND CHAT
		--------------------------------------------------

		local function sendChat(message)

			if not message then
				return
			end

			local success = false

			--------------------------------------------------
			-- TEXT CHAT
			--------------------------------------------------

			if TextChatService
				and TextChatService.TextChannels then

				local channel =
					TextChatService.TextChannels
					:FindFirstChild("RBXGeneral")

				if channel then

					pcall(function()

						channel:SendAsync(message)

					end)

					success = true

				end

			end

			--------------------------------------------------
			-- OLD CHAT FALLBACK
			--------------------------------------------------

			if not success then

				pcall(function()

					local chatEvents =
						ReplicatedStorage
						:FindFirstChild(
							"DefaultChatSystemChatEvents"
						)

					if not chatEvents then
						return
					end

					local sayMessageRequest =
						chatEvents:FindFirstChild(
							"SayMessageRequest"
						)

					if sayMessageRequest then

						sayMessageRequest:FireServer(
							message,
							"All"
						)

					end

				end)

			end

		end

		--------------------------------------------------
		-- STOP ARROW
		--------------------------------------------------

		local function stopArrow()

			arrowActive = false
			targetPlayer = nil

			if arrowConnection then

				arrowConnection:Disconnect()
				arrowConnection = nil

			end

			if humanoid then

				humanoid.AutoRotate = true

			end

		end

		--------------------------------------------------
		-- REGISTER CONTROLLER
		--------------------------------------------------

		vars.ModeControllers.arrow =
			stopArrow

		--------------------------------------------------
		-- STOP OTHER MODES
		--------------------------------------------------

		local function stopOtherModes()

			for name, stopFunction in
				pairs(vars.ModeControllers) do

				if name ~= "arrow"
					and type(stopFunction) == "function" then

					pcall(stopFunction)

				end

			end

		end

		--------------------------------------------------
		-- FIND PLAYER
		--------------------------------------------------

		local function findPlayerByName(name)

			if not name or name == "" then
				return nil
			end

			name = name:lower()

			--------------------------------------------------
			-- EXACT MATCH
			--------------------------------------------------

			for _, player in
				ipairs(Players:GetPlayers()) do

				if player.Name:lower() == name
					or player.DisplayName:lower() == name then

					return player

				end

			end

			--------------------------------------------------
			-- PARTIAL MATCH
			--------------------------------------------------

			for _, player in
				ipairs(Players:GetPlayers()) do

				if player.Name:lower():find(
					name,
					1,
					true
				)
					or player.DisplayName:lower():find(
						name,
						1,
						true
					) then

					return player

				end

			end

			return nil

		end

		--------------------------------------------------
		-- GET DISTANCE
		--------------------------------------------------

		local function getBotDistance(player)

			local distance = baseDistance

			--------------------------------------------------
			-- ADMIN DISTANCE
			--------------------------------------------------

			if Admin:IsAdmin(player) then

				distance = baseDistance

			end

			--------------------------------------------------
			-- SPECIAL DISTANCE
			--------------------------------------------------

			local specialDistance =
				Distance:GetDistance(
					tostring(LocalPlayer.UserId),
					tostring(player.UserId)
				)

			if specialDistance then

				distance = specialDistance

			end

			return distance

		end

		--------------------------------------------------
		-- GET ARROW POSITION
		--------------------------------------------------
		--
		-- FORMASI:
		--
		--                     B1
		--                     ▲
		--                     B2
		--                     ▲
		--                     B3
		--                     ▲
		--                     B4
		--                     ▲
		--           B5        B6        B7
		--            ▲         ▲         ▲
		--              B8    B9    B10
		--                   B11
		--                    ▲
		--                   👤
		--                 PLAYER
		--
		--------------------------------------------------

		local function getArrowPosition(
			myIndex,
			targetHRP,
			distance
		)

			if not myIndex
				or not targetHRP
				or not distance then

				return nil

			end

			--------------------------------------------------
			-- LOCAL AXIS
			--------------------------------------------------

			local forward =
				targetHRP.CFrame.LookVector

			local right =
				targetHRP.CFrame.RightVector

			local origin =
				targetHRP.Position

			--------------------------------------------------
			-- BOT 1
			-- UJUNG PANAH
			--------------------------------------------------

			if myIndex == 1 then

				return origin
					+ forward
					* distance

			end

			--------------------------------------------------
			-- BOT 2
			-- BATANG PANAH
			--------------------------------------------------

			if myIndex == 2 then

				return origin
					+ forward
					* (distance - bodySpacing)

			end

			--------------------------------------------------
			-- BOT 3
			-- BATANG PANAH
			--------------------------------------------------

			if myIndex == 3 then

				return origin
					+ forward
					* (distance - bodySpacing * 2)

			end

			--------------------------------------------------
			-- BOT 4
			-- DASAR BATANG
			--------------------------------------------------

			if myIndex == 4 then

				return origin
					+ forward
					* (distance - bodySpacing * 3)

			end

			--------------------------------------------------
			-- BOT 5
			-- KEPALA PANAH KIRI
			--------------------------------------------------

			if myIndex == 5 then

				return origin
					+ forward
					* (distance - bodySpacing * 3)
					- right
					* sideSpacing

			end

			--------------------------------------------------
			-- BOT 6
			-- TENGAH KEPALA PANAH
			--------------------------------------------------

			if myIndex == 6 then

				return origin
					+ forward
					* (distance - bodySpacing * 3)

			end

			--------------------------------------------------
			-- BOT 7
			-- KEPALA PANAH KANAN
			--------------------------------------------------

			if myIndex == 7 then

				return origin
					+ forward
					* (distance - bodySpacing * 3)
					+ right
					* sideSpacing

			end

			--------------------------------------------------
			-- BOT 8
			-- BAGIAN BAWAH KIRI
			--------------------------------------------------

			if myIndex == 8 then

				return origin
					+ forward
					* (distance - bodySpacing * 3 - bodySpacing)
					- right
					* lowerSideSpacing

			end

			--------------------------------------------------
			-- BOT 9
			-- BAGIAN BAWAH TENGAH
			--------------------------------------------------

			if myIndex == 9 then

				return origin
					+ forward
					* (distance - bodySpacing * 3 - bodySpacing)

			end

			--------------------------------------------------
			-- BOT 10
			-- BAGIAN BAWAH KANAN
			--------------------------------------------------

			if myIndex == 10 then

				return origin
					+ forward
					* (distance - bodySpacing * 3 - bodySpacing)
					+ right
					* lowerSideSpacing

			end

			--------------------------------------------------
			-- BOT 11
			-- PANGKAL PANAH
			--------------------------------------------------

			if myIndex == 11 then

				return origin
					+ forward
					* (distance - bodySpacing * 3 - bodySpacing * 2)

			end

			--------------------------------------------------
			-- INVALID INDEX
			--------------------------------------------------

			return nil

		end

		--------------------------------------------------
		-- START ARROW
		--------------------------------------------------

		local function startArrow(player)

			if not player then
				return
			end

			--------------------------------------------------
			-- STOP MODE LAIN
			--------------------------------------------------

			stopOtherModes()

			--------------------------------------------------
			-- ACTIVE MODE
			--------------------------------------------------

			vars.ActiveMode = "arrow"

			--------------------------------------------------
			-- DISCONNECT OLD LOOP
			--------------------------------------------------

			if arrowConnection then

				arrowConnection:Disconnect()
				arrowConnection = nil

			end

			--------------------------------------------------
			-- STATE
			--------------------------------------------------

			arrowActive = true
			targetPlayer = player

			--------------------------------------------------
			-- CHAT
			--------------------------------------------------

			sendChat("Yes, Sir!")

			--------------------------------------------------
			-- FIND BOT INDEX
			--------------------------------------------------

			local myIndex =
				table.find(
					botOrder,
					tostring(LocalPlayer.UserId)
				)

			--------------------------------------------------
			-- BOT TIDAK TERDAFTAR
			--------------------------------------------------

			if not myIndex then

				print(
					"[ARROW] Bot tidak termasuk formasi:",
					LocalPlayer.Name,
					LocalPlayer.UserId
				)

				stopArrow()

				return

			end

			--------------------------------------------------
			-- DEBUG
			--------------------------------------------------

			print(
				"[ARROW]",
				"Bot Index:",
				myIndex,
				"UserId:",
				LocalPlayer.UserId
			)

			--------------------------------------------------
			-- HEARTBEAT
			--------------------------------------------------

			arrowConnection =
				RunService.Heartbeat:Connect(
					function()

						--------------------------------------------------
						-- MODE CHANGED
						--------------------------------------------------

						if vars.ActiveMode
							~= "arrow" then

							stopArrow()

							return

						end

						--------------------------------------------------
						-- ACTIVE CHECK
						--------------------------------------------------

						if not arrowActive then
							return
						end

						--------------------------------------------------
						-- CHARACTER CHECK
						--------------------------------------------------

						if not humanoid
							or not myHRP then

							return

						end

						--------------------------------------------------
						-- TARGET CHECK
						--------------------------------------------------

						if not targetPlayer then
							return
						end

						--------------------------------------------------
						-- TARGET CHARACTER
						--------------------------------------------------

						local targetCharacter =
							targetPlayer.Character

						if not targetCharacter then
							return
						end

						--------------------------------------------------
						-- TARGET HRP
						--------------------------------------------------

						local targetHRP =
							targetCharacter:FindFirstChild(
								"HumanoidRootPart"
							)

						if not targetHRP then
							return
						end

						--------------------------------------------------
						-- DISTANCE
						--------------------------------------------------

						local distance =
							getBotDistance(
								targetPlayer
							)

						--------------------------------------------------
						-- FORMATION POSITION
						--------------------------------------------------

						local targetPosition =
							getArrowPosition(
								myIndex,
								targetHRP,
								distance
							)

						if not targetPosition then
							return
						end

						--------------------------------------------------
						-- DISTANCE TO FORMATION POSITION
						--------------------------------------------------

						local distanceToTarget =
							(
								myHRP.Position
								- targetPosition
							).Magnitude

						--------------------------------------------------
						-- MOVE
						--------------------------------------------------

						if distanceToTarget
							> stopThreshold then

							humanoid.AutoRotate = true

							humanoid:MoveTo(
								targetPosition
							)

							return

						end

						--------------------------------------------------
						-- REACHED FORMATION
						--------------------------------------------------

						humanoid.AutoRotate = false

						--------------------------------------------------
						-- COPY PLAYER ROTATION
						--------------------------------------------------

						local targetRotation =
							targetHRP.CFrame
							- targetHRP.Position

						myHRP.CFrame =
							CFrame.new(
								myHRP.Position
							)
							* targetRotation

					end
				)

		end

		--------------------------------------------------
		-- HANDLE COMMAND
		--------------------------------------------------

		local function handleCommand(
			message,
			sender
		)

			--------------------------------------------------
			-- ADMIN ONLY
			--------------------------------------------------

			if not Admin:IsAdmin(sender) then
				return
			end

			local lower =
				message:lower()

			--------------------------------------------------
			-- !ARROW
			--------------------------------------------------

			if lower == "!arrow" then

				startArrow(sender)

				return

			end

			--------------------------------------------------
			-- !ARROW PLAYER
			--------------------------------------------------

			local targetName =
				lower:match(
					"^!arrow%s+(.+)$"
				)

			if targetName then

				local target =
					findPlayerByName(
						targetName
					)

				if target then

					startArrow(
						target
					)

				end

				return

			end

			--------------------------------------------------
			-- !STOP
			--------------------------------------------------

			if lower == "!stop"
				or lower == "!unarrow" then

				vars.ActiveMode = nil

				stopArrow()

				return

			end

		end

		--------------------------------------------------
		-- TEXT CHAT SERVICE
		--------------------------------------------------

		if TextChatService
			and TextChatService.TextChannels then

			local channel =
				TextChatService.TextChannels
				:FindFirstChild("RBXGeneral")

			if channel then

				channel.OnIncomingMessage =
					function(message)

						local userId =
							message.TextSource
							and message.TextSource.UserId

						local sender =
							userId
							and Players:GetPlayerByUserId(
								userId
							)

						if sender then

							handleCommand(
								message.Text,
								sender
							)

						end

					end

			end

		end

		--------------------------------------------------
		-- OLD CHAT FALLBACK
		--------------------------------------------------

		for _, player in
			ipairs(Players:GetPlayers()) do

			player.Chatted:Connect(
				function(message)

					handleCommand(
						message,
						player
					)

				end
			)

		end

		--------------------------------------------------
		-- PLAYER ADDED
		--------------------------------------------------

		Players.PlayerAdded:Connect(
			function(player)

				player.Chatted:Connect(
					function(message)

						handleCommand(
							message,
							player
						)

					end
				)

			end
		)

		--------------------------------------------------
		-- RESPAWN
		--------------------------------------------------

		LocalPlayer.CharacterAdded:Connect(
			function()

				task.wait(1)

				updateCharacter()

				--------------------------------------------------
				-- RESTART ARROW
				--------------------------------------------------

				if vars.ActiveMode
					== "arrow"
					and targetPlayer then

					startArrow(
						targetPlayer
					)

				end

			end
		)

	end
}