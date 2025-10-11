-- Salute.lua
-- Command !salute: Bot memberi hormat (chat + /e salute) ke target pemain atau Komandan

return {
    Execute = function(msg, client)
        local vars = _G.BotVars or {}
        local Players = game:GetService("Players")
        local player = vars.LocalPlayer or Players.LocalPlayer

        -- Sistem chat (disamakan dengan Say.lua dan Shield.lua)
        local TextChatService = game:GetService("TextChatService")
        local channel
        if TextChatService.TextChannels then
            channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
        end

        vars.SaluteActive = true

        -- Ambil argumen dari perintah !salute
        local args = {}
        for word in msg:gmatch("%S+") do
            table.insert(args, word)
        end
        local targetNameOrUsername = args[2]

        -- Cari target player berdasarkan nama atau display name
        local targetPlayerName = nil
        if targetNameOrUsername then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr.Name:lower() == targetNameOrUsername:lower()
                or (plr.DisplayName and plr.DisplayName:lower() == targetNameOrUsername:lower()) then
                    targetPlayerName = plr.Name
                    break
                end
            end
        end

        -- Fungsi kirim chat ke RBXGeneral
        local function sendChat(text)
            if channel then
                pcall(function()
                    channel:SendAsync(text)
                end)
            else
                warn("Channel RBXGeneral tidak ditemukan!")
            end
        end

        -- Jalankan coroutine untuk hormat
        vars.SaluteConnection = task.spawn(function()
            -- Chat pertama: hormat ke target atau umum
            if targetPlayerName then
                sendChat("Siap Hormat, Komandan " .. targetPlayerName .. "!")
            else
                sendChat("Siap Hormat, Komandan!")
            end

            -- Tunggu sebentar sebelum emote
            task.wait(1.5)
            if not vars.SaluteActive then return end

            -- Kirim emote salute
            sendChat("/e salute")

            -- Nonaktifkan setelah selesai
            vars.SaluteActive = false
            vars.SaluteConnection = nil
        end)
    end
}
