--//==================================================
--// THREELINE.LUA
--//==================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")

--//==================================================
--// LOAD MODULES
--//==================================================

local Admin = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
))()

local Distance = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Distance.lua"
))()

--//==================================================
--// GLOBAL BOT VARIABLES
--//==================================================

_G.BotVars = _G.BotVars or {}
_G.BotVars.ModeControllers = _G.BotVars.ModeControllers or {}

--//==================================================
--// LOCAL PLAYER
--//==================================================

local LocalPlayer = Players.LocalPlayer

--//==================================================
--// CONFIG
--//==================================================

local adminFrontDistance = 3
local defaultBotFrontDistance = 2

local sideSpacing = 3
local rowSpacing = 3

local columns = 3

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
--// UPDATE CHARACTER
--//==================================================

local function updateCharacter()

    local character = LocalPlayer.Character

    if not character then
        return false
    end

    humanoid =
        character:FindFirstChildOfClass("Humanoid")
        or character:WaitForChild("Humanoid", 5)

    myHRP =
        character:FindFirstChild("HumanoidRootPart")
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

        local channels =
            TextChatService:WaitForChild("TextChannels", 3)

        local channel =
            channels and channels:FindFirstChild("RBXGeneral")

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

    -- Exact username / display name
    for _, player in ipairs(Players:GetPlayers()) do

        if player.Name:lower() == name
            or player.DisplayName:lower() == name then

            return player
        end

    end

    -- Partial username / display name
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
--// STOP THREELINE
--//==================================================

local function stopThreeline()

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
--// REGISTER THREELINE CONTROLLER
--//==================================================

_G.BotVars.ModeControllers.threeline = {

    Start = function(player)

        --==================================================
        -- STOP SEMUA MODE LAIN
        --==================================================

        for modeName, controller
            in pairs(_G.BotVars.ModeControllers) do

            if modeName ~= "threeline"
                and type(controller) == "table"
                and type(controller.Stop) == "function" then

                pcall(function()
                    controller.Stop()
                end)

            end

        end

        --==================================================
        -- SET ACTIVE MODE
        --==================================================

        _G.BotVars.ActiveMode = "threeline"

        if not player then
            return
        end

        task.spawn(function()

            --==================================================
            -- UPDATE CHARACTER
            --==================================================

            if not updateCharacter() then
                return
            end

            --==================================================
            -- GET BOT INDEX
            --==================================================

            local myIndex = getBotIndex()

            if not myIndex then

                warn(
                    "[Threeline] Bot tidak ditemukan di botOrder:",
                    LocalPlayer.UserId
                )

                return
            end

            --==================================================
            -- STATE
            --==================================================

            targetPlayer = player
            following = true

            sendChat("Yes, Sir!")

            --==================================================
            -- DISCONNECT OLD CONNECTION
            --==================================================

            if followConnection then
                followConnection:Disconnect()
            end

            --==================================================
            -- HEARTBEAT
            --==================================================

            followConnection =
                RunService.Heartbeat:Connect(function()

                --==================================================
                -- ACTIVE MODE CHECK
                --==================================================

                if _G.BotVars.ActiveMode ~= "threeline" then

                    stopThreeline()

                    return
                end

                --==================================================
                -- FOLLOWING CHECK
                --==================================================

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

                    stopThreeline()

                    return
                end

                local targetCharacter =
                    targetPlayer.Character

                if not targetCharacter then
                    return
                end

                local targetHRP =
                    targetCharacter:FindFirstChild(
                        "HumanoidRootPart"
                    )

                if not targetHRP then
                    return
                end

                --==================================================
                -- DISTANCE
                --==================================================

                local distance

                if Admin:IsAdmin(targetPlayer) then

                    distance = adminFrontDistance

                else

                    distance = defaultBotFrontDistance

                end

                --==================================================
                -- CALCULATE ROW
                --==================================================

                local row =
                    math.ceil(myIndex / columns)

                --==================================================
                -- CALCULATE COLUMN
                --==================================================

                local column =
                    ((myIndex - 1) % columns) + 1

                --==================================================
                -- HORIZONTAL POSITION
                --
                -- COLUMN 1 = -3
                -- COLUMN 2 =  0
                -- COLUMN 3 = +3
                --==================================================

                local horizontalOffset =
                    (
                        column
                        - ((columns + 1) / 2)
                    )
                    * sideSpacing

                --==================================================
                -- FORWARD DISTANCE
                --
                -- ROW 1 = distance
                -- ROW 2 = distance + rowSpacing
                -- ROW 3 = distance + rowSpacing * 2
                --==================================================

                local forwardDistance =
                    distance
                    + ((row - 1) * rowSpacing)

                --==================================================
                -- FORWARD OFFSET
                --==================================================

                local forwardOffset =
                    targetHRP.CFrame.LookVector
                    * forwardDistance

                --==================================================
                -- SIDE OFFSET
                --==================================================

                local sideOffset =
                    targetHRP.CFrame.RightVector
                    * horizontalOffset

                --==================================================
                -- FINAL TARGET POSITION
                --==================================================

                local targetPosition =
                    targetHRP.Position
                    + forwardOffset
                    + sideOffset

                --==================================================
                -- DISTANCE FROM BOT
                --==================================================

                local difference =
                    targetPosition - myHRP.Position

                local magnitude =
                    difference.Magnitude

                --==================================================
                -- MOVE
                --==================================================

                if magnitude > stopThreshold then

                    humanoid.AutoRotate = true

                    humanoid:MoveTo(targetPosition)

                else

                    humanoid:Move(Vector3.zero)

                    humanoid.AutoRotate = false

                    --==================================================
                    -- FACE TARGET
                    --==================================================

                    myHRP.CFrame =
                        CFrame.lookAt(
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

    end,

    Stop = stopThreeline,
}

--//==================================================
--// START THREELINE
--//==================================================

local function startThreeline(player)

    if not player then
        return
    end

    --==================================================
    -- STOP FOLLOW / TWOLINE
    --==================================================

    for modeName, controller
        in pairs(_G.BotVars.ModeControllers) do

        if modeName ~= "threeline"
            and type(controller) == "table"
            and type(controller.Stop) == "function" then

            pcall(function()
                controller.Stop()
            end)

        end

    end

    --==================================================
    -- SET ACTIVE MODE
    --==================================================

    _G.BotVars.ActiveMode = "threeline"

    --==================================================
    -- START
    --==================================================

    local controller =
        _G.BotVars.ModeControllers.threeline

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

    --==================================================
    -- ADMIN CHECK
    --==================================================

    if not Admin:IsAdmin(sender) then
        return
    end

    if not message then
        return
    end

    message = message:lower()

    --==================================================
    -- !THREELINE
    --==================================================

    if message == "!threeline" then

        startThreeline(sender)

        return
    end

    --==================================================
    -- !THREELINE PLAYER
    --==================================================

    if message:sub(1, 11) == "!threeline " then

        local playerName =
            message:sub(12)

        local target =
            findPlayerByName(playerName)

        if target then

            startThreeline(target)

        else

            warn(
                "[Threeline] Player tidak ditemukan:",
                playerName
            )

        end

        return
    end

    --==================================================
    -- !STOP
    --==================================================

    if message == "!stop"
        or message == "!unthreeline" then

        _G.BotVars.ActiveMode = nil

        stopThreeline()

        return
    end

end

--//==================================================
--// CHARACTER RESPAWN
--//==================================================

LocalPlayer.CharacterAdded:Connect(function()

    task.wait(1)

    updateCharacter()

    --==================================================
    -- RESUME THREELINE
    --==================================================

    if _G.BotVars.ActiveMode == "threeline"
        and targetPlayer
        and targetPlayer.Parent then

        local target =
            targetPlayer

        task.wait(0.5)

        startThreeline(target)

    end

end)

--//==================================================
--// INITIAL CHARACTER
--//==================================================

updateCharacter()

--//==================================================
--// CHAT HANDLER
--//==================================================

local channels =
    TextChatService:WaitForChild(
        "TextChannels",
        10
    )

local generalChannel =
    channels
    and channels:FindFirstChild("RBXGeneral")

if generalChannel then

    generalChannel.OnIncomingMessage =
        function(message)

        local textSource =
            message.TextSource

        if textSource then

            local sender =
                Players:GetPlayerByUserId(
                    textSource.UserId
                )

            if sender then

                handleCommand(
                    sender,
                    message.Text
                )

            end

        end

        return nil
    end

end

--//==================================================
--// FALLBACK CHAT
--//==================================================

Players.PlayerAdded:Connect(function(player)

    player.Chatted:Connect(function(message)

        handleCommand(
            player,
            message
        )

    end)

end)

for _, player in ipairs(
    Players:GetPlayers()
) do

    player.Chatted:Connect(function(message)

        handleCommand(
            player,
            message
        )

    end)

end

--//==================================================
--// DONE
--//==================================================

print("✅ Threeline.lua loaded")
