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
		-- GLOBAL MODE
		--------------------------------------------------

		_G.BotVars = _G.BotVars or {}

		--------------------------------------------------
		-- LOAD ADMIN MODULE
		--------------------------------------------------

		local Admin

		pcall(function()
			Admin = loadstring(
				game:HttpGet(
					"https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
				)
			)()
		end)

		if not Admin then
			warn("[FRONTLINE] Admin module gagal dimuat")
			return
		end

		--------------------------------------------------
		-- LOAD DISTANCE MODULE
		--------------------------------------------------

		local Distance

		pcall(function()
			Distance = loadstring(
				game:HttpGet(
					"https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Distance.lua"
				)
			)()
		end)

		if not Distance then
			warn("[FRONTLINE] Distance module gagal dimuat")
			return
		end

		--------------------------------------------------
		-- SETTINGS
		--------------------------------------------------

		local formationDistance = 5

		-- Jarak antar bot kiri/kanan
		local formationSpacing = 3

		-- Jarak antar baris
		local rowSpacing = 3

		-- Batas dianggap sudah sampai
		local stopThreshold = 1.5

		-- Tinggi formasi
		local formationHeight = 0

		--------------------------------------------------
		-- BOT ORDER
		--------------------------------------------------

		local botOrder = {

			11611503633, -- Bot1
			11611534165, -- Bot2
			11611567975, -- Bot3
			11611562042, -- Bot4
			11611591921, -- Bot5
			11122806815, -- Bot6
			11122806817, -- Bot7
			11122687468, -- Bot8
			11122854402, -- Bot9
			11641280895, -- Bot10
			11641342530, -- Bot11

		}

		--------------------------------------------------
		-- STATE
		--------------------------------------------------

		local frontlineActive = false
		local frontlineConnection = nil
		local targetPlayer = nil
		local currentFormation = nil

		--------------------------------------------------
		-- GET BOT DISTANCE
		--------------------------------------------------

		local function getBotDistance(player)

			local distance = 1

			pcall(function()

				local result = Distance:GetDistance(
					tostring(LocalPlayer.UserId),
					tostring(player.UserId)
				)

				if typeof(result) == "number" then
					distance = result
				end

			end)

			return distance
		end

		--------------------------------------------------
		-- GET BOT INDEX
		--------------------------------------------------

		local function getBotIndex(player)

			if not player then
				return nil
			end

			local userId = player.UserId

			for index, botUserId in ipairs(botOrder) do

				if botUserId == userId then
					return index
				end

			end

			return nil
		end

		--------------------------------------------------
		-- GET BOT CHARACTER
		--------------------------------------------------

		local function getCharacter(player)

			if not player then
				return nil
			end

			return player.Character
		end

		--------------------------------------------------
		-- GET HUMANOID ROOT
		--------------------------------------------------

		local function getRoot(character)

			if not character then
				return nil
			end

			return character:FindFirstChild("HumanoidRootPart")
		end

		--------------------------------------------------
		-- GET HUMANOID
		--------------------------------------------------

		local function getHumanoid(character)

			if not character then
				return nil
			end

			return character:FindFirstChildOfClass("Humanoid")
		end

		--------------------------------------------------
		-- COPY TARGET ROTATION
		--------------------------------------------------

		local function copyTargetRotation(myHRP, targetHRP)

			if not myHRP or not targetHRP then
				return
			end

			local targetRotation =
				targetHRP.CFrame
				- targetHRP.Position

			myHRP.CFrame =
				CFrame.new(myHRP.Position)
				* targetRotation

		end

		--------------------------------------------------
		-- GET FRONTLINE POSITION
		--
		-- FORMATION 1
		--
		-- Bot1 Bot2 Bot3 Bot4 Bot5 Bot6 Bot7
		-- Bot8 Bot9 Bot10 Bot11
		--------------------------------------------------

		local function getNormalFormationPosition(
			myIndex,
			targetHRP,
			distance
		)

			local totalBots = #botOrder

			local center =
				(totalBots + 1) / 2

			local horizontalOffset =
				(myIndex - center)
				* formationSpacing

			local frontPosition =
				targetHRP.Position
				+ targetHRP.CFrame.LookVector
				* (formationDistance + distance)

			local sidePosition =
				targetHRP.CFrame.RightVector
				* horizontalOffset

			return
				frontPosition
				+ sidePosition
				+ Vector3.new(
					0,
					formationHeight,
					0
				)

		end

		--------------------------------------------------
		-- GET TWO ROW FORMATION POSITION
		--
		--              Bot8 Bot9 Bot10 Bot11
		--
		-- Bot1 Bot2 Bot3 Bot4 Bot5 Bot6 Bot7
		--
		--                 PLAYER
		--------------------------------------------------

		local function getTwoRowFormationPosition(
			myIndex,
			targetHRP,
			distance
		)

			--------------------------------------------------
			-- BOT 1 - 7
			-- BARIS BELAKANG / DEKAT PLAYER
			--------------------------------------------------

			if myIndex <= 7 then

				local rowIndex = myIndex

				-- 7 bot:
				-- -9 -6 -3 0 +3 +6 +9

				local center = 4

				local horizontalOffset =
					(rowIndex - center)
					* formationSpacing

				local frontPosition =
					targetHRP.Position
					+ targetHRP.CFrame.LookVector
					* (formationDistance + distance)

				local sidePosition =
					targetHRP.CFrame.RightVector
					* horizontalOffset

				return
					frontPosition
					+ sidePosition
					+ Vector3.new(
						0,
						formationHeight,
						0
					)

			end

			--------------------------------------------------
			-- BOT 8 - 11
			-- BARIS DEPAN / LEBIH JAUH DARI PLAYER
			--------------------------------------------------

			local rowIndex = myIndex - 7

			-- 4 bot:
			-- -4.5 -1.5 +1.5 +4.5

			local center = 2.5

			local horizontalOffset =
				(rowIndex - center)
				* formationSpacing

			--------------------------------------------------
			-- MAJU SATU BARIS
			--------------------------------------------------

			local frontPosition =
				targetHRP.Position
				+ targetHRP.CFrame.LookVector
				* (
					formationDistance
					+ distance
					+ rowSpacing
				)

			local sidePosition =
				targetHRP.CFrame.RightVector
				* horizontalOffset

			return
				frontPosition
				+ sidePosition
				+ Vector3.new(
					0,
					formationHeight,
					0
				)

		end

		--------------------------------------------------
		-- GET FORMATION POSITION
		--------------------------------------------------

		local function getFormationPosition(
			myIndex,
			targetHRP,
			distance
		)

			if currentFormation == "twoRow" then

				return getTwoRowFormationPosition(
					myIndex,
					targetHRP,
					distance
				)

			end

			return getNormalFormationPosition(
				myIndex,
				targetHRP,
				distance
			)

		end

		--------------------------------------------------
		-- STOP FRONTLINE
		--------------------------------------------------

		local function stopFrontline()

			frontlineActive = false
			targetPlayer = nil
			currentFormation = nil

			if frontlineConnection then

				frontlineConnection:Disconnect()
				frontlineConnection = nil

			end

			--------------------------------------------------
			-- RESET BOT MOVEMENT
			--------------------------------------------------

			for _, player in ipairs(Players:GetPlayers()) do

				if table.find(botOrder, player.UserId) then

					local character = getCharacter(player)
					local humanoid = getHumanoid(character)

					if humanoid then
						humanoid.AutoRotate = true
					end

				end

			end

			print("[FRONTLINE] Formasi dihentikan")

		end

		--------------------------------------------------
		-- START FRONTLINE
		--------------------------------------------------

		local function startFrontline(player, formationType)

			if not player then
				return
			end

			local targetCharacter =
				getCharacter(player)

			local targetHRP =
				getRoot(targetCharacter)

			if not targetCharacter or not targetHRP then

				warn(
					"[FRONTLINE] Character Player belum siap:",
					player.Name
				)

				return
			end

			--------------------------------------------------
			-- STOP FORMASI SEBELUMNYA
			--------------------------------------------------

			if frontlineConnection then

				frontlineConnection:Disconnect()
				frontlineConnection = nil

			end

			--------------------------------------------------
			-- SET STATE
			--------------------------------------------------

			frontlineActive = true
			targetPlayer = player
			currentFormation = formationType or "normal"

			print(
				"[FRONTLINE] Started:",
				currentFormation,
				"Target:",
				player.Name
			)

			--------------------------------------------------
			-- UPDATE LOOP
			--------------------------------------------------

			frontlineConnection =
				RunService.Heartbeat:Connect(function()

					--------------------------------------------------
					-- VALIDASI STATE
					--------------------------------------------------

					if not frontlineActive then
						return
					end

					if not targetPlayer then

						stopFrontline()
						return

					end

					--------------------------------------------------
					-- TARGET CHARACTER
					--------------------------------------------------

					local targetCharacter =
						getCharacter(targetPlayer)

					local targetHRP =
						getRoot(targetCharacter)

					if not targetCharacter
						or not targetHRP
					then

						return

					end

					--------------------------------------------------
					-- UPDATE SETIAP BOT
					--------------------------------------------------

					for _, botUserId in ipairs(botOrder) do

						local bot =
							Players:GetPlayerByUserId(
								botUserId
							)

						if bot then

							local myCharacter =
								getCharacter(bot)

							local myHRP =
								getRoot(myCharacter)

							local humanoid =
								getHumanoid(myCharacter)

							if myCharacter
								and myHRP
								and humanoid
							then

								--------------------------------------------------
								-- ADMIN CHECK
								--------------------------------------------------

								local allowed = true

								pcall(function()

									if not Admin:IsAdmin(bot) then
										allowed = false
									end

								end)

								if allowed then

									--------------------------------------------------
									-- INDEX BOT
									--------------------------------------------------

									local myIndex =
										getBotIndex(bot)

									if myIndex then

										--------------------------------------------------
										-- DISTANCE KHUSUS BOT
										--------------------------------------------------

										local botDistance =
											getBotDistance(bot)

										--------------------------------------------------
										-- TARGET POSITION
										--------------------------------------------------

										local targetPosition =
											getFormationPosition(
												myIndex,
												targetHRP,
												botDistance
											)

										--------------------------------------------------
										-- DISTANCE KE POSISI
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
											> stopThreshold
										then

											humanoid.AutoRotate = true

											humanoid:MoveTo(
												targetPosition
											)

										else

											--------------------------------------------------
											-- SUDAH SAMPAI
											--------------------------------------------------

											humanoid:MoveTo(
												myHRP.Position
											)

											humanoid.AutoRotate = false

											--------------------------------------------------
											-- MENGHADAP ARAH PLAYER
											--------------------------------------------------

											copyTargetRotation(
												myHRP,
												targetHRP
											)

										end

									end

								end

							end

						end

					end

				end)

		end

		--------------------------------------------------
		-- FIND PLAYER
		--------------------------------------------------

		local function findPlayer(name)

			if not name then
				return nil
			end

			name = string.lower(name)

			--------------------------------------------------
			-- EXACT NAME
			--------------------------------------------------

			for _, player in ipairs(
				Players:GetPlayers()
			) do

				if string.lower(player.Name) == name
					or string.lower(player.DisplayName) == name
				then

					return player

				end

			end

			--------------------------------------------------
			-- PARTIAL NAME
			--------------------------------------------------

			for _, player in ipairs(
				Players:GetPlayers()
			) do

				if string.find(
					string.lower(player.Name),
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

		--------------------------------------------------
		-- COMMAND HANDLER
		--------------------------------------------------

		local function handleCommand(message)

			if not message then
				return
			end

			local args = {}

			for word in string.gmatch(
				message,
				"%S+"
			) do

				table.insert(
					args,
					word
				)

			end

			local command =
				string.lower(
					args[1] or ""
				)

			--------------------------------------------------
			-- !STOP
			--------------------------------------------------

			if command == "!stop"
				or command == "!unfrontline"
			then

				stopFrontline()
				return

			end

			--------------------------------------------------
			-- !FRONTLINE
			--
			-- 1 BARIS
			--------------------------------------------------

			if command == "!frontline" then

				local playerName =
					args[2]

				if not playerName then

					warn(
						"[FRONTLINE] Gunakan:"
					)

					warn(
						"!frontline PlayerName"
					)

					return

				end

				local player =
					findPlayer(playerName)

				if not player then

					warn(
						"[FRONTLINE] Player tidak ditemukan:",
						playerName
					)

					return

				end

				startFrontline(
					player,
					"normal"
				)

				return

			end

			--------------------------------------------------
			-- !FRONTLINE2
			--
			-- 2 BARIS
			--------------------------------------------------

			if command == "!frontline2" then

				local playerName =
					args[2]

				if not playerName then

					warn(
						"[FRONTLINE2] Gunakan:"
					)

					warn(
						"!frontline2 PlayerName"
					)

					return

				end

				local player =
					findPlayer(playerName)

				if not player then

					warn(
						"[FRONTLINE2] Player tidak ditemukan:",
						playerName
					)

					return

				end

				startFrontline(
					player,
					"twoRow"
				)

				return

			end

		end

		--------------------------------------------------
		-- TEXT CHAT SERVICE
		--------------------------------------------------

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

					if message.TextSource
						and message.TextSource.UserId
							== LocalPlayer.UserId
					then

						handleCommand(
							message.Text
						)

					end

				end
			)

		end)

		--------------------------------------------------
		-- OLD CHAT
		--------------------------------------------------

		LocalPlayer.Chatted:Connect(
			function(message)

				handleCommand(message)

			end
		)

		--------------------------------------------------
		-- RESPAWN TARGET
		--------------------------------------------------

		Players.PlayerAdded:Connect(
			function(player)

				player.CharacterAdded:Connect(
					function()

						if player == targetPlayer
							and frontlineActive
						then

							task.wait(1)

							startFrontline(
								player,
								currentFormation
							)

						end

					end
				)

			end
		)

		--------------------------------------------------
		-- EXISTING PLAYERS RESPAWN
		--------------------------------------------------

		for _, player in ipairs(
			Players:GetPlayers()
		) do

			player.CharacterAdded:Connect(
				function()

					if player == targetPlayer
						and frontlineActive
					then

						task.wait(1)

						startFrontline(
							player,
							currentFormation
						)

					end

				end
			)

		end

		--------------------------------------------------
		-- DONE
		--------------------------------------------------

		print(
			"[FRONTLINE] Module loaded"
		)

	end
}