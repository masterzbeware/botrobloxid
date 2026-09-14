-- Squat.lua
-- Menjalankan 1 emote Squat untuk semua bot yang menerima command.

local Players = game:GetService("Players")

local Admin = require(script.Parent:WaitForChild("Admin.lua"))
local Distance = require(script.Parent:WaitForChild("Distance.lua"))

local SQUAT_EMOTE_ID = "87939646671209"

local botOrder = {
    {name = "Bot 1", id = 1},
    {name = "Bot 2", id = 2},
    {name = "Bot 3", id = 3},
    {name = "Bot 4", id = 4},
    {name = "Bot 5", id = 5},
    {name = "Bot 6", id = 6},
    {name = "Bot 7", id = 7},
    {name = "Bot 8", id = 8},
    {name = "Bot 9", id = 9},
    {name = "Bot 10", id = 10},
    {name = "Bot 11", id = 11},
}

local botId
for _, bot in ipairs(botOrder) do
    if bot.name == script.Parent.Name then
        botId = bot.id
        break
    end
end

local function isAdmin(player)
    return Admin[player.UserId] == true
end

local modeControllers = _G.BotVars and _G.BotVars.ModeControllers
if not modeControllers then
    modeControllers = {}
    _G.BotVars = _G.BotVars or {}
    _G.BotVars.ModeControllers = modeControllers
end

local squatTrack
local squatting = false
local squatGeneration = 0

local function restoreNormalAnimation(generation)
    if generation and generation ~= squatGeneration then
        return
    end

    if squatTrack then
        pcall(function()
            squatTrack:Stop(0.15)
        end)
        squatTrack = nil
    end

    local character = script.Parent
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return
    end

    for _, track in ipairs(humanoid:GetPlayingAnimationTracks()) do
        if track.Priority == Enum.AnimationPriority.Action then
            pcall(function()
                track:Stop(0.15)
            end)
        end
    end

    local animate = character:FindFirstChild("Animate")
    if animate then
        animate.Disabled = true
        task.wait()
        animate.Disabled = false
    end

    humanoid:ChangeState(Enum.HumanoidStateType.Running)

    local currentGeneration = generation or squatGeneration
    task.defer(function()
        task.wait(0.1)

        if currentGeneration ~= squatGeneration or squatting then
            return
        end

        local currentHumanoid = character:FindFirstChildOfClass("Humanoid")
        if currentHumanoid then
            currentHumanoid:ChangeState(Enum.HumanoidStateType.Running)
        end
    end)
end

local function stopOtherModes()
    for modeName, controller in pairs(modeControllers) do
        if modeName ~= "squat" and type(controller) == "function" then
            pcall(controller)
        end
    end
end

local function stopSquat()
    squatGeneration += 1
    local generation = squatGeneration

    squatting = false
    restoreNormalAnimation(generation)
end

local function playSquat()
    squatGeneration += 1
    local generation = squatGeneration

    squatting = true
    _G.BotVars.ActiveMode = "squat"

    stopOtherModes()

    if squatTrack then
        pcall(function()
            squatTrack:Stop(0.1)
        end)
        squatTrack = nil
    end

    local character = script.Parent
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        squatting = false
        return
    end

    local success, track = pcall(function()
        return humanoid:PlayEmoteAndGetAnimTrackById(SQUAT_EMOTE_ID)
    end)

    if generation ~= squatGeneration or not squatting then
        if success and track then
            pcall(function()
                track:Stop(0.1)
            end)
        end
        return
    end

    if success and track then
        squatTrack = track

        task.spawn(function()
            local finishedTrack = track
            pcall(function()
                finishedTrack.Stopped:Wait()
            end)

            if squatGeneration == generation and squatTrack == finishedTrack then
                squatTrack = nil
                squatting = false
            end
        end)
    else
        squatting = false
    end
end

modeControllers.squat = stopSquat

local function handleCommand(player, message)
    if not isAdmin(player) then
        return
    end

    local command = message:lower():match("^%s*(%S+)")
    if not command then
        return
    end

    if command == "!squat" then
        playSquat()
    elseif command == "!unsquat" or command == "!stop" then
        stopSquat()
    end
end

local function setupCharacter(character)
    character:WaitForChild("Humanoid")

    if _G.BotVars.ActiveMode == "squat" then
        squatGeneration += 1
        task.defer(function()
            task.wait(0.2)
            if _G.BotVars.ActiveMode == "squat" then
                playSquat()
            end
        end)
    end
end

local function setupChat(player)
    if player.Chatted then
        player.Chatted:Connect(function(message)
            handleCommand(player, message)
        end)
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    setupChat(player)
end

Players.PlayerAdded:Connect(setupChat)

script.Parent.CharacterAdded:Connect(setupCharacter)

return {
    Execute = function()
        return true
    end
}
