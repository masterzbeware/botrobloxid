-- HulaDance.lua
-- Command:
-- !huladance
-- !huladance <username>
-- !unhuladance
-- !stop

return {
    Execute = function()

        ----------------------------------------------------------------
        -- SERVICES
        ----------------------------------------------------------------

        local Players = game:GetService("Players")
        local LocalPlayer = Players.LocalPlayer

        if not LocalPlayer then
            warn("[HulaDance] LocalPlayer tidak ditemukan.")
            return
        end

        ----------------------------------------------------------------
        -- BOT VARIABLES
        ----------------------------------------------------------------

        _G.BotVars = _G.BotVars or {}
        _G.BotVars.ModeControllers =
            _G.BotVars.ModeControllers or {}
        _G.BotVars.AdditionalAdmins =
            _G.BotVars.AdditionalAdmins or {}

        local MODE_NAME = "huladance"

        ----------------------------------------------------------------
        -- LOAD ADMIN MODULE
        ----------------------------------------------------------------

        local AdminModule = nil

        pcall(function()
            local url =
                "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"

            local source = game:HttpGet(url)
            local loader = loadstring(source)

            if loader then
                AdminModule = loader()
            end
        end)

        if not AdminModule then
            warn("[HulaDance] Gagal load Admin.lua.")
            return
        end

        ----------------------------------------------------------------
        -- CONFIGURATION
        ----------------------------------------------------------------

        local HULA_DANCE_ANIMATION_ID = "95946613531935"

        ----------------------------------------------------------------
        -- STATE
        ----------------------------------------------------------------

        local danceTrack = nil
        local dancing = false
        local danceGeneration = 0
        local connectedPlayers = {}

        ----------------------------------------------------------------
        -- CHARACTER
        ----------------------------------------------------------------

        local function getCharacter()
            local character = LocalPlayer.Character

            if not character then
                return nil, nil
            end

            local humanoid =
                character:FindFirstChildOfClass("Humanoid")

            return character, humanoid
        end

        ----------------------------------------------------------------
        -- RESTORE NORMAL ANIMATION
        ----------------------------------------------------------------

        local function restoreNormalAnimation(generation)
            if generation ~= danceGeneration then
                return
            end

            local character, humanoid = getCharacter()

            if danceTrack then
                local oldTrack = danceTrack
                danceTrack = nil

                pcall(function()
                    oldTrack:Stop(0.2)
                end)
            end

            if not character then
                dancing = false
                return
            end

            ------------------------------------------------------------
            -- STOP ACTION TRACKS
            ------------------------------------------------------------

            if humanoid then
                local animator =
                    humanoid:FindFirstChildOfClass("Animator")

                local tracks

                if animator then
                    tracks = animator:GetPlayingAnimationTracks()
                else
                    tracks = humanoid:GetPlayingAnimationTracks()
                end

                for _, track in ipairs(tracks) do
                    if track.Priority == Enum.AnimationPriority.Action
                        or track.Priority == Enum.AnimationPriority.Action2
                        or track.Priority == Enum.AnimationPriority.Action3
                        or track.Priority == Enum.AnimationPriority.Action4 then

                        pcall(function()
                            track:Stop(0.2)
                        end)
                    end
                end
            end

            if generation ~= danceGeneration then
                return
            end

            ------------------------------------------------------------
            -- RESTART DEFAULT ANIMATE
            ------------------------------------------------------------

            local animate = character:FindFirstChild("Animate")

            if animate and animate:IsA("LocalScript") then
                pcall(function()
                    animate.Disabled = true
                end)

                task.wait(0.1)

                if generation ~= danceGeneration then
                    return
                end

                if animate.Parent then
                    pcall(function()
                        animate.Disabled = false
                    end)
                end
            end

            if generation ~= danceGeneration then
                return
            end

            ------------------------------------------------------------
            -- FORCE RUNNING
            ------------------------------------------------------------

            if humanoid then
                pcall(function()
                    humanoid:ChangeState(
                        Enum.HumanoidStateType.Running
                    )
                end)
            end

            ------------------------------------------------------------
            -- DELAYED RUNNING STATE
            ------------------------------------------------------------

            task.delay(0.25, function()
                if generation ~= danceGeneration then
                    return
                end

                local _, currentHumanoid = getCharacter()

                if currentHumanoid then
                    pcall(function()
                        currentHumanoid:ChangeState(
                            Enum.HumanoidStateType.Running
                        )
                    end)
                end

                dancing = false
            end)
        end

        ----------------------------------------------------------------
        -- STOP HULA DANCE
        ----------------------------------------------------------------

        local function stopHulaDance()
            danceGeneration += 1

            local generation = danceGeneration

            dancing = false

            if danceTrack then
                local oldTrack = danceTrack
                danceTrack = nil

                pcall(function()
                    oldTrack:Stop(0.2)
                end)
            end

            restoreNormalAnimation(generation)
        end

        ----------------------------------------------------------------
        -- REGISTER MODE CONTROLLER
        ----------------------------------------------------------------

        _G.BotVars.ModeControllers[MODE_NAME] = stopHulaDance

        ----------------------------------------------------------------
        -- STOP OTHER MODES
        ----------------------------------------------------------------

        local function stopOtherModes()
            for modeName, stopFunction in pairs(
                _G.BotVars.ModeControllers
            ) do
                if modeName ~= MODE_NAME
                    and type(stopFunction) == "function" then

                    pcall(stopFunction)
                end
            end
        end

        ----------------------------------------------------------------
        -- ADMIN CHECK
        ----------------------------------------------------------------

        local function isAdmin(player)
            if not player then
                return false
            end

            if AdminModule and type(AdminModule) == "table" then
                local success, result = pcall(function()
                    if type(AdminModule.IsAdmin) == "function" then
                        return AdminModule:IsAdmin(player)
                    end

                    return false
                end)

                if success and result == true then
                    return true
                end
            end

            local additionalAdmins =
                _G.BotVars.AdditionalAdmins or {}

            return additionalAdmins[player.UserId] == true
        end

        ----------------------------------------------------------------
        -- FIND PLAYER
        ----------------------------------------------------------------

        local function findPlayerByName(name)
            if not name or name == "" then
                return nil
            end

            name = string.lower(
                name:match("^%s*(.-)%s*$")
            )

            -- Exact username atau DisplayName
            for _, player in ipairs(Players:GetPlayers()) do
                if string.lower(player.Name) == name
                    or string.lower(player.DisplayName) == name then

                    return player
                end
            end

            -- Username prefix
            for _, player in ipairs(Players:GetPlayers()) do
                if string.sub(
                    string.lower(player.Name),
                    1,
                    #name
                ) == name then

                    return player
                end
            end

            return nil
        end

        ----------------------------------------------------------------
        -- PLAY HULA DANCE
        ----------------------------------------------------------------

        local function playHulaDance(targetPlayer)
            danceGeneration += 1

            local generation = danceGeneration

            _G.BotVars.ActiveMode = MODE_NAME

            if targetPlayer then
                _G.BotVars.CommandTarget = targetPlayer
            end

            ------------------------------------------------------------
            -- STOP PREVIOUS TRACK
            ------------------------------------------------------------

            dancing = false

            if danceTrack then
                local oldTrack = danceTrack
                danceTrack = nil

                pcall(function()
                    oldTrack:Stop(0.2)
                end)
            end

            ------------------------------------------------------------
            -- STOP OTHER MODES
            ------------------------------------------------------------

            stopOtherModes()

            if generation ~= danceGeneration then
                return
            end

            ------------------------------------------------------------
            -- VALIDATE CHARACTER
            ------------------------------------------------------------

            local character, humanoid = getCharacter()

            if not character or not humanoid then
                warn(
                    "[HulaDance] Character atau Humanoid tidak ditemukan."
                )
                return
            end

            if humanoid.Health <= 0 then
                warn("[HulaDance] Humanoid tidak hidup.")
                return
            end

            ------------------------------------------------------------
            -- PLAY ANIMATION WITH RETRY
            ------------------------------------------------------------

            local track = nil
            local lastError = nil
            local maxAttempts = 3

            for attempt = 1, maxAttempts do
                if generation ~= danceGeneration then
                    return
                end

                local currentCharacter, currentHumanoid =
                    getCharacter()

                if currentCharacter ~= character
                    or currentHumanoid ~= humanoid
                    or humanoid.Health <= 0 then

                    return
                end

                local success, result = pcall(function()
                    return humanoid:PlayEmoteAndGetAnimTrackById(
                        HULA_DANCE_ANIMATION_ID
                    )
                end)

                if success and result then
                    track = result
                    break
                end

                lastError = result

                if attempt < maxAttempts then
                    task.wait(0.15)
                end
            end

            ------------------------------------------------------------
            -- VALIDATE RESULT
            ------------------------------------------------------------

            if generation ~= danceGeneration then
                if track then
                    pcall(function()
                        track:Stop(0.2)
                    end)
                end

                return
            end

            local latestCharacter, latestHumanoid = getCharacter()

            if not track
                or latestCharacter ~= character
                or latestHumanoid ~= humanoid
                or humanoid.Health <= 0 then

                warn(
                    "[HulaDance] Gagal memainkan animasi setelah "
                    .. maxAttempts
                    .. " percobaan. Periksa Animation ID dan izin animasi.",
                    lastError or ""
                )

                dancing = false
                restoreNormalAnimation(generation)
                return
            end

            ------------------------------------------------------------
            -- SAVE TRACK
            ------------------------------------------------------------

            danceTrack = track
            dancing = true

            print(
                "[HulaDance] Animasi berhasil dimainkan:",
                HULA_DANCE_ANIMATION_ID,
                "| Bot:",
                LocalPlayer.Name
            )

            ------------------------------------------------------------
            -- MONITOR TRACK
            ------------------------------------------------------------

            task.spawn(function()
                local success = pcall(function()
                    track.Stopped:Wait()
                end)

                if not success then
                    return
                end

                if generation ~= danceGeneration then
                    return
                end

                if danceTrack ~= track then
                    return
                end

                danceTrack = nil

                if dancing then
                    restoreNormalAnimation(generation)
                end
            end)
        end

        ----------------------------------------------------------------
        -- CHAT COMMAND HANDLER
        ----------------------------------------------------------------

        local function handleChat(player, message)
            if not player or not message then
                return
            end

            local lowerMessage = string.lower(
                message:match("^%s*(.-)%s*$")
            )

            local admin = isAdmin(player)

            local isCommandTarget =
                _G.BotVars.CommandTarget == player

            ------------------------------------------------------------
            -- !stop (ADMIN ONLY)
            ------------------------------------------------------------

            if lowerMessage == "!stop" then
                if not admin then
                    return
                end

                _G.BotVars.ActiveMode = nil
                _G.BotVars.CommandTarget = nil

                for _, stopFunction in pairs(
                    _G.BotVars.ModeControllers
                ) do
                    if type(stopFunction) == "function" then
                        pcall(stopFunction)
                    end
                end

                return
            end

            ------------------------------------------------------------
            -- !unhuladance (ADMIN ONLY)
            ------------------------------------------------------------

            if lowerMessage == "!unhuladance" then
                if not admin then
                    return
                end

                if _G.BotVars.ActiveMode == MODE_NAME then
                    _G.BotVars.ActiveMode = nil
                end

                stopHulaDance()
                return
            end

            ------------------------------------------------------------
            -- !huladance
            ------------------------------------------------------------

            if lowerMessage == "!huladance" then
                if not admin and not isCommandTarget then
                    return
                end

                _G.BotVars.CommandTarget = player

                playHulaDance(player)
                return
            end

            ------------------------------------------------------------
            -- !huladance <username> (ADMIN ONLY)
            ------------------------------------------------------------

            local targetName = lowerMessage:match(
                "^!huladance%s+(.+)$"
            )

            if targetName then
                if not admin then
                    return
                end

                targetName = targetName:match("^%s*(.-)%s*$")

                local targetPlayer = findPlayerByName(targetName)

                if not targetPlayer then
                    warn(
                        "[HulaDance] Player tidak ditemukan: "
                        .. targetName
                    )
                    return
                end

                _G.BotVars.CommandTarget = targetPlayer

                playHulaDance(targetPlayer)
                return
            end
        end

        ----------------------------------------------------------------
        -- CONNECT CHAT
        ----------------------------------------------------------------

        local function connectPlayer(player)
            if connectedPlayers[player] then
                return
            end

            connectedPlayers[player] = player.Chatted:Connect(
                function(message)
                    handleChat(player, message)
                end
            )
        end

        for _, player in ipairs(Players:GetPlayers()) do
            connectPlayer(player)
        end

        Players.PlayerAdded:Connect(connectPlayer)

        Players.PlayerRemoving:Connect(function(player)
            local connection = connectedPlayers[player]

            if connection then
                connection:Disconnect()
                connectedPlayers[player] = nil
            end
        end)

        ----------------------------------------------------------------
        -- RESPAWN HANDLER
        ----------------------------------------------------------------

        LocalPlayer.CharacterAdded:Connect(function()
            danceGeneration += 1

            danceTrack = nil
            dancing = false

            local respawnGeneration = danceGeneration

            task.wait(1)

            if respawnGeneration ~= danceGeneration then
                return
            end

            if _G.BotVars.ActiveMode == MODE_NAME then
                task.wait(0.5)

                if respawnGeneration ~= danceGeneration then
                    return
                end

                playHulaDance(
                    _G.BotVars.CommandTarget or LocalPlayer
                )
            end
        end)

        ----------------------------------------------------------------
        -- LOADED
        ----------------------------------------------------------------

        print(
            "[HulaDance] Loaded untuk: "
            .. LocalPlayer.Name
            .. " | Animation ID: "
            .. HULA_DANCE_ANIMATION_ID
        )
    end
}