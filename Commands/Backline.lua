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
        -- VARIABLES
        ----------------------------------------------------------------

        local humanoid
        local myHRP

        local backlining = false
        local targetPlayer = nil
        local backlineConnection = nil

        ----------------------------------------------------------------
        -- FORMATION DISTANCE
        ----------------------------------------------------------------

        local adminBacklineDistance = 6
        local defaultBotBacklineDistance = 6

        -- Jarak antar bot dalam barisan.
        local formationSpacing = 3

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

                    if chatEvents then

                        local sayMessageRequest =
                            chatEvents:FindFirstChild(
                                "SayMessageRequest"
                            )

                        if sayMessageRequest then

                            sayMessageRequest:FireServer(
                                message,
                                "All"
                            )

                        end

                    end

                end)

            end

        end

        ----------------------------------------------------------------
        -- STOP BACKLINE
        ----------------------------------------------------------------

        local function stopBackline()

            backlining = false
            targetPlayer = nil

            if backlineConnection then
                backlineConnection:Disconnect()
                backlineConnection = nil
            end

            if humanoid then
                humanoid.AutoRotate = true
            end

        end

        ----------------------------------------------------------------
        -- REGISTER CONTROLLER
        ----------------------------------------------------------------

        _G.BotVars.ModeControllers.backline =
            stopBackline

        ----------------------------------------------------------------
        -- STOP SEMUA MODE LAIN
        ----------------------------------------------------------------

        local function stopOtherModes()

            for name, stopFunction in pairs(
                _G.BotVars.ModeControllers
            ) do

                if name ~= "backline"
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

            -- Exact username atau display name.
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
        -- MENGAMBIL DAFTAR BOT AKTIF
        ----------------------------------------------------------------

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
                        botUserId
                    )

                end

            end

            return activeBots

        end

        ----------------------------------------------------------------
        -- START BACKLINE
        ----------------------------------------------------------------

        local function startBackline(player)

            if not player then
                return
            end

            ------------------------------------------------------------
            -- STOP MODE LAIN
            ------------------------------------------------------------

            stopOtherModes()

            ------------------------------------------------------------
            -- SET ACTIVE MODE
            ------------------------------------------------------------

            _G.BotVars.ActiveMode = "backline"

            ------------------------------------------------------------
            -- STOP CONNECTION LAMA
            ------------------------------------------------------------

            if backlineConnection then
                backlineConnection:Disconnect()
                backlineConnection = nil
            end

            ------------------------------------------------------------
            -- SET STATE
            ------------------------------------------------------------

            backlining = true
            targetPlayer = player

            _G.BotVars.CommandTarget = player

            sendChat("Yes, Sir!")

            ------------------------------------------------------------
            -- VALIDASI BOT
            ------------------------------------------------------------

            local activeBots = getActiveBots()

            local activeIndex = table.find(
                activeBots,
                tostring(LocalPlayer.UserId)
            )

            if not activeIndex then
                stopBackline()
                return
            end

            ------------------------------------------------------------
            -- BACKLINE LOOP
            ------------------------------------------------------------

            backlineConnection =
                RunService.Heartbeat:Connect(function()

                    ----------------------------------------------------
                    -- JIKA MODE SUDAH BERGANTI
                    ----------------------------------------------------

                    if _G.BotVars.ActiveMode ~= "backline" then
                        stopBackline()
                        return
                    end

                    ----------------------------------------------------
                    -- VALIDASI
                    ----------------------------------------------------

                    if not backlining then
                        return
                    end

                    if not humanoid
                        or not myHRP
                        or humanoid.Health <= 0 then

                        return
                    end

                    if not targetPlayer then
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
                    -- PERBARUI DAFTAR BOT AKTIF
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
                    -- DISTANCE
                    ----------------------------------------------------

                    local distance =
                        defaultBotBacklineDistance

                    if Admin:IsAdmin(targetPlayer) then

                        distance =
                            adminBacklineDistance

                    end

                    local specialDistance =
                        Distance:GetDistance(
                            tostring(LocalPlayer.UserId),
                            tostring(targetPlayer.UserId)
                        )

                    if specialDistance then
                        distance = specialDistance
                    end

                    ----------------------------------------------------
                    -- HITUNG TITIK TENGAH FORMASI
                    ----------------------------------------------------

                    local activeBotCount = #activeBots

                    local centerIndex =
                        (activeBotCount + 1) / 2

                    ----------------------------------------------------
                    -- HITUNG OFFSET HORIZONTAL
                    ----------------------------------------------------

                    local horizontalOffset =
                        (activeIndex - centerIndex)
                        * formationSpacing

                    ----------------------------------------------------
                    -- POSISI BACKLINE
                    --
                    -- Semua bot berada DI BELAKANG target.
                    -- Offset horizontal mengikuti urutan bot aktif.
                    ----------------------------------------------------

                    local targetPosition =
                        targetHRP.Position
                        - (
                            targetHRP.CFrame.LookVector
                            * distance
                        )
                        + (
                            targetHRP.CFrame.RightVector
                            * horizontalOffset
                        )

                    ----------------------------------------------------
                    -- JARAK KE POSISI TUJUAN
                    ----------------------------------------------------

                    local distanceToTarget =
                        (
                            myHRP.Position
                            - targetPosition
                        ).Magnitude

                    ----------------------------------------------------
                    -- JALAN KE POSISI
                    ----------------------------------------------------

                    if distanceToTarget > 1.5 then

                        humanoid.AutoRotate = true

                        humanoid:MoveTo(
                            targetPosition
                        )

                        return

                    end

                    ----------------------------------------------------
                    -- SUDAH SAMPAI
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
            -- !BACKLINE
            -- ADMIN ATAU COMMAND TARGET
            ------------------------------------------------------------

            if lower == "!backline" then

                if not isAdmin and not isCommandTarget then
                    return
                end

                startBackline(sender)

                return
            end

            ------------------------------------------------------------
            -- !BACKLINE PLAYER
            -- HANYA ADMIN
            ------------------------------------------------------------

            local targetName =
                lower:match("^!backline%s+(.+)$")

            if targetName then

                if not isAdmin then
                    return
                end

                local target =
                    findPlayerByName(targetName)

                if target then
                    startBackline(target)
                end

                return
            end

            ------------------------------------------------------------
            -- !STOP / !UNBACKLINE
            -- HANYA ADMIN
            ------------------------------------------------------------

            if lower == "!stop"
                or lower == "!unbackline" then

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
                            handleCommand(message.Text, sender)
                        end

                    end
                )

            end

        end

        ----------------------------------------------------------------
        -- FALLBACK CHAT
        ----------------------------------------------------------------

        for _, player in ipairs(Players:GetPlayers()) do

            player.Chatted:Connect(function(message)

                handleCommand(message, player)

            end)

        end

        ----------------------------------------------------------------
        -- PLAYER ADDED
        ----------------------------------------------------------------

        Players.PlayerAdded:Connect(function(player)

            player.Chatted:Connect(function(message)

                handleCommand(message, player)

            end)

        end)

        ----------------------------------------------------------------
        -- CHARACTER RESPAWN
        ----------------------------------------------------------------

        LocalPlayer.CharacterAdded:Connect(function()

            task.wait(1)

            updateCharacter()

            if _G.BotVars.ActiveMode == "backline"
                and targetPlayer then

                startBackline(targetPlayer)

            end

        end)

    end
}