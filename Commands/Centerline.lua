
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
        -- CONFIGURATION
        ----------------------------------------------------------------

        -- Jarak antarbot.
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
        -- GET BOT INDEX
        -- PENTING: gunakan urutan asli botOrder.
        -- Jangan menghitung slot dari jumlah bot aktif.
        ----------------------------------------------------------------

        local function getBotIndex()
            return table.find(
                botOrder,
                tostring(LocalPlayer.UserId)
            )
        end

        ----------------------------------------------------------------
        -- START CENTERLINE
        ----------------------------------------------------------------

        local function startCenterline(player)
            if not player then
                return
            end

            ------------------------------------------------------------
            -- VALIDATE BOT
            ------------------------------------------------------------

            local botIndex = getBotIndex()

            if not botIndex then
                warn(
                    "[Centerline] Bot tidak ditemukan dalam botOrder:",
                    LocalPlayer.UserId
                )
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
                    -- CALCULATE FIXED HORIZONTAL SLOT
                    ----------------------------------------------------

                    local horizontalOffset

                    if botIndex <= 5 then
                        -- Bot 1 sampai Bot 5 di sebelah kiri.
                        --
                        -- Bot 1 = -5 slot
                        -- Bot 2 = -4 slot
                        -- Bot 3 = -3 slot
                        -- Bot 4 = -2 slot
                        -- Bot 5 = -1 slot

                        horizontalOffset =
                            (botIndex - 6) * formationSpacing
                    else
                        -- Bot 6 sampai Bot 12 di sebelah kanan.
                        --
                        -- Bot 6  = +1 slot
                        -- Bot 7  = +2 slot
                        -- Bot 8  = +3 slot
                        -- Bot 9  = +4 slot
                        -- Bot 10 = +5 slot
                        -- Bot 11 = +6 slot
                        -- Bot 12 = +7 slot

                        horizontalOffset =
                            (botIndex - 5) * formationSpacing
                    end

                    ----------------------------------------------------
                    -- FORMATION POSITION
                    ----------------------------------------------------

                    -- Semua bot berada pada satu garis horizontal.
                    -- RightVector menentukan posisi kiri/kanan.
                    -- Tidak ada offset tambahan ke depan/belakang.

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
