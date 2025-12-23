-- Administrator/Distance.lua
-- Daftar Bot dan jarak antar pasangan

local DistanceModule = {}

-- ✅ Daftar Bot
DistanceModule.Bots = {
    ["10191476366"] = "Bot 1",
    ["10191480511"] = "Bot 2",
    ["10191462654"] = "Bot 3",
    ["10190853828"] = "Bot 4",
    ["10191023081"] = "Bot 5",
    ["10191070611"] = "Bot 6",
    ["10191489151"] = "Bot 7",
    ["10191571531"] = "Bot 8",
}

-- ✅ Pasangan Bot dan jaraknya (UserId sesuai daftar Bots)
DistanceModule.Pairs = {
    {["BotA"] = "10191476366", ["BotB"] = "10191480511", ["Distance"] = 3}, -- Bot1-Bot2
    {["BotA"] = "10191462654", ["BotB"] = "10190853828", ["Distance"] = 3}, -- Bot3-Bot4
    {["BotA"] = "10191023081", ["BotB"] = "10191070611", ["Distance"] = 3}, -- Bot5-Bot6
    {["BotA"] = "10191489151", ["BotB"] = "10191571531", ["Distance"] = 3}, -- Bot7-Bot8
}

-- ✅ Fungsi untuk mengambil jarak pasangan
function DistanceModule:GetDistance(userIdA, userIdB)
    for _, pair in ipairs(self.Pairs) do
        if (pair.BotA == userIdA and pair.BotB == userIdB) or (pair.BotA == userIdB and pair.BotB == userIdA)
