-- Punishment.lua
return {
    Execute = function(msg, client)
        print("[DEBUG] Punishment command triggered by: " .. client.Name)
        print("[DEBUG] Original msg: " .. tostring(msg))

        -- Gunakan TextChatService dari global bot vars
        local TextChatService = _G.BotVars.TextChatService
        if not TextChatService then
            warn("[DEBUG] TextChatService belum tersedia!")
            return
        end

        -- Tunggu channel RBXGeneral muncul
        local channel = TextChatService.TextChannels and TextChatService.TextChannels:FindFirstChild("RBXGeneral")
        if not channel then
            warn("[DEBUG] Channel RBXGeneral tidak ditemukan!")
            return
        end

        -- Cek command
        if msg:lower() == "!pushup" then
            print("[DEBUG] !pushup command dikenali, mengirim pesan...")
            local success, err = pcall(function()
                channel:SendAsync("Siap laksanakan!")
            end)
            if success then
                print("[DEBUG] Pesan berhasil dikirim!")
            else
                warn("[DEBUG] Gagal mengirim pesan: " .. tostring(err))
            end
        else
            print("[DEBUG] Command tidak cocok: " .. tostring(msg))
        end
    end
}
