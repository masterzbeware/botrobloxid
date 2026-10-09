return {
    Execute = function()

        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        local TextChatService = game:GetService("TextChatService")

        local LocalPlayer = Players.LocalPlayer
        if not LocalPlayer then
            warn("[Stagger] LocalPlayer tidak ditemukan!")
            return
        end

        _G.BotVars = _G.BotVars or {}
        _G.BotVars.ModeControllers =
            _G.BotVars.ModeControllers or {}

        --------------------------------------------------
        -- ADMIN
        --------------------------------------------------

        local success, Admin = pcall(function()
            return loadstring(game:HttpGet(
                "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
            ))()
        end)

        if not success or not Admin then
            warn("[Stagger] Gagal memuat Admin.lua:", Admin)
            return
        end

        --------------------------------------------------
        -- BOT ORDER: 11 BOT
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
        }

        --------------------------------------------------
        -- SETTINGS
        --------------------------------------------------

        local SIDE_SPACING = 3
        local ROW_SPACING = 3

        local active = false
        local connection = nil

        --------------------------------------------------
        -- STOP STAGGER
        --------------------------------------------------

        local function stopStagger()
            active = false

            if connection then
                connection:Disconnect()
                connection = nil
            end
        end

        --------------------------------------------------
        -- POSISI FORMASI
        --------------------------------------------------

        local function getBotPosition(targetHRP, index)

            local row
            local column
            local botsInRow

            if index <= 4 then
                -- Baris 1: B1-B4
                row = 0
                column = index - 1
                botsInRow = 4

            elseif index <= 7 then
                -- Baris 2: B5-B7
                row = 1
                column = index - 5
                botsInRow = 3

            else
                -- Baris 3: B8-B11
                row = 2
                column = index - 8
                botsInRow = 4
            end

            -- Baris tengah digeser setengah jarak
            local rowOffset = 0

            if row == 1 then
                rowOffset = SIDE_SPACING / 2
            end

            local xOffset =
                (column - (botsInRow - 1) / 2) * SIDE_SPACING
                + rowOffset

            local zOffset = ROW_SPACING * (row + 1)

            local targetCF = targetHRP.CFrame

            return targetHRP.Position
                + targetCF.RightVector * xOffset
                - targetCF.LookVector * zOffset
        end

        --------------------------------------------------
        -- START STAGGER
        --------------------------------------------------

        local function startStagger(target)

            stopStagger()

            if not target or not target.Character then
                warn("[Stagger] Target atau Character tidak ditemukan!")
                return
            end

            if not target.Character:FindFirstChild("HumanoidRootPart") then
                warn("[Stagger] HumanoidRootPart target tidak ditemukan!")
                return
            end

            active = true

            print("[Stagger] Aktif untuk:", target.Name)

            connection = RunService.Heartbeat:Connect(function()

                if not active then
                    return
                end

                if not target.Parent or not target.Character then
                    stopStagger()
                    return
                end

                local targetHRP =
                    target.Character:FindFirstChild("HumanoidRootPart")

                if not targetHRP then
                    return
                end

                for index, userId in ipairs(botOrder) do

                    local botPlayer =
                        Players:GetPlayerByUserId(tonumber(userId))

                    if botPlayer and botPlayer.Character then

                        local character = botPlayer.Character

                        local humanoid =
                            character:FindFirstChildOfClass("Humanoid")

                        local botHRP =
                            character:FindFirstChild("HumanoidRootPart")

                        if humanoid and botHRP then

                            local position =
                                getBotPosition(targetHRP, index)

                            humanoid:MoveTo(position)

                            -- Menghadap ke arah yang sama dengan target
                            botHRP.CFrame = CFrame.lookAt(
                                botHRP.Position,
                                botHRP.Position
                                    + targetHRP.CFrame.LookVector
                            )
                        end
                    end
                end
            end)
        end

        --------------------------------------------------
        -- CARI PLAYER BERDASARKAN NAMA
        --------------------------------------------------

        local function findPlayer(name)

            if not name then
                return nil
            end

            name = string.lower(name)

            for _, player in ipairs(Players:GetPlayers()) do
                if string.lower(player.Name) == name
                    or string.lower(player.DisplayName) == name then
                    return player
                end
            end

            return nil
        end

        --------------------------------------------------
        -- COMMAND HANDLER
        --------------------------------------------------

        local function handleCommand(message)

            local args = string.split(
                string.gsub(message, "^%s*(.-)%s*$", "%1"),
                " "
            )

            local command = string.lower(args[1] or "")

            if command == "!stagger" then

                if Admin:IsAdmin(LocalPlayer) then

                    local target = LocalPlayer

                    if args[2] then
                        local foundPlayer = findPlayer(args[2])

                        if not foundPlayer then
                            warn("[Stagger] Player tidak ditemukan:", args[2])
                            return
                        end

                        target = foundPlayer
                    end

                    _G.BotVars.CommandTarget = target
                    _G.BotVars.ActiveMode = "stagger"

                    startStagger(target)
                    return
                end

                -- Target yang telah dipilih admin bisa mengaktifkan formasi
                if _G.BotVars.CommandTarget == LocalPlayer then
                    _G.BotVars.ActiveMode = "stagger"
                    startStagger(LocalPlayer)
                end

                return
            end

            if command == "!stop" or command == "!unstagger" then

                if not Admin:IsAdmin(LocalPlayer) then
                    return
                end

                _G.BotVars.ActiveMode = nil
                _G.BotVars.CommandTarget = nil

                for _, stopFunction
                    in pairs(_G.BotVars.ModeControllers) do

                    if type(stopFunction) == "function" then
                        pcall(stopFunction)
                    end
                end

                print("[Stagger] Semua formasi dihentikan.")
            end
        end

        --------------------------------------------------
        -- CHAT LISTENER
        --------------------------------------------------

        TextChatService.SendingMessage:Connect(function(message)
            if message then
                handleCommand(message.Text)
            end
        end)

        --------------------------------------------------
        -- REGISTER MODE
        --------------------------------------------------

        _G.BotVars.ModeControllers.stagger = stopStagger

        print("[Stagger] Module berhasil aktif.")
    end
}