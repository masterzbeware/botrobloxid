-- Commands/WindowTab.lua

local Library = _G.BotVars.Library
local MainWindow = _G.BotVars.MainWindow

local Tabs = {}

-- Info Tab
Tabs.Info = MainWindow:AddTab("Info", "info")
local InfoGroup = Tabs.Info:AddLeftGroupbox("Bot Info")
InfoGroup:AddLabel("MasterZ HUB v1.0.0")
InfoGroup:AddLabel("Script loaded")

-- Combat Tab
Tabs.Combat = MainWindow:AddTab("Combat", "crosshair")

-- Utility Tab
Tabs.Utility = MainWindow:AddTab("Utility", "tool") -- gunakan icon yang sesuai jika ada

-- Visual Tab
Tabs.Visual = MainWindow:AddTab("Visual", "eye")

-- Save Tabs di global
_G.BotVars.Tabs = Tabs

print("[MasterZ HUB] WindowTab.lua loaded - Tabs siap digunakan.")

return Tabs
