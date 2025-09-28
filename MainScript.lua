-- Bot.lua
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local Options = Library.Options

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")
local localPlayer = Players.LocalPlayer
local clientName = "FiestaGuardVip"

-- Global variables
_G.toggleAktif = false
_G.followAllowed = false
_G.shieldActive = false
_G.rowActive = false
_G.jarakIkut = 5
_G.followSpacing = 2
_G.shieldDistance = 5
_G.shieldSpacing = 4
_G.rowSpacing = 4
_G.sideSpacing = 4
_G.currentFormasiTarget = nil
_G.client = nil
_G.humanoid = nil
_G.myRootPart = nil
_G.moving = false

-- Bot Mapping
_G.botMapping = {
    ["8802945328"] = "Bot1 - XBODYGUARDVIP01",
    ["8802949363"] = "Bot2 - XBODYGUARDVIP02",
    ["8802939883"] = "Bot3 - XBODYGUARDVIP03",
    ["8802998147"] = "Bot4 - XBODYGUARDVIP04",
}
_G.botIdentity = _G.botMapping[tostring(localPlayer.UserId)] or "Unknown Bot"

-- UI setup
local Window = Library:CreateWindow({
    Title = "Made by MasterZ",
    Footer = "v16.0.0",
    Icon = 0,
    NotifySide = "Right",
    ShowCustomCursor = true,
})

local Tabs = {
    Main = Window:AddTab("Main", "user")
}

local GroupBox1 = Tabs.Main:AddLeftGroupbox("Main Options")
GroupBox1:AddInput("BotIdentity", { Default = _G.botIdentity, Text = "Bot Identity", Placeholder = "Auto-detected bot info" })
GroupBox1:AddToggle("AktifkanFollow", { Text = "Enable Bot Follow", Default = false, Callback = function(value) _G.toggleAktif = value end })

-- Load all commands dynamically
local commandFiles = {"ikuti", "stop", "shield", "row", "sync"}
for _, cmd in ipairs(commandFiles) do
    local success, err = pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Commands/"..cmd..".lua"))()
    end)
    if not success then
        warn("Failed to load command: "..cmd..".lua", err)
    end
end

-- MoveTo helper
function _G.moveToPosition(targetPos, lookAtPos)
    if not _G.humanoid or not _G.myRootPart then return end
    if _G.moving then return end
    if ( _G.myRootPart.Position - targetPos ).Magnitude < 2 then return end

    _G.moving = true
    _G.humanoid:MoveTo(targetPos)
    _G.humanoid.MoveToFinished:Wait()
    _G.moving = false

    if lookAtPos then
        _G.myRootPart.CFrame = CFrame.new(_G.myRootPart.Position, Vector3.new(lookAtPos.X, _G.myRootPart.Position.Y, lookAtPos.Z))
    end
end

-- Update bot references
function _G.updateBotRefs()
    local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
    _G.humanoid = character:WaitForChild("Humanoid")
    _G.myRootPart = character:WaitForChild("HumanoidRootPart")
end

-- Start follow loop
RunService.Heartbeat:Connect(function()
    if _G.toggleAktif and _G.currentFormasiTarget and _G.currentFormasiTarget.Character and _G.humanoid and _G.myRootPart then
        -- Commands handle movement internally
    end
end)
