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
		-- SETTINGS
		----------------------------------------------------------------

		local EMOTE_ID = "111972708539890"

		----------------------------------------------------------------
		-- STATE
		----------------------------------------------------------------

		local greetingsActive = false
		local currentTrack = nil
		local modeToken = 0

		local humanoid = nil
		local animator = nil

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

			animator =
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

			return character

		end

		updateCharacter()

		----------------------------------------------------------------
		-- STOP CURRENT TRACK
		----------------------------------------------------------------

		local function stopCurrentTrack()

			if currentTrack then

				pcall(function()

					currentTrack:Stop(0.15)

				end)

				pcall(function()

					currentTrack:Destroy()

				end)

				currentTrack = nil

			end

		end

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
			-- STOP ANIMATION
			------------------------------------------------------------

			stopCurrentTrack()

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
				== "greetings"
			then

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
		-- PLAY GREETINGS
		----------------------------------------------------------------

		local function playGreetings()

			------------------------------------------------------------
			-- STOP OTHER MODES
			------------------------------------------------------------

			stopOtherModes()

			------------------------------------------------------------
			-- STOP PREVIOUS GREETINGS
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

			animator =
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
			-- CREATE ANIMATION
			------------------------------------------------------------

			local animation =
				Instance.new(
					"Animation"
				)

			animation.Name =
				"GreetingsAnimation"

			animation.AnimationId =
				"rbxassetid://" .. EMOTE_ID

			------------------------------------------------------------
			-- LOAD ANIMATION
			------------------------------------------------------------

			local success, track =
				pcall(function()

					return animator:LoadAnimation(
						animation
					)

				end)

			------------------------------------------------------------
			-- DESTROY OBJECT
			------------------------------------------------------------

			animation:Destroy()

			------------------------------------------------------------
			-- FAILED
			------------------------------------------------------------

			if not success then

				warn(
					"[GREETINGS] LoadAnimation error:",
					track
				)

				return

			end

			if not track then

				warn(
					"[GREETINGS] AnimationTrack tidak dibuat"
				)

				return

			end

			------------------------------------------------------------
			-- PRIORITY
			------------------------------------------------------------

			pcall(function()

				track.Priority =
					Enum.AnimationPriority.Action4

			end)

			------------------------------------------------------------
			-- LOOP
			------------------------------------------------------------

			track.Looped = true

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
			-- PLAY
			------------------------------------------------------------

			local playSuccess, playError =
				pcall(function()

					track:Play(
						0.15,
						1,
						1
					)

				end)

			if not playSuccess then

				warn(
					"[GREETINGS] Gagal Play:",
					playError
				)

				stopGreetings()

				return

			end

			------------------------------------------------------------
			-- DEBUG
			------------------------------------------------------------

			print(
				"[GREETINGS] ==========================="
			)

			print(
				"[GREETINGS] Emote:",
				EMOTE_ID
			)

			print(
				"[GREETINGS] Playing:",
				track.IsPlaying
			)

			print(
				"[GREETINGS] Looped:",
				track.Looped
			)

			print(
				"[GREETINGS] Length:",
				track.Length
			)

			print(
				"[GREETINGS] ==========================="
			)

			------------------------------------------------------------
			-- MONITOR
			------------------------------------------------------------

			task.spawn(function()

				while
					greetingsActive
					and currentTrack == track
					and currentToken == modeToken
				do

					----------------------------------------------------
					-- TRACK STOPPED
					----------------------------------------------------

					if not track.IsPlaying then

						warn(
							"[GREETINGS] Track berhenti sendiri."
						)

						break

					end

					task.wait(0.2)

				end

				--------------------------------------------------------
				-- CLEAN
				--------------------------------------------------------

				if currentTrack == track
					and currentToken == modeToken
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

			if not message
				or not sender
			then

				return

			end

			------------------------------------------------------------
			-- ADMIN ONLY
			------------------------------------------------------------

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
					"[GREETINGS] Command dari:",
					sender.Name
				)

				playGreetings()

				return

			end

			------------------------------------------------------------
			-- !GREETINGS PLAYER
			------------------------------------------------------------

			local targetName =
				lower:match(
					"^!greetings%s+(.+)$"
				)

			if targetName then

				local target =
					findPlayerByName(
						targetName
					)

				if not target then

					warn(
						"[GREETINGS] Player tidak ditemukan:",
						targetName
					)

					return

				end

				--------------------------------------------------------
				-- Untuk saat ini emote tetap dimainkan
				-- oleh LocalPlayer/Bot yang menerima command.
				--------------------------------------------------------

				playGreetings()

				return

			end

			------------------------------------------------------------
			-- !STOP
			------------------------------------------------------------

			if lower == "!stop" then

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
				-- RESTART GREETINGS
				--------------------------------------------------------

				if greetingsActive
					and vars.ActiveMode
						== "greetings"
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