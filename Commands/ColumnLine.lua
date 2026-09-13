```lua
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

			warn("[COLUMN] Gagal load Admin.lua")

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

			warn("[COLUMN] Gagal load Distance.lua")

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

		local columnActive = false
		local columnConnection = nil
		local targetPlayer = nil
		local columnCount = 3

		----------------------------------------------------------------
		-- MODE TOKEN
		----------------------------------------------------------------

		local modeToken = 0

		----------------------------------------------------------------
		-- COLUMN SETTINGS
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
		-- STOP COLUMN
		----------------------------------------------------------------

		local function stopColumn()

			------------------------------------------------------------
			-- INVALIDATE LOOP
			------------------------------------------------------------

			modeToken += 1

			------------------------------------------------------------
			-- STATE
			------------------------------------------------------------

			columnActive = false
			targetPlayer = nil

			------------------------------------------------------------
			-- DISCONNECT
			------------------------------------------------------------

			if columnConnection then

				columnConnection:Disconnect()

				columnConnection = nil

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

			if vars.ActiveMode == "column" then

				vars.ActiveMode = nil

			end

		end

		----------------------------------------------------------------
		-- REGISTER MODE
		----------------------------------------------------------------

		vars.ModeControllers.column =
			stopColumn

		----------------------------------------------------------------
		-- STOP OTHER MODES
		----------------------------------------------------------------

		local function stopOtherModes()

			for name, stopFunction in pairs(
				vars.ModeControllers
			) do

				if name ~= "column"
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
		-- GET COLUMN POSITION
		----------------------------------------------------------------
		--
		-- COLUMN 3
		--
		--             PLAYER
		--
		--       B1      B2      B3
		--       B4      B5      B6
		--       B7      B8      B9
		--       B10     B11
		--
		--
		-- COLUMN 2
		--
		--             PLAYER
		--
		--       B1      B2
		--       B4      B5
		--       B7      B8
		--       B9      B10
		--              B11
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
			-- COLUMN 1
			------------------------------------------------------------

			if columnCount == 1 then

				local forwardOffset =
					formationDistance
					+
					(
						(myIndex - 1)
						*
						rowSpacing
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
					Vector3.new(
						0,
						formationHeight,
						0
					)

			end

			------------------------------------------------------------
			-- COLUMN 2
			------------------------------------------------------------

			if columnCount == 2 then

				local row
				local side

				--------------------------------------------------------
				-- B1 B2
				-- B4 B5
				-- B7 B8
				-- B9 B10
				-- B11
				--------------------------------------------------------

				if myIndex == 1 then

					row = 0
					side = -0.5

				elseif myIndex == 2 then

					row = 0
					side = 0.5

				elseif myIndex == 3 then

					-- B3 tidak dipakai dalam pola Column 2
					return nil

				elseif myIndex == 4 then

					row = 1
					side = -0.5

				elseif myIndex == 5 then

					row = 1
					side = 0.5

				elseif myIndex == 6 then

					return nil

				elseif myIndex == 7 then

					row = 2
					side = -0.5

				elseif myIndex == 8 then

					row = 2
					side = 0.5

				elseif myIndex == 9 then

					row = 3
					side = -0.5

				elseif myIndex == 10 then

					row = 3
					side = 0.5

				elseif myIndex == 11 then

					row = 4
					side = 0

				else

					return nil

				end

				local forwardOffset =
					formationDistance
					+
					(
						row
						*
						rowSpacing
					)

				local horizontalOffset =
					side
					*
					columnSpacing

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
			-- COLUMN 3
			------------------------------------------------------------

			if columnCount == 3 then

				local row
				local column

				--------------------------------------------------------
				-- B1 B2 B3
				-- B4 B5 B6
				-- B7 B8 B9
				-- B10 B11
				--------------------------------------------------------

				if myIndex >= 1
					and myIndex <= 3
				then

					row = 0
					column = myIndex

				elseif myIndex >= 4
					and myIndex <= 6
				then

					row = 1
					column =
						myIndex - 3

				elseif myIndex >= 7
					and myIndex <= 9
				then

					row = 2
					column =
						myIndex - 6

				elseif myIndex == 10 then

					row = 3
					column = 1

				elseif myIndex == 11 then

					row = 3
					column = 2

				else

					return nil

				end

				--------------------------------------------------------
				-- COLUMN OFFSET
				--------------------------------------------------------

				local horizontalOffset

				if column == 1 then

					horizontalOffset =
						-columnSpacing

				elseif column == 2 then

					horizontalOffset =
						0

				elseif column == 3 then

					horizontalOffset =
						columnSpacing

				end

				--------------------------------------------------------
				-- FORWARD OFFSET
				--------------------------------------------------------

				local forwardOffset =
					formationDistance
					+
					(
						row
						*
						rowSpacing
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
		-- START COLUMN
		----------------------------------------------------------------

		local function startColumn(
			player,
			requestedColumn
		)

			if not player then
				return
			end

			------------------------------------------------------------
			-- VALID COLUMN
			------------------------------------------------------------

			if requestedColumn ~= 1
				and requestedColumn ~= 2
				and requestedColumn ~= 3
			then

				warn(
					"[COLUMN] Gunakan !column 1, !column 2, atau !column 3"
				)

				return

			end

			------------------------------------------------------------
			-- TARGET CHARACTER
			------------------------------------------------------------

			local targetCharacter =
				player.Character

			if not targetCharacter then

				warn(
					"[COLUMN] Target belum memiliki Character:",
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
					"[COLUMN] Target HRP tidak ditemukan:",
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

			if columnConnection then

				columnConnection:Disconnect()

				columnConnection = nil

			end

			------------------------------------------------------------
			-- SET COLUMN
			------------------------------------------------------------

			columnCount =
				requestedColumn

			------------------------------------------------------------
			-- ACTIVE
			------------------------------------------------------------

			vars.ActiveMode =
				"column"

			columnActive =
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
				"[COLUMN] ==========================="
			)

			print(
				"[COLUMN] Command: !column",
				columnCount
			)

			print(
				"[COLUMN] Target:",
				player.Name
			)

			print(
				"[COLUMN] LocalPlayer:",
				LocalPlayer.Name
			)

			print(
				"[COLUMN] UserId:",
				LocalPlayer.UserId
			)

			print(
				"[COLUMN] Bot Index:",
				myIndex
			)

			print(
				"[COLUMN] Column Count:",
				columnCount
			)

			print(
				"[COLUMN] ==========================="
			)

			------------------------------------------------------------
			-- BOT NOT REGISTERED
			------------------------------------------------------------

			if not myIndex then

				warn(
					"[COLUMN] LocalPlayer bukan Bot1-11"
				)

				stopColumn()

				return

			end

			------------------------------------------------------------
			-- HEARTBEAT
			------------------------------------------------------------

			columnConnection =
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
							~= "column"
						then

							return

						end

						------------------------------------------------
						-- ACTIVE
						------------------------------------------------

						if not columnActive then

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

						------------------------------------------------
						-- BOT TIDAK DIPAKAI
						------------------------------------------------

						if not targetPosition then

							return

						end

						------------------------------------------------
						-- DISTANCE TO TARGET
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
			-- !COLUMN 1/2/3
			------------------------------------------------------------

			local columnNumber =
				lower:match(
					"^!column%s+([123])$"
				)

			if columnNumber then

				local requestedColumn =
					tonumber(
						columnNumber
					)

				print(
					"[COLUMN] Command:",
					message
				)

				startColumn(
					sender,
					requestedColumn
				)

				return

			end

			------------------------------------------------------------
			-- INVALID COLUMN COMMAND
			------------------------------------------------------------

			if lower:match(
				"^!column"
			)
			then

				warn(
					"[COLUMN] Command salah. Gunakan: !column 1 / !column 2 / !column 3"
				)

				return

			end

			------------------------------------------------------------
			-- !STOP
			------------------------------------------------------------

			if lower == "!stop" then

				stopColumn()

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
							and columnActive
							and vars.ActiveMode
								== "column"
						then

							task.wait(1)

							if player == targetPlayer
								and columnActive
								and vars.ActiveMode
									== "column"
							then

								startColumn(
									player,
									columnCount
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
						and columnActive
						and vars.ActiveMode
							== "column"
					then

						task.wait(1)

						if player == targetPlayer
							and columnActive
							and vars.ActiveMode
								== "column"
						then

							startColumn(
								player,
								columnCount
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
				-- RESTART COLUMN
				--------------------------------------------------------

				if vars.ActiveMode
					== "column"
					and columnActive
					and targetPlayer
				then

					local savedTarget =
						targetPlayer

					local savedColumn =
						columnCount

					task.wait(0.2)

					if vars.ActiveMode
						== "column"
						and columnActive
						and targetPlayer
							== savedTarget
					then

						startColumn(
							savedTarget,
							savedColumn
						)

					end

				end

			end
		)

		----------------------------------------------------------------
		-- LOADED
		----------------------------------------------------------------

		print(
			"[COLUMN] Module loaded:",
			LocalPlayer.Name,
			LocalPlayer.UserId
		)

	end
}
```
