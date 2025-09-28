-- Absen.lua
return {
    Execute = function(msg, client)
        local vars = _G.BotVars or {}
        local player = vars.LocalPlayer or game:GetService("Players").LocalPlayer
        local Players = vars.Players or game:GetService("Players")

        -- Daftar bot
        local botList = {
            "Bot1 - XBODYGUARDVIP01",
            "Bot2 - XBODYGUARDVIP02",
            "Bot3 - XBODYGUARDVIP03",
            "Bot4 - XBODYGUARDVIP04"
        }

        -- Urutkan absen berdasarkan identity masing-masing bot
        local identity = vars.BotIdentity or "Unknown Bot"
        local index = table.find(botList, identity) or 0

        -- Kirim jawaban chat
        local response = ""
        if index > 0 then
            response = identity .. " hadir! Urutan ke-" .. tostring(index)
        else
            response = identity .. " tidak terdaftar di daftar absen."
        end

        -- Kirim ke client melalui chat
        if client and client.Name == vars.ClientName then
            if vars.TextChatService and vars.TextChatService.TextChannels then
                local generalChannel = vars.TextChatService.TextChannels.RBXGeneral
                if generalChannel then
                    generalChannel:SendAsync(response)
                end
            else
                client:Chatted(function() end) -- fallback
            end
        end

        print("[ABSEN] " .. response)
    end
}
