-- Centerline.lua
-- MasterZ HUB
-- Formasi horizontal dinamis dengan Admin/Player di tengah.
--
-- Formasi menyesuaikan jumlah bot aktif.
--
-- Contoh:
-- 2 bot  : B1 | ADMIN | B2
-- 4 bot  : B1 B2 | ADMIN | B3 B4
-- 6 bot  : B1 B2 B3 | ADMIN | B4 B5 B6
-- 10 bot : B1 B2 B3 B4 B5 | ADMIN | B6 B7 B8 B9 B10
--
-- Jarak antarbot: 5 studs
-- Jarak bot terdekat ke target: 5 studs
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
            warn(
                "[Centerline] Gagal memuat Admin.lua:",
                Admin
            )
            return
        end

        --------------------------------------------------
        -- CONFIGURATION
        --------------------------------------------------

        -- Jarak antarbot yang bersebelahan.
        local formationSpacing = 5

        -- Jarak bot terdekat dari target.
        local targetGap = formationSpacing

        -- Toleransi kedatangan.
        local arrivalTolerance = 0.3

        --------------------------------------------------
        -- BOT ORDER
        --------------------------------------------------

        local botOrder = {
            "11801693968", -- Bot 1
            "11801692411", -- Bot 2

            "11801726433", -- Bot 3
            "11801750996", -- Bot 4

            "11802903376", -- Bot 5
            "11802916689", -- Bot 6

            "11802903446", -- Bot 7
            "11775829997", -- Bot 8

            "11775843339", -- Bot 9
            "11810691407", -- Bot 10
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

            -- Exact username atau display name.
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

                if player.Name:lower():sub(
                    1,
                    #name
                ) == name then

                    return player

                end

            end

            -- Display name prefix.
            for _, player in ipairs(
                Players:GetPlayers()
            ) do

                if player.DisplayName:lower():sub(
                    1,
                    #name
                ) == name then

                    return player

                end

            end

            return nil

        end

        --------------------------------------------------
        -- GET ACTIVE BOTS
        --------------------------------------------------
        -- Hanya bot yang benar-benar berada di server.
        -- Urutan mengikuti botOrder.
        --------------------------------------------------

        local function getActiveBots()

            local activeBots = {}

            for _, botUserId in ipairs(botOrder) do

                local botPlayer =
                    Players:GetPlayerByUserId(
                        tonumber(botUserId)
                    )

                if botPlayer then

                    table.insert(
                        activeBots,
                        tostring(botUserId)
                    )

                end

            end

            return activeBots

        end

        --------------------------------------------------
        -- CALCULATE HORIZONTAL OFFSET
        --------------------------------------------------
        -- Jumlah bot genap:
        -- Jumlah bot kiri = jumlah bot kanan.
        --
        -- Jumlah bot ganjil:
        -- Satu sisi memiliki satu bot lebih banyak.
        --
        -- Contoh 2 bot:
        -- B1 = -5, B2 = +5
        --
        -- Contoh 4 bot:
        -- B1 = -10, B2 = -5
        -- B3 = +5,  B4 = +10
        --
        -- Contoh 6 bot:
        -- B1 = -15, B2 = -10, B3 = -5
        -- B4 = +5,  B5 = +10, B6 = +15
        --------------------------------------------------

        local function getHorizontalOffset(
            activeIndex,
            activeBotCount
        )

            local leftCount =
                math.floor(activeBotCount / 2)

            -- Bot berada di sisi kiri target.
            if activeIndex <= leftCount then

                return -(
                    targetGap
                    + (
                        (leftCount - activeIndex)
                        * formationSpacing
                    )
                )

            end

            -- Bot berada di sisi kanan target.
            return targetGap
                + (
                    (activeIndex - leftCount - 1)
                    * formationSpacing
                )

        end

        --------------------------------------------------
        -- START CENTERLINE
        --------------------------------------------------

        local function startCenterline(player)

            if not player then
                return
            end

            if not player:IsDescendantOf(Players) then

                warn(
                    "[Centerline] Target tidak tersedia."
                )

                return

            end

            --------------------------------------------------
            -- VALIDATE ACTIVE BOT
            --------------------------------------------------

            local activeBots = getActiveBots()

            local activeIndex = table.find(
                activeBots,
                tostring(LocalPlayer.UserId)
            )

            if not activeIndex then

                warn(
                    "[Centerline] Bot tidak aktif atau tidak terdaftar:",
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
            -- LOG FORMATION
            --------------------------------------------------

            local activeBotCount = #activeBots

            local horizontalOffset =
                getHorizontalOffset(
                    activeIndex,
                    activeBotCount
                )

            print(
                "[Centerline] Target:",
                player.Name
            )

            print(
                "[Centerline] Active bots:",
                activeBotCount
            )

            print(
                "[Centerline] Bot index:",
                activeIndex,
                "| Offset:",
                horizontalOffset
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
                    -- REFRESH ACTIVE BOTS
                    --------------------------------------------------
                    -- Dihitung ulang agar formasi menyesuaikan
                    -- saat bot masuk atau keluar server.
                    --------------------------------------------------

                    activeBots = getActiveBots()

                    activeBotCount = #activeBots

                    activeIndex = table.find(
                        activeBots,
                        tostring(LocalPlayer.UserId)
                    )

                    if not activeIndex then
                        return
                    end

                    --------------------------------------------------
                    -- RECALCULATE OFFSET
                    --------------------------------------------------

                    horizontalOffset =
                        getHorizontalOffset(
                            activeIndex,
                            activeBotCount
                        )

                    --------------------------------------------------
                    -- CALCULATE POSITION
                    --------------------------------------------------

                    local rightVector =
                        targetHRP.CFrame.RightVector

                    local targetPosition =
                        targetHRP.Position
                        + (
                            rightVector
                            * horizontalOffset
                        )

                    -- Samakan ketinggian dengan target.
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

                        humanoid:MoveTo(
                            targetPosition
                        )

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
            -- HANYA ADMIN
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

                print(
                    "[Centerline] Formasi dihentikan."
                )

                return

            end

            --------------------------------------------------
            -- !CENTERLINE
            -- ADMIN ATAU COMMAND TARGET
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

                    handleCommand(
                        message.Text,
                        sender
                    )

                end

            end)

        else

            local function connectPlayer(player)

                player.Chatted:Connect(function(message)

                    handleCommand(
                        message,
                        player
                    )

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

        print(
            "[Centerline] Loaded successfully."
        )

        print(
            "[Centerline] Jarak antarbot:",
            formationSpacing
        )

        print(
            "[Centerline] Jarak bot terdekat ke target:",
            targetGap
        )

        print(
            "[Centerline] Formasi menyesuaikan bot aktif."
        )

        print(
            "[Centerline] Gunakan !centerline untuk memulai."
        )

    end
}