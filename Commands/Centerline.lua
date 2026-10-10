-- Centerline.lua
-- MasterZ HUB
-- Formasi horizontal dengan Admin/Player di tengah.
--
-- Formasi:
-- B1 B2 B3 B4 B5 A B6 B7 B8 B9 B10 B11 B12
--
-- Command:
-- !centerline
-- !centerline <player>
-- !stop
-- !uncenterline

return {
    Execute = function()

        ----------------------------------------------------------------
        -- SERVICES
        ----------------------------------------------------------------

        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        local TextChatService = game:GetService("TextChatService")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")

        local LocalPlayer = Players.LocalPlayer

        if not LocalPlayer then
            warn("[Centerline] LocalPlayer tidak ditemukan.")
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

        local Admin = loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
        ))()

        ----------------------------------------------------------------
        -- LOAD DISTANCE
        ----------------------------------------------------------------

        local Distance = loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Distance.lua"
        ))()

        ----------------------------------------------------------------
        -- CONFIGURATION
        ----------------------------------------------------------------

        -- Jarak Admin/Player dari bot terdekat.
        local defaultCenterlineDistance = 3

        -- Jarak antarbot dalam satu barisan.
        local formationSpacing = 3

        -- Toleransi untuk menganggap bot sudah sampai.
        local arrivalTolerance = 1.5

        ----------------------------------------------------------------
        -- BOT ORDER
        ----------------------------------------------------------------

        local botOrder = {
            "11611503633", -- Bot 1
            "11611591921", -- Bot 2
            "11611597741", -- Bot 3
            "11672413029", -- Bot 4
            "11122806815", -- Bot 5
            "11122806817", -- Bot 6
            "11122687468", -- Bot 7
            "11122854402", -- Bot 8
            "11774472805", -- Bot 9
            "11774494628", -- Bot 10
            "11775829997", -- Bot 11
            "11775843339", -- Bot 12
        }

        ----------------------------------------------------------------
        -- VARIABLES
        ----------------------------------------------------------------

        local humanoid
        local myHRP

        local centering = false
        local targetPlayer = nil
        local centerlineConnection = nil

        ----------------------------------------------------------------
        -- UPDATE CHARACTER
        ----------------------------------------------------------------

        local function updateCharacter()
            local character =
                LocalPlayer.Character
                or LocalPlayer.CharacterAdded:Wait()

            humanoid =
                character:WaitForChild("Humanoid")

            myHRP =
                character:WaitForChild("HumanoidRootPart")

            humanoid.AutoRotate = true
        end

        updateCharacter()

        ----------------------------------------------------------------
        -- SEND CHAT
        ----------------------------------------------------------------

        local function sendChat(message)
            local success = false

            if TextChatService
                and TextChatService.TextChannels then

                local channel =
                    TextChatService.TextChannels:FindFirstChild(
                        "RBXGeneral"
                    )

                if channel then
                    success = pcall(function()
                        channel:SendAsync(message)
                    end)
                end
            end

            if not success then
                pcall(function()
                    local chatEvents =
                        ReplicatedStorage:FindFirstChild(
                            "DefaultChatSystemChatEvents"
                        )

                    local sayMessageRequest =
                        chatEvents
                        and chatEvents:FindFirstChild(
                            "SayMessageRequest"
                        )

                    if sayMessageRequest then
                        sayMessageRequest:FireServer(
                            message,
                            "All"
                        )
                    end
                end)
            end
        end

        ----------------------------------------------------------------
        -- STOP CENTERLINE
        ----------------------------------------------------------------

        local function stopCenterline()
            centering = false
            targetPlayer = nil

            if centerlineConnection then
                centerlineConnection:Disconnect()
                centerlineConnection = nil
            end

            if humanoid then
                humanoid.AutoRotate = true
            end
        end

        ----------------------------------------------------------------
        -- REGISTER CONTROLLER
        ----------------------------------------------------------------

        _G.BotVars.ModeControllers.centerline =
            stopCenterline

        ----------------------------------------------------------------
        -- STOP OTHER MODES
        ----------------------------------------------------------------

        local function stopOtherModes()
            for name, stopFunction in pairs(
                _G.BotVars.ModeControllers
            ) do
                if name ~= "centerline"
                    and type(stopFunction) == "function" then

                    pcall(stopFunction)
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

            name = name:lower()

            -- Exact username/display name.
            for _, player in ipairs(Players:GetPlayers()) do
                if player.Name:lower() == name
                    or player.DisplayName:lower() == name then

                    return player
                end
            end

            -- Username prefix.
            for _, player in ipairs(Players:GetPlayers()) do
                if player.Name:lower():sub(
                    1,
                    #name
                ) == name then

                    return player
                end
            end

            -- Display name prefix.
            for _, player in ipairs(Players:GetPlayers()) do
                if player.DisplayName:lower():sub(
                    1,
                    #name
                ) == name then

                    return player
                end
            end

            return nil
        end

        ----------------------------------------------------------------
        -- GET ACTIVE BOTS
        ----------------------------------------------------------------

        local function getActiveBots()
            local activeBots = {}

            for _, botUserId in ipairs(botOrder) do
                local botPlayer =
                    Players:GetPlayerByUserId(
                        tonumber(botUserId)
                    )

                if botPlayer then
                    table.insert(activeBots, botUserId)
                end
            end

            return activeBots
        end

        ----------------------------------------------------------------
        -- START CENTERLINE
        ----------------------------------------------------------------

        local function startCenterline(player)
            if not player then
                return
            end

            ------------------------------------------------------------
            -- STOP OTHER MODES
            ------------------------------------------------------------

            stopOtherModes()

            ------------------------------------------------------------
            -- SET ACTIVE MODE
            ------------------------------------------------------------

            _G.BotVars.ActiveMode = "centerline"

            ------------------------------------------------------------
            -- STOP OLD CONNECTION
            ------------------------------------------------------------

            if centerlineConnection then
                centerlineConnection:Disconnect()
                centerlineConnection = nil
            end

            ------------------------------------------------------------
            -- SET STATE
            ------------------------------------------------------------

            centering = true
            targetPlayer = player

            _G.BotVars.CommandTarget = player

            sendChat("Yes, Sir!")

            ------------------------------------------------------------
            -- VALIDATE BOT
            ------------------------------------------------------------

            local activeBots = getActiveBots()

            local activeIndex = table.find(
                activeBots,
                tostring(LocalPlayer.UserId)
            )

            if not activeIndex then
                stopCenterline()
                return
            end

            ------------------------------------------------------------
            -- CENTERLINE LOOP
            ------------------------------------------------------------

            centerlineConnection =
                RunService.Heartbeat:Connect(function()

                    ----------------------------------------------------
                    -- CHECK ACTIVE MODE
                    ----------------------------------------------------

                    if _G.BotVars.ActiveMode ~= "centerline" then
                        stopCenterline()
                        return
                    end

                    ----------------------------------------------------
                    -- VALIDATE STATE
                    ----------------------------------------------------

                    if not centering
                        or not humanoid
                        or not myHRP
                        or humanoid.Health <= 0
                        or not targetPlayer then

                        return
                    end

                    ----------------------------------------------------
                    -- TARGET CHARACTER
                    ----------------------------------------------------

                    local targetCharacter =
                        targetPlayer.Character

                    if not targetCharacter then
                        return
                    end

                    local targetHRP =
                        targetCharacter:FindFirstChild(
                            "HumanoidRootPart"
                        )

                    if not targetHRP then
                        return
                    end

                    ----------------------------------------------------
                    -- REFRESH ACTIVE BOT ORDER
                    ----------------------------------------------------

                    activeBots = getActiveBots()

                    activeIndex = table.find(
                        activeBots,
                        tostring(LocalPlayer.UserId)
                    )

                    if not activeIndex then
                        return
                    end

                    ----------------------------------------------------
                    -- DISTANCE FROM CENTER
                    ----------------------------------------------------

                    local centerDistance =
                        defaultCenterlineDistance

                    local specialDistance =
                        Distance:GetDistance(
                            tostring(LocalPlayer.UserId),
                            tostring(targetPlayer.UserId)
                        )

                    if specialDistance then
                        centerDistance = specialDistance
                    end

                    ----------------------------------------------------
                    -- CALCULATE HORIZONTAL OFFSET
                    ----------------------------------------------------

                    local activeBotCount = #activeBots

                    -- Setiap bot mendapatkan slot berdasarkan urutan.
                    -- Bot di bagian awal berada di kiri.
                    -- Bot di bagian akhir berada di kanan.

                    local centerIndex =
                        (activeBotCount + 1) / 2

                    local horizontalOffset =
                        (activeIndex - centerIndex)
                        * formationSpacing

                    ----------------------------------------------------
                    -- FORMATION POSITION
                    ----------------------------------------------------

                    -- Seluruh bot berada pada garis horizontal
                    -- yang melewati posisi target.
                    --
                    -- Tidak ada offset ke depan/belakang.
                    --
                    -- RightVector menentukan sisi kiri/kanan.

                    local targetPosition =
                        targetHRP.Position
                        + (
                            targetHRP.CFrame.RightVector
                            * horizontalOffset
                        )

                    ----------------------------------------------------
                    -- KEEP SAME HEIGHT AS TARGET
                    ----------------------------------------------------

                    targetPosition = Vector3.new(
                        targetPosition.X,
                        targetHRP.Position.Y,
                        targetPosition.Z
                    )

                    ----------------------------------------------------
                    -- DISTANCE TO DESTINATION
                    ----------------------------------------------------

                    local distanceToTarget =
                        (
                            myHRP.Position
                            - targetPosition
                        ).Magnitude

                    ----------------------------------------------------
                    -- MOVE TO POSITION
                    ----------------------------------------------------

                    if distanceToTarget > arrivalTolerance then
                        humanoid.AutoRotate = true

                        humanoid:MoveTo(targetPosition)

                        return
                    end

                    ----------------------------------------------------
                    -- ARRIVED
                    -- FACE THE SAME DIRECTION AS TARGET
                    ----------------------------------------------------

                    humanoid.AutoRotate = false

                    local targetRotation =
                        targetHRP.CFrame
                        - targetHRP.Position

                    myHRP.CFrame =
                        CFrame.new(myHRP.Position)
                        * targetRotation
                end)
        end

        ----------------------------------------------------------------
        -- COMMAND HANDLER
        ----------------------------------------------------------------

        local function handleCommand(message, sender)
            if not message or not sender then
                return
            end

            ------------------------------------------------------------
            -- ADMIN CHECK
            ------------------------------------------------------------

            local isAdmin = false

            pcall(function()
                isAdmin = Admin:IsAdmin(sender)
            end)

            local isCommandTarget =
                (_G.BotVars.CommandTarget == sender)

            ------------------------------------------------------------
            -- CLEAN MESSAGE
            ------------------------------------------------------------

            local lower =
                message:lower()
                :gsub("^%s+", "")
                :gsub("%s+$", "")

            ------------------------------------------------------------
            -- !CENTERLINE
            -- ADMIN ATAU TARGET AKTIF
            ------------------------------------------------------------

            if lower == "!centerline" then
                if not isAdmin and not isCommandTarget then
                    return
                end

                startCenterline(sender)
                return
            end

            ------------------------------------------------------------
            -- !CENTERLINE PLAYER
            -- HANYA ADMIN
            ------------------------------------------------------------

            local targetName =
                lower:match("^!centerline%s+(.+)$")

            if targetName then
                if not isAdmin then
                    return
                end

                local target =
                    findPlayerByName(targetName)

                if target then
                    startCenterline(target)
                else
                    sendChat("Player tidak ditemukan.")
                end

                return
            end

            ------------------------------------------------------------
            -- !STOP / !UNCENTERLINE
            -- HANYA ADMIN
            ------------------------------------------------------------

            if lower == "!stop"
                or lower == "!uncenterline" then

                if not isAdmin then
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
        end

        ----------------------------------------------------------------
        -- TEXT CHAT
        ----------------------------------------------------------------

        if TextChatService
            and TextChatService.TextChannels then

            local channel =
                TextChatService.TextChannels:FindFirstChild(
                    "RBXGeneral"
                )

            if channel then
                channel.MessageReceived:Connect(
                    function(message)

                        local userId =
                            message.TextSource
                            and message.TextSource.UserId

                        local sender =
                            userId
                            and Players:GetPlayerByUserId(userId)

                        if sender then
                            handleCommand(
                                message.Text,
                                sender
                            )
                        end
                    end
                )
            end
        end

        ----------------------------------------------------------------
        -- FALLBACK CHAT
        ----------------------------------------------------------------

        local function connectPlayer(player)
            player.Chatted:Connect(function(message)
                handleCommand(message, player)
            end)
        end

        for _, player in ipairs(Players:GetPlayers()) do
            connectPlayer(player)
        end

        Players.PlayerAdded:Connect(connectPlayer)

        ----------------------------------------------------------------
        -- CHARACTER RESPAWN
        ----------------------------------------------------------------

        LocalPlayer.CharacterAdded:Connect(function()
            task.wait(1)

            updateCharacter()

            if _G.BotVars.ActiveMode == "centerline"
                and targetPlayer then

                startCenterline(targetPlayer)
            end
        end)

        ----------------------------------------------------------------
        -- FINISHED
        ----------------------------------------------------------------

        print("[Centerline] Loaded successfully.")

    end
}