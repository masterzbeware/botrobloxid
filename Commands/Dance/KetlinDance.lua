-- KetlinDance.lua
-- Command:
-- !ketlindance
-- !ketlindance <username>
-- !unketlindance
-- !stop

return {
    Execute = function()

        ----------------------------------------------------------------
        -- SERVICES
        ----------------------------------------------------------------

        local Players = game:GetService("Players")

        local LocalPlayer = Players.LocalPlayer

        if not LocalPlayer then
            warn("[KetlinDance] LocalPlayer tidak ditemukan.")
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

        local MODE_NAME = "ketlindance"

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

        ----------------------------------------------------------------
        -- CONFIGURATION
        ----------------------------------------------------------------

        local KETLIN_DANCE_ANIMATION_ID = "120769095541981"

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
                pcall(function()
                    danceTrack:Stop(0.2)
                end)

                danceTrack = nil
            end

            if not character then
                dancing = false
                return
            end

            if humanoid then
                for _, track in ipairs(
                    humanoid:GetPlayingAnimationTracks()
                ) do
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

            local animate = character:FindFirstChild("Animate")

            if animate and animate:IsA("LocalScript") then
                pcall(function()
                    animate.Disabled = true
                    task.wait(0.1)

                    if generation ~= danceGeneration then
                        return
                    end

                    animate.Disabled = false
                end)
            end

            if generation ~= danceGeneration then
                return
            end

            if humanoid then
                pcall(function()
                    humanoid:ChangeState(
                        Enum.HumanoidStateType.Running
                    )
                end)
            end

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
        -- STOP KETLIN DANCE
        ----------------------------------------------------------------

        local function stopKetlinDance()
            danceGeneration += 1

            local generation = danceGeneration

            dancing = false

            if danceTrack then
                pcall(function()
                    danceTrack:Stop(0.2)
                end)

                danceTrack = nil
            end

            restoreNormalAnimation(generation)
        end

        ----------------------------------------------------------------
        -- REGISTER MODE CONTROLLER
        ----------------------------------------------------------------

        _G.BotVars.ModeControllers[MODE_NAME] =
            stopKetlinDance

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

            -- Username dengan awalan yang cocok
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
        -- PLAY KETLIN DANCE
        ----------------------------------------------------------------

        local function playKetlinDance(targetPlayer)
            danceGeneration += 1

            local generation = danceGeneration

            local character, humanoid = getCharacter()

            if not character or not humanoid then
                warn(
                    "[KetlinDance] Character atau Humanoid tidak ditemukan."
                )
                return
            end

            if humanoid.Health <= 0 then
                warn("[KetlinDance] Humanoid tidak hidup.")
                return
            end

            _G.BotVars.ActiveMode = MODE_NAME

            if targetPlayer then
                _G.BotVars.CommandTarget = targetPlayer
            end

            if danceTrack then
                pcall(function()
                    danceTrack:Stop(0.2)
                end)

                danceTrack = nil
            end

            dancing = false

            stopOtherModes()

            if generation ~= danceGeneration then
                return
            end

            -- Stop mode lain mungkin memerlukan waktu untuk selesai.
            -- Pastikan karakter masih sama sebelum memulai animasi.
            local currentCharacter, currentHumanoid = getCharacter()

            if currentCharacter ~= character
                or currentHumanoid ~= humanoid
                or humanoid.Health <= 0 then

                return
            end

            local track = nil

            for attempt = 1, 3 do
                if generation ~= danceGeneration then
                    return
                end

                local success, result = pcall(function()
                    return humanoid:PlayEmoteAndGetAnimTrackById(
                        KETLIN_DANCE_ANIMATION_ID
                    )
                end)

                if success and result then
                    track = result
                    break
                end

                if attempt < 3 then
                    task.wait(0.15)
                end
            end

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
                    "[KetlinDance] Gagal memainkan animasi setelah 3 percobaan. " ..
                    "Periksa Animation ID dan izin penggunaan animasi."
                )

                if _G.BotVars.ActiveMode == MODE_NAME then
                    _G.BotVars.ActiveMode = nil
                end

                dancing = false
                restoreNormalAnimation(generation)
                return
            end

            danceTrack = track
            dancing = true

            local trackGeneration = generation

            task.spawn(function()
                local success = pcall(function()
                    track.Stopped:Wait()
                end)

                if not success then
                    return
                end

                if trackGeneration ~= danceGeneration then
                    return
                end

                if danceTrack ~= track then
                    return
                end

                danceTrack = nil

                if dancing then
                    restoreNormalAnimation(trackGeneration)
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

            ------------------------------------------------------------
            -- !stop
            ------------------------------------------------------------

            if lowerMessage == "!stop" then
                if not isAdmin(player) then
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
            -- !unketlindance
            ------------------------------------------------------------

            if lowerMessage == "!unketlindance" then
                if not isAdmin(player) then
                    return
                end

                if _G.BotVars.ActiveMode == MODE_NAME then
                    _G.BotVars.ActiveMode = nil
                end

                stopKetlinDance()
                return
            end

            ------------------------------------------------------------
            -- !ketlindance
            ------------------------------------------------------------

            if lowerMessage == "!ketlindance" then
                if not isAdmin(player)
                    and _G.BotVars.CommandTarget ~= player then

                    return
                end

                _G.BotVars.CommandTarget = player
                playKetlinDance(player)

                return
            end

            ------------------------------------------------------------
            -- !ketlindance <username>
            ------------------------------------------------------------

            local targetName = lowerMessage:match(
                "^!ketlindance%s+(.+)$"
            )

            if targetName then
                if not isAdmin(player) then
                    return
                end

                targetName = targetName:match("^%s*(.-)%s*$")

                local targetPlayer = findPlayerByName(targetName)

                if not targetPlayer then
                    warn(
                        "[KetlinDance] Player tidak ditemukan: "
                        .. targetName
                    )

                    return
                end

                _G.BotVars.CommandTarget = targetPlayer
                playKetlinDance(targetPlayer)

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
                playKetlinDance(
                    _G.BotVars.CommandTarget or LocalPlayer
                )
            end
        end)

        ----------------------------------------------------------------
        -- LOADED
        ----------------------------------------------------------------

        print(
            "[KetlinDance] Loaded untuk: "
            .. LocalPlayer.Name
            .. " | Animation ID: "
            .. KETLIN_DANCE_ANIMATION_ID
        )
    end
}