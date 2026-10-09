return {
    Execute = function()

        ----------------------------------------------------------------
        -- SERVICES
        ----------------------------------------------------------------

        local Players = game:GetService("Players")

        local LocalPlayer = Players.LocalPlayer

        if not LocalPlayer then
            warn("[PargoyDance] LocalPlayer tidak ditemukan.")
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

        local AdminModule

        do
            local success, result = pcall(function()
                return loadstring(game:HttpGet(
                    "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
                ))()
            end)

            if success and result then
                AdminModule = result
            else
                warn("[PargoyDance] Gagal load Admin.lua.")
                return
            end
        end


        ----------------------------------------------------------------
        -- FE ANIMATION ID
        ----------------------------------------------------------------

        local PARGoy_DANCE_ANIMATION_ID =
            "80655010092183"


        ----------------------------------------------------------------
        -- VARIABLES
        ----------------------------------------------------------------

        local MODE_NAME = "pargoydance"

        local danceTrack = nil
        local dancing = false
        local danceGeneration = 0

        local connectedPlayers = {}
        local playerAddedConnection
        local playerRemovingConnection
        local characterAddedConnection


        ----------------------------------------------------------------
        -- ADMIN CHECK
        ----------------------------------------------------------------

        local function isAdmin(player)

            if not player then
                return false
            end

            local success, result = pcall(function()
                return AdminModule:IsAdmin(player)
            end)

            if success and result == true then
                return true
            end

            local additionalAdmins =
                _G.BotVars.AdditionalAdmins or {}

            return additionalAdmins[player.UserId] == true

        end


        ----------------------------------------------------------------
        -- GET CHARACTER
        ----------------------------------------------------------------

        local function getCharacter()

            local character = LocalPlayer.Character

            if not character then
                character = LocalPlayer.CharacterAdded:Wait()
            end

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

            if generation
                and generation ~= danceGeneration then
                return
            end

            local character = LocalPlayer.Character

            if not character then
                dancing = false
                return
            end

            local humanoid =
                character:FindFirstChildOfClass("Humanoid")

            if not humanoid then
                dancing = false
                return
            end


            ------------------------------------------------------------
            -- STOP PARGOY TRACK
            ------------------------------------------------------------

            if danceTrack then

                local oldTrack = danceTrack
                danceTrack = nil

                pcall(function()
                    oldTrack:Stop(0.15)
                end)

            end


            ------------------------------------------------------------
            -- STOP ACTION TRACKS
            ------------------------------------------------------------

            local animator =
                humanoid:FindFirstChildOfClass("Animator")

            if animator then

                local success, tracks = pcall(function()
                    return animator:GetPlayingAnimationTracks()
                end)

                if success and tracks then

                    for _, track in ipairs(tracks) do

                        if track.Priority
                            == Enum.AnimationPriority.Action
                            or track.Priority
                            == Enum.AnimationPriority.Action2
                            or track.Priority
                            == Enum.AnimationPriority.Action3
                            or track.Priority
                            == Enum.AnimationPriority.Action4 then

                            pcall(function()
                                track:Stop(0.15)
                            end)

                        end

                    end

                end

            end


            ------------------------------------------------------------
            -- RESTART DEFAULT ANIMATE SCRIPT
            ------------------------------------------------------------

            local animateScript =
                character:FindFirstChild("Animate")

            if animateScript
                and animateScript:IsA("LocalScript") then

                pcall(function()
                    animateScript.Disabled = true
                end)

                task.wait(0.1)

                if generation
                    and generation ~= danceGeneration then
                    return
                end

                pcall(function()
                    animateScript.Disabled = false
                end)

            end


            ------------------------------------------------------------
            -- RESTORE HUMANOID STATE
            ------------------------------------------------------------

            if generation
                and generation ~= danceGeneration then
                return
            end

            pcall(function()
                humanoid:ChangeState(
                    Enum.HumanoidStateType.Running
                )
            end)

            dancing = false


            ------------------------------------------------------------
            -- DELAYED RUNNING STATE
            ------------------------------------------------------------

            local cleanupGeneration =
                generation or danceGeneration

            task.defer(function()

                task.wait(0.1)

                if cleanupGeneration ~= danceGeneration then
                    return
                end

                if humanoid
                    and humanoid.Parent
                    and humanoid.Health > 0 then

                    pcall(function()
                        humanoid:ChangeState(
                            Enum.HumanoidStateType.Running
                        )
                    end)

                end

            end)

            print("[PargoyDance] Animasi normal dipulihkan.")

        end


        ----------------------------------------------------------------
        -- STOP PARGOY DANCE
        ----------------------------------------------------------------

        local function stopPargoyDance()

            danceGeneration = danceGeneration + 1

            local generation = danceGeneration

            dancing = false


            if danceTrack then

                local oldTrack = danceTrack
                danceTrack = nil

                pcall(function()
                    oldTrack:Stop(0.15)
                end)

            end


            restoreNormalAnimation(generation)

            -- CommandTarget sengaja tidak dihapus di sini.
            -- Hanya !stop dari admin yang membersihkan target global.

        end


        ----------------------------------------------------------------
        -- REGISTER CONTROLLER
        ----------------------------------------------------------------

        _G.BotVars.ModeControllers[MODE_NAME] =
            stopPargoyDance


        ----------------------------------------------------------------
        -- STOP OTHER MODES
        ----------------------------------------------------------------

        local function stopOtherModes()

            for name, stopFunction in pairs(
                _G.BotVars.ModeControllers
            ) do

                if name ~= MODE_NAME
                    and type(stopFunction) == "function" then

                    pcall(function()
                        stopFunction()
                    end)

                end

            end

        end


        ----------------------------------------------------------------
        -- PLAY PARGOY DANCE
        ----------------------------------------------------------------

        local function playPargoyDance(targetPlayer)

            ------------------------------------------------------------
            -- START NEW GENERATION
            ------------------------------------------------------------

            danceGeneration = danceGeneration + 1

            local generation = danceGeneration


            ------------------------------------------------------------
            -- SET GLOBAL MODE
            ------------------------------------------------------------

            _G.BotVars.ActiveMode = MODE_NAME

            if targetPlayer then
                _G.BotVars.CommandTarget = targetPlayer
            end


            ------------------------------------------------------------
            -- STOP OTHER MODES
            ------------------------------------------------------------

            stopOtherModes()

            if generation ~= danceGeneration then
                return
            end


            ------------------------------------------------------------
            -- STOP PREVIOUS TRACK
            ------------------------------------------------------------

            if danceTrack then

                local oldTrack = danceTrack
                danceTrack = nil

                pcall(function()
                    oldTrack:Stop(0.1)
                end)

            end


            ------------------------------------------------------------
            -- GET CHARACTER
            ------------------------------------------------------------

            local character, humanoid = getCharacter()

            if not character or not humanoid then
                warn("[PargoyDance] Character atau Humanoid tidak ditemukan.")
                return
            end

            if humanoid.Health <= 0 then
                warn("[PargoyDance] Humanoid sudah mati.")
                return
            end


            ------------------------------------------------------------
            -- PLAY FE ANIMATION WITH RETRY
            ------------------------------------------------------------

            local maxAttempts = 3
            local success = false
            local result = nil

            for attempt = 1, maxAttempts do

                if generation ~= danceGeneration then
                    return
                end

                if LocalPlayer.Character ~= character
                    or not humanoid.Parent then
                    return
                end

                local ok, track = pcall(function()
                    return humanoid:PlayEmoteAndGetAnimTrackById(
                        PARGoy_DANCE_ANIMATION_ID
                    )
                end)

                if ok and track then
                    success = true
                    result = track
                    break
                end

                result = track

                if attempt < maxAttempts then
                    task.wait(0.15)
                end

            end


            ------------------------------------------------------------
            -- VALIDATE GENERATION AFTER RETRY
            ------------------------------------------------------------

            if generation ~= danceGeneration
                or LocalPlayer.Character ~= character then

                if result then
                    pcall(function()
                        result:Stop(0)
                    end)
                end

                return
            end


            ------------------------------------------------------------
            -- RESULT
            ------------------------------------------------------------

            if success and result then

                danceTrack = result
                dancing = true

                print(
                    "[PargoyDance] FE Animation berhasil dimainkan:",
                    PARGoy_DANCE_ANIMATION_ID,
                    "| Bot:",
                    LocalPlayer.Name
                )


                --------------------------------------------------------
                -- MONITOR TRACK
                --------------------------------------------------------

                task.spawn(function()

                    local currentTrack = result
                    local trackGeneration = generation

                    pcall(function()
                        currentTrack.Stopped:Wait()
                    end)

                    if danceTrack == currentTrack
                        and dancing
                        and trackGeneration == danceGeneration then

                        danceTrack = nil

                        restoreNormalAnimation(
                            trackGeneration
                        )

                    end

                end)

            else

                dancing = false

                warn(
                    "[PargoyDance] FE Animation gagal dimainkan setelah",
                    maxAttempts,
                    "percobaan.",
                    "| Bot:",
                    LocalPlayer.Name,
                    "| Last Error:",
                    tostring(result)
                )

            end

        end


        ----------------------------------------------------------------
        -- FIND PLAYER
        ----------------------------------------------------------------

        local function findPlayerByName(name)

            if not name or name == "" then
                return nil
            end

            name = name:lower()


            ------------------------------------------------------------
            -- EXACT USERNAME / DISPLAY NAME
            ------------------------------------------------------------

            for _, player in ipairs(Players:GetPlayers()) do

                if player.Name:lower() == name
                    or player.DisplayName:lower() == name then

                    return player
                end

            end


            ------------------------------------------------------------
            -- PREFIX USERNAME
            ------------------------------------------------------------

            for _, player in ipairs(Players:GetPlayers()) do

                if player.Name:lower():sub(1, #name) == name then
                    return player
                end

            end

            return nil

        end


        ----------------------------------------------------------------
        -- COMMAND HANDLER
        ----------------------------------------------------------------

        local function handleCommand(message, sender)

            if not message or not sender then
                return
            end

            local lower = message:lower()
                :gsub("^%s+", "")
                :gsub("%s+$", "")

            local senderIsAdmin = isAdmin(sender)

            local commandTarget =
                _G.BotVars.CommandTarget

            local isCommandTarget =
                commandTarget == sender


            ------------------------------------------------------------
            -- !STOP (ADMIN ONLY)
            ------------------------------------------------------------

            if lower == "!stop" then

                if not senderIsAdmin then
                    print(
                        "[PargoyDance] !stop ditolak:",
                        sender.Name,
                        "bukan Admin."
                    )
                    return
                end

                print(
                    "[PargoyDance] !stop diterima | Admin:",
                    sender.Name
                )

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
            -- !UNPARGOYDANCE (ADMIN ONLY)
            ------------------------------------------------------------

            if lower == "!unpargoydance" then

                if not senderIsAdmin then
                    print(
                        "[PargoyDance] !unpargoydance ditolak:",
                        sender.Name,
                        "bukan Admin."
                    )
                    return
                end

                if _G.BotVars.ActiveMode == MODE_NAME then
                    _G.BotVars.ActiveMode = nil
                end

                stopPargoyDance()

                return

            end


            ------------------------------------------------------------
            -- !PARGOYDANCE
            ------------------------------------------------------------

            if lower == "!pargoydance" then

                if not senderIsAdmin and not isCommandTarget then
                    print(
                        "[PargoyDance] !pargoydance ditolak:",
                        sender.Name
                    )
                    return
                end

                _G.BotVars.CommandTarget = sender

                playPargoyDance(sender)

                return

            end


            ------------------------------------------------------------
            -- !PARGOYDANCE PLAYER (ADMIN ONLY)
            ------------------------------------------------------------

            local targetName =
                lower:match("^!pargoydance%s+(.+)$")

            if targetName then

                if not senderIsAdmin then
                    print(
                        "[PargoyDance] !pargoydance PLAYER ditolak:",
                        sender.Name,
                        "bukan Admin."
                    )
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

                _G.BotVars.CommandTarget = target

                playPargoyDance(target)

                return

            end

        end


        ----------------------------------------------------------------
        -- CHAT CONNECTIONS
        ----------------------------------------------------------------

        local function connectPlayerChat(player)

            if connectedPlayers[player] then
                return
            end

            connectedPlayers[player] =
                player.Chatted:Connect(function(message)
                    handleCommand(message, player)
                end)

        end


        ----------------------------------------------------------------
        -- CONNECT EXISTING PLAYERS
        ----------------------------------------------------------------

        for _, player in ipairs(Players:GetPlayers()) do
            connectPlayerChat(player)
        end


        ----------------------------------------------------------------
        -- PLAYER ADDED
        ----------------------------------------------------------------

        playerAddedConnection =
            Players.PlayerAdded:Connect(function(player)
                connectPlayerChat(player)
            end)


        ----------------------------------------------------------------
        -- PLAYER REMOVING
        ----------------------------------------------------------------

        playerRemovingConnection =
            Players.PlayerRemoving:Connect(function(player)

                local connection = connectedPlayers[player]

                if connection then
                    connection:Disconnect()
                    connectedPlayers[player] = nil
                end

            end)


        ----------------------------------------------------------------
        -- CHARACTER RESPAWN
        ----------------------------------------------------------------

        characterAddedConnection =
            LocalPlayer.CharacterAdded:Connect(function(character)

                task.wait(1)

                danceGeneration = danceGeneration + 1

                local generation = danceGeneration

                danceTrack = nil
                dancing = false

                if _G.BotVars.ActiveMode ~= MODE_NAME then
                    return
                end

                task.wait(0.5)

                if generation ~= danceGeneration then
                    return
                end

                if LocalPlayer.Character ~= character then
                    return
                end

                if _G.BotVars.ActiveMode == MODE_NAME then

                    local target =
                        _G.BotVars.CommandTarget or LocalPlayer

                    playPargoyDance(target)

                end

            end)


        ----------------------------------------------------------------
        -- READY
        ----------------------------------------------------------------

        print(
            "[PargoyDance] Loaded untuk:",
            LocalPlayer.Name,
            "| FE Animation:",
            PARGoy_DANCE_ANIMATION_ID
        )

    end
}