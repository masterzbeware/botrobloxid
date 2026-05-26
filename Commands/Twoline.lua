-- Commands/Twoline.lua
-- Admin-only follow system (TWO LINE formation)
-- Supports: !twoline / !twoline <username|displayname>

return {
    Execute = function()
        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        local TextChatService = game:GetService("TextChatService")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")

        local LocalPlayer = Players.LocalPlayer
        if not LocalPlayer then return end

        -- LOAD ADMIN MODULE
        local Admin = loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
        ))()

        -- LOAD DISTANCE MODULE
        local Distance = loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Distance.lua"
        ))()

        local humanoid, myHRP
        local following = false
        local targetPlayer
        local followConnection

        local adminFollowDistance = 3
        local defaultBotFollowDistance = 2
        local sideSpacing = 2.5

        ----------------------------------------------------------------
        -- UPDATE CHARACTER
        ----------------------------------------------------------------
        local function updateCharacter()
            local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            humanoid = char:WaitForChild("Humanoid")
            myHRP = char:WaitForChild("HumanoidRootPart")
        end
        updateCharacter()
        LocalPlayer.CharacterAdded:Connect(updateCharacter)

        ----------------------------------------------------------------
        -- SEND CHAT
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
                    ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest
                        :FireServer(msg, "All")
                end)
            end
        end

        ----------------------------------------------------------------
        -- STOP FOLLOW
        ----------------------------------------------------------------
        local function stopFollow()
            following = false
            targetPlayer = nil
            if followConnection then
                followConnection:Disconnect()
                followConnection = nil
            end
        end

        ----------------------------------------------------------------
        -- FIND PLAYER BY NAME / DISPLAY NAME
        ----------------------------------------------------------------
        local function findPlayerByName(name)
            name = name:lower()
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Name:lower() == name or p.DisplayName:lower() == name then
                    return p
                end
            end
            return nil
        end

        ----------------------------------------------------------------
        -- START TWOLINE FOLLOW
        ----------------------------------------------------------------
        local function startFollow(player)
            if not player then return end

            stopFollow()
            following = true
            targetPlayer = player
            sendChat("Yes, Sir!")

            -- BOT ORDER
            local botOrder = {
            "11001608049", -- Bot 1
            "11001625681", -- Bot 2
            "11001647769", -- Bot 3
            "11002716767", -- Bot 4
            "11002763516", -- Bot 5
            "11002833908", -- Bot 6
            "11002919499", -- Bot 7
            "11002918670", -- Bot 8
            "11007692539", -- Bot 9
            }

            local myIndex = table.find(botOrder, tostring(LocalPlayer.UserId))
            if not myIndex then return end

            followConnection = RunService.Heartbeat:Connect(function()
                if not following or not humanoid or not myHRP then return end
                if not targetPlayer.Character then return end

                local hrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
                if not hrp then return end

                -- DISTANCE
                local distance = defaultBotFollowDistance
                if Admin:IsAdmin(targetPlayer) then
                    distance = adminFollowDistance
                end

                local special = Distance:GetDistance(
                    tostring(LocalPlayer.UserId),
                    tostring(targetPlayer.UserId)
                )
                if special then
                    distance = special
                end

--- FORMATION TWO LINE
-- Bot1 Bot2 Bot3 Bot4
-- Bot5 Bot6 Bot7 Bot8
--       Bot9

local rightVector = hrp.CFrame.RightVector
local lookVector = hrp.CFrame.LookVector

local rowIndex
local columnIndex

if myIndex >= 1 and myIndex <= 4 then
    -- Baris pertama: Bot1 - Bot4
    rowIndex = 1
    columnIndex = myIndex

elseif myIndex >= 5 and myIndex <= 8 then
    -- Baris kedua: Bot5 - Bot8
    rowIndex = 2
    columnIndex = myIndex - 4

elseif myIndex == 9 then
    -- Bot9 paling belakang tengah
    rowIndex = 3
    columnIndex = 2.5

else
    return
end

local centerOffset = columnIndex - 2.5

local backOffset = lookVector * -(distance * rowIndex)
local sideOffset = rightVector * (centerOffset * sideSpacing)

local targetPosition = hrp.Position + backOffset + sideOffset
humanoid:MoveTo(targetPosition)

        ----------------------------------------------------------------
        -- COMMAND HANDLER (ADMIN ONLY)
        ----------------------------------------------------------------
        local function handleCommand(msg, sender)
            if not Admin:IsAdmin(sender) then return end

            local lower = msg:lower()

            -- !twoline
            if lower == "!twoline" then
                startFollow(sender)
                return
            end

            -- !twoline <name>
            local targetName = lower:match("^!twoline%s+(.+)$")
            if targetName then
                local target = findPlayerByName(targetName)
                if target then
                    startFollow(target)
                end
                return
            end            

            -- stop
            if lower == "!stop" or lower == "!unfollow" then
                stopFollow()
            end
        end

        ----------------------------------------------------------------
        -- TEXT CHAT SERVICE
        ----------------------------------------------------------------
        if TextChatService and TextChatService.TextChannels then
            local ch = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
            if ch then
                ch.OnIncomingMessage = function(message)
                    local uid = message.TextSource and message.TextSource.UserId
                    local sender = uid and Players:GetPlayerByUserId(uid)
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
