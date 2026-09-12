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
				"[FRONTLINE2] Gagal load Admin.lua"
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
				"[FRONTLINE2] Gagal load Distance.lua"
			)

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

		local frontline2Active = false
		local frontline2Connection = nil
		local targetPlayer = nil

		----------------------------------------------------------------
		-- FORMATION SETTINGS
		----------------------------------------------------------------

		-- Jarak PLAYER ke baris pertama
		local formationDistance = 5

		-- Jarak antar Bot kiri / kanan
		local formationSpacing = 3

		-- Jarak antara baris pertama dan baris kedua
		local rowSpacing = 3

		-- Toleransi sampai posisi
		local stopThreshold = 1.5

		-- Tinggi formasi
		local formationHeight = 0

		----------------------------------------------------------------
		-- BOT ORDER
		----------------------------------------------------------------
		--
		-- FORMASI:
		--
		--                 B8   B9   B10   B11
		--
		--          B1   B2   B3   B4   B5   B6   B7
		--
		--                       PLAYER
		--
		----------------------------------------------------------------

		local botOrder = {

			"11611503633", -- Bot1
			"11611534165", -- Bot2
			"11611567975", -- Bot3
			"11611562042", -- Bot4
			"11611591921", -- Bot5
			"11122806815", -- Bot6
			"11122806817", -- Bot7

			"11122687468", -- Bot8
			"11122854402", -- Bot9
			"11641280895", -- Bot10
			"11641342530", -- Bot11

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
		-- STOP FRONTLINE2
		----------------------------------------------------------------

		local function stopFrontline2()

			frontline2Active = false
			targetPlayer = nil

			if frontline2Connection then

				frontline2Connection:Disconnect()
				frontline2Connection = nil

			end

			if humanoid then
				humanoid.AutoRotate = true
			end

			------------------------------------------------------------
			-- HANYA HAPUS ACTIVE MODE JIKA MODE INI
			------------------------------------------------------------

			if vars.ActiveMode == "frontline2" then
				vars.ActiveMode = nil
			end

		end

		----------------------------------------------------------------
		-- REGISTER CONTROLLER
		----------------------------------------------------------------

		vars.ModeControllers.frontline2 =
			stopFrontline2

		----------------------------------------------------------------
		-- STOP OTHER MODES
		----------------------------------------------------------------

		local function stopOtherModes()

			for name, stopFunction in pairs(
				vars.ModeControllers
			) do

				if name ~= "frontline2"
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
		-- HASIL:
		--
		--                 B8   B9   B10   B11
		--
		--          B1   B2   B3   B4   B5   B6   B7
		--
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

			----------------------------------------------------------------
			-- TARGET BASIS
			----------------------------------------------------------------
			--
			-- LookVector = arah DEPAN player
			-- RightVector = arah KANAN player
			--
			----------------------------------------------------------------

			local targetPosition =
				targetHRP.Position

			local forward =
				targetHRP.CFrame.LookVector

			local right =
				targetHRP.CFrame.RightVector

			----------------------------------------------------------------
			-- BARIS 1
			--
			-- B1   B2   B3   B4   B5   B6   B7
			--
			----------------------------------------------------------------

			if myIndex <= 7 then

				------------------------------------------------------------
				-- POSISI TENGAH = BOT4
				------------------------------------------------------------

				local centerIndex = 4

				------------------------------------------------------------
				-- OFFSET HORIZONTAL
				--
				-- B1 = -9
				-- B2 = -6
				-- B3 = -3
				-- B4 =  0
				-- B5 = +3
				-- B6 = +6
				-- B7 = +9
				------------------------------------------------------------

				local horizontalOffset =
					(
						myIndex
						- centerIndex
					)
					* formationSpacing

				------------------------------------------------------------
				-- JARAK DEPAN
				------------------------------------------------------------

				local forwardOffset =
					formationDistance
					+ distance

				------------------------------------------------------------
				-- POSISI BARIS 1
				------------------------------------------------------------

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

			----------------------------------------------------------------
			-- BARIS 2
			--
			-- B8   B9   B10   B11
			--
			----------------------------------------------------------------

			local rowIndex =
				myIndex - 7

			------------------------------------------------------------
			-- POSISI TENGAH BARIS 2
			--
			-- Karena ada 4 bot:
			--
			-- B8  = -4.5
			-- B9  = -1.5
			-- B10 = +1.5
			-- B11 = +4.5
			--
			------------------------------------------------------------

			local centerIndex = 2.5

			local horizontalOffset =
				(
					rowIndex
					- centerIndex
				)
				* formationSpacing

			------------------------------------------------------------
			-- BARIS 2 LEBIH JAUH KE DEPAN
			------------------------------------------------------------

			local forwardOffset =
				formationDistance
				+ distance
				+ rowSpacing

			------------------------------------------------------------
			-- POSISI BARIS 2
			------------------------------------------------------------

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

		----------------------------------------------------------------
		-- COPY TARGET ROTATION
		----------------------------------------------------------------

		local function copyTargetRotation(
			targetHRP
		)

			if not targetHRP
				or not myHRP
			then

				return

			end

			local targetRotation =
				targetHRP.CFrame
				- targetHRP.Position

			myHRP.CFrame =
				CFrame.new(
					myHRP.Position
				)
				*
				targetRotation

		end

		----------------------------------------------------------------
		-- START FRONTLINE2
		----------------------------------------------------------------

		local function startFrontline2(
			player
		)

			if not player then
				return
			end

			----------------------------------------------------------------
			-- TARGET CHARACTER
			----------------------------------------------------------------

			local targetCharacter =
				player.Character

			if not targetCharacter then

				warn(
					"[FRONTLINE2] Target belum memiliki Character:",
					player.Name
				)

				return

			end

			local targetHRP =
				targetCharacter:FindFirstChild(
					"HumanoidRootPart"
				)

			if not targetHRP then

				warn(
					"[FRONTLINE2] Target HRP tidak ditemukan:",
					player.Name
				)

				return

			end

			----------------------------------------------------------------
			-- STOP MODE LAIN
			----------------------------------------------------------------

			stopOtherModes()

			----------------------------------------------------------------
			-- ACTIVE MODE
			----------------------------------------------------------------

			vars.ActiveMode =
				"frontline2"

			----------------------------------------------------------------
			-- DISCONNECT LOOP LAMA
			----------------------------------------------------------------

			if frontline2Connection then

				frontline2Connection:Disconnect()
				frontline2Connection = nil

			end

			----------------------------------------------------------------
			-- STATE
			----------------------------------------------------------------

			frontline2Active = true
			targetPlayer = player

			----------------------------------------------------------------
			-- FIND BOT INDEX
			----------------------------------------------------------------

			local myIndex =
				table.find(
					botOrder,
					tostring(LocalPlayer.UserId)
				)

			----------------------------------------------------------------
			-- DEBUG
			----------------------------------------------------------------

			print(
				"[FRONTLINE2] Command diterima"
			)

			print(
				"[FRONTLINE2] Target:",
				player.Name
			)

			print(
				"[FRONTLINE2] LocalPlayer:",
				LocalPlayer.Name
			)

			print(
				"[FRONTLINE2] UserId:",
				LocalPlayer.UserId
			)

			print(
				"[FRONTLINE2] Bot Index:",
				myIndex
			)

			----------------------------------------------------------------
			-- BOT TIDAK TERDAFTAR
			----------------------------------------------------------------

			if not myIndex then

				print(
					"[FRONTLINE2] LocalPlayer bukan Bot1-11"
				)

				stopFrontline2()

				return

			end

			----------------------------------------------------------------
			-- CHAT
			----------------------------------------------------------------

			sendChat("Yes, Sir!")

			----------------------------------------------------------------
			-- HEARTBEAT
			----------------------------------------------------------------

			frontline2Connection =
				RunService.Heartbeat:Connect(
					function()

						----------------------------------------------------
						-- MODE CHECK
						----------------------------------------------------

						if vars.ActiveMode
							~= "frontline2"
						then

							stopFrontline2()

							return

						end

						----------------------------------------------------
						-- ACTIVE CHECK
						----------------------------------------------------

						if not frontline2Active then
							return
						end

						----------------------------------------------------
						-- CHARACTER CHECK
						----------------------------------------------------

						if not humanoid
							or not myHRP
						then

							return

						end

						----------------------------------------------------
						-- TARGET CHECK
						----------------------------------------------------

						if not targetPlayer then
							return
						end

						----------------------------------------------------
						-- TARGET CHARACTER
						----------------------------------------------------

						local targetCharacter =
							targetPlayer.Character

						if not targetCharacter then
							return
						end

						----------------------------------------------------
						-- TARGET ROOT
						----------------------------------------------------

						local targetRoot =
							targetCharacter:FindFirstChild(
								"HumanoidRootPart"
							)

						if not targetRoot then
							return
						end

						----------------------------------------------------
						-- DISTANCE
						----------------------------------------------------

						local botDistance =
							getBotDistance(
								targetPlayer
							)

						----------------------------------------------------
						-- POSITION
						----------------------------------------------------

						local targetPosition =
							getFormationPosition(
								myIndex,
								targetRoot,
								botDistance
							)

						if not targetPosition then
							return
						end

						----------------------------------------------------
						-- DISTANCE TO TARGET POSITION
						----------------------------------------------------

						local distanceToTarget =
							(
								myHRP.Position
								-
								targetPosition
							).Magnitude

						----------------------------------------------------
						-- MOVE
						----------------------------------------------------

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

						----------------------------------------------------
						-- SUDAH SAMPAI
						----------------------------------------------------

						humanoid.AutoRotate =
							false

						----------------------------------------------------
						-- STOP DI POSISI
						----------------------------------------------------

						humanoid:MoveTo(
							myHRP.Position
						)

						----------------------------------------------------
						-- HADAP SESUAI PLAYER
						----------------------------------------------------

						copyTargetRotation(
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

			----------------------------------------------------------------
			-- ADMIN ONLY
			----------------------------------------------------------------

			if not sender then
				return
			end

			if not Admin:IsAdmin(sender) then
				return
			end

			----------------------------------------------------------------
			-- CLEAN MESSAGE
			----------------------------------------------------------------

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

			----------------------------------------------------------------
			-- !FRONTLINE2 PLAYER
			----------------------------------------------------------------

			local targetName =
				lower:match(
					"^!frontline2%s+(.+)$"
				)

			if targetName then

				print(
					"[FRONTLINE2] Command:",
					message
				)

				print(
					"[FRONTLINE2] Target Name:",
					targetName
				)

				local target =
					findPlayerByName(
						targetName
					)

				if not target then

					warn(
						"[FRONTLINE2] Player tidak ditemukan:",
						targetName
					)

					return

				end

				startFrontline2(
					target
				)

				return

			end

			----------------------------------------------------------------
			-- !FRONTLINE2 TANPA NAMA
			----------------------------------------------------------------

			if lower == "!frontline2" then

				startFrontline2(
					sender
				)

				return

			end

			----------------------------------------------------------------
			-- !STOP
			----------------------------------------------------------------

			if lower == "!stop"
				or lower == "!unfrontline"
			then

				stopFrontline2()

				return

			end

		end

		----------------------------------------------------------------
		-- TEXT CHAT SERVICE
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

					--------------------------------------------------------
					-- SEMUA BOT MENERIMA CHAT ADMIN
					--------------------------------------------------------

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
		-- NEW PLAYER CHAT
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
							and frontline2Active
						then

							task.wait(1)

							startFrontline2(
								player
							)

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
						and frontline2Active
					then

						task.wait(1)

						startFrontline2(
							player
						)

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
				-- RESTART FORMATION
				--------------------------------------------------------

				if vars.ActiveMode
					== "frontline2"
					and targetPlayer
				then

					startFrontline2(
						targetPlayer
					)

				end

			end
		)

		----------------------------------------------------------------
		-- LOADED
		----------------------------------------------------------------

		print(
			"[FRONTLINE2] Module loaded:",
			LocalPlayer.Name,
			LocalPlayer.UserId
		)

	end
}