return {
	Execute = function()

		----------------------------------------------------------------
		-- SERVICES
		----------------------------------------------------------------

		local Players = game:GetService("Players")
		local RunService = game:GetService("RunService")
		local TextChatService = game:GetService("TextChatService")
		local ReplicatedStorage = game:GetService("ReplicatedStorage")

		local LocalPlayer = Players.LocalPlayer

		if not LocalPlayer then
			return
		end

		----------------------------------------------------------------
		-- GLOBAL MODE SYSTEM
		----------------------------------------------------------------

		_G.BotVars = _G.BotVars or {}
		_G.BotVars.ModeControllers =
			_G.BotVars.ModeControllers or {}

		local vars = _G.BotVars

		----------------------------------------------------------------
		-- LOAD ADMIN
		----------------------------------------------------------------

		local Admin

		local adminSuccess, adminResult = pcall(function()

			return loadstring(
				game:HttpGet(
					"https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
				)
			)()

		end)

		if adminSuccess then
			Admin = adminResult
		end

		if not Admin then

			warn("[THREECOLUMN] Gagal load Admin.lua")

			return

		end

		----------------------------------------------------------------
		-- LOAD DISTANCE
		----------------------------------------------------------------

		local Distance

		local distanceSuccess, distanceResult = pcall(function()

			return loadstring(
				game:HttpGet(
					"https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Distance.lua"
				)
			)()

		end)

		if distanceSuccess then
			Distance = distanceResult
		end

		if not Distance then

			warn("[THREECOLUMN] Gagal load Distance.lua")

			return

		end

		----------------------------------------------------------------
		-- CHARACTER
		----------------------------------------------------------------

		local humanoid = nil
		local myHRP = nil

		----------------------------------------------------------------
		-- STATE
		----------------------------------------------------------------

		local threeColumnActive = false
		local threeColumnConnection = nil
		local targetPlayer = nil

		----------------------------------------------------------------
		-- MODE TOKEN
		----------------------------------------------------------------

		local modeToken = 0

		----------------------------------------------------------------
		-- FORMATION SETTINGS
		----------------------------------------------------------------

		-- Jarak baris pertama dari Player/Admin
		local formationDistance = 6

		-- Jarak antar kolom
		local columnSpacing = 4

		-- Jarak antar baris
		local rowSpacing = 4

		-- Toleransi posisi
		local stopThreshold = 1.5

		-- Tinggi formasi
		local formationHeight = 0

		----------------------------------------------------------------
		-- BOT ORDER
		----------------------------------------------------------------

		local botOrder = {

			"11611503633", -- B1
			"11611534165", -- B2
			"11611567975", -- B3
			"11611562042", -- B4
			"11611591921", -- B5
			"11122806815", -- B6
			"11122806817", -- B7
			"11122687468", -- B8
			"11122854402", -- B9
			"11641280895", -- B10
			"11641342530", -- B11

		}

		----------------------------------------------------------------
		-- UPDATE CHARACTER
		----------------------------------------------------------------

		local function updateCharacter()

			local character =
				LocalPlayer.Character
				or LocalPlayer.CharacterAdded:Wait()

			humanoid =
				character:WaitForChild(
					"Humanoid"
				)

			myHRP =
				character:WaitForChild(
					"HumanoidRootPart"
				)

			humanoid.AutoRotate = true

		end

		updateCharacter()

		----------------------------------------------------------------
		-- STOP THREE COLUMN
		----------------------------------------------------------------

		local function stopThreeColumn()

			------------------------------------------------------------
			-- INVALIDATE LOOP
			------------------------------------------------------------

			modeToken += 1

			------------------------------------------------------------
			-- STATE
			------------------------------------------------------------

			threeColumnActive = false
			targetPlayer = nil

			------------------------------------------------------------
			-- DISCONNECT
			------------------------------------------------------------

			if threeColumnConnection then

				threeColumnConnection:Disconnect()

				threeColumnConnection = nil

			end

			------------------------------------------------------------
			-- RESTORE
			------------------------------------------------------------

			if humanoid then

				humanoid.AutoRotate = true

			end

			------------------------------------------------------------
			-- CLEAR MODE
			------------------------------------------------------------

			if vars.ActiveMode == "threecolumn" then

				vars.ActiveMode = nil

			end

		end

		----------------------------------------------------------------
		-- REGISTER MODE
		----------------------------------------------------------------

		vars.ModeControllers.threecolumn =
			stopThreeColumn

		----------------------------------------------------------------
		-- STOP OTHER MODES
		----------------------------------------------------------------

		local function stopOtherModes()

			for name, stopFunction in pairs(
				vars.ModeControllers
			) do

				if name ~= "threecolumn"
					and type(stopFunction) == "function"
				then

					pcall(function()

						stopFunction()

					end)

				end

			end

		end

		----------------------------------------------------------------
		-- FIND PLAYER
		----------------------------------------------------------------

		local function findPlayerByName(name)

			if not name or name == "" then
				return nil
			end

			name = name:lower()

			------------------------------------------------------------
			-- EXACT MATCH
			------------------------------------------------------------

			for _, player in ipairs(
				Players:GetPlayers()
			) do

				if player.Name:lower() == name
					or player.DisplayName:lower() == name
				then

					return player

				end

			end

			------------------------------------------------------------
			-- PARTIAL MATCH
			------------------------------------------------------------

			for _, player in ipairs(
				Players:GetPlayers()
			) do

				if player.Name:lower():find(
					name,
					1,
					true
				)
					or player.DisplayName:lower():find(
						name,
						1,
						true
					)
				then

					return player

				end

			end

			return nil

		end

		----------------------------------------------------------------
		-- GET BOT DISTANCE
		----------------------------------------------------------------

		local function getBotDistance(player)

			local distance = 1

			pcall(function()

				local specialDistance =
					Distance:GetDistance(
						tostring(LocalPlayer.UserId),
						tostring(player.UserId)
					)

				if typeof(specialDistance) == "number" then

					distance =
						specialDistance

				end

			end)

			return distance

		end

		----------------------------------------------------------------
		-- GET FORMATION POSITION
		----------------------------------------------------------------
		--
		--                 PLAYER
		--                / ADMIN
		--
		--          B1      B2      B3
		--          B4      B5      B6
		--          B7      B8      B9
		--          B10     B11
		--
		----------------------------------------------------------------

		local function getFormationPosition(
			myIndex,
			targetHRP,
			distance
		)

			if not myIndex
				or not targetHRP
				or not distance
			then

				return nil

			end

			local targetPosition =
				targetHRP.Position

			local forward =
				targetHRP.CFrame.LookVector

			local right =
				targetHRP.CFrame.RightVector

			------------------------------------------------------------
			-- B1 / B2 / B3
			------------------------------------------------------------

			if myIndex >= 1
				and myIndex <= 3
			then

				local column =
					myIndex - 1

				local horizontalOffset =
					(
						column - 1
					)
					*
					columnSpacing

				local forwardOffset =
					formationDistance

				return
					targetPosition
					+
					(
						forward
						*
						forwardOffset
					)
					+
					(
						right
						*
						horizontalOffset
					)
					+
					Vector3.new(
						0,
						formationHeight,
						0
					)

			end

			------------------------------------------------------------
			-- B4 / B5 / B6
			------------------------------------------------------------

			if myIndex >= 4
				and myIndex <= 6
			then

				local column =
					myIndex - 4

				local horizontalOffset =
					(
						column - 1
					)
					*
					columnSpacing

				local forwardOffset =
					formationDistance
					+
					rowSpacing

				return
					targetPosition
					+
					(
						forward
						*
						forwardOffset
					)
					+
					(
						right
						*
						horizontalOffset
					)
					+
					Vector3.new(
						0,
						formationHeight,
						0
					)

			end

			------------------------------------------------------------
			-- B7 / B8 / B9
			------------------------------------------------------------

			if myIndex >= 7
				and myIndex <= 9
			then

				local column =
					myIndex - 7

				local horizontalOffset =
					(
						column - 1
					)
					*
					columnSpacing

				local forwardOffset =
					formationDistance
					+
					(
						rowSpacing * 2
					)

				return
					targetPosition
					+
					(
						forward
						*
						forwardOffset
					)
					+
					(
						right
						*
						horizontalOffset
					)
					+
					Vector3.new(
						0,
						formationHeight,
						0
					)

			end

			------------------------------------------------------------
			-- B10 / B11
			------------------------------------------------------------

			if myIndex == 10
				or myIndex == 11
			then

				local horizontalOffset

				if myIndex == 10 then

					horizontalOffset =
						-columnSpacing / 2

				else

					horizontalOffset =
						columnSpacing / 2

				end

				local forwardOffset =
					formationDistance
					+
					(
						rowSpacing * 3
					)

				return
					targetPosition
					+
					(
						forward
						*
						forwardOffset
					)
					+
					(
						right
						*
						horizontalOffset
					)
					+
					Vector3.new(
						0,
						formationHeight,
						0
					)

			end

			return nil

		end

		----------------------------------------------------------------
		-- SET ROTATION
		----------------------------------------------------------------

		local function setFormationRotation(
			targetHRP
		)

			if not myHRP
				or not targetHRP
			then

				return

			end

			local lookDirection =
				targetHRP.CFrame.LookVector

			myHRP.CFrame =
				CFrame.lookAt(
					myHRP.Position,
					myHRP.Position
						+
						lookDirection
				)

		end

		----------------------------------------------------------------
		-- START THREE COLUMN
		----------------------------------------------------------------

		local function startThreeColumn(
			player
		)

			if not player then
				return
			end

			------------------------------------------------------------
			-- TARGET CHARACTER
			------------------------------------------------------------

			local targetCharacter =
				player.Character

			if not targetCharacter then

				warn(
					"[THREECOLUMN] Target belum memiliki Character:",
					player.Name
				)

				return

			end

			------------------------------------------------------------
			-- TARGET HRP
			------------------------------------------------------------

			local targetHRP =
				targetCharacter:FindFirstChild(
					"HumanoidRootPart"
				)

			if not targetHRP then

				warn(
					"[THREECOLUMN] Target HRP tidak ditemukan:",
					player.Name
				)

				return

			end

			------------------------------------------------------------
			-- STOP OTHER MODES
			------------------------------------------------------------

			stopOtherModes()

			------------------------------------------------------------
			-- INVALIDATE OLD LOOP
			------------------------------------------------------------

			modeToken += 1

			local currentToken =
				modeToken

			------------------------------------------------------------
			-- DISCONNECT OLD LOOP
			------------------------------------------------------------

			if threeColumnConnection then

				threeColumnConnection:Disconnect()

				threeColumnConnection = nil

			end

			------------------------------------------------------------
			-- ACTIVE MODE
			------------------------------------------------------------

			vars.ActiveMode =
				"threecolumn"

			threeColumnActive =
				true

			targetPlayer =
				player

			------------------------------------------------------------
			-- UPDATE CHARACTER
			------------------------------------------------------------

			if not humanoid
				or not myHRP
				or not myHRP.Parent
			then

				updateCharacter()

			end

			------------------------------------------------------------
			-- FIND BOT INDEX
			------------------------------------------------------------

			local myIndex =
				table.find(
					botOrder,
					tostring(
						LocalPlayer.UserId
					)
				)

			------------------------------------------------------------
			-- DEBUG
			------------------------------------------------------------

			print(
				"[THREECOLUMN] ==========================="
			)

			print(
				"[THREECOLUMN] Command: !threeline"
			)

			print(
				"[THREECOLUMN] Target:",
				player.Name
			)

			print(
				"[THREECOLUMN] LocalPlayer:",
				LocalPlayer.Name
			)

			print(
				"[THREECOLUMN] UserId:",
				LocalPlayer.UserId
			)

			print(
				"[THREECOLUMN] Bot Index:",
				myIndex
			)

			print(
				"[THREECOLUMN] ==========================="
			)

			------------------------------------------------------------
			-- BOT NOT REGISTERED
			------------------------------------------------------------

			if not myIndex then

				warn(
					"[THREECOLUMN] LocalPlayer bukan Bot1-11"
				)

				stopThreeColumn()

				return

			end

			------------------------------------------------------------
			-- CHAT
			------------------------------------------------------------

			sendChat = sendChat or function(message)

				if not message then
					return
				end

				pcall(function()

					local textChannels =
						TextChatService:FindFirstChild(
							"TextChannels"
						)

					if not textChannels then
						return
					end

					local channel =
						textChannels:FindFirstChild(
							"RBXGeneral"
						)

					if channel then

						channel:SendAsync(
							message
						)

					end

				end)

			end

			sendChat(
				"Yes, Sir!"
			)

			------------------------------------------------------------
			-- HEARTBEAT
			------------------------------------------------------------

			threeColumnConnection =
				RunService.Heartbeat:Connect(
					function()

						------------------------------------------------
						-- TOKEN
						------------------------------------------------

						if currentToken
							~= modeToken
						then

							return

						end

						------------------------------------------------
						-- MODE
						------------------------------------------------

						if vars.ActiveMode
							~= "threecolumn"
						then

							return

						end

						------------------------------------------------
						-- ACTIVE
						------------------------------------------------

						if not threeColumnActive then

							return

						end

						------------------------------------------------
						-- CHARACTER
						------------------------------------------------

						if not humanoid
							or not myHRP
							or not myHRP.Parent
						then

							return

						end

						------------------------------------------------
						-- TARGET
						------------------------------------------------

						if not targetPlayer then

							return

						end

						------------------------------------------------
						-- TARGET CHARACTER
						------------------------------------------------

						local currentCharacter =
							targetPlayer.Character

						if not currentCharacter then

							return

						end

						------------------------------------------------
						-- TARGET ROOT
						------------------------------------------------

						local targetRoot =
							currentCharacter:FindFirstChild(
								"HumanoidRootPart"
							)

						if not targetRoot then

							return

						end

						------------------------------------------------
						-- DISTANCE
						------------------------------------------------

						local botDistance =
							getBotDistance(
								targetPlayer
							)

						------------------------------------------------
						-- FORMATION POSITION
						------------------------------------------------

						local targetPosition =
							getFormationPosition(
								myIndex,
								targetRoot,
								botDistance
							)

						if not targetPosition then

							return

						end

						------------------------------------------------
						-- DISTANCE TO POSITION
						------------------------------------------------

						local distanceToTarget =
							(
								myHRP.Position
								-
								targetPosition
							).Magnitude

						------------------------------------------------
						-- MOVE
						------------------------------------------------

						if distanceToTarget
							> stopThreshold
						then

							humanoid.AutoRotate =
								true

							humanoid:MoveTo(
								targetPosition
							)

							return

						end

						------------------------------------------------
						-- ARRIVED
						------------------------------------------------

						humanoid.AutoRotate =
							false

						------------------------------------------------
						-- FACE FORWARD
						------------------------------------------------

						setFormationRotation(
							targetRoot
						)

					end
				)

		end

		----------------------------------------------------------------
		-- HANDLE COMMAND
		----------------------------------------------------------------

		local function handleCommand(
			message,
			sender
		)

			if not message then
				return
			end

			------------------------------------------------------------
			-- ADMIN ONLY
			------------------------------------------------------------

			if not sender then
				return
			end

			if not Admin:IsAdmin(sender) then
				return
			end

			------------------------------------------------------------
			-- CLEAN MESSAGE
			------------------------------------------------------------

			message =
				message:gsub(
					"^%s+",
					""
				)

			message =
				message:gsub(
					"%s+$",
					""
				)

			local lower =
				message:lower()

			------------------------------------------------------------
			-- !THREELINE
			------------------------------------------------------------

			if lower == "!threeline" then

				print(
					"[THREECOLUMN] Command diterima"
				)

				startThreeColumn(
					sender
				)

				return

			end

			------------------------------------------------------------
			-- !STOP
			------------------------------------------------------------

			if lower == "!stop" then

				stopThreeColumn()

				return

			end

		end

		----------------------------------------------------------------
		-- TEXT CHAT
		----------------------------------------------------------------

		pcall(function()

			local textChannels =
				TextChatService:WaitForChild(
					"TextChannels"
				)

			local general =
				textChannels:WaitForChild(
					"RBXGeneral"
				)

			general.MessageReceived:Connect(
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
						message.Text,
						sender
					)

				end
			)

		end)

		----------------------------------------------------------------
		-- OLD CHAT
		----------------------------------------------------------------

		local function connectPlayerChat(
			player
		)

			player.Chatted:Connect(
				function(message)

					handleCommand(
						message,
						player
					)

				end
			)

		end

		for _, player in ipairs(
			Players:GetPlayers()
		) do

			connectPlayerChat(
				player
			)

		end

		----------------------------------------------------------------
		-- PLAYER ADDED
		----------------------------------------------------------------

		Players.PlayerAdded:Connect(
			function(player)

				connectPlayerChat(
					player
				)

				--------------------------------------------------------
				-- TARGET RESPAWN
				--------------------------------------------------------

				player.CharacterAdded:Connect(
					function()

						if player == targetPlayer
							and threeColumnActive
							and vars.ActiveMode
								== "threecolumn"
						then

							task.wait(1)

							if player == targetPlayer
								and threeColumnActive
								and vars.ActiveMode
									== "threecolumn"
							then

								startThreeColumn(
									player
								)

							end

						end

					end
				)

			end
		)

		----------------------------------------------------------------
		-- EXISTING PLAYER RESPAWN
		----------------------------------------------------------------

		for _, player in ipairs(
			Players:GetPlayers()
		) do

			player.CharacterAdded:Connect(
				function()

					if player == targetPlayer
						and threeColumnActive
						and vars.ActiveMode
							== "threecolumn"
					then

						task.wait(1)

						if player == targetPlayer
							and threeColumnActive
							and vars.ActiveMode
								== "threecolumn"
						then

							startThreeColumn(
								player
							)

						end

					end

				end
			)

		end

		----------------------------------------------------------------
		-- LOCAL BOT RESPAWN
		----------------------------------------------------------------

		LocalPlayer.CharacterAdded:Connect(
			function()

				task.wait(1)

				updateCharacter()

				--------------------------------------------------------
				-- RESTART THREE COLUMN
				--------------------------------------------------------

				if vars.ActiveMode
					== "threecolumn"
					and threeColumnActive
					and targetPlayer
				then

					local savedTarget =
						targetPlayer

					task.wait(0.2)

					if vars.ActiveMode
						== "threecolumn"
						and threeColumnActive
						and targetPlayer
							== savedTarget
					then

						startThreeColumn(
							savedTarget
						)

					end

				end

			end
		)

		----------------------------------------------------------------
		-- LOADED
		----------------------------------------------------------------

		print(
			"[THREECOLUMN] Module loaded:",
			LocalPlayer.Name,
			LocalPlayer.UserId
		)

	end
}
