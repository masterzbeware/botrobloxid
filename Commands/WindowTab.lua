-- Commands/WindowTab.lua
-- Menyediakan tab utama untuk MasterZ HUB dan disimpan global di _G.BotVars.Tabs

local Library = _G.BotVars.Library
local MainWindow = _G.BotVars.MainWindow
local Tabs = {}

Tabs.Info = MainWindow:AddTab("Info", "info")
local InfoGroup = Tabs.Info:AddLeftGroupbox("Bot Info")
InfoGroup:AddLabel("MasterZ HUB v1.0.0")
InfoGroup:AddLabel("Script loaded ✅")

Tabs.Combat = MainWindow:AddTab("Combat", "crosshair")
Tabs.Visual = MainWindow:AddTab("Visual", "eye")
Tabs.Misc = MainWindow:AddTab("Misc", "settings")

_G.BotVars.Tabs = Tabs

print("[MasterZ HUB] WindowTab.lua loaded — Semua tab siap digunakan.")

return Tabs
