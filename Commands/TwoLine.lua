return {
    Execute = function()

        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")

        local LocalPlayer = Players.LocalPlayer
        if not LocalPlayer then
            return
        end

        _G.BotVars = _G.BotVars or {}
        _G.BotVars.ModeControllers = _G.BotVars.ModeControllers or {}

        -- =========================
        -- ADMIN
        -- =========================

        local Admin = loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
        ))()

        -- =========================
        -- BOT ORDER
        -- =========================

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

        -- =========================
        -- SETTINGS
        -- =========================

        local SIDE_SPACING = 3
        local ROW_SPACING = 3

        local connection = nil
        local active = false

        -- =========================
        -- STOP FORMATION
        -- =========================

        local function stopTwoline()
            active = false

            if connection then
                connection:Disconnect()
                connection = nil
            end
        end

        -- Hentikan formasi sebelumnya
        if _G.BotVars.ModeControllers.twoline then
            _G.BotVars.ModeControllers.twoline()
        end

        -- =========================
        -- GET BOT POSITION
        -- =========================

        local function getBotPosition(targetHRP, botIndex)

            -- 2 bot setiap baris
            local botsPerRow = 2

            local row = math.floor((botIndex - 1) / botsPerRow)
            local column = (botIndex - 1) % botsPerRow

            -- Posisi kiri / kanan
            local xOffset

            if column == 0 then
                xOffset = -SIDE_SPACING / 2
            else
                xOffset = SIDE_SPACING / 2
            end

            -- Semakin ke bawah, semakin jauh ke belakang
            local zOffset = ROW_SPACING * (row + 1)

            local targetCF = targetHRP.CFrame

            local position =
                targetHRP.Position
                + targetCF.RightVector * xOffset
                - targetCF.LookVector * zOffset

            return position
        end

        -- =========================
        -- FIND TARGET
        -- =========================

        local function getTarget()
            local target = _G.BotVars.CommandTarget

            if not target then
                return nil
            end

            if not target.Character then
                return nil
            end

            return target
        end

        -- =========================
        -- START TWOLINE
        -- =========================

        local function startTwoline(target)

            stopTwoline()

            if not target then
                return
            end

            if not target.Character then
                return
            end

            local targetHRP =
                target.Character:FindFirstChild("HumanoidRootPart")

            if not targetHRP then
                return
            end

            active = true

            connection = RunService.Heartbeat:Connect(function()

                if not active then
                    return
                end

                -- Pastikan target masih valid
                if not target.Parent then
                    stopTwoline()
                    return
                end

                if not target.Character then
                    return
                end

                targetHRP =
                    target.Character:FindFirstChild("HumanoidRootPart")

                if not targetHRP then
                    return
                end

                for index, userId in ipairs(botOrder) do

                    local botPlayer =
                        Players:GetPlayerByUserId(tonumber(userId))

                    if botPlayer
                        and botPlayer.Character then

                        local humanoid =
                            botPlayer.Character:FindFirstChildOfClass("Humanoid")

                        local botHRP =
                            botPlayer.Character:FindFirstChild("HumanoidRootPart")

                        if humanoid and botHRP then

                            local position =
                                getBotPosition(targetHRP, index)

                            humanoid:MoveTo(position)

                            -- Bot menghadap arah yang sama dengan Admin/Player
                            botHRP.CFrame = CFrame.lookAt(
                                botHRP.Position,
                                botHRP.Position + targetHRP.CFrame.LookVector
                            )
                        end
                    end
                end
            end)
        end

        -- =========================
        -- COMMAND HANDLER
        -- =========================

        local function handleCommand(message)

            local args = string.split(message, " ")
            local command = string.lower(args[1] or "")

            -- =====================
            -- !TWOLINE
            -- =====================

            if command == "!twoline" then

                local sender = LocalPlayer

                -- Admin bisa menentukan target
                if Admin:IsAdmin(sender) then

                    local target = sender

                    if args[2] then

                        local requestedName =
                            string.lower(args[2])

                        for _, player in ipairs(Players:GetPlayers()) do

                            if string.lower(player.Name)
                                == requestedName
                                or string.lower(player.DisplayName)
                                == requestedName then

                                target = player
                                break
                            end
                        end
                    end

                    _G.BotVars.CommandTarget = target

                    _G.BotVars.ActiveMode = "twoline"

                    startTwoline(target)

                    return
                end

                -- Player yang sudah menjadi CommandTarget
                if _G.BotVars.CommandTarget == sender then

                    _G.BotVars.ActiveMode = "twoline"

                    startTwoline(sender)

                    return
                end

                return
            end

            -- =====================
            -- !STOP / !UNTWOLINE
            -- =====================

            if command == "!stop"
                or command == "!untwoline" then

                if not Admin:IsAdmin(LocalPlayer) then
                    return
                end

                _G.BotVars.ActiveMode = nil
                _G.BotVars.CommandTarget = nil

                -- Hentikan semua mode
                for _, stopFunction
                    in pairs(_G.BotVars.ModeControllers) do

                    if type(stopFunction) == "function" then
                        pcall(stopFunction)
                    end
                end

                return
            end
        end

        -- =========================
        -- CHAT CONNECTION
        -- =========================

        local TextChatService =
            game:GetService("TextChatService")

        TextChatService.MessageReceived:Connect(function(message)

            if not message.TextSource then
                return
            end

            if message.TextSource.UserId ~= LocalPlayer.UserId then
                return
            end

            handleCommand(message.Text)
        end)

        -- =========================
        -- REGISTER MODE
        -- =========================

        _G.BotVars.ModeControllers.twoline = stopTwoline

    end
}