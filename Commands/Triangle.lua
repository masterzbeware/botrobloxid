return {
    Execute = function()

        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        local TextChatService = game:GetService("TextChatService")

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

        -- Cari urutan bot untuk akun yang menjalankan script ini.
        local botIndex = table.find(botOrder, tostring(LocalPlayer.UserId))

        --------------------------------------------------
        -- STOP TRIANGLE
        --------------------------------------------------

        local function stopTriangle()
            active = false
            targetPlayer = nil

            if connection then
                connection:Disconnect()
                connection = nil
            end
        end

        --------------------------------------------------
        -- STOP MODE LAIN
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
        -- POSISI SEGITIGA
        --------------------------------------------------

        local function getBotPosition(targetHRP, index)

            local row
            local column
            local botsInRow

            if index <= 3 then
                -- Baris 1: B1-B3
                row = 0
                column = index - 1
                botsInRow = 3

            elseif index <= 7 then
                -- Baris 2: B4-B7
                row = 1
                column = index - 4
                botsInRow = 4

            else
                -- Baris 3: B8-B12
                row = 2
                column = index - 8
                botsInRow = 5
            end

            -- Pusatkan setiap baris.
            local xOffset =
                (column - (botsInRow - 1) / 2) * SIDE_SPACING

            -- Setiap baris berada lebih jauh di belakang target.
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

            if not botIndex then
                warn(
                    "[Triangle] Akun ini tidak terdaftar di botOrder:",
                    LocalPlayer.Name,
                    LocalPlayer.UserId
                )
                return
            end

            if not target or not target.Parent then
                warn("[Triangle] Target tidak ditemukan!")
                return
            end

            if not target.Character
                or not target.Character:FindFirstChild("HumanoidRootPart") then

                warn("[Triangle] Character atau HumanoidRootPart target belum siap!")
                return
            end

            stopTriangle()
            stopOtherModes()

            targetPlayer = target
            active = true

            _G.BotVars.CommandTarget = target
            _G.BotVars.ActiveMode = "triangle"

            print(
                "[Triangle] Aktif untuk:",
                target.Name,
                "| Bot:",
                botIndex
            )

            connection = RunService.Heartbeat:Connect(function()

                if not active then
                    return
                end

                if not targetPlayer or not targetPlayer.Parent then
                    stopTriangle()
                    return
                end

                local targetCharacter = targetPlayer.Character

                if not targetCharacter then
                    return
                end

                local targetHRP =
                    targetCharacter:FindFirstChild("HumanoidRootPart")

                if not targetHRP then
                    return
                end

                -- Setiap client hanya menggerakkan bot miliknya sendiri.
                local character = LocalPlayer.Character

                if not character then
                    return
                end

                local humanoid =
                    character:FindFirstChildOfClass("Humanoid")

                local botHRP =
                    character:FindFirstChild("HumanoidRootPart")

                if not humanoid or not botHRP then
                    return
                end

                local position =
                    getBotPosition(targetHRP, botIndex)

                humanoid:MoveTo(position)

                -- Hadapkan bot ke arah yang sama dengan target.
                local lookVector = targetHRP.CFrame.LookVector

                botHRP.CFrame = CFrame.lookAt(
                    botHRP.Position,
                    botHRP.Position + lookVector
                )
            end)
        end

        --------------------------------------------------
        -- FIND PLAYER
        --------------------------------------------------

        local function findPlayer(name)

            if not name or name == "" then
                return nil
            end

            name = string.lower(name)

            -- Cocokkan username atau display name secara tepat.
            for _, player in ipairs(Players:GetPlayers()) do
                if string.lower(player.Name) == name
                    or string.lower(player.DisplayName) == name then

                    return player
                end
            end

            -- Jika tidak ditemukan, coba awalan username/display name.
            for _, player in ipairs(Players:GetPlayers()) do
                if string.sub(
                    string.lower(player.Name), 1, #name
                ) == name
                    or string.sub(
                        string.lower(player.DisplayName), 1, #name
                    ) == name then

                    return player
                end
            end

            return nil
        end

        --------------------------------------------------
        -- COMMAND HANDLER
        --------------------------------------------------

        local function handleCommand(message, sender)

            if not message or not sender then
                return
            end

            local trimmed = string.match(message, "^%s*(.-)%s*$")

            if not trimmed or trimmed == "" then
                return
            end

            local args = string.split(trimmed, " ")
            local command = string.lower(args[1] or "")

            --------------------------------------------------
            -- !TRIANGLE
            --------------------------------------------------

            if command == "!triangle" then

                print(
                    "[Triangle] Command diterima dari:",
                    sender.Name,
                    "|",
                    trimmed
                )

                -- Admin dapat memilih target.
                if Admin:IsAdmin(sender) then

                    local target = LocalPlayer

                    if args[2] and args[2] ~= "" then
                        local foundPlayer = findPlayer(args[2])

                        if not foundPlayer then
                            warn(
                                "[Triangle] Player tidak ditemukan:",
                                args[2]
                            )
                            return
                        end

                        target = foundPlayer
                    end

                    startTriangle(target)
                    return
                end

                -- Target pilihan admin boleh mengaktifkan formasi
                -- untuk dirinya sendiri dengan !triangle.
                if _G.BotVars.CommandTarget == sender then
                    startTriangle(sender)
                end

                return
            end

            --------------------------------------------------
            -- !STOP / !UNTRIANGLE
            --------------------------------------------------

            if command == "!stop"
                or command == "!untriangle" then

                -- Hanya admin yang boleh menghentikan semua mode.
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
        -- DEDUPLIKASI PESAN CHAT
        --------------------------------------------------

        -- Kedua listener dapat menerima pesan yang sama.
        -- Gunakan kunci sender + isi pesan agar tidak diproses dua kali.
        local lastMessages = {}
        local DEDUPE_WINDOW = 1.5

        local function processMessage(message, sender)

            if not sender or not message then
                return
            end

            local normalized = string.lower(
                string.match(message, "^%s*(.-)%s*$") or ""
            )

            if normalized == "" then
                return
            end

            local key = tostring(sender.UserId) .. ":" .. normalized
            local now = os.clock()
            local previous = lastMessages[key]

            if previous and now - previous < DEDUPE_WINDOW then
                return
            end

            lastMessages[key] = now
            handleCommand(message, sender)
        end

        --------------------------------------------------
        -- CHAT LISTENER 1: RBXGeneral.MessageReceived
        --------------------------------------------------

        local function connectTextChannel()

            local textChannels = TextChatService:FindFirstChild("TextChannels")
            local generalChannel = textChannels
                and textChannels:FindFirstChild("RBXGeneral")

            if not generalChannel then
                warn("[Triangle] RBXGeneral belum ditemukan.")
                return
            end

            generalChannel.MessageReceived:Connect(function(textMessage)

                if not textMessage or not textMessage.TextSource then
                    return
                end

                local sender = Players:GetPlayerByUserId(
                    textMessage.TextSource.UserId
                )

                if sender then
                    processMessage(textMessage.Text, sender)
                end
            end)
        end

        connectTextChannel()

        --------------------------------------------------
        -- CHAT LISTENER 2: Player.Chatted
        --------------------------------------------------

        local connectedPlayers = {}

        local function connectPlayer(player)

            if connectedPlayers[player] then
                return
            end

            connectedPlayers[player] = true

            player.Chatted:Connect(function(message)
                processMessage(message, player)
            end)
        end

        -- Hubungkan pemain yang sudah ada.
        for _, player in ipairs(Players:GetPlayers()) do
            connectPlayer(player)
        end

        -- Hubungkan pemain yang masuk setelah script berjalan.
        Players.PlayerAdded:Connect(connectPlayer)

        Players.PlayerRemoving:Connect(function(player)
            connectedPlayers[player] = nil
        end)

        --------------------------------------------------
        -- CHARACTER RESPAWN
        --------------------------------------------------

        LocalPlayer.CharacterAdded:Connect(function()
            task.wait(1)

            if active and targetPlayer then
                local currentTarget = targetPlayer
                startTriangle(currentTarget)
            end
        end)

        --------------------------------------------------
        -- REGISTER MODE
        --------------------------------------------------

        _G.BotVars.ModeControllers.triangle = stopTriangle

        print("[Triangle] Module berhasil aktif.")
    end
}