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

			warn(
				"[FOURCOLUMN] Gagal load Admin.lua"
			)

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

			warn(
				"[FOURCOLUMN] Gagal load Distance.lua"
			)

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

		local fourColumnActive = false
		local fourColumnConnection = nil
		local targetPlayer = nil

		----------------------------------------------------------------
		-- MODE TOKEN
		----------------------------------------------------------------

		local modeToken = 0

		----------------------------------------------------------------
		-- FOUR COLUMN SETTINGS
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
		--
		--                 PLAYER
		--                / ADMIN
		--
		--        B1    B2    B3    B4
		--        B5    B6    B7    B8
		--        B9    B10   B11
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

				channel:SendAsync(
					message
				)

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
		-- STOP FOUR COLUMN
		----------------------------------------------------------------

		local function stopFourColumn()

			------------------------------------------------------------
			-- INVALIDATE LOOP
			------------------------------------------------------------

			modeToken += 1

			------------------------------------------------------------
			-- STATE
			------------------------------------------------------------

			fourColumnActive = false
			targetPlayer = nil

			------------------------------------------------------------
			-- DISCONNECT
			------------------------------------------------------------

			if fourColumnConnection then

				fourColumnConnection:Disconnect()

				fourColumnConnection = nil

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

			if vars.ActiveMode
				== "fourcolumn"
			then

				vars.ActiveMode = nil

			end

		end

		----------------------------------------------------------------
		-- REGISTER MODE
		----------------------------------------------------------------

		vars.ModeControllers.fourcolumn =
			stopFourColumn

		----------------------------------------------------------------
		-- STOP OTHER MODES
		----------------------------------------------------------------

		local function stopOtherModes()

			for name, stopFunction in pairs(
				vars.ModeControllers
			) do

				if name ~= "fourcolumn"
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

			if not name
				or name == ""
			then

				return nil

			end

			name = name:lower()

			------------------------------------------------------------
			-- EXACT MATCH
			------------------------------------------------------------

			for _, player in ipairs(
				Players:GetPlayers()
			) do

				if player.Name:lower()
					== name

					or player.DisplayName:lower()
					== name
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
						tostring(
							LocalPlayer.UserId
						),
						tostring(
							player.UserId
						)
					)

				if typeof(specialDistance)
					== "number"
				then

					distance =
						specialDistance

				end

			end)

			return distance

		end

		----------------------------------------------------------------
		-- GET FOUR COLUMN POSITION
		----------------------------------------------------------------
		--
		-- FORMASI DI BELAKANG PLAYER
		--
		--                 PLAYER
		--                / ADMIN
		--
		--        B1    B2    B3    B4
		--        B5    B6    B7    B8
		--        B9    B10   B11
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
			-- TARGET POSITION
			------------------------------------------------------------

			local targetPosition =
				targetHRP.Position

			------------------------------------------------------------
			-- TARGET DIRECTION
			------------------------------------------------------------

			local forward =
				targetHRP.CFrame.LookVector

			local right =
				targetHRP.CFrame.RightVector

			------------------------------------------------------------
			-- FORMATION KE BELAKANG
			------------------------------------------------------------

			local backward =
				-forward

			------------------------------------------------------------
			-- ROW
			------------------------------------------------------------

			local row =
				math.floor(
					(myIndex - 1) / 4
				)

			------------------------------------------------------------
			-- COLUMN
			------------------------------------------------------------

			local column =
				(myIndex - 1) % 4

			------------------------------------------------------------
			-- CENTERED COLUMN
			------------------------------------------------------------

			-- Column 0 = paling kiri
			-- Column 1 = kiri tengah
			-- Column 2 = kanan tengah
			-- Column 3 = paling kanan

			local horizontalOffset =
				(
					column
					-
					1.5
				)
				*
				columnSpacing

			------------------------------------------------------------
			-- BACKWARD OFFSET
			------------------------------------------------------------

			local backwardOffset =
				formationDistance
				+
				(
					rowSpacing
					*
					row
				)

			------------------------------------------------------------
			-- FINAL POSITION
			------------------------------------------------------------

			return
				targetPosition
				+
				(
					backward
					*
					backwardOffset
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

		----------------------------------------------------------------
		-- SET FORMATION ROTATION
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
		-- START FOUR COLUMN
		----------------------------------------------------------------

		local function startFourColumn(
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
					"[FOURCOLUMN] Target belum memiliki Character:",
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
					"[FOURCOLUMN] Target HRP tidak ditemukan:",
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

			if fourColumnConnection then

				fourColumnConnection:Disconnect()

				fourColumnConnection = nil

			end

			------------------------------------------------------------
			-- ACTIVE MODE
			------------------------------------------------------------

			vars.ActiveMode =
				"fourcolumn"

			fourColumnActive =
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
				"[FOURCOLUMN] ==========================="
			)

			print(
				"[FOURCOLUMN] Command: !fourline"
			)

			print(
				"[FOURCOLUMN] Target:",
				player.Name
			)

			print(
				"[FOURCOLUMN] LocalPlayer:",
				LocalPlayer.Name
			)

			print(
				"[FOURCOLUMN] UserId:",
				LocalPlayer.UserId
			)

			print(
				"[FOURCOLUMN] Bot Index:",
				myIndex
			)

			print(
				"[FOURCOLUMN] Formation: 4 COLUMN"
			)

			print(
				"[FOURCOLUMN] Position: BEHIND"
			)

			print(
				"[FOURCOLUMN] ==========================="
			)

			------------------------------------------------------------
			-- BOT NOT REGISTERED
			------------------------------------------------------------

			if not myIndex then

				warn(
					"[FOURCOLUMN] LocalPlayer bukan Bot1-11"
				)

				stopFourColumn()

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

			fourColumnConnection =
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
							~= "fourcolumn"
						then

							return

						end

						------------------------------------------------
						-- ACTIVE
						------------------------------------------------

						if not fourColumnActive then

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
			-- !FOURLINE PLAYER
			------------------------------------------------------------

			local targetName =
				lower:match(
					"^!fourline%s+(.+)$"
				)

			if targetName then

				print(
					"[FOURCOLUMN] Command:",
					message
				)

				local target =
					findPlayerByName(
						targetName
					)

				if not target then

					warn(
						"[FOURCOLUMN] Player tidak ditemukan:",
						targetName
					)

					return

				end

				startFourColumn(
					target
				)

				return

			end

			------------------------------------------------------------
			-- !FOURLINE
			------------------------------------------------------------

			if lower == "!fourline" then

				print(
					"[FOURCOLUMN] Command diterima"
				)

				startFourColumn(
					sender
				)

				return

			end

			------------------------------------------------------------
			-- !STOP
			------------------------------------------------------------

			if lower == "!stop" then

				stopFourColumn()

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
							and fourColumnActive
							and vars.ActiveMode
								== "fourcolumn"
						then

							task.wait(1)

							if player == targetPlayer
								and fourColumnActive
								and vars.ActiveMode
									== "fourcolumn"
							then

								startFourColumn(
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
						and fourColumnActive
						and vars.ActiveMode
							== "fourcolumn"
					then

						task.wait(1)

						if player == targetPlayer
							and fourColumnActive
							and vars.ActiveMode
								== "fourcolumn"
						then

							startFourColumn(
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
				-- RESTART FOUR COLUMN
				--------------------------------------------------------

				if vars.ActiveMode
					== "fourcolumn"
					and fourColumnActive
					and targetPlayer
				then

					local savedTarget =
						targetPlayer

					task.wait(0.2)

					if vars.ActiveMode
						== "fourcolumn"
						and fourColumnActive
						and targetPlayer
							== savedTarget
					then

						startFourColumn(
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
			"[FOURCOLUMN] Module loaded:",
			LocalPlayer.Name,
			LocalPlayer.UserId
		)

	end
}