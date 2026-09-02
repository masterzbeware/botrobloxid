--//==================================================
--// TWOLINE.LUA
--//==================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//==================================================
--// LOAD MODULES
--//==================================================

local Admin = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
))()

local Distance = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Distance.lua"
))()

_G.BotVars = _G.BotVars or {}
_G.BotVars.ModeControllers = _G.BotVars.ModeControllers or {}

--//==================================================
--// SERVICES / LOCAL PLAYER
--//==================================================

local LocalPlayer = Players.LocalPlayer

--//==================================================
--// CONFIG
--//==================================================

local adminFollowDistance = 3
local defaultBotFollowDistance = 2

local sideSpacing = 2.5
local stopThreshold = 1.5

--//==================================================
--// BOT ORDER
--//==================================================

local botOrder = {
    "11611503633", -- Bot 1
    "11611534165", -- Bot 2
    "11611567975", -- Bot 3
    "11611562042", -- Bot 4
    "11611591921", -- Bot 5
    "11122806815", -- Bot 6
    "11122806817", -- Bot 7
    "11122687468", -- Bot 8
    "11122854402", -- Bot 9
}

--//==================================================
--// STATE
--//==================================================

local humanoid = nil
local myHRP = nil

local following = false
local targetPlayer = nil
local followConnection = nil

--//==================================================
--// CHARACTER UPDATE
--//==================================================

local function updateCharacter()
    local character = LocalPlayer.Character

    if not character then
        return false
    end

    humanoid = character:FindFirstChildOfClass("Humanoid")
        or character:WaitForChild("Humanoid", 5)

    myHRP = character:FindFirstChild("HumanoidRootPart")
        or character:WaitForChild("HumanoidRootPart", 5)

    if humanoid then
        humanoid.AutoRotate = true
    end

    return humanoid ~= nil and myHRP ~= nil
end

--//==================================================
--// SEND CHAT
--//==================================================

local function sendChat(text)
    pcall(function()
        local channels = TextChatService:WaitForChild("TextChannels", 3)
        local channel = channels and channels:FindFirstChild("RBXGeneral")

        if channel then
            channel:SendAsync(text)
        end
    end)
end

--//==================================================
--// FIND PLAYER
--//==================================================

local function findPlayerByName(name)
    if not name or name == "" then
        return nil
    end

    name = name:lower()

    -- Exact match
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Name:lower() == name
            or player.DisplayName:lower() == name then

            return player
        end
    end

    -- Partial match
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Name:lower():find(name, 1, true)
            or player.DisplayName:lower():find(name, 1, true) then

            return player
        end
    end

    return nil
end

--//==================================================
--// GET BOT INDEX
--//==================================================

local function getBotIndex()
    local userId = tostring(LocalPlayer.UserId)

    for index, botId in ipairs(botOrder) do
        if botId == userId then
            return index
        end
    end

    return nil
end

--//==================================================
--// STOP TWOLINE
--//==================================================

local function stopTwoline()
    following = false
    targetPlayer = nil

    if followConnection then
        followConnection:Disconnect()
        followConnection = nil
    end

    if humanoid then
        humanoid.AutoRotate = true
        humanoid:Move(Vector3.zero)
    end
end

--//==================================================
--// REGISTER MODE CONTROLLER
--//==================================================

_G.BotVars.ModeControllers.twoline = {
    Start = function(player)
        -- Stop semua mode lain terlebih dahulu
        for modeName, controller in pairs(_G.BotVars.ModeControllers) do
            if modeName ~= "twoline"
                and type(controller) == "table"
                and type(controller.Stop) == "function" then

                pcall(function()
                    controller.Stop()
                end)
            end
        end

        _G.BotVars.ActiveMode = "twoline"

        if player then
            -- Jalankan Twoline
            task.spawn(function()

                if not updateCharacter() then
                    return
                end

                local myIndex = getBotIndex()

                if not myIndex then
                    warn("[Twoline] Bot tidak ditemukan di botOrder:", LocalPlayer.UserId)
                    return
                end

                targetPlayer = player
                following = true

                sendChat("Yes, Sir!")

                if followConnection then
                    followConnection:Disconnect()
                end

                followConnection = RunService.Heartbeat:Connect(function()

                    --==================================================
                    -- MODE CHECK
                    --==================================================

                    if _G.BotVars.ActiveMode ~= "twoline" then
                        stopTwoline()
                        return
                    end

                    if not following then
                        return
                    end

                    --==================================================
                    -- CHARACTER CHECK
                    --==================================================

                    if not LocalPlayer.Character
                        or not humanoid
                        or not myHRP then

                        if not updateCharacter() then
                            return
                        end
                    end

                    --==================================================
                    -- TARGET CHECK
                    --==================================================

                    if not targetPlayer
                        or not targetPlayer.Parent then

                        stopTwoline()
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

                    --==================================================
                    -- DISTANCE
                    --==================================================

                    local distance

                    if Admin:IsAdmin(targetPlayer) then
                        distance = adminFollowDistance
                    else
                        distance = defaultBotFollowDistance
                    end

                    --==================================================
                    -- TWO LINE POSITION
                    --
                    -- BOT 1    BOT 2
                    -- BOT 3    BOT 4
                    -- BOT 5    BOT 6
                    -- BOT 7    BOT 8
                    -- BOT 9
                    --
                    --             TARGET
                    --==================================================

                    local column
                    local row

                    if myIndex % 2 == 1 then
                        -- Kiri
                        column = -1
                        row = math.ceil(myIndex / 2)
                    else
                        -- Kanan
                        column = 1
                        row = myIndex / 2
                    end

                    --==================================================
                    -- BACK OFFSET
                    --==================================================

                    local backOffset =
                        targetHRP.CFrame.LookVector
                        * -(distance * row)

                    --==================================================
                    -- SIDE OFFSET
                    --==================================================

                    local sideOffset =
                        targetHRP.CFrame.RightVector
                        * (sideSpacing * column)

                    --==================================================
                    -- FINAL POSITION
                    --==================================================

                    local targetPosition =
                        targetHRP.Position
                        + backOffset
                        + sideOffset

                    local currentPosition = myHRP.Position

                    local difference =
                        targetPosition - currentPosition

                    local magnitude = difference.Magnitude

                    --==================================================
                    -- MOVE
                    --==================================================

                    if magnitude > stopThreshold then

                        humanoid.AutoRotate = true

                        humanoid:MoveTo(targetPosition)

                    else

                        humanoid:Move(Vector3.zero)

                        humanoid.AutoRotate = false

                        -- Menghadap arah target
                        myHRP.CFrame = CFrame.lookAt(
                            myHRP.Position,
                            Vector3.new(
                                targetHRP.Position.X,
                                myHRP.Position.Y,
                                targetHRP.Position.Z
                            )
                        )
                    end
                end)
            end)
        end
    end,

    Stop = stopTwoline,
}

--//==================================================
--// START TWOLINE
--//==================================================

local function startTwoline(player)

    if not player then
        return
    end

    -- Stop semua mode lain
    for modeName, controller in pairs(_G.BotVars.ModeControllers) do

        if modeName ~= "twoline"
            and type(controller) == "table"
            and type(controller.Stop) == "function" then

            pcall(function()
                controller.Stop()
            end)
        end
    end

    -- Set active mode
    _G.BotVars.ActiveMode = "twoline"

    -- Jalankan controller
    local controller = _G.BotVars.ModeControllers.twoline

    if controller and controller.Start then
        controller.Start(player)
    end
end

--//==================================================
--// COMMAND HANDLER
--//==================================================

local function handleCommand(sender, message)

    if not sender then
        return
    end

    if not Admin:IsAdmin(sender) then
        return
    end

    if not message then
        return
    end

    message = message:lower()

    --==================================================
    -- !TWOLINE
    --==================================================

    if message == "!twoline" then

        startTwoline(sender)
        return
    end

    --==================================================
    -- !TWOLINE PLAYER
    --==================================================

    if message:sub(1, 9) == "!twoline " then

        local playerName = message:sub(10)
        local target = findPlayerByName(playerName)

        if target then

            startTwoline(target)

        else

            warn("[Twoline] Player tidak ditemukan:", playerName)

        end

        return
    end

    --==================================================
    -- !STOP
    --==================================================

    if message == "!stop" or message == "!untwoline" then

        _G.BotVars.ActiveMode = nil
        stopTwoline()

        return
    end
end

--//==================================================
--// CHARACTER RESPAWN
--//==================================================

LocalPlayer.CharacterAdded:Connect(function()

    task.wait(1)

    updateCharacter()

    -- Jika Twoline masih menjadi mode aktif,
    -- jalankan kembali setelah respawn.
    if _G.BotVars.ActiveMode == "twoline"
        and targetPlayer
        and targetPlayer.Parent then

        local target = targetPlayer

        task.wait(0.5)

        startTwoline(target)
    end
end)

--==================================================
-- INITIAL CHARACTER
--==================================================

updateCharacter()

--==================================================
-- CHAT HANDLER
--==================================================

local channels = TextChatService:WaitForChild("TextChannels", 10)
local generalChannel = channels and channels:FindFirstChild("RBXGeneral")

if generalChannel then

    generalChannel.OnIncomingMessage = function(message)

        local textSource = message.TextSource

        if textSource then

            local sender = Players:GetPlayerByUserId(
                textSource.UserId
            )

            if sender then
                handleCommand(sender, message.Text)
            end
        end

        return nil
    end

end

--==================================================
-- FALLBACK CHAT
--==================================================

Players.PlayerAdded:Connect(function(player)

    player.Chatted:Connect(function(message)
        handleCommand(player, message)
    end)

end)

for _, player in ipairs(Players:GetPlayers()) do

    player.Chatted:Connect(function(message)
        handleCommand(player, message)
    end)

end

--==================================================
-- DONE
--==================================================

print("✅ Twoline.lua loaded")