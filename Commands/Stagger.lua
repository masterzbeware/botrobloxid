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
            warn("[Stagger] LocalPlayer tidak ditemukan!")
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

        local success, Admin = pcall(function()
            return loadstring(game:HttpGet(
                "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
            ))()
        end)

        if not success or not Admin then
            warn("[Stagger] Gagal memuat Admin.lua:", Admin)
            return
        end

        ----------------------------------------------------------------
        -- VARIABLES
        ----------------------------------------------------------------

        local humanoid
        local myHRP

        local staggering = false
        local targetPlayer = nil
        local staggerConnection = nil

        -- Mencegah satu pesan ditangani berulang kali oleh listener.
        local recentMessages = {}

        ----------------------------------------------------------------
        -- FORMATION SETTINGS
        ----------------------------------------------------------------

        local spacing = 5
        local rowSpacing = 5

        ----------------------------------------------------------------
        -- BOT ORDER: 11 BOTS
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

            local sent = false

            if TextChatService
                and TextChatService.TextChannels then

                local channel =
                    TextChatService.TextChannels:FindFirstChild(
                        "RBXGeneral"
                    )

                if channel then

                    local ok = pcall(function()
                        channel:SendAsync(message)
                    end)

                    sent = ok
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

        ----------------------------------------------------------------
        -- STOP STAGGER
        ----------------------------------------------------------------

        local function stopStagger()

            staggering = false
            targetPlayer = nil

            if staggerConnection then
                staggerConnection:Disconnect()
                staggerConnection = nil
            end

            if humanoid then
                humanoid.AutoRotate = true
            end
        end

        ----------------------------------------------------------------
        -- REGISTER CONTROLLER
        ----------------------------------------------------------------

        _G.BotVars.ModeControllers.stagger = stopStagger

        ----------------------------------------------------------------
        -- STOP OTHER MODES
        ----------------------------------------------------------------

        local function stopOtherModes()

            for name, stopFunction in pairs(
                _G.BotVars.ModeControllers
            ) do

                if name ~= "stagger"
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

            -- Exact username/display name

            for _, player in ipairs(Players:GetPlayers()) do

                if player.Name:lower() == name
                    or player.DisplayName:lower() == name then

                    return player
                end
            end

            -- Username prefix

            for _, player in ipairs(Players:GetPlayers()) do

                if player.Name:lower():sub(
                    1, #name
                ) == name then

                    return player
                end
            end

            -- Display name prefix

            for _, player in ipairs(Players:GetPlayers()) do

                if player.DisplayName:lower():sub(
                    1, #name
                ) == name then

                    return player
                end
            end

            return nil
        end

        ----------------------------------------------------------------
        -- GET STAGGER POSITION
        ----------------------------------------------------------------

        local function getStaggerPosition(
            targetHRP,
            botIndex
        )

            local row
            local column
            local botsInRow

            ------------------------------------------------------------
            -- ROW 1: B1-B4
            ------------------------------------------------------------

            if botIndex <= 4 then

                row = 0
                column = botIndex - 1
                botsInRow = 4

            ------------------------------------------------------------
            -- ROW 2: B5-B7
            ------------------------------------------------------------

            elseif botIndex <= 7 then

                row = 1
                column = botIndex - 5
                botsInRow = 3

            ------------------------------------------------------------
            -- ROW 3: B8-B11
            ------------------------------------------------------------

            else

                row = 2
                column = botIndex - 8
                botsInRow = 4
            end

            ------------------------------------------------------------
            -- CENTER EACH ROW
            ------------------------------------------------------------

            local centerColumn =
                (botsInRow - 1) / 2

            local horizontalOffset =
                (column - centerColumn) * spacing

            ------------------------------------------------------------
            -- DEPTH OFFSET
            ------------------------------------------------------------

            local depthOffset =
                (row + 1) * rowSpacing

            ------------------------------------------------------------
            -- TARGET DIRECTION
            ------------------------------------------------------------

            local right =
                targetHRP.CFrame.RightVector

            local backward =
                -targetHRP.CFrame.LookVector

            ------------------------------------------------------------
            -- FINAL POSITION
            ------------------------------------------------------------

            return targetHRP.Position
                + right * horizontalOffset
                + backward * depthOffset
        end

        ----------------------------------------------------------------
        -- START STAGGER
        ----------------------------------------------------------------

        local function startStagger(player)

            if not player then
                return
            end

            local myIndex = table.find(
                botOrder,
                tostring(LocalPlayer.UserId)
            )

            if not myIndex then

                warn(
                    "[Stagger] Akun ini tidak ada dalam botOrder:",
                    LocalPlayer.Name
                )

                return
            end

            if not player.Character
                or not player.Character:FindFirstChild(
                    "HumanoidRootPart"
                ) then

                warn(
                    "[Stagger] Character target belum siap:",
                    player.Name
                )

                return
            end

            ------------------------------------------------------------
            -- STOP OTHER MODES
            ------------------------------------------------------------

            stopOtherModes()

            ------------------------------------------------------------
            -- UPDATE STATE
            ------------------------------------------------------------

            if staggerConnection then
                staggerConnection:Disconnect()
                staggerConnection = nil
            end

            staggering = true
            targetPlayer = player

            _G.BotVars.ActiveMode = "stagger"
            _G.BotVars.CommandTarget = player

            ------------------------------------------------------------
            -- CHAT CONFIRMATION
            ------------------------------------------------------------

            sendChat("Yes, Sir!")

            print(
                "[Stagger] Aktif | Bot:",
                myIndex,
                "| Target:",
                player.Name
            )

            ------------------------------------------------------------
            -- MOVEMENT LOOP
            ------------------------------------------------------------

            staggerConnection =
                RunService.Heartbeat:Connect(function()

                    if not staggering then
                        return
                    end

                    if _G.BotVars.ActiveMode ~= "stagger" then
                        stopStagger()
                        return
                    end

                    if not targetPlayer
                        or not targetPlayer.Parent then

                        stopStagger()
                        return
                    end

                    if not humanoid
                        or not myHRP
                        or not myHRP.Parent then

                        return
                    end

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
                    -- CALCULATE POSITION
                    ----------------------------------------------------

                    local targetPosition =
                        getStaggerPosition(
                            targetHRP,
                            myIndex
                        )

                    ----------------------------------------------------
                    -- MOVE TO POSITION
                    ----------------------------------------------------

                    local distance =
                        (myHRP.Position - targetPosition).Magnitude

                    if distance > 1.5 then

                        humanoid.AutoRotate = true
                        humanoid:MoveTo(targetPosition)

                        return
                    end

                    ----------------------------------------------------
                    -- FACE SAME DIRECTION AS TARGET
                    ----------------------------------------------------

                    humanoid.AutoRotate = false

                    local lookDirection =
                        targetHRP.CFrame.LookVector

                    myHRP.CFrame = CFrame.lookAt(
                        myHRP.Position,
                        myHRP.Position + lookDirection
                    )
                end)
        end

        ----------------------------------------------------------------
        -- COMMAND HANDLER
        ----------------------------------------------------------------

        local function handleCommand(
            message,
            sender
        )

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

            ------------------------------------------------------------
            -- NORMALIZE MESSAGE
            ------------------------------------------------------------

            local lower = message
                :lower()
                :gsub("^%s+", "")
                :gsub("%s+$", "")

            ------------------------------------------------------------
            -- !STOP / !UNSTAGGER
            ------------------------------------------------------------

            if lower == "!stop"
                or lower == "!unstagger" then

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

                print("[Stagger] Semua formasi dihentikan.")
                return
            end

            ------------------------------------------------------------
            -- !STAGGER [PLAYER]
            ------------------------------------------------------------

            local command, targetName =
                lower:match("^(%S+)%s*(.-)$")

            if command ~= "!stagger" then
                return
            end

            ------------------------------------------------------------
            -- ADMIN COMMAND
            ------------------------------------------------------------

            if isAdmin then

                local target = sender

                if targetName ~= "" then

                    target =
                        findPlayerByName(targetName)

                    if not target then

                        warn(
                            "[Stagger] Player tidak ditemukan:",
                            targetName
                        )

                        return
                    end
                end

                _G.BotVars.CommandTarget = target

                startStagger(target)

                return
            end

            ------------------------------------------------------------
            -- CURRENT COMMAND TARGET
            ------------------------------------------------------------

            if _G.BotVars.CommandTarget == sender then

                startStagger(sender)

                return
            end
        end

        ----------------------------------------------------------------
        -- DEDUPLICATE CHAT MESSAGES
        ----------------------------------------------------------------

        local function processMessage(
            message,
            sender,
            messageId
        )

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

            -- Bersihkan cache agar tidak terus bertambah.
            task.delay(3, function()
                recentMessages[key] = nil
            end)

            handleCommand(message, sender)
        end

        ----------------------------------------------------------------
        -- CHAT LISTENER 1: RBXGENERAL.MESSAGERECEIVED
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
                    end
                )
            else
                warn(
                    "[Stagger] RBXGeneral tidak ditemukan; " ..
                    "listener Player.Chatted tetap dipasang."
                )
            end
        end

        ----------------------------------------------------------------
        -- CHAT LISTENER 2: PLAYER.CHATTED
        ----------------------------------------------------------------

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

        ----------------------------------------------------------------
        -- CHARACTER RESPAWN
        ----------------------------------------------------------------

        LocalPlayer.CharacterAdded:Connect(function()

            task.wait(1)

            updateCharacter()

            if _G.BotVars.ActiveMode == "stagger"
                and targetPlayer then

                startStagger(targetPlayer)
            end
        end)

        ----------------------------------------------------------------
        -- MODULE READY
        ----------------------------------------------------------------

        print(
            "[Stagger] Module berhasil aktif untuk:",
            LocalPlayer.Name
        )
    end
}