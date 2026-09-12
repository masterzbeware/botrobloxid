return {
    Execute = function()

        --------------------------------------------------
        -- SERVICES
        --------------------------------------------------

        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        local TextChatService = game:GetService("TextChatService")

        local LocalPlayer = Players.LocalPlayer

        --------------------------------------------------
        -- SHARED VARIABLES
        --------------------------------------------------

        _G.BotVars = _G.BotVars or {}
        _G.BotVars.ModeControllers = _G.BotVars.ModeControllers or {}

        local vars = _G.BotVars

        --------------------------------------------------
        -- BOT ORDER
        --------------------------------------------------

        local BOT_ORDER = {
            "11611503633", -- B1
            "11611534165", -- B2
            "11611567975", -- B3
            "11611562042", -- B4
            "11611591921", -- B5
        }

        --------------------------------------------------
        -- CONFIG
        --------------------------------------------------

        -- Jarak B1 dari Player/Admin
        local firstDistance = 3

        -- Jarak antar baris ke belakang
        local rowSpacing = 3

        -- Jarak kiri / kanan
        local sideSpacing = 2.5

        -- Jarak untuk dianggap sudah sampai posisi
        local stopThreshold = 1.5

        --------------------------------------------------
        -- STATE
        --------------------------------------------------

        local active = false
        local targetPlayer = nil
        local connection = nil

        --------------------------------------------------
        -- FIND PLAYER
        --------------------------------------------------

        local function findPlayer(name)
            if not name or name == "" then
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
        -- GET BOT INDEX
        --------------------------------------------------

        local function getBotIndex()
            local myUserId = tostring(LocalPlayer.UserId)

            for index, userId in ipairs(BOT_ORDER) do
                if userId == myUserId then
                    return index
                end
            end

            return nil
        end

        --------------------------------------------------
        -- GET TARGET
        --------------------------------------------------

        local function getTarget()
            if targetPlayer and targetPlayer.Parent then
                return targetPlayer
            end

            return LocalPlayer
        end

        --------------------------------------------------
        -- GET CHARACTER
        --------------------------------------------------

        local function getHRP(player)
            if not player then
                return nil
            end

            local character = player.Character
            if not character then
                return nil
            end

            return character:FindFirstChild("HumanoidRootPart")
        end

        --------------------------------------------------
        -- STOP
        --------------------------------------------------

        local function stopFormation()

            active = false
            targetPlayer = nil

            if connection then
                connection:Disconnect()
                connection = nil
            end

            if vars.ModeControllers.twowings then
                vars.ModeControllers.twowings = nil
            end

            if vars.ActiveMode == "twowings" then
                vars.ActiveMode = nil
            end

            print("[TwoWings] Formation stopped.")

        end

        --------------------------------------------------
        -- STOP OTHER MODES
        --------------------------------------------------

        local function stopOtherModes()

            for modeName, stopFunction in pairs(vars.ModeControllers) do

                if modeName ~= "twowings" then

                    if typeof(stopFunction) == "function" then
                        pcall(stopFunction)
                    end

                end

            end

        end

        --------------------------------------------------
        -- GET FORMATION POSITION
        --------------------------------------------------

        local function getFormationPosition(targetHRP, botIndex)

            --------------------------------------------------
            -- IMPORTANT
            -- Semua posisi menggunakan arah BELAKANG target.
            --------------------------------------------------

            local backward = -targetHRP.CFrame.LookVector
            local right = targetHRP.CFrame.RightVector

            local backDistance
            local sideOffset

            --------------------------------------------------
            -- B1
            --
            --             B1
            --           PLAYER
            --------------------------------------------------

            if botIndex == 1 then

                backDistance = firstDistance
                sideOffset = 0

            --------------------------------------------------
            -- B2
            --
            --          B2
            --          B1
            --        PLAYER
            --------------------------------------------------

            elseif botIndex == 2 then

                backDistance = firstDistance + rowSpacing
                sideOffset = -sideSpacing

            --------------------------------------------------
            -- B3
            --
            --             B3
            --             B1
            --           PLAYER
            --------------------------------------------------

            elseif botIndex == 3 then

                backDistance = firstDistance + rowSpacing
                sideOffset = sideSpacing

            --------------------------------------------------
            -- B4
            --
            --          B4
            --          B2
            --          B1
            --        PLAYER
            --------------------------------------------------

            elseif botIndex == 4 then

                backDistance = firstDistance + (rowSpacing * 2)
                sideOffset = -sideSpacing

            --------------------------------------------------
            -- B5
            --
            --             B5
            --             B3
            --             B1
            --           PLAYER
            --------------------------------------------------

            elseif botIndex == 5 then

                backDistance = firstDistance + (rowSpacing * 2)
                sideOffset = sideSpacing

            else
                return nil
            end

            --------------------------------------------------
            -- BUILD POSITION
            --------------------------------------------------

            local position =
                targetHRP.Position
                + (backward * backDistance)
                + (right * sideOffset)

            return position

        end

        --------------------------------------------------
        -- MOVE BOT
        --------------------------------------------------

        local function moveBot(targetPosition, targetHRP)

            local character = LocalPlayer.Character
            if not character then
                return
            end

            local humanoid = character:FindFirstChildOfClass("Humanoid")
            local myHRP = character:FindFirstChild("HumanoidRootPart")

            if not humanoid or not myHRP then
                return
            end

            --------------------------------------------------
            -- MOVE
            --------------------------------------------------

            local distance =
                (myHRP.Position - targetPosition).Magnitude

            if distance > stopThreshold then

                humanoid:MoveTo(targetPosition)

            else

                --------------------------------------------------
                -- FACE SAME DIRECTION AS PLAYER/ADMIN
                --------------------------------------------------

                local lookVector = targetHRP.CFrame.LookVector

                local flatLook =
                    Vector3.new(
                        lookVector.X,
                        0,
                        lookVector.Z
                    )

                if flatLook.Magnitude > 0.01 then

                    flatLook = flatLook.Unit

                    myHRP.CFrame =
                        CFrame.lookAt(
                            myHRP.Position,
                            myHRP.Position + flatLook
                        )

                end

            end

        end

        --------------------------------------------------
        -- START FORMATION
        --------------------------------------------------

        local function startFormation(player)

            local botIndex = getBotIndex()

            if not botIndex then
                return
            end

            targetPlayer = player
            active = true

            --------------------------------------------------
            -- STOP OTHER FORMATIONS
            --------------------------------------------------

            stopOtherModes()

            --------------------------------------------------
            -- REGISTER CURRENT MODE
            --------------------------------------------------

            vars.ActiveMode = "twowings"

            vars.ModeControllers.twowings = stopFormation

            --------------------------------------------------
            -- DISCONNECT OLD LOOP
            --------------------------------------------------

            if connection then
                connection:Disconnect()
                connection = nil
            end

            --------------------------------------------------
            -- MAIN LOOP
            --------------------------------------------------

            connection = RunService.Heartbeat:Connect(function()

                if not active then
                    return
                end

                local currentTarget = getTarget()

                if not currentTarget then
                    return
                end

                local targetHRP = getHRP(currentTarget)

                if not targetHRP then
                    return
                end

                local targetPosition =
                    getFormationPosition(
                        targetHRP,
                        botIndex
                    )

                if not targetPosition then
                    return
                end

                moveBot(
                    targetPosition,
                    targetHRP
                )

            end)

            print(
                "[TwoWings] Started. B" ..
                tostring(botIndex) ..
                " following " ..
                currentTargetName(player)
            )

        end

        --------------------------------------------------
        -- TARGET NAME HELPER
        --------------------------------------------------

        function currentTargetName(player)

            if player then
                return player.Name
            end

            return "LocalPlayer"

        end

        --------------------------------------------------
        -- COMMAND HANDLER
        --------------------------------------------------

        local function handleCommand(message)

            if not message then
                return
            end

            local text = message.Text

            if not text then
                return
            end

            text = string.gsub(text, "^%s+", "")
            text = string.gsub(text, "%s+$", "")

            local args = string.split(text, " ")

            local command =
                string.lower(args[1] or "")

            --------------------------------------------------
            -- !twowings
            --------------------------------------------------

            if command == "!twowings" then

                --------------------------------------------------
                -- !twowings PLAYER
                --------------------------------------------------

                if args[2] then

                    local target =
                        findPlayer(args[2])

                    if target then

                        startFormation(target)

                    else

                        warn(
                            "[TwoWings] Player tidak ditemukan: "
                            .. tostring(args[2])
                        )

                    end

                --------------------------------------------------
                -- !twowings
                --------------------------------------------------

                else

                    startFormation(LocalPlayer)

                end

            --------------------------------------------------
            -- !stop
            --------------------------------------------------

            elseif command == "!stop" then

                stopFormation()

            --------------------------------------------------
            -- !untwowings
            --------------------------------------------------

            elseif command == "!untwowings" then

                stopFormation()

            end

        end

        --------------------------------------------------
        -- CHAT CONNECTION
        --------------------------------------------------

        TextChatService.MessageReceived:Connect(function(message)

            pcall(function()

                handleCommand(message)

            end)

        end)

        --------------------------------------------------
        -- READY
        --------------------------------------------------

        print("[TwoWings] Module loaded.")
        print("[TwoWings] Commands:")
        print("  !twowings")
        print("  !twowings PLAYER")
        print("  !stop")
        print("  !untwowings")

    end
}