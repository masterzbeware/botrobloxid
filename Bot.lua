-- Bot.lua
-- Made by MasterZ

local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local Options = Library.Options

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")
local localPlayer = Players.LocalPlayer

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

-- UI Setup
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
GroupBox1:AddToggle("AktifkanFollow", { Text = "Enable Bot Follow", Default = false, Callback = function(value)
    _G.toggleAktif = value
    print("[DEBUG] ToggleAktif set to: "..tostring(value))
end })

-- MoveTo Helper
function _G.moveToPosition(targetPos, lookAtPos)
    if not _G.humanoid or not _G.myRootPart then return end
    if _G.moving then return end
    if (_G.myRootPart.Position - targetPos).Magnitude < 2 then return end

    _G.moving = true
    _G.humanoid:MoveTo(targetPos)
    _G.humanoid.MoveToFinished:Wait()
    _G.moving = false

    if lookAtPos then
        _G.myRootPart.CFrame = CFrame.new(_G.myRootPart.Position, Vector3.new(lookAtPos.X, _G.myRootPart.Position.Y, lookAtPos.Z))
    end
end

-- Update Bot References
function _G.updateBotRefs()
    local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
    _G.humanoid = character:WaitForChild("Humanoid")
    _G.myRootPart = character:WaitForChild("HumanoidRootPart")
    print("[DEBUG] Bot references updated")
end

-- Load Commands
local commandFiles = {"ikuti", "stop", "shield", "row", "sync"}
for _, cmd in ipairs(commandFiles) do
    local url = "https://raw.githubusercontent.com/<username>/botrobloxid/main/Commands/"..cmd..".lua" -- Ganti <username> dengan username GitHub mu
    local success, err = pcall(function()
        local scriptString = game:HttpGet(url)
        loadstring(scriptString)()
    end)
    if not success then
        warn("[ERROR] Failed to load command: "..cmd..".lua. Check URL:", url)
        warn(err)
    else
        print("[INFO] Loaded command: "..cmd..".lua")
    end
end

-- Follow Loop
RunService.Heartbeat:Connect(function()
    if _G.toggleAktif and _G.currentFormasiTarget and _G.currentFormasiTarget.Character and _G.humanoid and _G.myRootPart then
        -- Movement handled by commands
    end
end)

-- Update references on respawn
localPlayer.CharacterAdded:Connect(_G.updateBotRefs)
if localPlayer.Character then _G.updateBotRefs() end
