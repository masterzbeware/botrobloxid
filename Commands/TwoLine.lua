return {
    Execute = function()

        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        local TextChatService = game:GetService("TextChatService")

        local LocalPlayer = Players.LocalPlayer

        if not LocalPlayer then
            warn("[Twoline] LocalPlayer tidak ditemukan!")
            return
        end

        --------------------------------------------------
        -- BOT VARS
        --------------------------------------------------

        _G.BotVars = _G.BotVars or {}
        _G.BotVars.ModeControllers =
            _G.BotVars.ModeControllers or {}

        --------------------------------------------------
        -- ADMIN
        --------------------------------------------------

        local Admin

        local successAdmin, resultAdmin = pcall(function()
            return loadstring(game:HttpGet(
                "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
            ))()
        end)

        if not successAdmin or not resultAdmin then
            warn("[Twoline] Gagal load Admin.lua:", resultAdmin)
            return
        end

        Admin = resultAdmin

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

        --------------------------------------------------
        -- STOP TWOLINE
        --------------------------------------------------

        local function stopTwoline()

            active = false

            if connection then
                connection:Disconnect()
                connection = nil
            end

        end

        --------------------------------------------------
        -- BOT POSITION
        --------------------------------------------------

        local function getBotPosition(targetHRP, botIndex)

            -- 2 BOT SETIAP BARIS
            local botsPerRow = 2

            local row =
                math.floor((botIndex - 1) / botsPerRow)

            local column =
                (botIndex - 1) % botsPerRow

            --------------------------------------------------
            -- KIRI / KANAN
            --------------------------------------------------

            local xOffset

            if column == 0 then
                xOffset = -SIDE_SPACING / 2
            else
                xOffset = SIDE_SPACING / 2
            end

            --------------------------------------------------
            -- JARAK KE BELAKANG
            --------------------------------------------------

            local zOffset =
                ROW_SPACING * (row + 1)

            local targetCF = targetHRP.CFrame

            local position =
                targetHRP.Position
                + targetCF.RightVector * xOffset
                - targetCF.LookVector * zOffset

            return position
        end

        --------------------------------------------------
        -- START TWOLINE
        --------------------------------------------------

        local function startTwoline(target)

            stopTwoline()

            if not target then
                warn("[Twoline] Target tidak ditemukan!")
                return
            end

            if not target.Character then
                warn("[Twoline] Character target tidak ditemukan!")
                return
            end

            local targetHRP =
                target.Character:FindFirstChild("HumanoidRootPart")

            if not targetHRP then
                warn("[Twoline] HumanoidRootPart target tidak ditemukan!")
                return
            end

            active = true

            print(
                "[Twoline] Aktif untuk target:",
                target.Name
            )

            connection = RunService.Heartbeat:Connect(function()

                if not active then
                    return
                end

                --------------------------------------------------
                -- CEK TARGET
                --------------------------------------------------

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

                --------------------------------------------------
                -- GERAKKAN 12 BOT
                --------------------------------------------------

                for index, userId in ipairs(botOrder) do

                    local botPlayer =
                        Players:GetPlayerByUserId(
                            tonumber(userId)
                        )

                    if botPlayer
                        and botPlayer.Character then

                        local humanoid =
                            botPlayer.Character:FindFirstChildOfClass(
                                "Humanoid"
                            )

                        local botHRP =
                            botPlayer.Character:FindFirstChild(
                                "HumanoidRootPart"
                            )

                        if humanoid and botHRP then

                            local position =
                                getBotPosition(
                                    targetHRP,
                                    index
                                )

                            humanoid:MoveTo(position)

                            --------------------------------------------------
                            -- MENGHADAP KE ARAH YANG SAMA DENGAN TARGET
                            --------------------------------------------------

                            botHRP.CFrame =
                                CFrame.lookAt(
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
        -- FIND PLAYER
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

            if not message then
                return
            end

            local args = string.split(
                string.gsub(message, "^%s*(.-)%s*$", "%1"),
                " "
            )

            local command =
                string.lower(args[1] or "")

            --------------------------------------------------
            -- !TWOLINE
            --------------------------------------------------

            if command == "!twoline" then

                print("[Twoline] Command diterima:", message)

                --------------------------------------------------
                -- ADMIN
                --------------------------------------------------

                if Admin:IsAdmin(LocalPlayer) then

                    local target = LocalPlayer

                    --------------------------------------------------
                    -- !twoline Player
                    --------------------------------------------------

                    if args[2] and args[2] ~= "" then

                        local foundPlayer =
                            findPlayer(args[2])

                        if foundPlayer then
                            target = foundPlayer
                        else
                            warn(
                                "[Twoline] Player tidak ditemukan:",
                                args[2]
                            )
                            return
                        end
                    end

                    _G.BotVars.CommandTarget = target
                    _G.BotVars.ActiveMode = "twoline"

                    startTwoline(target)

                    return
                end

                --------------------------------------------------
                -- NON-ADMIN YANG SUDAH MENJADI TARGET
                --------------------------------------------------

                if _G.BotVars.CommandTarget == LocalPlayer then

                    _G.BotVars.ActiveMode = "twoline"

                    startTwoline(LocalPlayer)

                    return
                end

                return
            end

            --------------------------------------------------
            -- !STOP
            --------------------------------------------------

            if command == "!stop"
                or command == "!untwoline" then

                if not Admin:IsAdmin(LocalPlayer) then
                    return
                end

                print("[Twoline] Stop command")

                _G.BotVars.ActiveMode = nil
                _G.BotVars.CommandTarget = nil

                for _, stopFunction
                    in pairs(_G.BotVars.ModeControllers) do

                    if type(stopFunction) == "function" then
                        pcall(stopFunction)
                    end
                end

                return
            end
        end

        --------------------------------------------------
        -- CHAT LISTENER
        --
        -- MENGGUNAKAN SendingMessage
        -- supaya command lokal langsung diproses.
        --------------------------------------------------

        TextChatService.SendingMessage:Connect(
            function(message)

                if not message then
                    return
                end

                handleCommand(message.Text)

            end
        )

        --------------------------------------------------
        -- REGISTER MODE
        --------------------------------------------------

        _G.BotVars.ModeControllers.twoline =
            stopTwoline

        print("[Twoline] Module berhasil aktif.")

    end
}