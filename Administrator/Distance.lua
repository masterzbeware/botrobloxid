-- Administrator/Distance.lua
-- Daftar bot dan pasangan bot untuk sistem formasi/jarak.

local DistanceModule = {}

--------------------------------------------------
-- DAFTAR BOT
--------------------------------------------------

DistanceModule.Bots = {

        ["11954797420"] = "Bot 1",
        ["11954814620"] = "Bot 2",
        ["11954816098"] = "Bot 3",
        ["11957237714"] = "Bot 4",
        ["11960711816"] = "Bot 5",
        ["11957234942"] = "Bot 6",
        ["11960702834"] = "Bot 7",
        ["11960661126"] = "Bot 8",

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
        ["11954797420"] = "Bot 1",
        ["11954814620"] = "Bot 2",

        ["11954816098"] = "Bot 3",
        ["11957237714"] = "Bot 4",

        ["11960711816"] = "Bot 5",
        ["11957234942"] = "Bot 6",
        
        ["11960702834"] = "Bot 7",
        ["11960661126"] = "Bot 8",
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
        ["BotA"] = "11954797420",
        ["BotB"] = "11954814620",
        ["Distance"] = 2
    }, -- Bot 1 - Bot 2

    {
        ["BotA"] = "11954816098",
        ["BotB"] = "11957237714",
        ["Distance"] = 2
    }, -- Bot 3 - Bot 4

    {
        ["BotA"] = "11960711816",
        ["BotB"] = "11957234942",
        ["Distance"] = 2
    }, -- Bot 5 - Bot 6

    {
        ["BotA"] = "11960702834",
        ["BotB"] = "11960661126",
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
