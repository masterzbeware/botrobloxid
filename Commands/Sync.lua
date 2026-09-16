return {
    Execute = function()

        ----------------------------------------------------------------
        -- SERVICES
        ----------------------------------------------------------------

        local Players = game:GetService("Players")

        local LocalPlayer = Players.LocalPlayer

        if not LocalPlayer then
            warn("[Sync] LocalPlayer tidak ditemukan.")
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

        local Admin

        do
            local success, result = pcall(function()
                return loadstring(game:HttpGet(
                    "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
                ))()
            end)

            if success and result then
                Admin = result
            else
                warn("[Sync] Gagal load Admin.lua.")
                return
            end
        end


        ----------------------------------------------------------------
        -- VARIABLES
        ----------------------------------------------------------------

        local syncTrack = nil
        local syncTarget = nil
        local syncing = false

        local syncGeneration = 0


        ----------------------------------------------------------------
        -- FIND PLAYER
        -- Support Username ATAU DisplayName
        ----------------------------------------------------------------

        local function findPlayer(name)
            if not name then
                return nil
            end

            name = tostring(name):lower()

            -- Username exact match
            for _, player in ipairs(Players:GetPlayers()) do
                if player.Name:lower() == name then
                    return player
                end
            end

            -- DisplayName exact match
            for _, player in ipairs(Players:GetPlayers()) do
                if player.DisplayName:lower() == name then
                    return player
                end
            end

            return nil
        end


        ----------------------------------------------------------------
        -- GET CHARACTER
        ----------------------------------------------------------------

        local function getCharacter(player)
            if not player then
                return nil
            end

            return player.Character
                or player.CharacterAdded:Wait()
        end


        ----------------------------------------------------------------
        -- GET CURRENT ANIMATION
        ----------------------------------------------------------------

        local function getCurrentAnimation(player)
            local character = getCharacter(player)

            if not character then
                return nil
            end

            local humanoid =
                character:FindFirstChildOfClass("Humanoid")

            if not humanoid then
                return nil
            end

            local animator =
                humanoid:FindFirstChildOfClass("Animator")

            if not animator then
                return nil
            end

            local tracks =
                animator:GetPlayingAnimationTracks()

            local bestTrack = nil
            local bestPriority = -math.huge

            for _, track in ipairs(tracks) do

                if track
                    and track.IsPlaying
                    and track.Animation
                    and track.Animation.AnimationId
                    and track.Animation.AnimationId ~= "" then

                    local priorityValue = 0

                    if track.Priority == Enum.AnimationPriority.Action4 then
                        priorityValue = 4
                    elseif track.Priority == Enum.AnimationPriority.Action3 then
                        priorityValue = 3
                    elseif track.Priority == Enum.AnimationPriority.Action2 then
                        priorityValue = 2
                    elseif track.Priority == Enum.AnimationPriority.Action then
                        priorityValue = 1
                    elseif track.Priority == Enum.AnimationPriority.Movement then
                        priorityValue = 0
                    elseif track.Priority == Enum.AnimationPriority.Idle then
                        priorityValue = -1
                    elseif track.Priority == Enum.AnimationPriority.Core then
                        priorityValue = -2
                    end

                    if priorityValue > bestPriority then
                        bestPriority = priorityValue
                        bestTrack = track
                    end
                end
            end

            return bestTrack
        end


        ----------------------------------------------------------------
        -- EXTRACT ANIMATION ID
        ----------------------------------------------------------------

        local function getAnimationId(track)
            if not track or not track.Animation then
                return nil
            end

            local animationId =
                track.Animation.AnimationId

            if not animationId or animationId == "" then
                return nil
            end

            return animationId
        end


        ----------------------------------------------------------------
        -- STOP SYNC
        ----------------------------------------------------------------

        local function stopSync()

            syncGeneration =
                syncGeneration + 1

            syncing = false
            syncTarget = nil

            if syncTrack then

                local oldTrack =
                    syncTrack

                syncTrack = nil

                pcall(function()
                    oldTrack:Stop(0.15)
                end)
            end

            print("[Sync] Sync dihentikan | Bot:", LocalPlayer.Name)
        end


        ----------------------------------------------------------------
        -- REGISTER CONTROLLER
        ----------------------------------------------------------------

        _G.BotVars.ModeControllers.sync =
            stopSync


        ----------------------------------------------------------------
        -- STOP OTHER MODES
        ----------------------------------------------------------------

        local function stopOtherModes()

            for name, stopFunction in pairs(
                _G.BotVars.ModeControllers
            ) do

                if name ~= "sync"
                    and type(stopFunction) == "function" then

                    pcall(function()
                        stopFunction()
                    end)

                end
            end
        end


        ----------------------------------------------------------------
        -- PLAY ANIMATION
        ----------------------------------------------------------------

        local function playAnimation(animationId, generation)

            if not animationId then
                return nil
            end

            if generation ~= syncGeneration then
                return nil
            end

            local character =
                getCharacter(LocalPlayer)

            if not character then
                return nil
            end

            local humanoid =
                character:FindFirstChildOfClass("Humanoid")

            if not humanoid then
                return nil
            end

            -- Stop sync track sebelumnya
            if syncTrack then
                local oldTrack = syncTrack
                syncTrack = nil

                pcall(function()
                    oldTrack:Stop(0.1)
                end)
            end

            ----------------------------------------------------------------
            -- Coba FE animation terlebih dahulu, sama seperti AteezDance
            ----------------------------------------------------------------

            local ok, track =
                pcall(function()
                    return humanoid:PlayEmoteAndGetAnimTrackById(
                        animationId:gsub("rbxassetid://", "")
                    )
                end)

            if ok and track then
                syncTrack = track

                pcall(function()
                    track.Looped = true
                end)

                return track
            end

            ----------------------------------------------------------------
            -- Fallback: LoadAnimation
            ----------------------------------------------------------------

            local animator =
                humanoid:FindFirstChildOfClass("Animator")

            if not animator then
                return nil
            end

            local animation =
                Instance.new("Animation")

            animation.AnimationId = animationId

            local fallbackOk, fallbackTrack =
                pcall(function()
                    return animator:LoadAnimation(animation)
                end)

            animation:Destroy()

            if fallbackOk and fallbackTrack then
                syncTrack = fallbackTrack

                pcall(function()
                    fallbackTrack.Looped = true
                    fallbackTrack:Play(0.1)
                end)

                return fallbackTrack
            end

            return nil
        end


        ----------------------------------------------------------------
        -- START SYNC
        ----------------------------------------------------------------

        local function startSync(target)

            if not target then
                return
            end

            syncGeneration =
                syncGeneration + 1

            local generation =
                syncGeneration

            stopOtherModes()

            _G.BotVars.ActiveMode =
                "sync"

            syncTarget = target
            syncing = true

            print(
                "[Sync] Target:",
                target.Name,
                "| DisplayName:",
                target.DisplayName
            )

            ----------------------------------------------------------------
            -- MONITOR TARGET
            ----------------------------------------------------------------

            task.spawn(function()

                local lastAnimationId = nil
                local lastTrack = nil

                while syncing
                    and syncTarget == target
                    and generation == syncGeneration
                    and target.Parent do

                    local targetTrack =
                        getCurrentAnimation(target)

                    local animationId =
                        getAnimationId(targetTrack)

                    ----------------------------------------------------------------
                    -- TARGET SEDANG MEMAINKAN ANIMATION
                    ----------------------------------------------------------------

                    if animationId then

                        if animationId ~= lastAnimationId
                            or targetTrack ~= lastTrack
                            or not syncTrack
                            or not syncTrack.IsPlaying then

                            local newTrack =
                                playAnimation(
                                    animationId,
                                    generation
                                )

                            if newTrack then

                                lastAnimationId =
                                    animationId

                                lastTrack =
                                    targetTrack

                                print(
                                    "[Sync] Animation:",
                                    animationId,
                                    "| Target:",
                                    target.Name
                                )

                            else

                                warn(
                                    "[Sync] Gagal memainkan:",
                                    animationId,
                                    "| Target:",
                                    target.Name
                                )

                            end
                        end

                    else

                        ----------------------------------------------------------------
                        -- TARGET TIDAK PUNYA ANIMATION AKTIF
                        ----------------------------------------------------------------

                        if syncTrack then

                            pcall(function()
                                syncTrack:Stop(0.15)
                            end)

                            syncTrack = nil
                        end

                        lastAnimationId = nil
                        lastTrack = nil
                    end

                    task.wait(0.15)
                end

            end)
        end


        ----------------------------------------------------------------
        -- COMMAND HANDLER
        ----------------------------------------------------------------

        local function handleCommand(message, sender)

            if not message or not sender then
                return
            end


            ----------------------------------------------------------------
            -- ADMIN CHECK
            ----------------------------------------------------------------

            local isAdmin = false

            pcall(function()
                isAdmin =
                    Admin:IsAdmin(sender)
            end)

            if not isAdmin then
                return
            end


            ----------------------------------------------------------------
            -- CLEAN MESSAGE
            ----------------------------------------------------------------

            local lower =
                message:lower()

            lower =
                lower:gsub("^%s+", "")

            lower =
                lower:gsub("%s+$", "")


            ----------------------------------------------------------------
            -- !SYNC USERNAME / DISPLAYNAME
            ----------------------------------------------------------------

            if lower:sub(1, 6) == "!sync " then

                local targetName =
                    message:sub(7):gsub("^%s+", ""):gsub("%s+$", "")

                if targetName == "" then
                    warn("[Sync] Gunakan: !sync Username/DisplayName")
                    return
                end

                local target =
                    findPlayer(targetName)

                if not target then
                    warn(
                        "[Sync] Player tidak ditemukan:",
                        targetName
                    )
                    return
                end

                print(
                    "[Sync] Command diterima | Bot:",
                    LocalPlayer.Name,
                    "| Target:",
                    target.Name,
                    "| DisplayName:",
                    target.DisplayName
                )

                startSync(target)

                return
            end


            ----------------------------------------------------------------
            -- !UNSYNC
            ----------------------------------------------------------------

            if lower == "!unsync" then

                if _G.BotVars.ActiveMode == "sync" then
                    _G.BotVars.ActiveMode = nil
                end

                stopSync()

                return
            end


            ----------------------------------------------------------------
            -- !STOP
            ----------------------------------------------------------------

            if lower == "!stop" then

                if _G.BotVars.ActiveMode == "sync" then
                    _G.BotVars.ActiveMode = nil
                    stopSync()
                end

                return
            end

        end


        ----------------------------------------------------------------
        -- CHAT HANDLER
        ----------------------------------------------------------------

        local connectedPlayers = {}

        local function connectPlayerChat(player)

            if connectedPlayers[player] then
                return
            end

            connectedPlayers[player] = true

            player.Chatted:Connect(
                function(message)

                    handleCommand(
                        message,
                        player
                    )

                end
            )
        end


        ----------------------------------------------------------------
        -- EXISTING PLAYERS
        ----------------------------------------------------------------

        for _, player in ipairs(
            Players:GetPlayers()
        ) do

            connectPlayerChat(player)

        end


        ----------------------------------------------------------------
        -- PLAYER ADDED
        ----------------------------------------------------------------

        Players.PlayerAdded:Connect(
            function(player)

                connectPlayerChat(player)

            end
        )


        ----------------------------------------------------------------
        -- PLAYER REMOVING
        ----------------------------------------------------------------

        Players.PlayerRemoving:Connect(
            function(player)

                connectedPlayers[player] = nil

                if syncTarget == player then
                    stopSync()

                    if _G.BotVars.ActiveMode == "sync" then
                        _G.BotVars.ActiveMode = nil
                    end
                end

            end
        )


        ----------------------------------------------------------------
        -- CHARACTER RESPAWN
        ----------------------------------------------------------------

        LocalPlayer.CharacterAdded:Connect(
            function()

                task.wait(1)

                if _G.BotVars.ActiveMode == "sync"
                    and syncTarget then

                    syncGeneration =
                        syncGeneration + 1

                    local target =
                        syncTarget

                    syncTrack = nil

                    local generation =
                        syncGeneration

                    task.wait(0.5)

                    if syncing
                        and syncTarget == target
                        and generation == syncGeneration then

                        local targetTrack =
                            getCurrentAnimation(target)

                        local animationId =
                            getAnimationId(targetTrack)

                        if animationId then
                            playAnimation(
                                animationId,
                                generation
                            )
                        end
                    end
                end

            end
        )


        ----------------------------------------------------------------
        -- READY
        ----------------------------------------------------------------

        print(
            "[Sync] Loaded untuk:",
            LocalPlayer.Name
        )

    end
}
