-- WindowTab.lua
-- Bertugas membuat semua tab untuk MasterZ HUB

local Library = _G.BotVars.Library
local MainWindow = _G.BotVars.MainWindow

local Tabs = {}

-- 1️⃣ Tab Info
Tabs.Info = MainWindow:AddTab("Info", "info") -- icon opsional
local InfoGroup = Tabs.Info:AddLeftGroupbox("Bot Info")
InfoGroup:AddLabel("MasterZ HUB v1.5.0")
InfoGroup:AddLabel("Script loaded ✅")

-- 2️⃣ Tab Combat (Headshot + AIM)
Tabs.Combat = MainWindow:AddTab("Combat", "crosshair") -- Headshot & AIM ditempatkan di sini

-- 3️⃣ Tab Visual (ESP)
Tabs.Visual = MainWindow:AddTab("Visual", "eye") -- ESP ditempatkan di sini

-- Opsional: daftar module untuk tiap tab
Tabs.Modules = {
    Info   = {},               -- module yang ingin ditaruh di Info
    Combat = { "Headshot", "AIM" },  -- Headshot + AIM
    Visual = { "ESP" },        -- ESP
}

return Tabs
