-- PargoyDance.lua
-- Pargoy Dance dengan sistem mode bersama.
-- Animation ID tetap dipertahankan.

return {
    Execute = function()

        --------------------------------------------------
        -- SERVICES
        --------------------------------------------------

        local Players = game:GetService("Players")
        local LocalPlayer = Players.LocalPlayer

        if not LocalPlayer then
            warn("[PargoyDance] LocalPlayer tidak ditemukan.")
            return
        end

        --------------------------------------------------
        -- GLOBAL VARIABLES
        --------------------------------------------------

        _G.BotVars = _G.BotVars or {}

        local Vars = _G.BotVars
        Vars.ModeControllers = Vars.ModeControllers or {}
        Vars.AdditionalAdmins = Vars.AdditionalAdmins or {}

        local MODE_NAME = "pargoydance"
        local ANIMATION_ID = 80655010092183

        --------------------------------------------------
        -- LOAD ADMIN MODULE
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
                "[PargoyDance] Gagal memuat Admin.lua:",
                tostring(adminResult)
            )
            return
        end

        --------------------------------------------------
        -- ADMIN CHECK
        --------------------------------------------------

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

        local playerAddedConnection
        local playerRemovingConnection
        local characterAddedConnection

        --------------------------------------------------
        -- GET CHARACTER DATA
        --------------------------------------------------

        local function getCharacterData(player)
            if not player then
                return nil, nil, nil
            end

            local character = player.Character

            if not character then
                return nil, nil, nil
            end

            local humanoid =
                character:FindFirstChildOfClass("Humanoid")

            if not humanoid or humanoid.Health <= 0 then
                return character, nil, nil
            end

            local animator =
                humanoid:FindFirstChildOfClass("Animator")

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

            local character, humanoid =
                getCharacterData(LocalPlayer)

            if not character or not humanoid then
                dancing = false
                return
            end

            if danceTrack then
                local oldTrack = danceTrack
                danceTrack = nil

                pcall(function()
                    oldTrack:Stop(0.1)
                end)
            end

            dancing = false

            --------------------------------------------------
            -- STOP ACTION TRACKS
            --------------------------------------------------

            local animator =
                humanoid:FindFirstChildOfClass("Animator")

            if animator then
                local ok, tracks = pcall(function()
                    return animator:GetPlayingAnimationTracks()
                end)

                if ok and tracks then
                    for _, track in ipairs(tracks) do
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
            end

            if generation ~= danceGeneration then
                return
            end

            --------------------------------------------------
            -- RESTART DEFAULT ANIMATE
            --------------------------------------------------

            local animateScript =
                character:FindFirstChild("Animate")

            if animateScript
                and animateScript:IsA("LocalScript") then

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

            --------------------------------------------------
            -- RESTORE HUMANOID STATE
            --------------------------------------------------

            pcall(function()
                humanoid:ChangeState(
                    Enum.HumanoidStateType.Running
                )
            end)

            task.delay(0.2, function()
                if generation ~= danceGeneration then
                    return
                end

                local _, currentHumanoid =
                    getCharacterData(LocalPlayer)

                if currentHumanoid then
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
                if modeName ~= MODE_NAME
                    and type(controller) == "function" then

                    pcall(controller)
                end
            end
        end

        --------------------------------------------------
        -- STOP PARGOY DANCE
        --------------------------------------------------

        local function stopPargoyDance()
            danceGeneration += 1

            local generation = danceGeneration

            dancing = false

            if danceTrack then
                local oldTrack = danceTrack
                danceTrack = nil

                pcall(function()
                    oldTrack:Stop(0.1)
                end)
            end

            restoreNormalAnimation(generation)

            -- CommandTarget sengaja tidak dihapus di sini.
        end

        Vars.ModeControllers[MODE_NAME] = stopPargoyDance

        --------------------------------------------------
        -- FIND PLAYER
        --------------------------------------------------

        local function findPlayerByName(name)
            if not name or name == "" then
                return nil
            end

            local searchName = name:lower()

            -- Exact username atau display name
            for _, player in ipairs(Players:GetPlayers()) do
                if player.Name:lower() == searchName
                    or player.DisplayName:lower() == searchName then

                    return player
                end
            end

            -- Username atau display name dengan prefix
            for _, player in ipairs(Players:GetPlayers()) do
                if player.Name:lower():sub(1, #searchName) == searchName
                    or player.DisplayName:lower():sub(1, #searchName) == searchName then

                    return player
                end
            end

            return nil
        end

        --------------------------------------------------
        -- PLAY PARGOY DANCE
        --------------------------------------------------

        local function playPargoyDance(targetPlayer)
            danceGeneration += 1

            local generation = danceGeneration

            dancing = false

            --------------------------------------------------
            -- SET GLOBAL MODE
            --------------------------------------------------

            Vars.ActiveMode = MODE_NAME

            if targetPlayer then
                Vars.CommandTarget = targetPlayer
            end

            --------------------------------------------------
            -- STOP PREVIOUS PARGOY TRACK
            --------------------------------------------------

            if danceTrack then
                local oldTrack = danceTrack
                danceTrack = nil

                pcall(function()
                    oldTrack:Stop(0.1)
                end)
            end

            --------------------------------------------------
            -- STOP OTHER MODES
            --------------------------------------------------

            stopOtherModes()

            if generation ~= danceGeneration then
                return
            end

            --------------------------------------------------
            -- GET CHARACTER
            --------------------------------------------------

            local character, humanoid =
                getCharacterData(LocalPlayer)

            if not character or not humanoid then
                warn(
                    "[PargoyDance] Character atau Humanoid tidak tersedia."
                )
                return
            end

            if humanoid.Health <= 0 then
                warn("[PargoyDance] Humanoid sudah mati.")
                return
            end

            --------------------------------------------------
            -- PLAY ANIMATION WITH RETRY
            --------------------------------------------------

            local track = nil
            local maxAttempts = 3

            for attempt = 1, maxAttempts do
                if generation ~= danceGeneration then
                    return
                end

                if LocalPlayer.Character ~= character then
                    return
                end

                local ok, result = pcall(function()
                    return humanoid:PlayEmoteAndGetAnimTrackById(
                        ANIMATION_ID
                    )
                end)

                if ok and result then
                    track = result
                    break
                end

                if attempt < maxAttempts then
                    task.wait(0.15)
                end
            end

            --------------------------------------------------
            -- VALIDATE AFTER RETRY
            --------------------------------------------------

            if generation ~= danceGeneration
                or LocalPlayer.Character ~= character then

                if track then
                    pcall(function()
                        track:Stop(0.1)
                    end)
                end

                return
            end

            --------------------------------------------------
            -- HANDLE FAILURE
            --------------------------------------------------

            if not track then
                dancing = false

                warn(
                    "[PargoyDance] Gagal memainkan Animation ID:",
                    ANIMATION_ID
                )

                restoreNormalAnimation(generation)
                return
            end

            --------------------------------------------------
            -- REGISTER ACTIVE TRACK
            --------------------------------------------------

            danceTrack = track
            dancing = true

            print(
                "[PargoyDance] Animasi dimulai:",
                ANIMATION_ID,
                "| Bot:",
                LocalPlayer.Name
            )

            --------------------------------------------------
            -- MONITOR TRACK
            --------------------------------------------------

            local currentTrack = track
            local trackGeneration = generation

            task.spawn(function()
                local ok = pcall(function()
                    currentTrack.Stopped:Wait()
                end)

                if not ok then
                    return
                end

                if trackGeneration ~= danceGeneration then
                    return
                end

                if danceTrack ~= currentTrack then
                    return
                end

                if not dancing then
                    return
                end

                danceTrack = nil
                dancing = false

                restoreNormalAnimation(trackGeneration)
            end)
        end

        --------------------------------------------------
        -- CHAT COMMAND HANDLER
        --------------------------------------------------

        local function handleCommand(message, sender)
            if not sender or type(message) ~= "string" then
                return
            end

            local trimmed = message:match("^%s*(.-)%s*$")

            if not trimmed or trimmed == "" then
                return
            end

            local lower = trimmed:lower()
            local senderIsAdmin = isAdmin(sender)

            local isCommandTarget =
                Vars.CommandTarget == sender

            --------------------------------------------------
            -- !STOP (ADMIN ONLY)
            --------------------------------------------------

            if lower == "!stop" then
                if not senderIsAdmin then
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
            -- !UNPARGOYDANCE (ADMIN ONLY)
            --------------------------------------------------

            if lower == "!unpargoydance" then
                if not senderIsAdmin then
                    return
                end

                if Vars.ActiveMode == MODE_NAME then
                    Vars.ActiveMode = nil
                end

                stopPargoyDance()
                return
            end

            --------------------------------------------------
            -- !PARGOYDANCE
            --------------------------------------------------

            if lower == "!pargoydance" then
                if not senderIsAdmin and not isCommandTarget then
                    return
                end

                Vars.CommandTarget = sender
                playPargoyDance(sender)
                return
            end

            --------------------------------------------------
            -- !PARGOYDANCE USERNAME (ADMIN ONLY)
            --------------------------------------------------

            local targetName =
                trimmed:match("^[!][Pp][Aa][Rr][Gg][Oo][Yy][Dd][Aa][Nn][Cc][Ee]%s+(.+)$")

            if targetName then
                if not senderIsAdmin then
                    return
                end

                local target = findPlayerByName(targetName)

                if not target then
                    warn(
                        "[PargoyDance] Player tidak ditemukan:",
                        targetName
                    )
                    return
                end

                Vars.CommandTarget = target
                playPargoyDance(target)
            end
        end

        --------------------------------------------------
        -- CONNECT PLAYER CHAT
        --------------------------------------------------

        local function connectPlayerChat(player)
            if connectedPlayers[player] then
                return
            end

            connectedPlayers[player] =
                player.Chatted:Connect(function(message)
                    handleCommand(message, player)
                end)
        end

        for _, player in ipairs(Players:GetPlayers()) do
            connectPlayerChat(player)
        end

        --------------------------------------------------
        -- PLAYER ADDED
        --------------------------------------------------

        playerAddedConnection =
            Players.PlayerAdded:Connect(function(player)
                connectPlayerChat(player)
            end)

        --------------------------------------------------
        -- PLAYER REMOVING
        --------------------------------------------------

        playerRemovingConnection =
            Players.PlayerRemoving:Connect(function(player)
                local connection = connectedPlayers[player]

                if connection then
                    connection:Disconnect()
                    connectedPlayers[player] = nil
                end
            end)

        --------------------------------------------------
        -- CHARACTER RESPAWN
        --------------------------------------------------

        characterAddedConnection =
            LocalPlayer.CharacterAdded:Connect(function(character)
                danceGeneration += 1

                local generation = danceGeneration

                danceTrack = nil
                dancing = false

                task.wait(0.5)

                if generation ~= danceGeneration then
                    return
                end

                if LocalPlayer.Character ~= character then
                    return
                end

                if Vars.ActiveMode ~= MODE_NAME then
                    return
                end

                playPargoyDance(
                    Vars.CommandTarget or LocalPlayer
                )
            end)

        --------------------------------------------------
        -- READY
        --------------------------------------------------

        print(
            "[PargoyDance] Loaded untuk:",
            LocalPlayer.Name,
            "| Animation ID:",
            ANIMATION_ID
        )
    end
}
