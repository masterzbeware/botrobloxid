-- Salute.lua (chat hormat singkat + /e salute)
return {
    Execute = function(msg, client)
        local vars = _G.BotVars or {}
        local Players = game:GetService("Players")
        local TextChatService = vars.TextChatService or game:GetService("TextChatService")
        local player = vars.LocalPlayer or Players.LocalPlayer

        vars.SaluteActive = true

        -- Ambil argumen !salute [nama]
        local args = {}
        for word in msg:gmatch("%S+") do table.insert(args, word) end
        local targetNameOrUsername = args[2]

        local targetPlayerName = "Komandan"
        if targetNameOrUsername then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr.Name:lower() == targetNameOrUsername:lower() or 
                   (plr.DisplayName and plr.DisplayName:lower() == targetNameOrUsername:lower()) then
                    targetPlayerName = plr.Name
                    break
                end
            end
        end

        -- Ambil channel chat
        local channel = TextChatService.TextChannels and TextChatService.TextChannels:FindFirstChild("RBXGeneral")
        local function sendChat(text)
            if channel then
                pcall(function() channel:SendAsync(text) end)
            end
        end

        -- Jalankan coroutine untuk chat salute
        vars.SaluteConnection = task.spawn(function()
            -- Pertama: kirim chat awal
            sendChat("Siap hormat, Komandan " .. targetPlayerName .. "!")
            task.wait(1.5)
            if not vars.SaluteActive then return end

            -- Lalu jalankan emote salute
            sendChat("/e salute")

            vars.SaluteActive = false
            vars.SaluteConnection = nil
        end)
    end
}
