-- Commands/Box.lua
-- Admin-only BOX formation
--
-- Commands:
-- !box
-- !box <username|displayname>
--
-- FORMATION:
--
-- BG1   BG2   BG3
--
-- BG4    VIP   BG5
--
-- BG6   BG7   BG8
--
-- BG9   BG10 (rear support)

return {
    Execute = function()

        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        local TextChatService = game:GetService("TextChatService")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")

        local LocalPlayer = Players.LocalPlayer
        if not LocalPlayer then
            return
        end

        ----------------------------------------------------------------
        -- LOAD ADMIN MODULE
        ----------------------------------------------------------------
        local Admin = loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
        ))()

        ----------------------------------------------------------------
        -- CHARACTER
        ----------------------------------------------------------------
        local humanoid
        local myHRP

        local function updateCharacter()

            local char =
                LocalPlayer.Character
                or LocalPlayer.CharacterAdded:Wait()

            humanoid = char:WaitForChild("Humanoid")
            myHRP = char:WaitForChild("HumanoidRootPart")
        end

        updateCharacter()
        LocalPlayer.CharacterAdded:Connect(updateCharacter)

        ----------------------------------------------------------------
        -- BOT ORDER
        ----------------------------------------------------------------
        local botOrder = {
            "11001608049", -- BG1
            "11001625681", -- BG2
            "11001647769", -- BG3
            "11002716767", -- BG4
            "11002763516", -- BG5
            "11002833908", -- BG6
            "11002919499", -- BG7
            "11002918670", -- BG8
            "11007692539", -- BG9
            "11008102483", -- BG10
        }

        ----------------------------------------------------------------
        -- CHAT
        ----------------------------------------------------------------
        local function sendChat(msg)

            local success = false

            if TextChatService
            and TextChatService.TextChannels then

                local channel =
                    TextChatService.TextChannels
                    :FindFirstChild("RBXGeneral")

                if channel then

                    pcall(function()
                        channel:SendAsync(msg)
                    end)

                    success = true
                end
            end

            if not success then

                pcall(function()

                    ReplicatedStorage
                        .DefaultChatSystemChatEvents
                        .SayMessageRequest
                        :FireServer(msg, "All")
                end)
            end
        end

        ----------------------------------------------------------------
        -- FIND PLAYER
        ----------------------------------------------------------------
local function findPlayerByName(name)

    name = name:lower()

    for _, player in ipairs(Players:GetPlayers()) do

        local username =
            player.Name:lower()

        local displayname =
            player.DisplayName:lower()

        --------------------------------------------------------
        -- EXACT MATCH
        --------------------------------------------------------
        if username == name
        or displayname == name then

            return player
        end

        --------------------------------------------------------
        -- PARTIAL MATCH
        --------------------------------------------------------
        if username:find(name, 1, true)
        or displayname:find(name, 1, true) then

            return player
        end
    end

    return nil
end

        ----------------------------------------------------------------
        -- FORMATION STATE
        ----------------------------------------------------------------
        local active = false
        local targetPlayer
        local followConnection

        ----------------------------------------------------------------
        -- STOP FORMATION
        ----------------------------------------------------------------
        local function stopFormation()

            active = false
            targetPlayer = nil

            if humanoid then
                humanoid.AutoRotate = true
            end

            if followConnection then
                followConnection:Disconnect()
                followConnection = nil
            end
        end

        ----------------------------------------------------------------
        -- BOX OFFSETS
        --
        -- Negative Z = depan VIP
        -- Positive Z = belakang VIP
        ----------------------------------------------------------------
        local formationOffsets = {

            ------------------------------------------------------------
            -- FRONT LINE
            ------------------------------------------------------------
            [1] = Vector3.new(-6, 0, -8),
            [2] = Vector3.new( 0, 0, -8),
            [3] = Vector3.new( 6, 0, -8),

            ------------------------------------------------------------
            -- VIP SIDE PROTECTION
            -- Sejajar dengan VIP
            ------------------------------------------------------------
            [4] = Vector3.new(-4.5, 0, 0),
            [5] = Vector3.new( 4.5, 0, 0),

            ------------------------------------------------------------
            -- BACK LINE
            ------------------------------------------------------------
            [6] = Vector3.new(-6, 0, 8),
            [7] = Vector3.new( 0, 0, 8),
            [8] = Vector3.new( 6, 0, 8),

            ------------------------------------------------------------
            -- REAR SUPPORT
            ------------------------------------------------------------
            [9]  = Vector3.new(-3, 0, 14),
            [10] = Vector3.new( 3, 0, 14),
        }

        ----------------------------------------------------------------
        -- START BOX
        ----------------------------------------------------------------
        local function startBox(player)

            if not player then
                return
            end

            if player == LocalPlayer then
                stopFormation()
                return
            end

            stopFormation()

            active = true
            targetPlayer = player

            sendChat("Box Formation!")

            ------------------------------------------------------------
            -- FIND BOT POSITION
            ------------------------------------------------------------
            local myOrder = table.find(
                botOrder,
                tostring(LocalPlayer.UserId)
            )

            if not myOrder then
                stopFormation()
                return
            end

            local myOffset = formationOffsets[myOrder]

            if not myOffset then
                stopFormation()
                return
            end

            humanoid.AutoRotate = false

            ------------------------------------------------------------
            -- FOLLOW LOOP
            ------------------------------------------------------------
            followConnection = RunService.Heartbeat:Connect(function()

                if not active then return end
                if not targetPlayer then return end
                if not targetPlayer.Character then return end
                if not humanoid then return end
                if not myHRP then return end

                local hrp =
                    targetPlayer.Character
                    :FindFirstChild("HumanoidRootPart")

                if not hrp then
                    return
                end

                --------------------------------------------------------
                -- TARGET POSITION
                --------------------------------------------------------
                local targetPosition =
                    hrp.CFrame:PointToWorldSpace(myOffset)

                humanoid:MoveTo(targetPosition)

                --------------------------------------------------------
                -- FACE SAME DIRECTION AS VIP
                --------------------------------------------------------
                local distance =
                    (myHRP.Position - targetPosition).Magnitude

                if distance <= 3 then

                    local lookPosition =
                        myHRP.Position
                        + hrp.CFrame.LookVector

                    myHRP.CFrame = CFrame.lookAt(
                        myHRP.Position,
                        lookPosition
                    )
                end
            end)
        end

        ----------------------------------------------------------------
        -- COMMAND HANDLER
        ----------------------------------------------------------------
        local function handleCommand(msg, sender)

            if not Admin:IsAdmin(sender) then
                return
            end

            local lower = msg:lower()

            ------------------------------------------------------------
            -- !box
            ------------------------------------------------------------
            if lower == "!box" then

                startBox(sender)
                return
            end

            ------------------------------------------------------------
            -- !box username
            ------------------------------------------------------------
            local targetName =
                lower:match("^!box%s+(.+)$")

            if targetName then

                local target =
                    findPlayerByName(targetName)

                if target then
                    startBox(target)
                end

                return
            end

            ------------------------------------------------------------
            -- STOP
            ------------------------------------------------------------
            if lower == "!stop"
            or lower == "!unbox" then

                stopFormation()
                return
            end
        end

        ----------------------------------------------------------------
        -- TEXT CHAT SERVICE
        ----------------------------------------------------------------
        if TextChatService
        and TextChatService.TextChannels then

            local channel =
                TextChatService.TextChannels
                :FindFirstChild("RBXGeneral")

            if channel then

                channel.OnIncomingMessage = function(message)

                    local userId =
                        message.TextSource
                        and message.TextSource.UserId

                    local sender =
                        userId
                        and Players:GetPlayerByUserId(userId)

                    if sender then
                        handleCommand(message.Text, sender)
                    end
                end
            end
        end

        ----------------------------------------------------------------
        -- LEGACY CHAT FALLBACK
        ----------------------------------------------------------------
        for _, player in ipairs(Players:GetPlayers()) do

            player.Chatted:Connect(function(msg)
                handleCommand(msg, player)
            end)
        end

        Players.PlayerAdded:Connect(function(player)

            player.Chatted:Connect(function(msg)
                handleCommand(msg, player)
            end)
        end)
    end
}