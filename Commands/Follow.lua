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

		----------------------------------------------------------------
		-- LOAD ADMIN
		----------------------------------------------------------------

		local Admin = loadstring(game:HttpGet(
			"https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
		))()

		----------------------------------------------------------------
		-- LOAD DISTANCE
		----------------------------------------------------------------

		local Distance = loadstring(game:HttpGet(
			"https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Distance.lua"
		))()

		----------------------------------------------------------------
		-- VARIABLES
		----------------------------------------------------------------

		local humanoid
		local myHRP

		local following = false
		local targetPlayer = nil
		local followConnection = nil

		----------------------------------------------------------------
		-- FOLLOW CONTROLLER
		--
		-- Player/Admin yang memberikan command !follow
		-- dan memiliki hak untuk menghentikan follow.
		----------------------------------------------------------------

		local followController = nil

		----------------------------------------------------------------
		-- DISTANCE
		----------------------------------------------------------------

		local adminFollowDistance = 3
		local defaultBotFollowDistance = 2

		----------------------------------------------------------------
		-- BOT ORDER
		----------------------------------------------------------------

		local botOrder = {

			"11001625681", -- Bot 1
			"11001608049", -- Bot 2
			"11001607521", -- Bot 3
			"11611493000", -- Bot 4
			"11611503633", -- Bot 5
			"11611567975", -- Bot 6
			"11611562042", -- Bot 7
			"11611591921", -- Bot 8
			"11611597741", -- Bot 9
			"11122806815", -- Bot 10
			"11122806817", -- Bot 11
			"11122687468", -- Bot 12
			"11122854402", -- Bot 13

		}

		----------------------------------------------------------------
		-- UPDATE CHARACTER
		----------------------------------------------------------------

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

		----------------------------------------------------------------
		-- SEND CHAT
		----------------------------------------------------------------

		local function sendChat(message)

			local success = false

			------------------------------------------------------------
			-- TEXT CHAT
			------------------------------------------------------------

			if TextChatService
				and TextChatService.TextChannels then

				local channel =
					TextChatService.TextChannels:FindFirstChild(
						"RBXGeneral"
					)

				if channel then

					pcall(function()

						channel:SendAsync(
							message
						)

					end)

					success = true

				end

			end

			------------------------------------------------------------
			-- FALLBACK CHAT
			------------------------------------------------------------

			if not success then

				pcall(function()

					local chatEvents =
						ReplicatedStorage:FindFirstChild(
							"DefaultChatSystemChatEvents"
						)

					if chatEvents then

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

					end

				end)

			end

		end

		----------------------------------------------------------------
		-- STOP FOLLOW
		----------------------------------------------------------------

		local function stopFollow()

			following = false

			targetPlayer = nil

			followController = nil

			------------------------------------------------------------
			-- DISCONNECT FOLLOW LOOP
			------------------------------------------------------------

			if followConnection then

				followConnection:Disconnect()

				followConnection = nil

			end

			------------------------------------------------------------
			-- RESTORE ROTATION
			------------------------------------------------------------

			if humanoid then

				humanoid.AutoRotate = true

			end

		end

		----------------------------------------------------------------
		-- REGISTER CONTROLLER
		----------------------------------------------------------------

		_G.BotVars.ModeControllers.follow =
			stopFollow

		----------------------------------------------------------------
		-- STOP SEMUA MODE LAIN
		----------------------------------------------------------------

		local function stopOtherModes()

			for name, stopFunction in pairs(
				_G.BotVars.ModeControllers
			) do

				if name ~= "follow"
					and type(stopFunction) == "function" then

					pcall(stopFunction)

				end

			end

		end

		----------------------------------------------------------------
		-- FIND PLAYER
		--
		-- Bisa menggunakan:
		-- Username
		-- DisplayName
		----------------------------------------------------------------

		local function findPlayerByName(name)

			if not name then
				return nil
			end

			name =
				name:lower()

			for _, player in ipairs(
				Players:GetPlayers()
			) do

				if player.Name:lower() == name
					or player.DisplayName:lower() == name then

					return player

				end

			end

			return nil

		end

		----------------------------------------------------------------
		-- START FOLLOW
		----------------------------------------------------------------

		local function startFollow(
			player,
			controller
		)

			if not player then
				return
			end

			------------------------------------------------------------
			-- STOP MODE LAIN
			------------------------------------------------------------

			stopOtherModes()

			------------------------------------------------------------
			-- SET ACTIVE MODE
			------------------------------------------------------------

			_G.BotVars.ActiveMode =
				"follow"

			------------------------------------------------------------
			-- STOP CONNECTION LAMA
			------------------------------------------------------------

			if followConnection then

				followConnection:Disconnect()

				followConnection = nil

			end

			------------------------------------------------------------
			-- SET FOLLOW
			------------------------------------------------------------

			following = true

			targetPlayer = player

			------------------------------------------------------------
			-- SET CONTROLLER
			--
			-- Jika controller diberikan:
			-- gunakan controller tersebut.
			--
			-- Jika tidak:
			-- player menjadi controller.
			------------------------------------------------------------

			followController =
				controller or player

			------------------------------------------------------------
			-- CHAT
			------------------------------------------------------------

			sendChat(
				"Yes, Sir!"
			)

			------------------------------------------------------------
			-- CARI INDEX BOT
			------------------------------------------------------------

			local myIndex =
				table.find(
					botOrder,
					tostring(
						LocalPlayer.UserId
					)
				)

			if not myIndex then

				stopFollow()

				return

			end

			----------------------------------------------------------------
			-- FOLLOW LOOP
			----------------------------------------------------------------

			followConnection =
				RunService.Heartbeat:Connect(
					function()

						------------------------------------------------
						-- JIKA MODE SUDAH BERGANTI
						------------------------------------------------

						if _G.BotVars.ActiveMode
							~= "follow" then

							stopFollow()

							return

						end

						------------------------------------------------
						-- VALIDASI
						------------------------------------------------

						if not following then
							return
						end

						if not humanoid
							or not myHRP then

							return

						end

						if not targetPlayer then
							return
						end

						------------------------------------------------
						-- TARGET CHARACTER
						------------------------------------------------

						local targetCharacter =
							targetPlayer.Character

						if not targetCharacter then
							return
						end

						local targetHRP =
							targetCharacter:FindFirstChild(
								"HumanoidRootPart"
							)

						if not targetHRP then
							return
						end

						------------------------------------------------
						-- DISTANCE
						------------------------------------------------

						local distance =
							defaultBotFollowDistance

						------------------------------------------------
						-- JIKA TARGET ADALAH ADMIN
						------------------------------------------------

						if Admin:IsAdmin(
							targetPlayer
						) then

							distance =
								adminFollowDistance

						end

						------------------------------------------------
						-- SPECIAL DISTANCE
						------------------------------------------------

						local specialDistance =
							Distance:GetDistance(
								tostring(
									LocalPlayer.UserId
								),
								tostring(
									targetPlayer.UserId
								)
							)

						if specialDistance then

							distance =
								specialDistance

						end

						------------------------------------------------
						-- POSISI BOT
						------------------------------------------------

						local targetPosition =
							targetHRP.Position
							-
							(
								targetHRP.CFrame.LookVector
								*
								(
									distance
									*
									myIndex
								)
							)

						------------------------------------------------
						-- JARAK
						------------------------------------------------

						local distanceToTarget =
							(
								myHRP.Position
								-
								targetPosition
							).Magnitude

						------------------------------------------------
						-- JALAN
						------------------------------------------------

						if distanceToTarget > 1.5 then

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

						local targetRotation =
							targetHRP.CFrame
							-
							targetHRP.Position

						myHRP.CFrame =
							CFrame.new(
								myHRP.Position
							)
							*
							targetRotation

					end
				)

		end

		----------------------------------------------------------------
		-- COMMAND HANDLER
		----------------------------------------------------------------

		local function handleCommand(
			message,
			sender
		)

			if not sender then
				return
			end

			------------------------------------------------------------
			-- LOWERCASE COMMAND
			------------------------------------------------------------

			local lower =
				message:lower()

			------------------------------------------------------------
			-- ADMIN CHECK
			------------------------------------------------------------

			local isAdmin =
				Admin:IsAdmin(sender)

			------------------------------------------------------------
			-- CEK APAKAH SENDER ADALAH TARGET
			--
			-- Contoh:
			-- Admin -> !follow Budi
			--
			-- Maka Budi = targetPlayer
			------------------------------------------------------------

			local isCurrentTarget =
				following
				and targetPlayer == sender

			----------------------------------------------------------------
			-- !FOLLOW
			----------------------------------------------------------------

			if lower == "!follow" then

				------------------------------------------------------------
				-- ADMIN
				------------------------------------------------------------

				if isAdmin then

					--------------------------------------------------------
					-- ADMIN FOLLOW DIRINYA SENDIRI
					--------------------------------------------------------

					startFollow(
						sender,
						sender
					)

					return

				end

				------------------------------------------------------------
				-- TARGET
				------------------------------------------------------------

				if isCurrentTarget then

					--------------------------------------------------------
					-- TARGET BOLEH !FOLLOW
					--
					-- TAPI TARGET TIDAK BERUBAH
					-- CONTROLLER JUGA TIDAK BERUBAH
					--------------------------------------------------------

					startFollow(
						targetPlayer,
						followController
					)

					return

				end

				------------------------------------------------------------
				-- PLAYER BIASA
				------------------------------------------------------------

				return

			end

			----------------------------------------------------------------
			-- !FOLLOW USERNAME / DISPLAYNAME
			----------------------------------------------------------------

			local targetName =
				lower:match(
					"^!follow%s+(.+)$"
				)

			if targetName then

				------------------------------------------------------------
				-- HANYA ADMIN YANG BOLEH MEMILIH TARGET BARU
				------------------------------------------------------------

				if not isAdmin then

					--------------------------------------------------------
					-- TARGET TIDAK BOLEH MENGGANTI TARGET
					--------------------------------------------------------

					if isCurrentTarget then

						return

					end

					return

				end

				------------------------------------------------------------
				-- CARI TARGET
				------------------------------------------------------------

				local target =
					findPlayerByName(
						targetName
					)

				if not target then
					return
				end

				------------------------------------------------------------
				-- ADMIN MENJADI CONTROLLER
				------------------------------------------------------------

				startFollow(
					target,
					sender
				)

				return

			end

			----------------------------------------------------------------
			-- !STOP / !UNFOLLOW
			----------------------------------------------------------------

			if lower == "!stop"
				or lower == "!unfollow" then

				------------------------------------------------------------
				-- HANYA FOLLOW CONTROLLER YANG BOLEH STOP
				------------------------------------------------------------

				if followController
					and sender == followController then

					--------------------------------------------------------
					-- MATIKAN MODE
					--------------------------------------------------------

					_G.BotVars.ActiveMode =
						nil

					--------------------------------------------------------
					-- STOP TOTAL
					--------------------------------------------------------

					stopFollow()

					return

				end

				------------------------------------------------------------
				-- TARGET TIDAK BOLEH STOP
				------------------------------------------------------------

				if isCurrentTarget then

					return

				end

				------------------------------------------------------------
				-- PLAYER BIASA JUGA DIABAIKAN
				------------------------------------------------------------

				return

			end

		end

		----------------------------------------------------------------
		-- TEXT CHAT
		----------------------------------------------------------------

		if TextChatService
			and TextChatService.TextChannels then

			local channel =
				TextChatService.TextChannels:FindFirstChild(
					"RBXGeneral"
				)

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

		----------------------------------------------------------------
		-- FALLBACK CHAT
		----------------------------------------------------------------

		for _, player in ipairs(
			Players:GetPlayers()
		) do

			player.Chatted:Connect(
				function(message)

					handleCommand(
						message,
						player
					)

				end
			)

		end

		----------------------------------------------------------------
		-- PLAYER ADDED
		----------------------------------------------------------------

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

		----------------------------------------------------------------
		-- CHARACTER RESPAWN
		----------------------------------------------------------------

		LocalPlayer.CharacterAdded:Connect(
			function()

				task.wait(1)

				updateCharacter()

				------------------------------------------------------------
				-- JIKA MASIH DALAM MODE FOLLOW
				------------------------------------------------------------

				if _G.BotVars.ActiveMode
					== "follow"
					and targetPlayer then

					--------------------------------------------------------
					-- SIMPAN TARGET DAN CONTROLLER
					--------------------------------------------------------

					local savedTarget =
						targetPlayer

					local savedController =
						followController

					--------------------------------------------------------
					-- START ULANG FOLLOW
					--------------------------------------------------------

					startFollow(
						savedTarget,
						savedController
					)

				end

			end
		)

	end
}