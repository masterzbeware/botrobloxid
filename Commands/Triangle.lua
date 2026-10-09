return {
    Execute = function()

        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        local TextChatService = game:GetService("TextChatService")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")

        local LocalPlayer = Players.LocalPlayer

        if not LocalPlayer then
            warn("[Triangle] LocalPlayer tidak ditemukan!")
            return
        end

        _G.BotVars = _G.BotVars or {}
        _G.BotVars.ModeControllers = _G.BotVars.ModeControllers or {}

        --------------------------------------------------
        -- ADMIN
        --------------------------------------------------

        local success, Admin = pcall(function()
            return loadstring(game:HttpGet(
                "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
            ))()
        end)

        if not success or not Admin then
            warn("[Triangle] Gagal memuat Admin.lua:", Admin)
            return
        end

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
            "11775829997", -- Bot 11
            "11775843339", -- Bot 12
        }

        --------------------------------------------------
        -- SETTINGS
        --------------------------------------------------

        local SIDE_SPACING = 3
        local ROW_SPACING = 3

        local active = false
        local connection = nil
        local targetPlayer = nil
        local humanoid = nil
        local rootPart = nil

        --------------------------------------------------
        -- CHARACTER
        --------------------------------------------------

        local function updateCharacter(character)
            character = character or LocalPlayer.Character

            if not character then
                humanoid = nil
                rootPart = nil
                return
            end

            humanoid = character:FindFirstChildOfClass("Humanoid")
            rootPart = character:FindFirstChild("HumanoidRootPart")
        end

        updateCharacter()

        --------------------------------------------------
        -- CHAT OUTPUT
        --------------------------------------------------

        local function sendChat(text)
            local channels = TextChatService:FindFirstChild("TextChannels")
            local general = channels and channels:FindFirstChild("RBXGeneral")

            if general then
                pcall(function()
                    general:SendAsync(text)
                end)
                return
            end

            local events = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
            local sayMessage = events and events:FindFirstChild("SayMessageRequest")

            if sayMessage then
                pcall(function()
                    sayMessage:FireServer(text, "All")
                end)
            end
        end

        --------------------------------------------------
        -- STOP TRIANGLE
        --------------------------------------------------

        local function stopTriangle()
            active = false

            if connection then
                connection:Disconnect()
                connection = nil
            end

            if humanoid then
                humanoid.AutoRotate = true
            end
        end

        _G.BotVars.ModeControllers.triangle = stopTriangle

        --------------------------------------------------
        -- STOP OTHER MODES
        --------------------------------------------------

        local function stopOtherModes()
            for modeName, stopFunction in pairs(
                _G.BotVars.ModeControllers
            ) do
                if modeName ~= "triangle"
                    and type(stopFunction) == "function" then

                    pcall(stopFunction)
                end
            end
        end

        --------------------------------------------------
        -- FIND PLAYER
        --------------------------------------------------

        local function findPlayer(name)
            if not name or name == "" then
                return nil
            end

            name = string.lower(name)

            -- Exact username or display name
            for _, player in ipairs(Players:GetPlayers()) do
                if string.lower(player.Name) == name
                    or string.lower(player.DisplayName) == name then
                    return player
                end
            end

            -- Username prefix
            for _, player in ipairs(Players:GetPlayers()) do
                if string.sub(string.lower(player.Name), 1, #name) == name then
                    return player
                end
            end

            -- Display name prefix
            for _, player in ipairs(Players:GetPlayers()) do
                if string.sub(string.lower(player.DisplayName), 1, #name) == name then
                    return player
                end
            end

            return nil
        end

        --------------------------------------------------
        -- TRIANGLE POSITION: 3 - 4 - 5
        --------------------------------------------------

        local function getBotPosition(targetHRP, index)
            local row
            local column
            local botsInRow

            if index <= 3 then
                -- Baris 1: Bot 1-3
                row = 0
                column = index - 1
                botsInRow = 3

            elseif index <= 7 then
                -- Baris 2: Bot 4-7
                row = 1
                column = index - 4
                botsInRow = 4

            else
                -- Baris 3: Bot 8-12
                row = 2
                column = index - 8
                botsInRow = 5
            end

            -- Pusatkan setiap baris
            local xOffset =
                (column - (botsInRow - 1) / 2) * SIDE_SPACING

            -- Setiap baris berada lebih jauh di belakang target
            local zOffset = ROW_SPACING * (row + 1)

            local targetCF = targetHRP.CFrame

            return targetHRP.Position
                + targetCF.RightVector * xOffset
                - targetCF.LookVector * zOffset
        end

        --------------------------------------------------
        -- START TRIANGLE
        --------------------------------------------------

        local function startTriangle(target)
            stopTriangle()

            if not target or not target.Parent then
                warn("[Triangle] Target tidak ditemukan!")
                return
            end

            if not table.find(botOrder, tostring(LocalPlayer.UserId)) then
                warn("[Triangle] Akun ini tidak terdaftar dalam botOrder!")
                return
            end

            if not target.Character
                or not target.Character:FindFirstChild("HumanoidRootPart") then
                warn("[Triangle] Character atau HumanoidRootPart target belum tersedia!")
                return
            end

            stopOtherModes()

            targetPlayer = target
            active = true

            _G.BotVars.CommandTarget = target
            _G.BotVars.ActiveMode = "triangle"

            updateCharacter()

            if humanoid then
                humanoid.AutoRotate = true
            end

            print("[Triangle] Aktif untuk:", target.Name)
            sendChat("Yes, Sir!")

            -- Indeks akun bot yang menjalankan script ini
            local botIndex = table.find(botOrder, tostring(LocalPlayer.UserId))

            connection = RunService.Heartbeat:Connect(function()
                if not active then
                    return
                end

                if _G.BotVars.ActiveMode ~= "triangle" then
                    stopTriangle()
                    return
                end

                if not targetPlayer or not targetPlayer.Parent then
                    stopTriangle()
                    return
                end

                if not targetPlayer.Character then
                    return
                end

                local targetHRP =
                    targetPlayer.Character:FindFirstChild("HumanoidRootPart")

                if not targetHRP then
                    return
                end

                if not LocalPlayer.Character
                    or not LocalPlayer.Character.Parent then
                    return
                end

                updateCharacter()

                if not humanoid or not rootPart or humanoid.Health <= 0 then
                    return
                end

                local position = getBotPosition(targetHRP, botIndex)

                humanoid:MoveTo(position)

                -- Menghadap ke arah yang sama dengan target
                local lookVector = targetHRP.CFrame.LookVector

                rootPart.CFrame = CFrame.lookAt(
                    rootPart.Position,
                    rootPart.Position + lookVector
                )
            end)
        end

        --------------------------------------------------
        -- COMMAND HANDLER
        --------------------------------------------------

        local function handleCommand(message, sender)
            if not message or not sender then
                return
            end

            local trimmed = string.gsub(message, "^%s*(.-)%s*$", "%1")
            local command, argument = trimmed:match("^(%S+)%s*(.-)$")

            command = string.lower(command or "")
            argument = argument or ""

            --------------------------------------------------
            -- !TRIANGLE
            --------------------------------------------------

            if command == "!triangle" then
                print("[Triangle] Command diterima dari:", sender.Name, trimmed)

                if Admin:IsAdmin(sender) then
                    local target = sender

                    -- Admin dapat memilih target
                    if argument ~= "" then
                        local foundPlayer = findPlayer(argument)

                        if not foundPlayer then
                            warn("[Triangle] Player tidak ditemukan:", argument)
                            return
                        end

                        target = foundPlayer
                    end

                    _G.BotVars.CommandTarget = target
                    _G.BotVars.ActiveMode = "triangle"

                    startTriangle(target)
                    return
                end

                -- Target pilihan admin dapat mengganti formasi
                if _G.BotVars.CommandTarget == sender then
                    startTriangle(sender)
                end

                return
            end

            --------------------------------------------------
            -- !STOP / !UNTRIANGLE
            --------------------------------------------------

            if command == "!stop" or command == "!untriangle" then
                if not Admin:IsAdmin(sender) then
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

                print("[Triangle] Semua formasi dihentikan.")
            end
        end

        --------------------------------------------------
        -- CHAT LISTENER + DUPLICATE PROTECTION
        --------------------------------------------------

        local recentMessages = {}

        local function processMessage(message, sender)
            if not sender or not message then
                return
            end

            -- Deduplikasi berdasarkan pengirim dan isi pesan,
            -- agar dua listener tidak memproses perintah yang sama dua kali.
            local key = tostring(sender.UserId)
                .. ":"
                .. string.lower(
                    string.gsub(message, "^%s*(.-)%s*$", "%1")
                )

            if recentMessages[key] then
                return
            end

            recentMessages[key] = true

            task.delay(2, function()
                recentMessages[key] = nil
            end)

            handleCommand(message, sender)
        end

        -- TextChatService
        local textChannels = TextChatService:FindFirstChild("TextChannels")
        local generalChannel = textChannels
            and textChannels:FindFirstChild("RBXGeneral")

        if generalChannel then
            generalChannel.MessageReceived:Connect(function(message)
                if not message or not message.TextSource then
                    return
                end

                local sender = Players:GetPlayerByUserId(
                    message.TextSource.UserId
                )

                if sender then
                    processMessage(message.Text, sender)
                end
            end)
        end

        -- Player.Chatted fallback
        local function connectPlayerChat(player)
            player.Chatted:Connect(function(message)
                processMessage(message, player)
            end)
        end

        for _, player in ipairs(Players:GetPlayers()) do
            connectPlayerChat(player)
        end

        Players.PlayerAdded:Connect(connectPlayerChat)

        --------------------------------------------------
        -- CHARACTER RESPAWN
        --------------------------------------------------

        LocalPlayer.CharacterAdded:Connect(function(character)
            updateCharacter(character)

            task.wait(1)

            if active
                and _G.BotVars.ActiveMode == "triangle"
                and targetPlayer then

                startTriangle(targetPlayer)
            end
        end)

        --------------------------------------------------
        -- READY
        --------------------------------------------------

        print("[Triangle] Module berhasil aktif.")
    end
}