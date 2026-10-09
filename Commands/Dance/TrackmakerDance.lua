-- TrackmakerDance.lua
-- Command:
-- !trackmakerdance
-- !trackmakerdance <username>
-- !untrackmakerdance
-- !stop

return {
    Execute = function()

        ----------------------------------------------------------------
        -- SERVICES
        ----------------------------------------------------------------

        local Players = game:GetService("Players")
        local LocalPlayer = Players.LocalPlayer

        if not LocalPlayer then
            warn("[TrackmakerDance] LocalPlayer tidak ditemukan.")
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

        ----------------------------------------------------------------
        -- LOAD ADMIN MODULE
        ----------------------------------------------------------------

        local AdminModule = nil

        local ADMIN_URL =
            "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"

        local adminSuccess, adminResult = pcall(function()
            local source = game:HttpGet(ADMIN_URL)
            local loader = loadstring(source)

            if not loader then
                error("loadstring gagal membuat fungsi.")
            end

            return loader()
        end)

        if adminSuccess and type(adminResult) == "table" then
            AdminModule = adminResult
        else
            warn(
                "[TrackmakerDance] Gagal memuat Admin.lua:",
                tostring(adminResult)
            )
        end

        ----------------------------------------------------------------
        -- CONFIGURATION
        ----------------------------------------------------------------

        local TRACKMAKER_DANCE_ANIMATION_ID = "75541759268466"
        local MODE_NAME = "trackmakerdance"

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
        -- ADMIN CHECK
        ----------------------------------------------------------------

        local function isAdmin(player)
            if not player then
                return false
            end

            if AdminModule
                and type(AdminModule) == "table"
                and type(AdminModule.IsAdmin) == "function" then

                local success, result = pcall(function()
                    return AdminModule:IsAdmin(player)
                end)

                if success and result == true then
                    return true
                end
            end

            -- AdditionalAdmins menggunakan UserId sebagai key.
            local additionalAdmins =
                _G.BotVars.AdditionalAdmins or {}

            if additionalAdmins[player.UserId] == true then
                return true
            end

            return false
        end

        ----------------------------------------------------------------
        -- STOP OWN TRACK
        ----------------------------------------------------------------

        local function stopOwnTrack(fadeTime)
            local track = danceTrack
            danceTrack = nil

            if track then
                pcall(function()
                    track:Stop(fadeTime or 0.1)
                end)
            end
        end

        ----------------------------------------------------------------
        -- RESTORE NORMAL ANIMATION
        ----------------------------------------------------------------

        local function restoreNormalAnimation(generation)
            if generation ~= danceGeneration then
                return
            end

            stopOwnTrack(0.1)

            local character, humanoid = getCharacter()

            if not character or not humanoid then
                dancing = false
                return
            end

            -- Hentikan track Action yang mungkin tertinggal.
            local animator =
                humanoid:FindFirstChildOfClass("Animator")

            if animator then
                for _, track in ipairs(
                    animator:GetPlayingAnimationTracks()
                ) do
                    if track.Priority == Enum.AnimationPriority.Action
                        or track.Priority == Enum.AnimationPriority.Action2
                        or track.Priority == Enum.AnimationPriority.Action3
                        or track.Priority == Enum.AnimationPriority.Action4 then

                        pcall(function()
                            track:Stop(0.1)
                        end)
                    end
                end
            end

            -- Pulihkan animasi normal Roblox.
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

            if humanoid.Parent and humanoid.Health > 0 then
                pcall(function()
                    humanoid:ChangeState(
                        Enum.HumanoidStateType.Running
                    )
                end)
            end

            dancing = false
        end

        ----------------------------------------------------------------
        -- STOP TRACKMAKER DANCE
        ----------------------------------------------------------------

        local function stopTrackmakerDance()
            danceGeneration += 1

            local generation = danceGeneration

            dancing = false
            stopOwnTrack(0.1)

            restoreNormalAnimation(generation)
        end

        ----------------------------------------------------------------
        -- REGISTER MODE CONTROLLER
        ----------------------------------------------------------------

        _G.BotVars.ModeControllers[MODE_NAME] =
            stopTrackmakerDance

        ----------------------------------------------------------------
        -- STOP OTHER MODES
        ----------------------------------------------------------------

        local function stopOtherModes()
            local controllers =
                _G.BotVars.ModeControllers or {}

            for modeName, stopFunction in pairs(controllers) do
                if modeName ~= MODE_NAME
                    and type(stopFunction) == "function" then

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

            local searchName = string.lower(name)

            -- Cocokkan username atau DisplayName secara persis.
            for _, player in ipairs(Players:GetPlayers()) do
                if string.lower(player.Name) == searchName
                    or string.lower(player.DisplayName) == searchName then

                    return player
                end
            end

            -- Jika tidak ada kecocokan persis, cari awalan username.
            for _, player in ipairs(Players:GetPlayers()) do
                if string.sub(
                    string.lower(player.Name),
                    1,
                    #searchName
                ) == searchName then

                    return player
                end
            end

            return nil
        end

        ----------------------------------------------------------------
        -- PLAY TRACKMAKER DANCE
        ----------------------------------------------------------------

        local function playTrackmakerDance(targetPlayer)
            local character, humanoid = getCharacter()

            if not character or not humanoid then
                warn(
                    "[TrackmakerDance] Character atau Humanoid tidak ditemukan."
                )
                return
            end

            if humanoid.Health <= 0 then
                return
            end

            -- Batalkan operasi dance sebelumnya.
            danceGeneration += 1

            local generation = danceGeneration

            dancing = false
            stopOwnTrack(0.1)

            -- Hentikan mode lain sebelum memulai TrackmakerDance.
            stopOtherModes()

            if generation ~= danceGeneration then
                return
            end

            _G.BotVars.ActiveMode = MODE_NAME

            if targetPlayer then
                _G.BotVars.CommandTarget = targetPlayer
            end

            ------------------------------------------------------------
            -- PLAY WITH RETRIES
            ------------------------------------------------------------

            local track = nil
            local lastError = nil

            for attempt = 1, 3 do
                if generation ~= danceGeneration then
                    return
                end

                local success, result = pcall(function()
                    return humanoid:PlayEmoteAndGetAnimTrackById(
                        TRACKMAKER_DANCE_ANIMATION_ID
                    )
                end)

                if success and result then
                    track = result
                    break
                end

                lastError = result

                if attempt < 3 then
                    task.wait(0.15)
                end

                -- Pastikan karakter tidak berganti saat menunggu.
                if LocalPlayer.Character ~= character then
                    return
                end

                if humanoid.Health <= 0 then
                    return
                end
            end

            ------------------------------------------------------------
            -- VALIDATE RESULT
            ------------------------------------------------------------

            if generation ~= danceGeneration then
                if track then
                    pcall(function()
                        track:Stop(0)
                    end)
                end

                return
            end

            if not track then
                warn(
                    "[TrackmakerDance] Animasi gagal setelah 3 percobaan:",
                    TRACKMAKER_DANCE_ANIMATION_ID,
                    "| Error:",
                    tostring(lastError)
                )

                dancing = false
                return
            end

            danceTrack = track
            dancing = true

            ------------------------------------------------------------
            -- TRACK STOPPED
            ------------------------------------------------------------

            track.Stopped:Connect(function()
                if generation ~= danceGeneration then
                    return
                end

                if danceTrack ~= track then
                    return
                end

                danceTrack = nil
                dancing = false

                -- Jangan mengganggu mode lain yang sudah aktif.
                if _G.BotVars.ActiveMode == MODE_NAME then
                    restoreNormalAnimation(generation)
                end
            end)
        end

        ----------------------------------------------------------------
        -- CHAT COMMAND HANDLER
        ----------------------------------------------------------------

        local function handleChat(player, message)
            if not player or type(message) ~= "string" then
                return
            end

            local lowerMessage = string.lower(
                message:match("^%s*(.-)%s*$")
            )

            local admin = isAdmin(player)

            ------------------------------------------------------------
            -- !stop
            ------------------------------------------------------------

            if lowerMessage == "!stop" then
                if not admin then
                    return
                end

                _G.BotVars.ActiveMode = nil
                _G.BotVars.CommandTarget = nil

                local controllers =
                    _G.BotVars.ModeControllers or {}

                for _, stopFunction in pairs(controllers) do
                    if type(stopFunction) == "function" then
                        pcall(function()
                            stopFunction()
                        end)
                    end
                end

                return
            end

            ------------------------------------------------------------
            -- !untrackmakerdance
            ------------------------------------------------------------

            if lowerMessage == "!untrackmakerdance" then
                if not admin then
                    return
                end

                if _G.BotVars.ActiveMode == MODE_NAME then
                    _G.BotVars.ActiveMode = nil
                    _G.BotVars.CommandTarget = nil
                end

                stopTrackmakerDance()
                return
            end

            ------------------------------------------------------------
            -- !trackmakerdance
            ------------------------------------------------------------

            if lowerMessage == "!trackmakerdance" then
                if not admin
                    and _G.BotVars.CommandTarget ~= player then
                    return
                end

                _G.BotVars.CommandTarget = player

                playTrackmakerDance(player)
                return
            end

            ------------------------------------------------------------
            -- !trackmakerdance <username>
            ------------------------------------------------------------

            local targetName = lowerMessage:match(
                "^!trackmakerdance%s+(.+)$"
            )

            if targetName then
                if not admin then
                    return
                end

                targetName =
                    targetName:match("^%s*(.-)%s*$")

                local targetPlayer =
                    findPlayerByName(targetName)

                if not targetPlayer then
                    warn(
                        "[TrackmakerDance] Pemain tidak ditemukan:",
                        targetName
                    )
                    return
                end

                _G.BotVars.CommandTarget = targetPlayer

                playTrackmakerDance(targetPlayer)
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

            connectedPlayers[player] =
                player.Chatted:Connect(function(message)
                    handleChat(player, message)
                end)
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
            task.wait(0.5)

            if _G.BotVars.ActiveMode ~= MODE_NAME then
                return
            end

            if not dancing then
                playTrackmakerDance(
                    _G.BotVars.CommandTarget or LocalPlayer
                )
            end
        end)

        ----------------------------------------------------------------
        -- LOADED
        ----------------------------------------------------------------

        print(
            "[TrackmakerDance] Loaded untuk: " .. LocalPlayer.Name
        )

    end
}