-- Bot.lua
-- MasterZ Beware Bot System (tanpa cursor, crosshair, atau ikon mouse apapun)

local repoBase     = "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Commands/"
local obsidianRepo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"

local Library = loadstring(game:HttpGet(obsidianRepo .. "Library.lua"))()

local function debugPrint(msg)
    print("[DEBUG] " .. tostring(msg))
end

_G.BotVars = {
    Players = game:GetService("Players"),
    TextChatService = game:GetService("TextChatService"),
    RunService = game:GetService("RunService"),
    LocalPlayer = game:GetService("Players").LocalPlayer,
    ToggleAktif = false,
}

local player = _G.BotVars.LocalPlayer
local Mouse = player:GetMouse()
local UserInputService = game:GetService("UserInputService")

pcall(function()
    UserInputService.MouseIconEnabled = false
    if player and player:FindFirstChild("PlayerGui") then
        for _, gui in ipairs(player.PlayerGui:GetDescendants()) do
            if gui:IsA("ImageLabel") or gui:IsA("ImageButton") then
                if gui.Name:lower():find("cursor") or gui.Name:lower():find("cross") then
                    gui:Destroy()
                end
            end
        end
    end
    Mouse.Icon = ""
    player.CharacterAdded:Connect(function(char)
        task.wait(1)
        for _, tool in ipairs(player.Backpack:GetChildren()) do
            if tool:IsA("Tool") then
                tool.Equipped:Connect(function()
                    Mouse.Icon = ""
                    UserInputService.MouseIconEnabled = false
                end)
                tool.Unequipped:Connect(function()
                    Mouse.Icon = ""
                end)
            end
        end
    end)
    player.Backpack.ChildAdded:Connect(function(tool)
        if tool:IsA("Tool") then
            tool.Equipped:Connect(function()
                Mouse.Icon = ""
                UserInputService.MouseIconEnabled = false
            end)
        end
    end)
end)

local MainWindow = Library:CreateWindow({
    Title = "MasterZ HUB",
    Footer = "1.0.0",
    Icon = 0,
})

_G.BotVars.Library = Library
_G.BotVars.MainWindow = MainWindow

local VIPCommands = {}
local commandFiles = { "Headshot.lua","ESP.lua","AIM.lua","Hide.lua","WindowTab.lua","NoRecoil.lua" }

local function loadScripts(files, repo, targetTable)
    for _, fileName in ipairs(files) do
        local url = repo .. fileName
        local success, response = pcall(function() return game:HttpGet(url) end)
        if success and response then
            local func = loadstring(response)
            if func then
                local status, cmdTable = pcall(func)
                if status and type(cmdTable) == "table" then
                    local nameKey = fileName:sub(1, #fileName - 4)
                    targetTable[nameKey:lower()] = cmdTable
                    debugPrint("Loaded module: " .. nameKey)
                end
            end
        else
            warn("Failed to load " .. fileName)
        end
    end
end

loadScripts(commandFiles, repoBase, VIPCommands)
_G.BotVars.CommandFiles = VIPCommands

for name, module in pairs(VIPCommands) do
    if module.Execute then
        debugPrint("Running UI module: " .. name)
        module.Execute()
    end
end

debugPrint("✅ Bot.lua loaded — semua UI aktif tanpa kursor atau crosshair.")
