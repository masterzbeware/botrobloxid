-- Absen.lua
return {
    Execute = function(msg, client)
        local vars = _G.BotVars or {}
        local Players = game:GetService("Players")
        local TextChatService = vars.TextChatService or game:GetService("TextChatService")
        local player = vars.LocalPlayer or Players.LocalPlayer

        if not msg:lower():match("^!absen") then return end

        local botMapping = vars.BotMapping or {
            ["8802945328"] = "Bot1",
            ["8802949363"] = "Bot2",
            ["8802939883"] = "Bot3",
            ["8802998147"] = "Bot4",
        }

        -- Urutkan bot berdasarkan UserId
        local botIds = {}
        for idStr, _ in pairs(botMapping) do
            table.insert(botIds, tonumber(idStr))
        end
        table.sort(botIds)

        -- Cari index bot ini
        local index = 1
        for i, id in ipairs(botIds) do
            if id == player.UserId then
                index = i
                break
            end
        end

        -- Channel global
        local channel = TextChatService.TextChannels and TextChatService.TextChannels.RBXGeneral
        if not channel then return end

        -- Hanya Bot1 yang memulai chat "Siap laksanakan! Mulai Berhitung"
        if index == 1 then
            pcall(function() channel:SendAsync("Siap laksanakan! Mulai Berhitung") end)
        end

        -- Delay agar semua bot siap
        task.delay(2, function()
            -- Delay per bot: 1 detik
            local delayPerBot = 1
            task.delay((index-1) * delayPerBot, function()
                pcall(function() channel:SendAsync(tostring(index)) end)
            end)
        end)

        print("[COMMAND] Absen executed by", player.Name)
    end
}
