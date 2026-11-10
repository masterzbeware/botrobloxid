-- Administrator/Distance.lua
-- Daftar bot dan pasangan bot untuk sistem formasi/jarak.

local DistanceModule = {}

--------------------------------------------------
-- DAFTAR BOT
--------------------------------------------------

DistanceModule.Bots = {

        ["11954814620"] = "Bot 1",
        ["11954816098"] = "Bot 2",
        ["11960711816"] = "Bot 3",
        ["11611493000"] = "Bot 4",
        ["11611591921"] = "Bot 5",
        ["11611597741"] = "Bot 6",
        ["11672413029"] = "Bot 7",
        ["11122806817"] = "Bot 8",

}


--------------------------------------------------
-- URUTAN BOT
--------------------------------------------------
--
-- Bot 1  - Bot 2
-- Bot 3  - Bot 4
-- Bot 5  - Bot 6
-- Bot 7  - Bot 8
-- Bot 9  - Bot 10
-- Bot 11 - Bot 12
--
-- Jarak antar pasangan = 3
--
--------------------------------------------------


--------------------------------------------------
-- DAFTAR BOT
--------------------------------------------------

DistanceModule.Bots = {
        ["11954814620"] = "Bot 1",
        ["11954816098"] = "Bot 2",

        ["11960711816"] = "Bot 3",
        ["11611493000"] = "Bot 4",

        ["11611591921"] = "Bot 5",
        ["11611597741"] = "Bot 6",
        
        ["11672413029"] = "Bot 7",
        ["11122806817"] = "Bot 8",
}

--------------------------------------------------
-- PASANGAN BOT
--------------------------------------------------
-- Bot 1 - Bot 2
-- Bot 3 - Bot 4
-- Bot 5 - Bot 6
-- Bot 7 - Bot 8
-- Bot 9 tidak memiliki pasangan
-- Jarak antar pasangan = 2
--------------------------------------------------

DistanceModule.Pairs = {
    {
        ["BotA"] = "11954814620",
        ["BotB"] = "11954816098",
        ["Distance"] = 2
    }, -- Bot 1 - Bot 2

    {
        ["BotA"] = "11960711816",
        ["BotB"] = "11611493000",
        ["Distance"] = 2
    }, -- Bot 3 - Bot 4

    {
        ["BotA"] = "11611591921",
        ["BotB"] = "11611597741",
        ["Distance"] = 2
    }, -- Bot 5 - Bot 6

    {
        ["BotA"] = "11672413029",
        ["BotB"] = "11122806817",
        ["Distance"] = 2
    }, -- Bot 7 - Bot 8
}


--------------------------------------------------
-- MENGAMBIL JARAK ANTAR PASANGAN BOT
--------------------------------------------------

function DistanceModule:GetDistance(userIdA, userIdB)

    userIdA = tostring(userIdA)
    userIdB = tostring(userIdB)

    for _, pair in ipairs(self.Pairs) do

        if (
            pair.BotA == userIdA
            and pair.BotB == userIdB
        )
        or (
            pair.BotA == userIdB
            and pair.BotB == userIdA
        ) then

            return pair.Distance

        end

    end

    return nil

end

--------------------------------------------------
-- CEK APAKAH USER ID ADALAH BOT
--------------------------------------------------

function DistanceModule:IsBot(userId)

    return self.Bots[tostring(userId)] ~= nil

end

--------------------------------------------------
-- MENGAMBIL NAMA BOT
--------------------------------------------------

function DistanceModule:GetBotName(userId)

    return self.Bots[tostring(userId)]

end

--------------------------------------------------
-- MENGAMBIL SEMUA BOT
--------------------------------------------------

function DistanceModule:GetBots()

    return self.Bots

end

--------------------------------------------------
-- RETURN MODULE
--------------------------------------------------

return DistanceModule
