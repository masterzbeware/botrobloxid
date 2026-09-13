return {
	Execute = function()

		----------------------------------------------------------------
		-- SERVICES
		----------------------------------------------------------------

		local Players = game:GetService("Players")
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

			warn("[GREETINGS] Gagal load Admin.lua")

			return

		end

		----------------------------------------------------------------
		-- EMOTE SETTINGS
		----------------------------------------------------------------

		local EMOTE_ID =
			"111972708539890"

		----------------------------------------------------------------
		-- STATE
		----------------------------------------------------------------

		local greetingsActive = false
		local currentTrack = nil

		----------------------------------------------------------------
		-- MODE TOKEN
		----------------------------------------------------------------

		local modeToken = 0

		----------------------------------------------------------------
		-- CHARACTER
		----------------------------------------------------------------

		local humanoid = nil

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

			return character

		end

		updateCharacter()

		----------------------------------------------------------------
		-- STOP GREETINGS
		----------------------------------------------------------------

		local function stopGreetings()

			------------------------------------------------------------
			-- INVALIDATE
			------------------------------------------------------------

			modeToken += 1

			------------------------------------------------------------
			-- STATE
			------------------------------------------------------------

			greetingsActive = false

			------------------------------------------------------------
			-- STOP TRACK
			------------------------------------------------------------

			if currentTrack then

				pcall(function()

					currentTrack:Stop(0.15)

				end)

				currentTrack = nil

			end

			------------------------------------------------------------
			-- RESTORE CHARACTER
			------------------------------------------------------------

			if humanoid then

				humanoid.AutoRotate = true

			end

			------------------------------------------------------------
			-- CLEAR MODE
			------------------------------------------------------------

			if vars.ActiveMode == "greetings" then

				vars.ActiveMode = nil

			end

		end

		----------------------------------------------------------------
		-- REGISTER MODE
		----------------------------------------------------------------

		vars.ModeControllers.greetings =
			stopGreetings

		----------------------------------------------------------------
		-- STOP OTHER MODES
		----------------------------------------------------------------

		local function stopOtherModes()

			for name, stopFunction in pairs(
				vars.ModeControllers
			) do

				if name ~= "greetings"
					and type(stopFunction) == "function"
				then

					pcall(function()

						stopFunction()

					end)

				end

			end

		end

		----------------------------------------------------------------
		-- PLAY GREETINGS EMOTE
		----------------------------------------------------------------

		local function playGreetings()

			------------------------------------------------------------
			-- STOP OTHER MODES
			------------------------------------------------------------

			stopOtherModes()

			------------------------------------------------------------
			-- STOP PREVIOUS
			------------------------------------------------------------

			stopGreetings()

			------------------------------------------------------------
			-- NEW TOKEN
			------------------------------------------------------------

			modeToken += 1

			local currentToken =
				modeToken

			------------------------------------------------------------
			-- CHARACTER
			------------------------------------------------------------

			local character =
				LocalPlayer.Character

			if not character then

				updateCharacter()

				character =
					LocalPlayer.Character

			end

			if not character then

				warn(
					"[GREETINGS] Character tidak ditemukan"
				)

				return

			end

			------------------------------------------------------------
			-- HUMANOID
			------------------------------------------------------------

			humanoid =
				character:FindFirstChild(
					"Humanoid"
				)

			if not humanoid then

				warn(
					"[GREETINGS] Humanoid tidak ditemukan"
				)

				return

			end

			------------------------------------------------------------
			-- ANIMATOR
			------------------------------------------------------------

			local animator =
				humanoid:FindFirstChildOfClass(
					"Animator"
				)

			if not animator then

				animator =
					Instance.new(
						"Animator"
					)

				animator.Parent =
					humanoid

			end

			------------------------------------------------------------
			-- ANIMATION
			------------------------------------------------------------

			local animation =
				Instance.new(
					"Animation"
				)

			animation.AnimationId =
				"rbxassetid://" .. EMOTE_ID

			------------------------------------------------------------
			-- LOAD
			------------------------------------------------------------

			local success, track =
				pcall(function()

					return animator:LoadAnimation(
						animation
					)

				end)

			------------------------------------------------------------
			-- CLEAN ANIMATION INSTANCE
			------------------------------------------------------------

			animation:Destroy()

			------------------------------------------------------------
			-- LOAD FAILED
			------------------------------------------------------------

			if not success
				or not track
			then

				warn(
					"[GREETINGS] Gagal load emote:",
					EMOTE_ID
				)

				return

			end

			------------------------------------------------------------
			-- STATE
			------------------------------------------------------------

			currentTrack =
				track

			greetingsActive =
				true

			vars.ActiveMode =
				"greetings"

			------------------------------------------------------------
			-- PRIORITY
			------------------------------------------------------------

			pcall(function()

				track.Priority =
					Enum.AnimationPriority.Action

			end)

			------------------------------------------------------------
			-- PLAY
			------------------------------------------------------------

			track:Play(
				0.15,
				1,
				1
			)

			print(
				"[GREETINGS] Emote dimainkan:",
				EMOTE_ID
			)

			------------------------------------------------------------
			-- CHECK STOP
			------------------------------------------------------------

			task.spawn(function()

				while
					greetingsActive
					and currentTrack == track
					and currentToken == modeToken
				do

					if not track.IsPlaying then

						break

					end

					task.wait(0.2)

				end

				if currentToken
					== modeToken
					and currentTrack
						== track
				then

					currentTrack = nil
					greetingsActive = false

					if vars.ActiveMode
						== "greetings"
					then

						vars.ActiveMode = nil

					end

				end

			end)

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

			name =
				name:lower()

			------------------------------------------------------------
			-- EXACT
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
			-- PARTIAL
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
			-- CLEAN
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
			-- !GREETINGS
			------------------------------------------------------------

			if lower == "!greetings" then

				print(
					"[GREETINGS] Command diterima dari:",
					sender.Name
				)

				--------------------------------------------------------
				-- Jika command dijalankan oleh Admin,
				-- bot akan memainkan emote.
				--------------------------------------------------------

				playGreetings()

				return

			end

			------------------------------------------------------------
			-- !STOP
			------------------------------------------------------------

			if lower == "!stop" then

				print(
					"[GREETINGS] Stop command diterima dari:",
					sender.Name
				)

				stopGreetings()

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

			end
		)

		----------------------------------------------------------------
		-- LOCAL PLAYER RESPAWN
		----------------------------------------------------------------

		LocalPlayer.CharacterAdded:Connect(
			function()

				task.wait(1)

				updateCharacter()

				--------------------------------------------------------
				-- PLAY AGAIN AFTER RESPAWN
				--------------------------------------------------------

				if vars.ActiveMode
					== "greetings"
					and greetingsActive
				then

					task.wait(0.2)

					playGreetings()

				end

			end
		)

		----------------------------------------------------------------
		-- LOADED
		----------------------------------------------------------------

		print(
			"[GREETINGS] Module loaded:",
			LocalPlayer.Name,
			LocalPlayer.UserId
		)

	end
}