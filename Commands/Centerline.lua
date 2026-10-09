return {
    Execute = function()

        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        local TextChatService = game:GetService("TextChatService")

        local LocalPlayer = Players.LocalPlayer
        if not LocalPlayer then
            warn("[Centerline] LocalPlayer tidak ditemukan!")
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
            warn("[Centerline] Gagal memuat Admin.lua:", Admin)
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

        local SPACING = 3

        local active = false
        local connection = nil

        --------------------------------------------------
        -- STOP CENTERLINE
        --------------------------------------------------

        local function stopCenterline()
            active = false

            if connection then
                connection:Disconnect()
                connection = nil
            end
        end

        --------------------------------------------------
        -- POSISI BOT
        --------------------------------------------------

        local function getBotPosition(targetHRP, index)

            -- Bot 1-6 di kiri, Bot 7-12 di kanan.
            -- Index kiri diurutkan dari luar menuju tengah.
            local xOffset

            if index <= 6 then
                xOffset = -(7 - index) * SPACING
            else
                xOffset = (index - 6) * SPACING
            end

            local targetCF = targetHRP.CFrame

            return targetHRP.Position
                + targetCF.RightVector * xOffset
        end

        --------------------------------------------------
        -- START CENTERLINE
        --------------------------------------------------

        local function startCenterline(target)

            stopCenterline()

            if not target or not target.Character then
                warn("[Centerline] Target atau Character tidak ditemukan!")
                return
            end

            if not target.Character:FindFirstChild("HumanoidRootPart") then
                warn("[Centerline] HumanoidRootPart target tidak ditemukan!")
                return
            end

            active = true

            print("[Centerline] Aktif untuk:", target.Name)

            connection = RunService.Heartbeat:Connect(function()

                if not active then
                    return
                end

                if not target.Parent or not target.Character then
                    stopCenterline()
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

                            -- Semua bot menghadap arah yang sama
                            -- dengan Admin/Player.
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
        -- CARI PLAYER
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

            if command == "!centerline" then

                print("[Centerline] Command diterima:", message)

                if Admin:IsAdmin(LocalPlayer) then

                    local target = LocalPlayer

                    if args[2] and args[2] ~= "" then

                        local foundPlayer = findPlayer(args[2])

                        if not foundPlayer then
                            warn(
                                "[Centerline] Player tidak ditemukan:",
                                args[2]
                            )
                            return
                        end

                        target = foundPlayer
                    end

                    _G.BotVars.CommandTarget = target
                    _G.BotVars.ActiveMode = "centerline"

                    startCenterline(target)
                    return
                end

                -- Target pilihan admin bisa mengaktifkan formasi
                if _G.BotVars.CommandTarget == LocalPlayer then
                    _G.BotVars.ActiveMode = "centerline"
                    startCenterline(LocalPlayer)
                end

                return
            end

            if command == "!stop"
                or command == "!uncenterline" then

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

                print("[Centerline] Semua formasi dihentikan.")
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

        _G.BotVars.ModeControllers.centerline = stopCenterline

        print("[Centerline] Module berhasil aktif.")
    end
}