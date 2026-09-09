return {
	Execute = function()

		--------------------------------------------------
		-- SERVICES
		--------------------------------------------------

		local Players = game:GetService("Players")
		local RunService = game:GetService("RunService")
		local TextChatService = game:GetService("TextChatService")

		local LocalPlayer = Players.LocalPlayer

		if not LocalPlayer then
			return
		end

		--------------------------------------------------
		-- GLOBAL
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
			warn("[FRONTLINE2] Admin module gagal dimuat")
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
			warn("[FRONTLINE2] Distance module gagal dimuat")
			return
		end

		--------------------------------------------------
		-- SETTINGS
		--------------------------------------------------

		-- Jarak formasi dari Player
		local formationDistance = 5

		-- Jarak antar Bot kiri/kanan
		local formationSpacing = 3

		-- Jarak antara baris Bot1-7 dan Bot8-11
		local rowSpacing = 3

		-- Toleransi posisi
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

		local active = false
		local connection = nil
		local targetPlayer = nil

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
		-- GET CHARACTER
		--------------------------------------------------

		local function getCharacter(player)

			if not player then
				return nil
			end

			return player.Character

		end

		--------------------------------------------------
		-- GET ROOT
		--------------------------------------------------

		local function getRoot(character)

			if not character then
				return nil
			end

			return character:FindFirstChild(
				"HumanoidRootPart"
			)

		end

		--------------------------------------------------
		-- GET HUMANOID
		--------------------------------------------------

		local function getHumanoid(character)

			if not character then
				return nil
			end

			return character:FindFirstChildOfClass(
				"Humanoid"
			)

		end

		--------------------------------------------------
		-- FIND BOT INDEX
		--------------------------------------------------

		local function getBotIndex(player)

			if not player then
				return nil
			end

			for index, userId in ipairs(botOrder) do

				if userId == player.UserId then
					return index
				end

			end

			return nil

		end

		--------------------------------------------------
		-- COPY PLAYER ROTATION
		--------------------------------------------------

		local function copyTargetRotation(
			myHRP,
			targetHRP
		)

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
		-- GET FORMATION POSITION
		--------------------------------------------------
		--
		--                BOT8  BOT9  BOT10  BOT11
		--
		--         BOT1 BOT2 BOT3 BOT4 BOT5 BOT6 BOT7
		--
		--                      PLAYER
		--
		--------------------------------------------------

		local function getFormationPosition(
			myIndex,
			targetHRP,
			distance
		)

			--------------------------------------------------
			-- BARIS 1
			-- BOT1 - BOT7
			--------------------------------------------------

			if myIndex <= 7 then

				--------------------------------------------------
				-- Posisi:
				--
				-- Bot1 = -9
				-- Bot2 = -6
				-- Bot3 = -3
				-- Bot4 =  0
				-- Bot5 = +3
				-- Bot6 = +6
				-- Bot7 = +9
				--------------------------------------------------

				local center = 4

				local horizontalOffset =
					(myIndex - center)
					* formationSpacing

				local forwardDistance =
					formationDistance
					+ distance

				local frontPosition =
					targetHRP.Position
					+ targetHRP.CFrame.LookVector
					* forwardDistance

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
			-- BARIS 2
			-- BOT8 - BOT11
			--------------------------------------------------

			local rowIndex =
				myIndex - 7

			--------------------------------------------------
			-- Posisi:
			--
			-- Bot8  = -4.5
			-- Bot9  = -1.5
			-- Bot10 = +1.5
			-- Bot11 = +4.5
			--------------------------------------------------

			local center = 2.5

			local horizontalOffset =
				(rowIndex - center)
				* formationSpacing

			--------------------------------------------------
			-- BARIS KEDUA LEBIH DEPAN
			--------------------------------------------------

			local forwardDistance =
				formationDistance
				+ distance
				+ rowSpacing

			local frontPosition =
				targetHRP.Position
				+ targetHRP.CFrame.LookVector
				* forwardDistance

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
		-- STOP
		--------------------------------------------------

		local function stopFrontline2()

			active = false
			targetPlayer = nil

			if connection then

				connection:Disconnect()
				connection = nil

			end

			--------------------------------------------------
			-- RESET BOT
			--------------------------------------------------

			for _, player in ipairs(
				Players:GetPlayers()
			) do

				if table.find(
					botOrder,
					player.UserId
				)
				then

					local character =
						getCharacter(player)

					local humanoid =
						getHumanoid(character)

					if humanoid then

						humanoid.AutoRotate = true

					end

				end

			end

			print(
				"[FRONTLINE2] Formasi dihentikan"
			)

		end

		--------------------------------------------------
		-- START
		--------------------------------------------------

		local function startFrontline2(player)

			if not player then
				return
			end

			local character =
				getCharacter(player)

			local targetHRP =
				getRoot(character)

			if not character or not targetHRP then

				warn(
					"[FRONTLINE2] Character target belum siap:",
					player.Name
				)

				return

			end

			--------------------------------------------------
			-- DISCONNECT LOOP LAMA
			--------------------------------------------------

			if connection then

				connection:Disconnect()
				connection = nil

			end

			--------------------------------------------------
			-- SET STATE
			--------------------------------------------------

			active = true
			targetPlayer = player

			print(
				"[FRONTLINE2] Started:",
				player.Name
			)

			--------------------------------------------------
			-- HEARTBEAT
			--------------------------------------------------

			connection =
				RunService.Heartbeat:Connect(
					function()

						if not active then
							return
						end

						if not targetPlayer then

							stopFrontline2()
							return

						end

						--------------------------------------------------
						-- UPDATE TARGET
						--------------------------------------------------

						local targetCharacter =
							getCharacter(targetPlayer)

						local targetRoot =
							getRoot(targetCharacter)

						if not targetCharacter
							or not targetRoot
						then

							return

						end

						--------------------------------------------------
						-- UPDATE SEMUA BOT
						--------------------------------------------------

						for _, botUserId in ipairs(
							botOrder
						) do

							local bot =
								Players:GetPlayerByUserId(
									botUserId
								)

							if bot then

								local botCharacter =
									getCharacter(bot)

								local botHRP =
									getRoot(botCharacter)

								local humanoid =
									getHumanoid(botCharacter)

								if botCharacter
									and botHRP
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
										-- INDEX
										--------------------------------------------------

										local index =
											getBotIndex(bot)

										if index then

											--------------------------------------------------
											-- DISTANCE
											--------------------------------------------------

											local botDistance =
												getBotDistance(bot)

											--------------------------------------------------
											-- FORMATION POSITION
											--------------------------------------------------

											local targetPosition =
												getFormationPosition(
													index,
													targetRoot,
													botDistance
												)

											--------------------------------------------------
											-- DISTANCE TO POSITION
											--------------------------------------------------

											local distanceToPosition =
												(
													botHRP.Position
													- targetPosition
												).Magnitude

											--------------------------------------------------
											-- MOVE
											--------------------------------------------------

											if distanceToPosition
												> stopThreshold
											then

												humanoid.AutoRotate = true

												humanoid:MoveTo(
													targetPosition
												)

											else

												--------------------------------------------------
												-- STOP
												--------------------------------------------------

												humanoid:MoveTo(
													botHRP.Position
												)

												humanoid.AutoRotate = false

												--------------------------------------------------
												-- FACE PLAYER
												--------------------------------------------------

												copyTargetRotation(
													botHRP,
													targetRoot
												)

											end

										end

									end

								end

							end

						end

					end
				)

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
			-- !FRONTLINE2
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

				startFrontline2(player)

				return

			end

			--------------------------------------------------
			-- !STOP
			--------------------------------------------------

			if command == "!stop"
				or command == "!unfrontline"
			then

				stopFrontline2()

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
		-- PLAYER RESPAWN
		--------------------------------------------------

		Players.PlayerAdded:Connect(
			function(player)

				player.CharacterAdded:Connect(
					function()

						if player == targetPlayer
							and active
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

		--------------------------------------------------
		-- EXISTING PLAYER RESPAWN
		--------------------------------------------------

		for _, player in ipairs(
			Players:GetPlayers()
		) do

			player.CharacterAdded:Connect(
				function()

					if player == targetPlayer
						and active
					then

						task.wait(1)

						startFrontline2(
							player
						)

					end

				end
			)

		end

		--------------------------------------------------
		-- LOADED
		--------------------------------------------------

		print(
			"[FRONTLINE2] Module loaded"
		)

	end
}