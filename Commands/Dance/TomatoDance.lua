-- TomatoDance.lua
-- Command:
-- !tomatodance
-- !tomatodance <username>
-- !untomatodance
-- !stop

return {
    Execute = function()

        ----------------------------------------------------------------
        -- SERVICES
        ----------------------------------------------------------------

        local Players = game:GetService("Players")
        local LocalPlayer = Players.LocalPlayer

        if not LocalPlayer then
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
        -- ADMIN MODULE
        ----------------------------------------------------------------

        local AdminModule = nil

        local ADMIN_URL =
            "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"

        local adminSuccess, adminResult = pcall(function()
            return loadstring(game:HttpGet(ADMIN_URL))()
        end)

        if adminSuccess and type(adminResult) == "table" then
            AdminModule = adminResult
        else
            warn(
                "[TomatoDance] Gagal memuat Admin.lua:",
                tostring(adminResult)
            )
        end

        ----------------------------------------------------------------
        -- CONFIGURATION
        ----------------------------------------------------------------

        local TOMATO_DANCE_ANIMATION_ID = "125871567269726"

        local MODE_NAME = "tomatodance"

        ----------------------------------------------------------------
        -- STATE
        ----------------------------------------------------------------

        local danceTrack = nil
        local dancing = false
        local danceGeneration = 0

        ----------------------------------------------------------------
        -- CHARACTER
        ----------------------------------------------------------------

        local function getCharacter(player)
            player = player or LocalPlayer

            if not player then
                return nil, nil
            end

            local character = player.Character

            if not character then
                return nil, nil
            end

            local humanoid =
                character:FindFirstChildOfClass("Humanoid")

            if not humanoid then
                return character, nil
            end

            return character, humanoid
        end

        ----------------------------------------------------------------
        -- ADMIN CHECK
        ----------------------------------------------------------------

        local function isAdmin(player)
            if not player then
                return false
            end

            -- Admin utama dan admin tambahan diperiksa melalui Admin.lua.
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

            -- Fallback untuk AdditionalAdmins berbentuk map UserId.
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

            local character, humanoid =
                getCharacter(LocalPlayer)

            if not character or not humanoid then
                dancing = false
                return
            end

            -- Hentikan track Action yang mungkin tertinggal.
            local animator =
                humanoid:FindFirstChildOfClass("Animator")

            if animator then
                for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
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

            -- Aktifkan kembali Animate untuk animasi normal Roblox.
            local animate =
                character:FindFirstChild("Animate")

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
        -- STOP TOMATO DANCE
        ----------------------------------------------------------------

        local function stopTomatoDance()
            danceGeneration += 1

            local generation = danceGeneration

            dancing = false
            stopOwnTrack(0.1)

            restoreNormalAnimation(generation)
        end

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
        -- PLAY TOMATO DANCE
        ----------------------------------------------------------------

        local function playTomatoDance(targetPlayer)
            targetPlayer = targetPlayer or LocalPlayer

            local character, humanoid =
                getCharacter(LocalPlayer)

            if not character or not humanoid then
                warn(
                    "[TomatoDance] Character atau Humanoid belum tersedia."
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

            -- Hentikan mode lain sebelum memulai TomatoDance.
            stopOtherModes()

            if generation ~= danceGeneration then
                return
            end

            _G.BotVars.ActiveMode = MODE_NAME
            _G.BotVars.CommandTarget = targetPlayer

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
                        TOMATO_DANCE_ANIMATION_ID
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

                -- Pastikan karakter belum berganti saat menunggu.
                local currentCharacter =
                    LocalPlayer.Character

                if currentCharacter ~= character then
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
                    "[TomatoDance] Animasi gagal setelah 3 percobaan:",
                    TOMATO_DANCE_ANIMATION_ID,
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

                -- Jangan mengubah mode lain yang sudah aktif.
                if _G.BotVars.ActiveMode == MODE_NAME then
                    restoreNormalAnimation(generation)
                end
            end)
        end

        ----------------------------------------------------------------
        -- REGISTER MODE CONTROLLER
        ----------------------------------------------------------------

        _G.BotVars.ModeControllers[MODE_NAME] =
            stopTomatoDance

        ----------------------------------------------------------------
        -- FIND PLAYER
        ----------------------------------------------------------------

        local function findPlayerByName(name)
            if not name or name == "" then
                return nil
            end

            local searchName = string.lower(name)

            -- Cocokkan username atau DisplayName secara persis dahulu.
            for _, player in ipairs(Players:GetPlayers()) do
                if string.lower(player.Name) == searchName
                    or string.lower(player.DisplayName) == searchName then

                    return player
                end
            end

            -- Jika tidak ada kecocokan persis, coba awalan username.
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
        -- CHAT HANDLER
        ----------------------------------------------------------------

        local function onChatted(player, message)
            if type(message) ~= "string" then
                return
            end

            local msg = string.lower(
                message:match("^%s*(.-)%s*$")
            )

            local admin = isAdmin(player)

            ------------------------------------------------------------
            -- STOP ALL MODES
            ------------------------------------------------------------

            if msg == "!stop" then
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
            -- STOP TOMATO DANCE
            ------------------------------------------------------------

            if msg == "!untomatodance" then
                if not admin then
                    return
                end

                if _G.BotVars.ActiveMode == MODE_NAME then
                    _G.BotVars.ActiveMode = nil
                    _G.BotVars.CommandTarget = nil
                end

                stopTomatoDance()
                return
            end

            ------------------------------------------------------------
            -- !tomatodance
            ------------------------------------------------------------

            if msg == "!tomatodance" then
                -- Admin dapat menjalankan dance.
                -- Target yang ditunjuk juga dapat menjalankannya sendiri.
                if not admin
                    and _G.BotVars.CommandTarget ~= player then
                    return
                end

                _G.BotVars.CommandTarget = player

                playTomatoDance(player)
                return
            end

            ------------------------------------------------------------
            -- !tomatodance <username>
            ------------------------------------------------------------

            local targetName =
                msg:match("^!tomatodance%s+(.+)$")

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
                        "[TomatoDance] Pemain tidak ditemukan:",
                        targetName
                    )
                    return
                end

                _G.BotVars.CommandTarget = targetPlayer

                playTomatoDance(targetPlayer)
                return
            end
        end

        ----------------------------------------------------------------
        -- CONNECT CHAT
        ----------------------------------------------------------------

        local connectedPlayers = {}

        local function connectPlayer(player)
            if connectedPlayers[player] then
                return
            end

            connectedPlayers[player] = true

            player.Chatted:Connect(function(message)
                onChatted(player, message)
            end)
        end

        for _, player in ipairs(Players:GetPlayers()) do
            connectPlayer(player)
        end

        Players.PlayerAdded:Connect(connectPlayer)

        Players.PlayerRemoving:Connect(function(player)
            connectedPlayers[player] = nil
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
                playTomatoDance(
                    _G.BotVars.CommandTarget or LocalPlayer
                )
            end
        end)

    end
}