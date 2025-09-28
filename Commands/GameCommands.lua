-- GameCommands.lua
return {
    Execute = function(msg, player)
        local Players = game:GetService("Players")
        local TextChatService = game:GetService("TextChatService")
        local vars = _G.BotVars or {}
        vars.BotMapping = vars.BotMapping or {
            ["8802945328"] = "Bot1",
            ["8802949363"] = "Bot2",
            ["8802939883"] = "Bot3",
            ["8802998147"] = "Bot4"
        }
        vars.BotMode = vars.BotMode or "Bot1" -- default mode Bot1

        local lowerMsg = string.lower(msg)
        local channel = TextChatService.TextChannels and TextChatService.TextChannels.RBXGeneral
        if not channel then return end

        local function sendGlobal(text)
            pcall(function()
                channel:SendAsync(text)
            end)
        end

        -- 🔹 Mode game: pilih bot
        if lowerMsg:find("!modegame") then
            for botId, botName in pairs(vars.BotMapping) do
                if lowerMsg:find(string.lower(botName)) then
                    vars.BotMode = botName
                    sendGlobal("Mode game sekarang aktif pada " .. botName .. "!")
                    return
                end
            end
            sendGlobal("Bot tidak dikenali. Gunakan !modegame Bot1/2/3/4")
            return
        end

        -- Cek apakah pemain bisa interaktif dengan bot yang sedang aktif
        local activeBotName = vars.BotMode
        if not activeBotName then return end

        local botMappingUserIds = {}
        for id, name in pairs(vars.BotMapping) do
            botMappingUserIds[name] = tonumber(id)
        end

        -- Interaksi hanya untuk pemain (bukan bot) dan sesuai mode
        local function isPlayerInteractive()
            return not botMappingUserIds[player.Name] -- pastikan bukan bot
        end

        if isPlayerInteractive() then
            -- 🔹 Cek Khodam
            if lowerMsg:find("!cekkhodam") then
                local khodams = {"Macan", "Naga", "Harimau", "Elang", "Kuda", "Ular", "Ayam Jantan"}
                local khodam = khodams[math.random(1, #khodams)]
                sendGlobal(player.Name .. " khodam kamu adalah " .. khodam .. " oleh " .. activeBotName .. "!")
            end

            -- 🔹 Ball8 (biliar)
            if lowerMsg:find("!ball8") then
                local ballNumber = math.random(1,15)
                sendGlobal(player.Name .. " melempar bola biliar, nomor yang keluar adalah " .. ballNumber .. "! oleh " .. activeBotName)
            end

            -- 🔹 RockPaper
            if lowerMsg:find("!rockpaper") then
                local choices = {"batu", "gunting", "kertas"}
                local botChoice = choices[math.random(1,#choices)]
                local playerChoice = "batu" -- default player choice
                local resultText = player.Name .. "...kamu kalah memilih " .. playerChoice .. ", " .. activeBotName .. " memilih " .. botChoice .. "!"
                sendGlobal(resultText)
            end
        end
    end
}
