-- Salute.lua (chat hormat berurutan + /e salute)
return {
    Execute = function(msg, client)
        local vars = _G.BotVars or {}
        local Players = game:GetService("Players")
        local TextChatService = vars.TextChatService or game:GetService("TextChatService")
        local player = vars.LocalPlayer or Players.LocalPlayer

        vars.SaluteActive = true

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
            sendChat("Siap hormat, Komandan!")
            task.wait(1.5)
            if not vars.SaluteActive then return end

            -- Lalu jalankan emote salute
            sendChat("/e salute")

            -- Chat tambahan setelah hormat
            task.wait(1) 
            if not vars.SaluteActive then return end 
            sendChat("Hormat untuk Komandan!")

            task.wait(1.5) 
            if not vars.SaluteActive then return end 
            sendChat("Kami siap menerima perintah!")

            vars.SaluteActive = false
            vars.SaluteConnection = nil
        end)
    end
}
