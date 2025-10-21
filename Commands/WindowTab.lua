-- Commands/WindowTab.lua
-- Membuat semua tab utama untuk MasterZ HUB dan disimpan global di _G.BotVars.Tabs

local Library = _G.BotVars.Library
local MainWindow = _G.BotVars.MainWindow

local Tabs = {}

-- 🧠 INFO TAB
Tabs.Info = MainWindow:AddTab("Info", "info")
local InfoGroup = Tabs.Info:AddLeftGroupbox("Bot Info")
InfoGroup:AddLabel("MasterZ HUB v1.5.0")
InfoGroup:AddLabel("Script loaded ✅")

-- 🎯 COMBAT TAB (Headshot + AIM)
Tabs.Combat = MainWindow:AddTab("Combat", "crosshair")

-- 👁️ VISUAL TAB (ESP)
Tabs.Visual = MainWindow:AddTab("Visual", "eye")

-- Simpan ke global agar module lain bisa akses
_G.BotVars.Tabs = Tabs

print("[MasterZ HUB] WindowTab.lua loaded — Tabs siap digunakan.")

return Tabs
