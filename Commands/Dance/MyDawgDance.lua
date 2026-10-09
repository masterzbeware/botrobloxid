-- MyDawgDance.lua
-- Command:
-- !mydawgdance
-- !mydawgdance <username>
-- !unmydawgdance
-- !stop

return {
    Execute = function()

        ----------------------------------------------------------------
        -- SERVICES
        ----------------------------------------------------------------

        local Players = game:GetService("Players")
        local LocalPlayer = Players.LocalPlayer

        if not LocalPlayer then
            warn("[MyDawgDance] LocalPlayer tidak ditemukan.")
            return
        end

        ----------------------------------------------------------------
        -- BOT VARIABLES
        ----------------------------------------------------------------

        _G.BotVars = _G.BotVars or {}
        _G.BotVars.ModeControllers = _G.BotVars.ModeControllers or {}

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

        local MYDAWG_DANCE_ANIMATION_ID = "73279689665894"

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

            local humanoid = character:FindFirstChildOfClass("Humanoid")

            return character, humanoid
        end

        ----------------------------------------------------------------
        -- RESTORE NORMAL ANIMATION
        ----------------------------------------------------------------

        local function restoreNormalAnimation(generation)
            local character, humanoid = getCharacter()

            if danceTrack then
                pcall(function()
                    danceTrack:Stop(0.2)
                end)

                danceTrack = nil
            end

            if character then
                if humanoid then
                    for _, track in ipairs(
                        humanoid:GetPlayingAnimationTracks()
                    ) do
                        if track.Priority == Enum.AnimationPriority.Action then
                            pcall(function()
                                track:Stop(0.2)
                            end)
                        end
                    end
                end

                local animate = character:FindFirstChild("Animate")

                if animate and animate:IsA("LocalScript") then
                    pcall(function()
                        animate.Disabled = true
                        task.wait(0.1)
                        animate.Disabled = false
                    end)
                end
            end

            if humanoid then
                pcall(function()
                    humanoid:ChangeState(Enum.HumanoidStateType.Running)
                end)
            end

            task.delay(0.25, function()
                if generation ~= danceGeneration then
                    return
                end

                dancing = false
            end)
        end

        ----------------------------------------------------------------
        -- STOP MYDAWG DANCE
        ----------------------------------------------------------------

        local function stopMyDawgDance()
            danceGeneration += 1
            dancing = false

            local generation = danceGeneration

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

        _G.BotVars.ModeControllers.mydawgdance = stopMyDawgDance

        ----------------------------------------------------------------
        -- STOP OTHER MODES
        ----------------------------------------------------------------

        local function stopOtherModes()
            for modeName, stopFunction in pairs(
                _G.BotVars.ModeControllers
            ) do
                if modeName ~= "mydawgdance"
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

            if player == LocalPlayer then
                return true
            end

            if AdminModule and type(AdminModule) == "table" then
                local success, result = pcall(function()
                    if type(AdminModule.IsAdmin) == "function" then
                        return AdminModule.IsAdmin(player)
                    end

                    if type(AdminModule.isAdmin) == "function" then
                        return AdminModule.isAdmin(player)
                    end

                    return false
                end)

                if success and result then
                    return true
                end
            end

            for _, adminName in ipairs(
                _G.BotVars.AdditionalAdmins or {}
            ) do
                if string.lower(tostring(adminName))
                    == string.lower(player.Name) then
                    return true
                end
            end

            return false
        end

        ----------------------------------------------------------------
        -- FIND PLAYER
        ----------------------------------------------------------------

        local function findPlayerByName(name)
            if not name or name == "" then
                return nil
            end

            name = string.lower(name)

            for _, player in ipairs(Players:GetPlayers()) do
                if string.lower(player.Name) == name
                    or string.lower(player.DisplayName) == name then
                    return player
                end
            end

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
        -- PLAY MYDAWG DANCE
        ----------------------------------------------------------------

        local function playMyDawgDance(targetPlayer)
            local character, humanoid = getCharacter()

            if not character or not humanoid then
                warn("[MyDawgDance] Character atau Humanoid tidak ditemukan.")
                return
            end

            danceGeneration += 1
            local generation = danceGeneration

            if danceTrack then
                pcall(function()
                    danceTrack:Stop(0.2)
                end)

                danceTrack = nil
            end

            stopOtherModes()

            _G.BotVars.ActiveMode = "mydawgdance"

            if targetPlayer then
                _G.BotVars.CommandTarget = targetPlayer
            end

            dancing = true

            local success, track = pcall(function()
                return humanoid:PlayEmoteAndGetAnimTrackById(
                    MYDAWG_DANCE_ANIMATION_ID
                )
            end)

            if not success or not track then
                warn(
                    "[MyDawgDance] Gagal memainkan animasi. " ..
                    "Pastikan Animation ID dapat digunakan."
                )

                dancing = false
                return
            end

            if generation ~= danceGeneration then
                pcall(function()
                    track:Stop(0.2)
                end)

                return
            end

            danceTrack = track

            track.Stopped:Connect(function()
                if generation ~= danceGeneration then
                    return
                end

                danceTrack = nil
                dancing = false

                if _G.BotVars.ActiveMode == "mydawgdance" then
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

            local lowerMessage = string.lower(message)

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
            -- !unmydawgdance
            ------------------------------------------------------------

            if lowerMessage == "!unmydawgdance" then
                if not isAdmin(player) then
                    return
                end

                if _G.BotVars.ActiveMode == "mydawgdance" then
                    _G.BotVars.ActiveMode = nil
                end

                stopMyDawgDance()
                return
            end

            ------------------------------------------------------------
            -- !mydawgdance
            ------------------------------------------------------------

            if lowerMessage == "!mydawgdance" then
                if not isAdmin(player)
                    and _G.BotVars.CommandTarget ~= player then
                    return
                end

                _G.BotVars.CommandTarget = player
                playMyDawgDance(player)

                return
            end

            ------------------------------------------------------------
            -- !mydawgdance <username>
            ------------------------------------------------------------

            local targetName = lowerMessage:match(
                "^!mydawgdance%s+(.+)$"
            )

            if targetName then
                if not isAdmin(player) then
                    return
                end

                targetName = targetName:match("^%s*(.-)%s*$")

                local targetPlayer = findPlayerByName(targetName)

                if not targetPlayer then
                    warn(
                        "[MyDawgDance] Player tidak ditemukan: "
                        .. targetName
                    )

                    return
                end

                _G.BotVars.CommandTarget = targetPlayer
                playMyDawgDance(targetPlayer)

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
            task.wait(1)

            if _G.BotVars.ActiveMode == "mydawgdance" then
                playMyDawgDance(LocalPlayer)
            end
        end)

        ----------------------------------------------------------------
        -- LOADED
        ----------------------------------------------------------------

        print("[MyDawgDance] Loaded untuk: " .. LocalPlayer.Name)

    end
}