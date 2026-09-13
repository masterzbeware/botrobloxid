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

			warn("[VANGUARD] Gagal load Admin.lua")

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

			warn("[VANGUARD] Gagal load Distance.lua")

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

		local vanguardActive = false
		local vanguardConnection = nil
		local targetPlayer = nil

		----------------------------------------------------------------
		-- MODE TOKEN
		----------------------------------------------------------------

		local modeToken = 0

		----------------------------------------------------------------
		-- VANGUARD SETTINGS
		----------------------------------------------------------------

		-- Jarak bot paling depan dari Player
		local formationDistance = 5

		-- Jarak bot dari tengah Player
		local sideSpacing = 4

		-- Jarak antar baris dari depan ke belakang
		local rowSpacing = 4

		-- Toleransi posisi
		local stopThreshold = 1.5

		-- Tinggi formasi
		local formationHeight = 0

		----------------------------------------------------------------
		-- BOT ORDER
		----------------------------------------------------------------
		--
		-- B1  B3  B5  B7  B9
		--     KIRI
		--
		-- B2  B4  B6  B8  B10
		--     KANAN
		--
		-- B11 berada di belakang dan menghadap kiri.
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
		-- STOP VANGUARD
		----------------------------------------------------------------

		local function stopVanguard()

			------------------------------------------------------------
			-- INVALIDATE LOOP LAMA
			------------------------------------------------------------

			modeToken += 1

			------------------------------------------------------------
			-- STATE
			------------------------------------------------------------

			vanguardActive = false
			targetPlayer = nil

			------------------------------------------------------------
			-- DISCONNECT
			------------------------------------------------------------

			if vanguardConnection then

				vanguardConnection:Disconnect()

				vanguardConnection = nil

			end

			------------------------------------------------------------
			-- RESTORE
			------------------------------------------------------------

			if humanoid then

				humanoid.AutoRotate = true

			end

			------------------------------------------------------------
			-- CLEAR ACTIVE MODE
			------------------------------------------------------------

			if vars.ActiveMode == "vanguard" then

				vars.ActiveMode = nil

			end

		end

		----------------------------------------------------------------
		-- REGISTER CONTROLLER
		----------------------------------------------------------------

		vars.ModeControllers.vanguard =
			stopVanguard

		----------------------------------------------------------------
		-- STOP OTHER MODES
		----------------------------------------------------------------

		local function stopOtherModes()

			for name, stopFunction in pairs(
				vars.ModeControllers
			) do

				if name ~= "vanguard"
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
			-- TARGET DATA
			------------------------------------------------------------

			local targetPosition =
				targetHRP.Position

			local forward =
				targetHRP.CFrame.LookVector

			local right =
				targetHRP.CFrame.RightVector

			------------------------------------------------------------
			-- LEFT SIDE
			------------------------------------------------------------
			--
			-- B1
			-- B3
			-- B5
			-- B7
			-- B9
			--
			------------------------------------------------------------

			if myIndex % 2 == 1
				and myIndex <= 10
			then

				local row =
					math.ceil(
						myIndex / 2
					)

				local forwardOffset =
					formationDistance
					+
					distance
					+
					(
						(row - 1)
						*
						rowSpacing
					)

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
			-- RIGHT SIDE
			------------------------------------------------------------
			--
			-- B2
			-- B4
			-- B6
			-- B8
			-- B10
			--
			------------------------------------------------------------

			if myIndex % 2 == 0
				and myIndex <= 10
			then

				local row =
					myIndex / 2

				local forwardOffset =
					formationDistance
					+
					distance
					+
					(
						(row - 1)
						*
						rowSpacing
					)

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
			-- B11
			------------------------------------------------------------
			--
			-- B11 berada di belakang tengah.
			--
			------------------------------------------------------------

			if myIndex == 11 then

				local forwardOffset =
					formationDistance
					+
					distance
					+
					(
						5
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

			return nil

		end

		----------------------------------------------------------------
		-- SET FORMATION ROTATION
		----------------------------------------------------------------
		--
		-- KIRI:
		-- B1  B3  B5  B7  B9
		-- menghadap KANAN.
		--
		-- KANAN:
		-- B2  B4  B6  B8  B10
		-- menghadap KIRI.
		--
		-- B11 juga menghadap KIRI.
		--
		----------------------------------------------------------------

		local function setFormationRotation(
			myIndex,
			targetHRP
		)

			if not myHRP
				or not targetHRP
			then

				return
			end

			------------------------------------------------------------
			-- LEFT SIDE
			------------------------------------------------------------

			if myIndex % 2 == 1
				and myIndex <= 10
			then

				local lookDirection =
					targetHRP.CFrame.RightVector

				myHRP.CFrame =
					CFrame.lookAt(
						myHRP.Position,
						myHRP.Position
							+
							lookDirection
					)

				return

			end

			------------------------------------------------------------
			-- RIGHT SIDE
			------------------------------------------------------------

			if myIndex % 2 == 0
				and myIndex <= 10
			then

				local lookDirection =
					-targetHRP.CFrame.RightVector

				myHRP.CFrame =
					CFrame.lookAt(
						myHRP.Position,
						myHRP.Position
							+
							lookDirection
					)

				return

			end

			------------------------------------------------------------
			-- B11
			------------------------------------------------------------

			if myIndex == 11 then

				local lookDirection =
					-targetHRP.CFrame.RightVector

				myHRP.CFrame =
					CFrame.lookAt(
						myHRP.Position,
						myHRP.Position
							+
							lookDirection
					)

				return

			end

		end

		----------------------------------------------------------------
		-- START VANGUARD
		----------------------------------------------------------------

		local function startVanguard(
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
					"[VANGUARD] Target belum memiliki Character:",
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
					"[VANGUARD] Target HRP tidak ditemukan:",
					player.Name
				)

				return

			end

			------------------------------------------------------------
			-- STOP MODE LAIN
			------------------------------------------------------------

			stopOtherModes()

			------------------------------------------------------------
			-- INVALIDATE LOOP LAMA
			------------------------------------------------------------

			modeToken += 1

			local currentToken =
				modeToken

			------------------------------------------------------------
			-- DISCONNECT LOOP LAMA
			------------------------------------------------------------

			if vanguardConnection then

				vanguardConnection:Disconnect()

				vanguardConnection = nil

			end

			------------------------------------------------------------
			-- ACTIVE
			------------------------------------------------------------

			vars.ActiveMode =
				"vanguard"

			vanguardActive = true
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
				"[VANGUARD] Command diterima"
			)

			print(
				"[VANGUARD] Target:",
				player.Name
			)

			print(
				"[VANGUARD] LocalPlayer:",
				LocalPlayer.Name
			)

			print(
				"[VANGUARD] UserId:",
				LocalPlayer.UserId
			)

			print(
				"[VANGUARD] Bot Index:",
				myIndex
			)

			------------------------------------------------------------
			-- BOT TIDAK TERDAFTAR
			------------------------------------------------------------

			if not myIndex then

				warn(
					"[VANGUARD] LocalPlayer bukan Bot1-11"
				)

				stopVanguard()

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

			vanguardConnection =
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
							~= "vanguard"
						then

							return

						end

						------------------------------------------------
						-- ACTIVE
						------------------------------------------------

						if not vanguardActive then

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
						-- POSITION
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
						-- DISTANCE TO TARGET POSITION
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
						-- SUDAH SAMPAI
						------------------------------------------------

						humanoid.AutoRotate =
							false

						------------------------------------------------
						-- SET ARAH HADAP FORMASI
						------------------------------------------------

						setFormationRotation(
							myIndex,
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
			-- !VANGUARD PLAYER
			------------------------------------------------------------

			local targetName =
				lower:match(
					"^!vanguard%s+(.+)$"
				)

			if targetName then

				print(
					"[VANGUARD] Command:",
					message
				)

				local target =
					findPlayerByName(
						targetName
					)

				if not target then

					warn(
						"[VANGUARD] Player tidak ditemukan:",
						targetName
					)

					return

				end

				startVanguard(
					target
				)

				return

			end

			------------------------------------------------------------
			-- !VANGUARD
			------------------------------------------------------------

			if lower == "!vanguard" then

				startVanguard(
					sender
				)

				return

			end

			------------------------------------------------------------
			-- !STOP
			------------------------------------------------------------

			if lower == "!stop" then

				stopVanguard()

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
							and vanguardActive
							and vars.ActiveMode
								== "vanguard"
						then

							task.wait(1)

							if player == targetPlayer
								and vanguardActive
								and vars.ActiveMode
									== "vanguard"
							then

								startVanguard(
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
						and vanguardActive
						and vars.ActiveMode
							== "vanguard"
					then

						task.wait(1)

						if player == targetPlayer
							and vanguardActive
							and vars.ActiveMode
								== "vanguard"
						then

							startVanguard(
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
				-- RESTART VANGUARD
				--------------------------------------------------------

				if vars.ActiveMode
					== "vanguard"
					and vanguardActive
					and targetPlayer
				then

					local savedTarget =
						targetPlayer

					task.wait(0.2)

					if vars.ActiveMode
						== "vanguard"
						and vanguardActive
						and targetPlayer
							== savedTarget
					then

						startVanguard(
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
			"[VANGUARD] Module loaded:",
			LocalPlayer.Name,
			LocalPlayer.UserId
		)

	end
}