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

			warn("[SPEARHEAD] Gagal load Admin.lua")

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

			warn("[SPEARHEAD] Gagal load Distance.lua")

			return
		end

		----------------------------------------------------------------
		-- CHARACTER
		----------------------------------------------------------------

		local humanoid
		local myHRP

		----------------------------------------------------------------
		-- STATE
		----------------------------------------------------------------

		local spearHeadActive = false
		local spearHeadConnection = nil
		local targetPlayer = nil

		----------------------------------------------------------------
		-- MODE TOKEN
		----------------------------------------------------------------

		local modeToken = 0

		----------------------------------------------------------------
		-- SPEARHEAD SETTINGS
		----------------------------------------------------------------

		-- Jarak Player/Admin dari B9/B10
		local formationDistance = 6

		-- Jarak horizontal antar bot
		local sideSpacing = 3.5

		-- Jarak antar baris
		local rowSpacing = 4

		-- Toleransi posisi
		local stopThreshold = 1.5

		-- Tinggi formasi
		local formationHeight = 0

		----------------------------------------------------------------
		-- BOT ORDER
		----------------------------------------------------------------
		--
		--                    B11
		--               B1       B2
		--          B3               B4
		--     B5                       B6
		-- B7                               B8
		--          B9           B10
		--                 PLAYER
		--
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
		-- SEND CHAT
		----------------------------------------------------------------

		local function sendChat(message)

			if not message then
				return
			end

			local sent = false

			------------------------------------------------------------
			-- TEXT CHAT
			------------------------------------------------------------

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

				if not channel then
					return
				end

				channel:SendAsync(message)

				sent = true

			end)

			------------------------------------------------------------
			-- OLD CHAT
			------------------------------------------------------------

			if not sent then

				pcall(function()

					local chatEvents =
						ReplicatedStorage:FindFirstChild(
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

		----------------------------------------------------------------
		-- STOP SPEARHEAD
		----------------------------------------------------------------

		local function stopSpearHead()

			------------------------------------------------------------
			-- INVALIDATE LOOP
			------------------------------------------------------------

			modeToken += 1

			------------------------------------------------------------
			-- STATE
			------------------------------------------------------------

			spearHeadActive = false
			targetPlayer = nil

			------------------------------------------------------------
			-- DISCONNECT
			------------------------------------------------------------

			if spearHeadConnection then

				spearHeadConnection:Disconnect()

				spearHeadConnection = nil

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

			if vars.ActiveMode == "spearhead" then

				vars.ActiveMode = nil

			end

		end

		----------------------------------------------------------------
		-- REGISTER MODE
		----------------------------------------------------------------

		vars.ModeControllers.spearhead =
			stopSpearHead

		----------------------------------------------------------------
		-- STOP OTHER MODES
		----------------------------------------------------------------

		local function stopOtherModes()

			for name, stopFunction in pairs(
				vars.ModeControllers
			) do

				if name ~= "spearhead"
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
		-- GET SPEARHEAD POSITION
		----------------------------------------------------------------
		--
		-- Posisi final:
		--
		--                         B11
		--                    B1       B2
		--               B3               B4
		--          B5                       B6
		--     B7                               B8
		--               B9           B10
		--                       PLAYER
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

			------------------------------------------------------------
			-- TARGET
			------------------------------------------------------------

			local targetPosition =
				targetHRP.Position

			local forward =
				targetHRP.CFrame.LookVector

			local right =
				targetHRP.CFrame.RightVector

			------------------------------------------------------------
			-- B1
			------------------------------------------------------------
			--
			-- Depan Player, kiri dekat
			--
			------------------------------------------------------------

			if myIndex == 1 then

				local forwardOffset =
					formationDistance
					+
					rowSpacing

				local horizontalOffset =
					-sideSpacing

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
			-- B2
			------------------------------------------------------------

			if myIndex == 2 then

				local forwardOffset =
					formationDistance
					+
					rowSpacing

				local horizontalOffset =
					sideSpacing

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
			-- B3
			------------------------------------------------------------

			if myIndex == 3 then

				local forwardOffset =
					formationDistance
					+
					(
						rowSpacing * 2
					)

				local horizontalOffset =
					-(sideSpacing * 2)

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
			-- B4
			------------------------------------------------------------

			if myIndex == 4 then

				local forwardOffset =
					formationDistance
					+
					(
						rowSpacing * 2
					)

				local horizontalOffset =
					sideSpacing * 2

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
			-- B5
			------------------------------------------------------------

			if myIndex == 5 then

				local forwardOffset =
					formationDistance
					+
					(
						rowSpacing * 3
					)

				local horizontalOffset =
					-(sideSpacing * 3)

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
			-- B6
			------------------------------------------------------------

			if myIndex == 6 then

				local forwardOffset =
					formationDistance
					+
					(
						rowSpacing * 3
					)

				local horizontalOffset =
					sideSpacing * 3

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
			-- B7
			------------------------------------------------------------

			if myIndex == 7 then

				local forwardOffset =
					formationDistance
					+
					(
						rowSpacing * 4
					)

				local horizontalOffset =
					-(sideSpacing * 4)

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
			-- B8
			------------------------------------------------------------

			if myIndex == 8 then

				local forwardOffset =
					formationDistance
					+
					(
						rowSpacing * 4
					)

				local horizontalOffset =
					sideSpacing * 4

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
			-- B9
			------------------------------------------------------------

			if myIndex == 9 then

				local forwardOffset =
					formationDistance
					+
					(
						rowSpacing * 5
					)

				local horizontalOffset =
					-(sideSpacing * 2)

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
			-- B10
			------------------------------------------------------------

			if myIndex == 10 then

				local forwardOffset =
					formationDistance
					+
					(
						rowSpacing * 5
					)

				local horizontalOffset =
					sideSpacing * 2

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
			-- B11
			------------------------------------------------------------
			--
			-- B11 berada di tengah antara B1 dan B2.
			--
			------------------------------------------------------------

			if myIndex == 11 then

				local forwardOffset =
					formationDistance

				local horizontalOffset =
					0

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
		-- SET SPEARHEAD ROTATION
		----------------------------------------------------------------
		--
		-- Semua bot menghadap arah jalan Player/Admin.
		--
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
		-- START SPEARHEAD
		----------------------------------------------------------------

		local function startSpearHead(
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
					"[SPEARHEAD] Target belum memiliki Character:",
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
					"[SPEARHEAD] Target HRP tidak ditemukan:",
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

			if spearHeadConnection then

				spearHeadConnection:Disconnect()

				spearHeadConnection = nil

			end

			------------------------------------------------------------
			-- ACTIVE MODE
			------------------------------------------------------------

			vars.ActiveMode =
				"spearhead"

			spearHeadActive = true
			targetPlayer = player

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
					tostring(LocalPlayer.UserId)
				)

			------------------------------------------------------------
			-- DEBUG
			------------------------------------------------------------

			print(
				"[SPEARHEAD] Command diterima"
			)

			print(
				"[SPEARHEAD] Target:",
				player.Name
			)

			print(
				"[SPEARHEAD] LocalPlayer:",
				LocalPlayer.Name
			)

			print(
				"[SPEARHEAD] UserId:",
				LocalPlayer.UserId
			)

			print(
				"[SPEARHEAD] Bot Index:",
				myIndex
			)

			------------------------------------------------------------
			-- BOT NOT REGISTERED
			------------------------------------------------------------

			if not myIndex then

				warn(
					"[SPEARHEAD] LocalPlayer bukan Bot1-11"
				)

				stopSpearHead()

				return

			end

			------------------------------------------------------------
			-- CHAT
			------------------------------------------------------------

			sendChat(
				"Yes, Sir!"
			)

			------------------------------------------------------------
			-- HEARTBEAT
			------------------------------------------------------------

			spearHeadConnection =
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
							~= "spearhead"
						then

							return

						end

						------------------------------------------------
						-- ACTIVE
						------------------------------------------------

						if not spearHeadActive then

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
			-- !SPEARHEAD PLAYER
			------------------------------------------------------------

			local targetName =
				lower:match(
					"^!spearhead%s+(.+)$"
				)

			if targetName then

				print(
					"[SPEARHEAD] Command:",
					message
				)

				local target =
					findPlayerByName(
						targetName
					)

				if not target then

					warn(
						"[SPEARHEAD] Player tidak ditemukan:",
						targetName
					)

					return

				end

				startSpearHead(
					target
				)

				return

			end

			------------------------------------------------------------
			-- !SPEARHEAD
			------------------------------------------------------------

			if lower == "!spearhead" then

				startSpearHead(
					sender
				)

				return

			end

			------------------------------------------------------------
			-- !STOP
			------------------------------------------------------------

			if lower == "!stop" then

				stopSpearHead()

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
							and spearHeadActive
							and vars.ActiveMode
								== "spearhead"
						then

							task.wait(1)

							if player == targetPlayer
								and spearHeadActive
								and vars.ActiveMode
									== "spearhead"
							then

								startSpearHead(
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
						and spearHeadActive
						and vars.ActiveMode
							== "spearhead"
					then

						task.wait(1)

						if player == targetPlayer
							and spearHeadActive
							and vars.ActiveMode
								== "spearhead"
						then

							startSpearHead(
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
				-- RESTART SPEARHEAD
				--------------------------------------------------------

				if vars.ActiveMode
					== "spearhead"
					and spearHeadActive
					and targetPlayer
				then

					local savedTarget =
						targetPlayer

					task.wait(0.2)

					if vars.ActiveMode
						== "spearhead"
						and spearHeadActive
						and targetPlayer
							== savedTarget
					then

						startSpearHead(
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
			"[SPEARHEAD] Module loaded:",
			LocalPlayer.Name,
			LocalPlayer.UserId
		)

	end
}
