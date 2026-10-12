-- Centerline.lua
-- MasterZ HUB
-- Formasi horizontal dengan Admin/Player di tengah.
--
-- Formasi:
-- B1 B2 B3 B4 B5 | ADMIN | B6 B7 B8 B9 B10
--
-- Jarak antarslot: 3 studs
-- Jarak Admin ke bot terdekat: 1.5 studs
--
-- Commands:
-- !centerline
-- !centerline <player>
-- !stop
-- !uncenterline

return {
    Execute = function()

        --------------------------------------------------
        -- SERVICES
        --------------------------------------------------

        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        local TextChatService = game:GetService("TextChatService")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")

        local LocalPlayer = Players.LocalPlayer

        if not LocalPlayer then
            warn("[Centerline] LocalPlayer tidak ditemukan.")
            return
        end

        --------------------------------------------------
        -- GLOBAL MODE SYSTEM
        --------------------------------------------------

        _G.BotVars = _G.BotVars or {}

        local vars = _G.BotVars
        vars.ModeControllers = vars.ModeControllers or {}

        --------------------------------------------------
        -- LOAD ADMIN
        --------------------------------------------------

        local adminOk, Admin = pcall(function()
            local source = game:HttpGet(
                "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
            )

            local loader, compileError = loadstring(source)

            if not loader then
                error(compileError)
            end

            return loader()
        end)

        if not adminOk or not Admin then
            warn("[Centerline] Gagal memuat Admin.lua:", Admin)
            return
        end

        --------------------------------------------------
        -- CONFIGURATION
        --------------------------------------------------

        -- Jarak antara posisi bot yang bersebelahan.
        local formationSpacing = 5

        -- Jarak bot paling dekat dari target:
        -- setengah jarak antarbot agar target berada di tengah.
        local targetGap = formationSpacing / 1

        -- Toleransi kedatangan.
        local arrivalTolerance = 0.3

        --------------------------------------------------
        -- BOT ORDER
        --------------------------------------------------

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
        }

        --------------------------------------------------
        -- VARIABLES
        --------------------------------------------------

        local humanoid
        local myHRP

        local centering = false
        local targetPlayer = nil
        local centerlineConnection = nil

        --------------------------------------------------
        -- UPDATE CHARACTER
        --------------------------------------------------

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

        --------------------------------------------------
        -- SEND CHAT
        --------------------------------------------------

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

        --------------------------------------------------
        -- STOP CENTERLINE
        --------------------------------------------------

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

        --------------------------------------------------
        -- REGISTER CONTROLLER
        --------------------------------------------------

        vars.ModeControllers.centerline = stopCenterline

        --------------------------------------------------
        -- STOP OTHER MODES
        --------------------------------------------------

        local function stopOtherModes()

            for name, stopFunction in pairs(
                vars.ModeControllers
            ) do

                if name ~= "centerline"
                    and type(stopFunction) == "function" then

                    pcall(stopFunction)
                end
            end
        end

        --------------------------------------------------
        -- FIND PLAYER
        --------------------------------------------------

        local function findPlayerByName(name)

            if not name or name == "" then
                return nil
            end

            name = name:lower()

            -- Exact username / display name.
            for _, player in ipairs(
                Players:GetPlayers()
            ) do

                if player.Name:lower() == name
                    or player.DisplayName:lower() == name then

                    return player
                end
            end

            -- Username prefix.
            for _, player in ipairs(
                Players:GetPlayers()
            ) do

                if player.Name:lower():sub(1, #name) == name then
                    return player
                end
            end

            -- Display name prefix.
            for _, player in ipairs(
                Players:GetPlayers()
            ) do

                if player.DisplayName:lower():sub(1, #name) == name then
                    return player
                end
            end

            return nil
        end

        --------------------------------------------------
        -- GET BOT INDEX
        --------------------------------------------------

        local function getBotIndex()

            return table.find(
                botOrder,
                tostring(LocalPlayer.UserId)
            )
        end

        --------------------------------------------------
        -- CALCULATE HORIZONTAL OFFSET
        --------------------------------------------------
        -- Bot 1  = -13.5 studs
        -- Bot 2  = -10.5 studs
        -- Bot 3  =  -7.5 studs
        -- Bot 4  =  -4.5 studs
        -- Bot 5  =  -1.5 studs
        -- Admin  =   0 studs
        -- Bot 6  =  +1.5 studs
        -- Bot 7  =  +4.5 studs
        -- Bot 8  =  +7.5 studs
        -- Bot 9  = +10.5 studs
        -- Bot 10 = +13.5 studs
        --
        -- Jarak Bot 5 ke Admin = 1.5 studs.
        -- Jarak Bot 6 ke Admin = 1.5 studs.
        -- Jarak antarbots selalu 3 studs.

        local function getHorizontalOffset(botIndex)

            if botIndex <= 5 then

                return -(
                    targetGap
                    + ((5 - botIndex) * formationSpacing)
                )

            else

                return targetGap
                    + ((botIndex - 6) * formationSpacing)

            end
        end

        --------------------------------------------------
        -- START CENTERLINE
        --------------------------------------------------

        local function startCenterline(player)

            if not player then
                return
            end

            if not player:IsDescendantOf(Players) then
                warn("[Centerline] Target tidak tersedia.")
                return
            end

            --------------------------------------------------
            -- VALIDATE BOT
            --------------------------------------------------

            local botIndex = getBotIndex()

            if not botIndex then
                warn(
                    "[Centerline] Bot tidak terdaftar:",
                    LocalPlayer.UserId
                )
                return
            end

            --------------------------------------------------
            -- STOP OTHER MODES
            --------------------------------------------------

            stopOtherModes()

            --------------------------------------------------
            -- SET MODE
            --------------------------------------------------

            vars.ActiveMode = "centerline"

            --------------------------------------------------
            -- STOP OLD CONNECTION
            --------------------------------------------------

            if centerlineConnection then
                centerlineConnection:Disconnect()
                centerlineConnection = nil
            end

            --------------------------------------------------
            -- SET TARGET
            --------------------------------------------------

            centering = true
            targetPlayer = player

            vars.CommandTarget = player

            --------------------------------------------------
            -- BOT OFFSET
            --------------------------------------------------

            local horizontalOffset =
                getHorizontalOffset(botIndex)

            print(
                "[Centerline] Target:",
                player.Name
            )

            print(
                "[Centerline] Bot:",
                botIndex,
                "| Offset:",
                horizontalOffset,
                "| Spacing:",
                formationSpacing,
                "| Target gap:",
                targetGap
            )

            --------------------------------------------------
            -- CHAT CONFIRMATION
            --------------------------------------------------

            sendChat("Yes, Sir!")

            --------------------------------------------------
            -- CENTERLINE LOOP
            --------------------------------------------------

            centerlineConnection =
                RunService.Heartbeat:Connect(function()

                    --------------------------------------------------
                    -- CHECK ACTIVE MODE
                    --------------------------------------------------

                    if vars.ActiveMode ~= "centerline" then
                        stopCenterline()
                        return
                    end

                    --------------------------------------------------
                    -- VALIDATE STATE
                    --------------------------------------------------

                    if not centering
                        or not humanoid
                        or not myHRP
                        or not myHRP.Parent
                        or humanoid.Health <= 0
                        or not targetPlayer then

                        return
                    end

                    --------------------------------------------------
                    -- TARGET CHARACTER
                    --------------------------------------------------

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

                    --------------------------------------------------
                    -- CALCULATE POSITION
                    --------------------------------------------------

                    -- Posisi kiri/kanan mengikuti arah target.
                    local rightVector =
                        targetHRP.CFrame.RightVector

                    local targetPosition =
                        targetHRP.Position
                        + (rightVector * horizontalOffset)

                    -- Ratakan ketinggian agar semua bot berada
                    -- pada level yang sama dengan target.

                    targetPosition = Vector3.new(
                        targetPosition.X,
                        targetHRP.Position.Y,
                        targetPosition.Z
                    )

                    --------------------------------------------------
                    -- DISTANCE TO DESTINATION
                    --------------------------------------------------

                    local distanceToTarget =
                        (
                            myHRP.Position
                            - targetPosition
                        ).Magnitude

                    --------------------------------------------------
                    -- MOVE TO POSITION
                    --------------------------------------------------

                    if distanceToTarget > arrivalTolerance then

                        humanoid.AutoRotate = true

                        humanoid:MoveTo(targetPosition)

                        return
                    end

                    --------------------------------------------------
                    -- ARRIVED
                    -- FACE SAME DIRECTION AS TARGET
                    --------------------------------------------------

                    humanoid.AutoRotate = false

                    local targetRotation =
                        targetHRP.CFrame
                        - targetHRP.Position

                    myHRP.CFrame =
                        CFrame.new(myHRP.Position)
                        * targetRotation

                end)
        end

        --------------------------------------------------
        -- COMMAND HANDLER
        --------------------------------------------------

        local function handleCommand(message, sender)

            if not message or not sender then
                return
            end

            --------------------------------------------------
            -- ADMIN CHECK
            --------------------------------------------------

            local isAdmin = false

            pcall(function()
                isAdmin = Admin:IsAdmin(sender)
            end)

            local isCommandTarget =
                vars.CommandTarget == sender

            --------------------------------------------------
            -- NORMALIZE MESSAGE
            --------------------------------------------------

            local lower =
                message:lower()
                :gsub("^%s+", "")
                :gsub("%s+$", "")

            --------------------------------------------------
            -- !STOP / !UNCENTERLINE
            --------------------------------------------------

            if lower == "!stop"
                or lower == "!uncenterline" then

                if not isAdmin then
                    return
                end

                vars.ActiveMode = nil
                vars.CommandTarget = nil

                for _, stopFunction in pairs(
                    vars.ModeControllers
                ) do

                    if type(stopFunction) == "function" then
                        pcall(stopFunction)
                    end
                end

                print("[Centerline] Formasi dihentikan.")
                return
            end

            --------------------------------------------------
            -- !CENTERLINE
            --------------------------------------------------

            if lower == "!centerline" then

                if not isAdmin and not isCommandTarget then
                    return
                end

                startCenterline(sender)
                return
            end

            --------------------------------------------------
            -- !CENTERLINE PLAYER
            -- HANYA ADMIN
            --------------------------------------------------

            local targetName =
                lower:match("^!centerline%s+(.+)$")

            if targetName then

                if not isAdmin then
                    return
                end

                local target =
                    findPlayerByName(targetName)

                if not target then
                    warn(
                        "[Centerline] Player tidak ditemukan:",
                        targetName
                    )
                    return
                end

                startCenterline(target)
                return
            end
        end

        --------------------------------------------------
        -- CHAT CONNECTIONS
        --------------------------------------------------

        local channel

        if TextChatService
            and TextChatService.TextChannels then

            channel =
                TextChatService.TextChannels:FindFirstChild(
                    "RBXGeneral"
                )
        end

        if channel then

            channel.MessageReceived:Connect(function(message)

                local textSource = message.TextSource

                if not textSource then
                    return
                end

                local sender =
                    Players:GetPlayerByUserId(
                        textSource.UserId
                    )

                if sender then
                    handleCommand(message.Text, sender)
                end
            end)

        else

            local function connectPlayer(player)

                player.Chatted:Connect(function(message)
                    handleCommand(message, player)
                end)
            end

            for _, player in ipairs(
                Players:GetPlayers()
            ) do
                connectPlayer(player)
            end

            Players.PlayerAdded:Connect(connectPlayer)
        end

        --------------------------------------------------
        -- CHARACTER RESPAWN
        --------------------------------------------------

        LocalPlayer.CharacterAdded:Connect(function()

            task.wait(1)

            updateCharacter()

            if vars.ActiveMode == "centerline"
                and targetPlayer then

                startCenterline(targetPlayer)
            end
        end)

        --------------------------------------------------
        -- DONE
        --------------------------------------------------

        print("[Centerline] Loaded successfully.")
        print("[Centerline] Jarak antarbot:", formationSpacing)
        print("[Centerline] Jarak bot terdekat ke target:", targetGap)
        print("[Centerline] Gunakan !centerline untuk memulai.")

    end
}