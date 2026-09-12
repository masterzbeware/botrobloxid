```lua
return {
    Execute = function()

        --------------------------------------------------
        -- SERVICES
        --------------------------------------------------

        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        local TextChatService = game:GetService("TextChatService")

        local LocalPlayer = Players.LocalPlayer

        if not LocalPlayer then
            return
        end

        --------------------------------------------------
        -- GLOBAL
        --------------------------------------------------

        _G.BotVars = _G.BotVars or {}
        _G.BotVars.ModeControllers = _G.BotVars.ModeControllers or {}

        local vars = _G.BotVars

        --------------------------------------------------
        -- LOAD ADMIN
        --------------------------------------------------

        local Admin = loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
        ))()

        --------------------------------------------------
        -- BOT ORDER
        --------------------------------------------------
        -- B1 = tengah
        -- B2 = kiri
        -- B3 = kanan
        -- B4 = kiri
        -- B5 = kanan

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

        -- Jarak setiap baris ke belakang
        local rowSpacing = 3

        -- Jarak kiri / kanan
        local sideSpacing = 2.5

        -- Jarak minimum sebelum dianggap sampai
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

            name = name:lower()

            --------------------------------------------------
            -- EXACT
            --------------------------------------------------

            for _, player in ipairs(Players:GetPlayers()) do

                if player.Name:lower() == name
                    or player.DisplayName:lower() == name then

                    return player

                end

            end

            --------------------------------------------------
            -- PARTIAL
            --------------------------------------------------

            for _, player in ipairs(Players:GetPlayers()) do

                if player.Name:lower():find(
                    name,
                    1,
                    true
                )
                    or player.DisplayName:lower():find(
                        name,
                        1,
                        true
                    ) then

                    return player

                end

            end

            return nil

        end

        --------------------------------------------------
        -- GET BOT INDEX
        --------------------------------------------------

        local function getBotIndex()

            local userId =
                tostring(LocalPlayer.UserId)

            for index, botUserId in ipairs(BOT_ORDER) do

                if botUserId == userId then
                    return index
                end

            end

            return nil

        end

        --------------------------------------------------
        -- GET CHARACTER HRP
        --------------------------------------------------

        local function getHRP(player)

            if not player then
                return nil
            end

            local character =
                player.Character

            if not character then
                return nil
            end

            return character:FindFirstChild(
                "HumanoidRootPart"
            )

        end

        --------------------------------------------------
        -- GET HUMANOID
        --------------------------------------------------

        local function getHumanoid()

            local character =
                LocalPlayer.Character

            if not character then
                return nil
            end

            return character:FindFirstChildOfClass(
                "Humanoid"
            )

        end

        --------------------------------------------------
        -- STOP FORMATION
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

            print(
                "[TwoWings] Formation stopped."
            )

        end

        --------------------------------------------------
        -- STOP OTHER MODES
        --------------------------------------------------

        local function stopOtherModes()

            for modeName, stopFunction in pairs(
                vars.ModeControllers
            ) do

                if modeName ~= "twowings" then

                    if type(stopFunction) == "function" then

                        pcall(stopFunction)

                    end

                end

            end

        end

        --------------------------------------------------
        -- GET FORMATION POSITION
        --------------------------------------------------
        --
        -- FORMASI:
        --
        --              B4       B5
        --              B2       B3
        --                  B1
        --                PLAYER
        --
        --------------------------------------------------

        local function getFormationPosition(
            targetHRP,
            botIndex
        )

            if not targetHRP then
                return nil
            end

            --------------------------------------------------
            -- ARAH BELAKANG PLAYER
            --------------------------------------------------

            local backward =
                -targetHRP.CFrame.LookVector

            --------------------------------------------------
            -- ARAH KANAN PLAYER
            --------------------------------------------------

            local right =
                targetHRP.CFrame.RightVector

            --------------------------------------------------
            -- B1
            --------------------------------------------------
            -- Tengah tepat di belakang Player
            --
            --              B1
            --            PLAYER
            --------------------------------------------------

            if botIndex == 1 then

                return targetHRP.Position
                    + (
                        backward
                        * firstDistance
                    )

            end

            --------------------------------------------------
            -- B2
            --------------------------------------------------
            -- Kiri belakang B1
            --
            --             B1
            --          B2
            --        PLAYER
            --------------------------------------------------

            if botIndex == 2 then

                return targetHRP.Position
                    + (
                        backward
                        * (
                            firstDistance
                            + rowSpacing
                        )
                    )
                    + (
                        right
                        * -sideSpacing
                    )

            end

            --------------------------------------------------
            -- B3
            --------------------------------------------------
            -- Kanan belakang B1
            --
            --             B1
            --          B2    B3
            --        PLAYER
            --------------------------------------------------

            if botIndex == 3 then

                return targetHRP.Position
                    + (
                        backward
                        * (
                            firstDistance
                            + rowSpacing
                        )
                    )
                    + (
                        right
                        * sideSpacing
                    )

            end

            --------------------------------------------------
            -- B4
            --------------------------------------------------
            -- Kiri belakang B2
            --
            --             B1
            --          B2    B3
            --       B4
            --        PLAYER
            --------------------------------------------------

            if botIndex == 4 then

                return targetHRP.Position
                    + (
                        backward
                        * (
                            firstDistance
                            + (
                                rowSpacing
                                * 2
                            )
                        )
                    )
                    + (
                        right
                        * -sideSpacing
                    )

            end

            --------------------------------------------------
            -- B5
            --------------------------------------------------
            -- Kanan belakang B3
            --
            --             B1
            --          B2    B3
            --       B4    B5
            --        PLAYER
            --------------------------------------------------

            if botIndex == 5 then

                return targetHRP.Position
                    + (
                        backward
                        * (
                            firstDistance
                            + (
                                rowSpacing
                                * 2
                            )
                        )
                    )
                    + (
                        right
                        * sideSpacing
                    )

            end

            return nil

        end

        --------------------------------------------------
        -- MOVE BOT
        --------------------------------------------------

        local function moveBot(
            targetPosition,
            targetHRP
        )

            local character =
                LocalPlayer.Character

            if not character then
                return
            end

            local humanoid =
                character:FindFirstChildOfClass(
                    "Humanoid"
                )

            local myHRP =
                character:FindFirstChild(
                    "HumanoidRootPart"
                )

            if not humanoid or not myHRP then
                return
            end

            --------------------------------------------------
            -- DISTANCE
            --------------------------------------------------

            local distance =
                (
                    myHRP.Position
                    - targetPosition
                ).Magnitude

            --------------------------------------------------
            -- MOVE
            --------------------------------------------------

            if distance > stopThreshold then

                humanoid.AutoRotate = true

                humanoid:MoveTo(
                    targetPosition
                )

                return

            end

            --------------------------------------------------
            -- SUDAH SAMPAI
            --------------------------------------------------

            humanoid.AutoRotate = false

            --------------------------------------------------
            -- HADAP SAMA DENGAN PLAYER
            --------------------------------------------------

            local lookVector =
                targetHRP.CFrame.LookVector

            local flatLook =
                Vector3.new(
                    lookVector.X,
                    0,
                    lookVector.Z
                )

            if flatLook.Magnitude > 0.01 then

                flatLook =
                    flatLook.Unit

                myHRP.CFrame =
                    CFrame.lookAt(
                        myHRP.Position,
                        myHRP.Position
                        + flatLook
                    )

            end

        end

        --------------------------------------------------
        -- START FORMATION
        --------------------------------------------------

        local function startFormation(player)

            if not player then
                return
            end

            --------------------------------------------------
            -- CEK ADMIN
            --------------------------------------------------

            if not Admin:IsAdmin(player) then
                return
            end

            --------------------------------------------------
            -- CEK BOT
            --------------------------------------------------

            local botIndex =
                getBotIndex()

            if not botIndex then

                return

            end

            --------------------------------------------------
            -- STOP MODE LAIN
            --------------------------------------------------

            stopOtherModes()

            --------------------------------------------------
            -- SET TARGET
            --------------------------------------------------

            targetPlayer = player
            active = true

            --------------------------------------------------
            -- SET ACTIVE MODE
            --------------------------------------------------

            vars.ActiveMode =
                "twowings"

            vars.ModeControllers.twowings =
                stopFormation

            --------------------------------------------------
            -- DISCONNECT LOOP LAMA
            --------------------------------------------------

            if connection then

                connection:Disconnect()
                connection = nil

            end

            --------------------------------------------------
            -- MAIN LOOP
            --------------------------------------------------

            connection =
                RunService.Heartbeat:Connect(
                    function()

                        --------------------------------------------------
                        -- CHECK ACTIVE MODE
                        --------------------------------------------------

                        if not active then
                            return
                        end

                        if vars.ActiveMode
                            ~= "twowings" then

                            stopFormation()

                            return

                        end

                        --------------------------------------------------
                        -- TARGET
                        --------------------------------------------------

                        if not targetPlayer
                            or not targetPlayer.Parent then

                            return

                        end

                        local targetHRP =
                            getHRP(targetPlayer)

                        if not targetHRP then
                            return
                        end

                        --------------------------------------------------
                        -- POSITION
                        --------------------------------------------------

                        local targetPosition =
                            getFormationPosition(
                                targetHRP,
                                botIndex
                            )

                        if not targetPosition then
                            return
                        end

                        --------------------------------------------------
                        -- MOVE
                        --------------------------------------------------

                        moveBot(
                            targetPosition,
                            targetHRP
                        )

                    end
                )

            print(
                "[TwoWings] B"
                .. tostring(botIndex)
                .. " following "
                .. targetPlayer.Name
            )

        end

        --------------------------------------------------
        -- COMMAND HANDLER
        --------------------------------------------------

        local function handleCommand(
            message,
            sender
        )

            if not message then
                return
            end

            if not sender then
                return
            end

            --------------------------------------------------
            -- ADMIN ONLY
            --------------------------------------------------

            if not Admin:IsAdmin(sender) then
                return
            end

            --------------------------------------------------
            -- CLEAN MESSAGE
            --------------------------------------------------

            local text =
                tostring(message)

            text =
                text:gsub(
                    "^%s+",
                    ""
                )

            text =
                text:gsub(
                    "%s+$",
                    ""
                )

            local lower =
                text:lower()

            --------------------------------------------------
            -- !TWOWINGS
            --------------------------------------------------
            -- Target = Admin yang mengetik command
            --------------------------------------------------

            if lower == "!twowings" then

                startFormation(sender)

                return

            end

            --------------------------------------------------
            -- !TWOWINGS PLAYER
            --------------------------------------------------

            local targetName =
                lower:match(
                    "^!twowings%s+(.+)$"
                )

            if targetName then

                local target =
                    findPlayer(
                        targetName
                    )

                if target then

                    startFormation(target)

                else

                    warn(
                        "[TwoWings] Player tidak ditemukan: "
                        .. tostring(targetName)
                    )

                end

                return

            end

            --------------------------------------------------
            -- !UNTWOWINGS
            --------------------------------------------------

            if lower == "!untwowings" then

                stopFormation()

                return

            end

            --------------------------------------------------
            -- !STOP
            --------------------------------------------------

            if lower == "!stop" then

                stopFormation()

                return

            end

        end

        --------------------------------------------------
        -- REGISTER CONTROLLER
        --------------------------------------------------

        vars.ModeControllers.twowings =
            stopFormation

        --------------------------------------------------
        -- TEXT CHAT
        --------------------------------------------------

        if TextChatService
            and TextChatService.TextChannels then

            local channel =
                TextChatService.TextChannels:
                FindFirstChild(
                    "RBXGeneral"
                )

            if channel then

                channel.OnIncomingMessage =
                    function(message)

                        local userId =
                            message.TextSource
                            and message.TextSource.UserId

                        if not userId then
                            return
                        end

                        local sender =
                            Players:GetPlayerByUserId(
                                userId
                            )

                        if sender then

                            handleCommand(
                                message.Text,
                                sender
                            )

                        end

                    end

            end

        end

        --------------------------------------------------
        -- FALLBACK CHAT
        --------------------------------------------------

        for _, player in ipairs(
            Players:GetPlayers()
        ) do

            player.Chatted:Connect(
                function(message)

                    handleCommand(
                        message,
                        player
                    )

                end
            )

        end

        --------------------------------------------------
        -- PLAYER ADDED
        --------------------------------------------------

        Players.PlayerAdded:Connect(
            function(player)

                player.Chatted:Connect(
                    function(message)

                        handleCommand(
                            message,
                            player
                        )

                    end
                )

            end
        )

        --------------------------------------------------
        -- CHARACTER RESPAWN
        --------------------------------------------------

        LocalPlayer.CharacterAdded:Connect(
            function()

                task.wait(1)

                if vars.ActiveMode
                    == "twowings"
                    and targetPlayer then

                    startFormation(
                        targetPlayer
                    )

                end

            end
        )

        --------------------------------------------------
        -- READY
        --------------------------------------------------

        print(
            "[TwoWings] Module loaded."
        )

        print(
            "[TwoWings] Formation:"
        )

        print(
            "             B4       B5"
        )

        print(
            "             B2       B3"
        )

        print(
            "                 B1"
        )

        print(
            "               PLAYER"
        )

        print(
            "[TwoWings] Commands:"
        )

        print(
            "  !twowings"
        )

        print(
            "  !twowings PLAYER"
        )

        print(
            "  !stop"
        )

        print(
            "  !untwowings"
        )

    end
}