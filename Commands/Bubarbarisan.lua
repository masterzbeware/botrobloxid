-- Bubarbarisan.lua
-- Command !bubarbarisan: Bot mengirim chat "Siap, bubar barisan komandan!" lalu /e wave

return {
    Execute = function(msg, client)
        local vars = _G.BotVars or {}

        local TextChatService = game:GetService("TextChatService")
        local channel

        if TextChatService.TextChannels then
            channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
        end

        if channel then
            pcall(function()
                -- 1️⃣ Kirim pesan bubar barisan
                channel:SendAsync("Siap, bubar barisan komandan!")
                task.wait(1) -- jeda kecil agar tidak tabrakan

                -- 2️⃣ Kirim /e wave
                channel:SendAsync("/e salute")
            end)
        else
            warn("Channel RBXGeneral tidak ditemukan!")
        end
    end
}
