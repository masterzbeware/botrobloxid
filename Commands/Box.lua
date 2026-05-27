-- Commands/Box.lua
-- Admin-only BOX formation
-- Command:
-- !box
-- !box <username|displayname>
--
-- FORMATION:
--
--        BG7
--
-- BG1   BG2   BG3
--
-- BG4    VIP   BG5
--
-- BG6   BG7   BG8
--
-- Sisa bot otomatis di belakang

return {
    Execute = function()

        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        local TextChatService = game:GetService("TextChatService")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")

        local LocalPlayer = Players.LocalPlayer
        if not LocalPlayer then return end

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
            local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

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
            local ok = false

            if TextChatService and TextChatService.TextChannels then
                local ch = TextChatService.TextChannels:FindFirstChild("RBXGeneral")

                if ch then
                    pcall(function()
                        ch:SendAsync(msg)
                    end)

                    ok = true
                end
            end

            if not ok then
                pcall(function()
                    ReplicatedStorage.DefaultChatSystemChatEvents
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

            for _, p in ipairs(Players:GetPlayers()) do
                if p.Name:lower() == name
                or p.DisplayName:lower() == name then
                    return p
                end
            end

            return nil
        end

        ----------------------------------------------------------------
        -- FORMATION
        ----------------------------------------------------------------
        local active = false
        local targetPlayer
        local followConnection

        ----------------------------------------------------------------
        -- STOP
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
        -- BOX POSITIONS
        ----------------------------------------------------------------
        local formationOffsets = {

            -- BG1 BG2 BG3 (depan)
            [1] = Vector3.new(-6,0,-8),
            [2] = Vector3.new(0,0,-8),
            [3] = Vector3.new(6,0,-8),

            -- BG4 VIP BG5 (tengah)
            [4] = Vector3.new(-6,0,0),
            [5] = Vector3.new(6,0,0),

            -- BG6 BG7 BG8 (belakang)
            [6] = Vector3.new(-6,0,8),
            [7] = Vector3.new(0,0,8),
            [8] = Vector3.new(6,0,8),

            -- sisa di belakang lagi
            [9] = Vector3.new(-3,0,14),
            [10] = Vector3.new(3,0,14),
        }

        ----------------------------------------------------------------
        -- START BOX
        ----------------------------------------------------------------
        local function startBox(player)

            if not player then return end

            if player == LocalPlayer then
                stopFormation()
                return
            end

            stopFormation()

            active = true
            targetPlayer = player

            sendChat("Box Formation!")

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

            followConnection = RunService.Heartbeat:Connect(function()

                if not active then return end
                if not targetPlayer then return end
                if not targetPlayer.Character then return end
                if not humanoid then return end
                if not myHRP then return end

                local hrp = targetPlayer.Character:FindFirstChild(
                    "HumanoidRootPart"
                )

                if not hrp then return end

                --------------------------------------------------------
                -- POSITION
                --------------------------------------------------------
                local targetPosition =
                    hrp.CFrame:PointToWorldSpace(myOffset)

                humanoid:MoveTo(targetPosition)

                --------------------------------------------------------
                -- FACE SAME DIRECTION AS LEADER
                --------------------------------------------------------
                local distance =
                    (myHRP.Position - targetPosition).Magnitude

                if distance <= 3 then

                    local lookPos =
                        myHRP.Position + hrp.CFrame.LookVector

                    myHRP.CFrame =
                        CFrame.lookAt(myHRP.Position, lookPos)
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
            local targetName = lower:match("^!box%s+(.+)$")

            if targetName then

                local target = findPlayerByName(targetName)

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
        -- TEXTCHATSERVICE
        ----------------------------------------------------------------
        if TextChatService and TextChatService.TextChannels then

            local ch =
                TextChatService.TextChannels:FindFirstChild("RBXGeneral")

            if ch then

                ch.OnIncomingMessage = function(message)

                    local uid =
                        message.TextSource
                        and message.TextSource.UserId

                    local sender =
                        uid and Players:GetPlayerByUserId(uid)

                    if sender then
                        handleCommand(message.Text, sender)
                    end
                end
            end
        end

        ----------------------------------------------------------------
        -- FALLBACK CHAT
        ----------------------------------------------------------------
        for _, p in ipairs(Players:GetPlayers()) do

            p.Chatted:Connect(function(msg)
                handleCommand(msg, p)
            end)
        end

        Players.PlayerAdded:Connect(function(p)

            p.Chatted:Connect(function(msg)
                handleCommand(msg, p)
            end)
        end)
    end
}