-- PakodiDance.lua
-- Pakodi Dance dengan sistem mode bersama.
-- Animation ID dipertahankan.

return {
    Execute = function()

        --------------------------------------------------
        -- SERVICES
        --------------------------------------------------

        local Players = game:GetService("Players")
        local LocalPlayer = Players.LocalPlayer

        if not LocalPlayer then
            warn("[PakodiDance] LocalPlayer tidak ditemukan.")
            return
        end

        --------------------------------------------------
        -- GLOBAL VARIABLES
        --------------------------------------------------

        _G.BotVars = _G.BotVars or {}

        local Vars = _G.BotVars
        Vars.ModeControllers = Vars.ModeControllers or {}
        Vars.AdditionalAdmins = Vars.AdditionalAdmins or {}

        local MODE_NAME = "pakodidance"
        local ANIMATION_ID = 80676655500518

        --------------------------------------------------
        -- ADMIN MODULE
        --------------------------------------------------

        local AdminModule

        local adminOk, adminResult = pcall(function()
            local source = game:HttpGet(
                "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
            )

            local loader, compileError = loadstring(source)

            if not loader then
                error(compileError or "Gagal compile Admin.lua")
            end

            return loader()
        end)

        if adminOk and type(adminResult) == "table" then
            AdminModule = adminResult
        else
            warn(
                "[PakodiDance] Gagal memuat Admin.lua:",
                tostring(adminResult)
            )
            return
        end

        local function isAdmin(player)
            if not player then
                return false
            end

            local ok, result = pcall(function()
                return AdminModule:IsAdmin(player)
            end)

            if ok and result == true then
                return true
            end

            return Vars.AdditionalAdmins[player.UserId] == true
        end

        --------------------------------------------------
        -- DANCE STATE
        --------------------------------------------------

        local danceTrack = nil
        local dancing = false
        local danceGeneration = 0
        local connectedPlayers = {}

        --------------------------------------------------
        -- GET CHARACTER
        --------------------------------------------------

        local function getCharacterData(player)
            if not player then
                return nil, nil, nil
            end

            local character = player.Character

            if not character then
                return nil, nil, nil
            end

            local humanoid = character:FindFirstChildOfClass("Humanoid")

            if not humanoid or humanoid.Health <= 0 then
                return character, nil, nil
            end

            local animator = humanoid:FindFirstChildOfClass("Animator")

            if not animator then
                animator = Instance.new("Animator")
                animator.Parent = humanoid
            end

            return character, humanoid, animator
        end

        --------------------------------------------------
        -- RESTORE NORMAL ANIMATION
        --------------------------------------------------

        local function restoreNormalAnimation(generation)
            if generation ~= danceGeneration then
                return
            end

            local character, humanoid = getCharacterData(LocalPlayer)

            if not character or not humanoid then
                return
            end

            if danceTrack then
                pcall(function()
                    danceTrack:Stop(0.1)
                end)

                danceTrack = nil
            end

            dancing = false

            local animator = humanoid:FindFirstChildOfClass("Animator")

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

            if generation ~= danceGeneration then
                return
            end

            local animateScript = character:FindFirstChild("Animate")

            if animateScript and animateScript:IsA("LocalScript") then
                pcall(function()
                    animateScript.Disabled = true
                end)

                task.wait(0.1)

                if generation ~= danceGeneration then
                    return
                end

                if animateScript.Parent then
                    pcall(function()
                        animateScript.Disabled = false
                    end)
                end
            end

            if generation ~= danceGeneration then
                return
            end

            pcall(function()
                humanoid:ChangeState(Enum.HumanoidStateType.Running)
            end)

            task.delay(0.2, function()
                if generation ~= danceGeneration then
                    return
                end

                local _, currentHumanoid = getCharacterData(LocalPlayer)

                if currentHumanoid and currentHumanoid.Health > 0 then
                    pcall(function()
                        currentHumanoid:ChangeState(
                            Enum.HumanoidStateType.Running
                        )
                    end)
                end
            end)
        end

        --------------------------------------------------
        -- STOP OTHER MODES
        --------------------------------------------------

        local function stopOtherModes()
            for modeName, controller in pairs(Vars.ModeControllers) do
                if modeName ~= MODE_NAME and type(controller) == "function" then
                    pcall(controller)
                end
            end
        end

        --------------------------------------------------
        -- STOP PAKODI DANCE
        --------------------------------------------------

        local function stopPakodiDance()
            danceGeneration += 1

            local generation = danceGeneration

            dancing = false

            if danceTrack then
                pcall(function()
                    danceTrack:Stop(0.1)
                end)

                danceTrack = nil
            end

            restoreNormalAnimation(generation)
        end

        Vars.ModeControllers[MODE_NAME] = stopPakodiDance

        --------------------------------------------------
        -- FIND PLAYER
        --------------------------------------------------

        local function findPlayer(name)
            if not name or name == "" then
                return nil
            end

            local searchName = name:lower()

            for _, player in ipairs(Players:GetPlayers()) do
                if player.Name:lower() == searchName
                    or player.DisplayName:lower() == searchName then
                    return player
                end
            end

            for _, player in ipairs(Players:GetPlayers()) do
                if player.Name:lower():sub(1, #searchName) == searchName
                    or player.DisplayName:lower():sub(1, #searchName) == searchName then
                    return player
                end
            end

            return nil
        end

        --------------------------------------------------
        -- PLAY PAKODI DANCE
        --------------------------------------------------

        local function playPakodiDance(targetPlayer)
            danceGeneration += 1

            local generation = danceGeneration

            dancing = false

            Vars.ActiveMode = MODE_NAME

            if targetPlayer then
                Vars.CommandTarget = targetPlayer
            end

            if danceTrack then
                pcall(function()
                    danceTrack:Stop(0.1)
                end)

                danceTrack = nil
            end

            stopOtherModes()

            if generation ~= danceGeneration then
                return
            end

            local character, humanoid = getCharacterData(LocalPlayer)

            if not character or not humanoid then
                warn("[PakodiDance] Character atau Humanoid tidak tersedia.")
                return
            end

            if humanoid.Health <= 0 then
                warn("[PakodiDance] Humanoid sudah mati.")
                return
            end

            local track = nil

            for attempt = 1, 3 do
                if generation ~= danceGeneration then
                    return
                end

                if LocalPlayer.Character ~= character then
                    return
                end

                local success, result = pcall(function()
                    return humanoid:PlayEmoteAndGetAnimTrackById(
                        ANIMATION_ID
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
                        track:Stop(0.1)
                    end)
                end
                return
            end

            if LocalPlayer.Character ~= character then
                if track then
                    pcall(function()
                        track:Stop(0.1)
                    end)
                end
                return
            end

            if not track then
                warn(
                    "[PakodiDance] Gagal memainkan Animation ID:",
                    ANIMATION_ID
                )
                restoreNormalAnimation(generation)
                return
            end

            danceTrack = track
            dancing = true

            print(
                "[PakodiDance] Animasi dimulai:",
                ANIMATION_ID
            )

            local currentTrack = track
            local currentGeneration = generation

            task.spawn(function()
                currentTrack.Stopped:Wait()

                if danceGeneration ~= currentGeneration then
                    return
                end

                if danceTrack ~= currentTrack then
                    return
                end

                danceTrack = nil
                dancing = false

                restoreNormalAnimation(currentGeneration)
            end)
        end

        --------------------------------------------------
        -- CHAT COMMANDS
        --------------------------------------------------

        local function handleCommand(player, message)
            if not player or type(message) ~= "string" then
                return
            end

            local trimmed = message:match("^%s*(.-)%s*$")

            if not trimmed or trimmed == "" then
                return
            end

            local command = trimmed:lower()

            --------------------------------------------------
            -- !stop
            --------------------------------------------------

            if command == "!stop" then
                if not isAdmin(player) then
                    return
                end

                Vars.ActiveMode = nil
                Vars.CommandTarget = nil

                for _, controller in pairs(Vars.ModeControllers) do
                    if type(controller) == "function" then
                        pcall(controller)
                    end
                end

                return
            end

            --------------------------------------------------
            -- !unpakodidance
            --------------------------------------------------

            if command == "!unpakodidance" then
                if not isAdmin(player) then
                    return
                end

                if Vars.ActiveMode == MODE_NAME then
                    Vars.ActiveMode = nil
                end

                stopPakodiDance()
                return
            end

            --------------------------------------------------
            -- !pakodidance
            --------------------------------------------------

            if command == "!pakodidance" then
                if not isAdmin(player)
                    and Vars.CommandTarget ~= player then
                    return
                end

                Vars.CommandTarget = player
                playPakodiDance(player)
                return
            end

            --------------------------------------------------
            -- !pakodidance username
            --------------------------------------------------

            local targetName = trimmed:match("^[!][Pp][Aa][Kk][Oo][Dd][Ii][Dd][Aa][Nn][Cc][Ee]%s+(.+)$")

            if targetName then
                if not isAdmin(player) then
                    return
                end

                local targetPlayer = findPlayer(targetName)

                if not targetPlayer then
                    warn("[PakodiDance] Player tidak ditemukan:", targetName)
                    return
                end

                Vars.CommandTarget = targetPlayer
                playPakodiDance(targetPlayer)
            end
        end

        --------------------------------------------------
        -- CONNECT PLAYER CHAT
        --------------------------------------------------

        local function connectPlayer(player)
            if connectedPlayers[player] then
                return
            end

            connectedPlayers[player] = player.Chatted:Connect(function(message)
                handleCommand(player, message)
            end)
        end

        for _, player in ipairs(Players:GetPlayers()) do
            connectPlayer(player)
        end

        Players.PlayerAdded:Connect(connectPlayer)

        Players.PlayerRemoving:Connect(function(player)
            if connectedPlayers[player] then
                connectedPlayers[player]:Disconnect()
                connectedPlayers[player] = nil
            end
        end)

        --------------------------------------------------
        -- RESPAWN HANDLER
        --------------------------------------------------

        LocalPlayer.CharacterAdded:Connect(function()
            danceGeneration += 1

            danceTrack = nil
            dancing = false

            local generation = danceGeneration

            task.wait(0.5)

            if generation ~= danceGeneration then
                return
            end

            if Vars.ActiveMode == MODE_NAME then
                playPakodiDance(
                    Vars.CommandTarget or LocalPlayer
                )
            end
        end)

        print(
            "[PakodiDance] Loaded. Animation ID:",
            ANIMATION_ID
        )
    end
}