return {
    Execute = function()

        ------------------------------------------------------------
        -- SERVICES
        ------------------------------------------------------------

        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        local TextChatService = game:GetService("TextChatService")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")

        local LocalPlayer = Players.LocalPlayer

        if not LocalPlayer then
            warn("[Centerline] LocalPlayer tidak ditemukan!")
            return
        end

        ------------------------------------------------------------
        -- GLOBAL MODE SYSTEM
        ------------------------------------------------------------

        _G.BotVars = _G.BotVars or {}
        _G.BotVars.ModeControllers =
            _G.BotVars.ModeControllers or {}

        ------------------------------------------------------------
        -- LOAD ADMIN
        ------------------------------------------------------------

        local success, Admin = pcall(function()
            return loadstring(game:HttpGet(
                "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
            ))()
        end)

        if not success or not Admin then
            warn("[Centerline] Gagal memuat Admin.lua:", Admin)
            return
        end

        ------------------------------------------------------------
        -- VARIABLES
        ------------------------------------------------------------

        local humanoid
        local myHRP

        local centering = false
        local targetPlayer = nil
        local centerlineConnection = nil

        -- Mencegah pesan yang sama diproses berulang kali.
        local recentMessages = {}

        ------------------------------------------------------------
        -- FORMATION SETTINGS
        ------------------------------------------------------------

        local spacing = 3
        local rowSpacing = 4

        ------------------------------------------------------------
        -- BOT ORDER
        ------------------------------------------------------------

        local botOrder = {
            "11611503633", -- Bot 1: kiri paling luar
            "11611591921", -- Bot 2
            "11611597741", -- Bot 3
            "11672413029", -- Bot 4
            "11122806815", -- Bot 5
            "11122806817", -- Bot 6: kiri dekat target

            "11122687468", -- Bot 7: kanan dekat target
            "11122854402", -- Bot 8
            "11774472805", -- Bot 9
            "11774494628", -- Bot 10
            "11775829997", -- Bot 11
            "11775843339", -- Bot 12: kanan paling luar
        }

        ------------------------------------------------------------
        -- UPDATE CHARACTER
        ------------------------------------------------------------

        local function updateCharacter()

            local character =
                LocalPlayer.Character
                or LocalPlayer.CharacterAdded:Wait()

            humanoid = character:WaitForChild("Humanoid")
            myHRP = character:WaitForChild("HumanoidRootPart")

            humanoid.AutoRotate = true
        end

        updateCharacter()

        ------------------------------------------------------------
        -- SEND CHAT
        ------------------------------------------------------------

        local function sendChat(message)

            local sent = false

            if TextChatService
                and TextChatService.TextChannels then

                local channel =
                    TextChatService.TextChannels:FindFirstChild(
                        "RBXGeneral"
                    )

                if channel then
                    sent = pcall(function()
                        channel:SendAsync(message)
                    end)
                end
            end

            if not sent then
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

        ------------------------------------------------------------
        -- STOP CENTERLINE
        ------------------------------------------------------------

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

        ------------------------------------------------------------
        -- REGISTER CONTROLLER
        ------------------------------------------------------------

        _G.BotVars.ModeControllers.centerline =
            stopCenterline

        ------------------------------------------------------------
        -- STOP OTHER MODES
        ------------------------------------------------------------

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

        ------------------------------------------------------------
        -- FIND PLAYER
        ------------------------------------------------------------

        local function findPlayerByName(name)

            if not name or name == "" then
                return nil
            end

            name = name:lower()

            -- Exact username / display name

            for _, player in ipairs(Players:GetPlayers()) do

                if player.Name:lower() == name
                    or player.DisplayName:lower() == name then

                    return player
                end
            end

            -- Username prefix

            for _, player in ipairs(Players:GetPlayers()) do

                if player.Name:lower():sub(1, #name) == name then
                    return player
                end
            end

            -- Display name prefix

            for _, player in ipairs(Players:GetPlayers()) do

                if player.DisplayName:lower():sub(1, #name) == name then
                    return player
                end
            end

            return nil
        end

        ------------------------------------------------------------
        -- GET CENTERLINE POSITION
        ------------------------------------------------------------

        local function getCenterlinePosition(targetHRP, botIndex)

            local horizontalOffset

            --------------------------------------------------------
            -- BOT 1-6: SEBELAH KIRI TARGET
            --------------------------------------------------------

            if botIndex <= 6 then

                -- Bot 6 paling dekat dengan target.
                -- Bot 1 paling jauh dari target.

                horizontalOffset =
                    -(7 - botIndex) * spacing

            --------------------------------------------------------
            -- BOT 7-12: SEBELAH KANAN TARGET
            --------------------------------------------------------

            else

                -- Bot 7 paling dekat dengan target.
                -- Bot 12 paling jauh dari target.

                horizontalOffset =
                    (botIndex - 6) * spacing
            end

            --------------------------------------------------------
            -- ARAH TARGET
            --------------------------------------------------------

            local right =
                targetHRP.CFrame.RightVector

            local backward =
                -targetHRP.CFrame.LookVector

            --------------------------------------------------------
            -- POSISI AKHIR
            --------------------------------------------------------

            return targetHRP.Position
                + right * horizontalOffset
                + backward * rowSpacing
        end

        ------------------------------------------------------------
        -- START CENTERLINE
        ------------------------------------------------------------

        local function startCenterline(player)

            if not player then
                return
            end

            --------------------------------------------------------
            -- VALIDATE BOT INDEX
            --------------------------------------------------------

            local myIndex = table.find(
                botOrder,
                tostring(LocalPlayer.UserId)
            )

            if not myIndex then

                warn(
                    "[Centerline] Akun ini tidak ada dalam botOrder:",
                    LocalPlayer.Name
                )

                return
            end

            --------------------------------------------------------
            -- VALIDATE TARGET
            --------------------------------------------------------

            local targetCharacter = player.Character

            local targetHRP = targetCharacter
                and targetCharacter:FindFirstChild(
                    "HumanoidRootPart"
                )

            if not targetHRP then

                warn(
                    "[Centerline] Character target belum siap:",
                    player.Name
                )

                return
            end

            --------------------------------------------------------
            -- STOP OTHER MODES
            --------------------------------------------------------

            stopOtherModes()

            --------------------------------------------------------
            -- STOP OLD CONNECTION
            --------------------------------------------------------

            if centerlineConnection then
                centerlineConnection:Disconnect()
                centerlineConnection = nil
            end

            --------------------------------------------------------
            -- UPDATE STATE
            --------------------------------------------------------

            centering = true
            targetPlayer = player

            _G.BotVars.ActiveMode = "centerline"
            _G.BotVars.CommandTarget = player

            --------------------------------------------------------
            -- CHAT CONFIRMATION
            --------------------------------------------------------

            sendChat("Yes, Sir!")

            print(
                "[Centerline] Aktif | Bot:",
                myIndex,
                "| Target:",
                player.Name
            )

            --------------------------------------------------------
            -- MOVEMENT LOOP
            --------------------------------------------------------

            centerlineConnection =
                RunService.Heartbeat:Connect(function()

                    if not centering then
                        return
                    end

                    if _G.BotVars.ActiveMode ~= "centerline" then
                        stopCenterline()
                        return
                    end

                    if not targetPlayer
                        or not targetPlayer.Parent then

                        stopCenterline()
                        return
                    end

                    if not humanoid
                        or not myHRP
                        or not myHRP.Parent then

                        return
                    end

                    local character = targetPlayer.Character

                    if not character then
                        return
                    end

                    local targetRoot =
                        character:FindFirstChild("HumanoidRootPart")

                    if not targetRoot then
                        return
                    end

                    ------------------------------------------------
                    -- CALCULATE POSITION
                    ------------------------------------------------

                    local targetPosition =
                        getCenterlinePosition(
                            targetRoot,
                            myIndex
                        )

                    ------------------------------------------------
                    -- MOVE BOT
                    ------------------------------------------------

                    local distance =
                        (myHRP.Position - targetPosition).Magnitude

                    if distance > 1.5 then

                        humanoid.AutoRotate = true
                        humanoid:MoveTo(targetPosition)

                        return
                    end

                    ------------------------------------------------
                    -- FACE SAME DIRECTION AS TARGET
                    ------------------------------------------------

                    humanoid.AutoRotate = false

                    local lookDirection =
                        targetRoot.CFrame.LookVector

                    myHRP.CFrame = CFrame.lookAt(
                        myHRP.Position,
                        myHRP.Position + lookDirection
                    )
                end)
        end

        ------------------------------------------------------------
        -- COMMAND HANDLER
        ------------------------------------------------------------

        local function handleCommand(message, sender)

            if not message or not sender then
                return
            end

            --------------------------------------------------------
            -- ADMIN CHECK
            --------------------------------------------------------

            local isAdmin = false

            pcall(function()
                isAdmin = Admin:IsAdmin(sender)
            end)

            --------------------------------------------------------
            -- NORMALIZE MESSAGE
            --------------------------------------------------------

            local lower = message
                :lower()
                :gsub("^%s+", "")
                :gsub("%s+$", "")

            --------------------------------------------------------
            -- !STOP / !UNCENTERLINE
            -- HANYA ADMIN
            --------------------------------------------------------

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

                print("[Centerline] Semua formasi dihentikan.")
                return
            end

            --------------------------------------------------------
            -- PARSE !CENTERLINE [PLAYER]
            --------------------------------------------------------

            local command, targetName =
                lower:match("^(%S+)%s*(.-)$")

            if command ~= "!centerline" then
                return
            end

            --------------------------------------------------------
            -- ADMIN: !CENTERLINE ATAU !CENTERLINE PLAYER
            --------------------------------------------------------

            if isAdmin then

                local target = sender

                if targetName ~= "" then

                    target = findPlayerByName(targetName)

                    if not target then

                        warn(
                            "[Centerline] Player tidak ditemukan:",
                            targetName
                        )

                        return
                    end
                end

                startCenterline(target)
                return
            end

            --------------------------------------------------------
            -- COMMAND TARGET: !CENTERLINE
            --------------------------------------------------------

            if _G.BotVars.CommandTarget == sender
                and targetName == "" then

                startCenterline(sender)
                return
            end
        end

        ------------------------------------------------------------
        -- PROCESS CHAT WITH DEDUPLICATION
        ------------------------------------------------------------

        local function processMessage(message, sender, messageId)

            if not message or not sender then
                return
            end

            local key

            if messageId then
                key = tostring(messageId)
            else
                key = tostring(sender.UserId)
                    .. ":"
                    .. message:lower()
            end

            if recentMessages[key] then
                return
            end

            recentMessages[key] = true

            task.delay(3, function()
                recentMessages[key] = nil
            end)

            handleCommand(message, sender)
        end

        ------------------------------------------------------------
        -- CHAT LISTENER: TEXTCHAT
        ------------------------------------------------------------

        if TextChatService
            and TextChatService.TextChannels then

            local channel =
                TextChatService.TextChannels:FindFirstChild(
                    "RBXGeneral"
                )

            if channel then

                channel.MessageReceived:Connect(function(message)

                    if not message.TextSource then
                        return
                    end

                    local sender =
                        Players:GetPlayerByUserId(
                            message.TextSource.UserId
                        )

                    if sender then
                        processMessage(
                            message.Text,
                            sender,
                            message.MessageId
                        )
                    end
                end)
            end
        end

        ------------------------------------------------------------
        -- CHAT LISTENER: PLAYER.CHATTED
        ------------------------------------------------------------

        local function connectPlayerChat(player)

            player.Chatted:Connect(function(message)

                processMessage(
                    message,
                    player,
                    nil
                )
            end)
        end

        for _, player in ipairs(Players:GetPlayers()) do
            connectPlayerChat(player)
        end

        Players.PlayerAdded:Connect(function(player)
            connectPlayerChat(player)
        end)

        ------------------------------------------------------------
        -- CHARACTER RESPAWN
        ------------------------------------------------------------

        LocalPlayer.CharacterAdded:Connect(function()

            task.wait(1)

            updateCharacter()

            if _G.BotVars.ActiveMode == "centerline"
                and targetPlayer then

                startCenterline(targetPlayer)
            end
        end)

        ------------------------------------------------------------
        -- MODULE READY
        ------------------------------------------------------------

        print(
            "[Centerline] Module berhasil aktif untuk:",
            LocalPlayer.Name
        )
    end
}