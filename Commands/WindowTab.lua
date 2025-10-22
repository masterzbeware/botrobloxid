-- Commands/WindowTab.lua
-- Membuat semua tab utama untuk MasterZ HUB dan disimpan global di _G.BotVars.Tabs

local Library = _G.BotVars.Library
local MainWindow = _G.BotVars.MainWindow

local Tabs = {}

-- INFO TAB
Tabs.Info = MainWindow:AddTab("Info", "info")
local InfoGroup = Tabs.Info:AddLeftGroupbox("Bot Info")
InfoGroup:AddLabel("MasterZ HUB v1.0.0")
InfoGroup:AddLabel("Script loaded")

-- COMBAT TAB (Headshot + AIM + Reload)
Tabs.Combat = MainWindow:AddTab("Combat", "crosshair")
-- Buat groupbox kosong untuk modul lain menambahkan toggle
Tabs.Combat.LeftGroup = Tabs.Combat:AddLeftGroupbox("Left Controls")
Tabs.Combat.RightGroup = Tabs.Combat:AddRightGroupbox("Right Controls")

-- VISUAL TAB (ESP)
Tabs.Visual = MainWindow:AddTab("Visual", "eye")
-- Buat groupbox kosong agar modul ESP bisa menambahkan toggle
Tabs.Visual.LeftGroup = Tabs.Visual:AddLeftGroupbox("Visual Controls")
Tabs.Visual.RightGroup = Tabs.Visual:AddRightGroupbox("Additional Controls")

-- Simpan ke global agar module lain bisa akses
_G.BotVars.Tabs = Tabs

print("[MasterZ HUB] WindowTab.lua loaded - Tabs siap digunakan.")

return Tabs
