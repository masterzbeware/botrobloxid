-- Pushup.lua (bot melakukan animasi push-up + chat berurutan)
return {
    Execute = function(msg, client)
        local vars = _G.BotVars or {}
        local TextChatService = vars.TextChatService or game:GetService("TextChatService")

        -- Ambil channel chat
        local channel = TextChatService.TextChannels and TextChatService.TextChannels:FindFirstChild("RBXGeneral")

        -- Fungsi aman untuk kirim chat
        local function sendChat(text)
            if channel then
                pcall(function()
                    channel:SendAsync(text)
                end)
            else
                warn("Channel RBXGeneral tidak ditemukan!")
            end
        end

        -- 🔹 Jalankan animasi push-up
        local args = {
            "playAnimation",
            "Push Up"
        }
        pcall(function()
            game:GetService("ReplicatedStorage")
                :WaitForChild("Connections")
                :WaitForChild("dataProviders")
                :WaitForChild("animationHandler")
                :InvokeServer(unpack(args))
        end)

        -- 🔹 Urutan chat + jeda
        task.spawn(function()
            sendChat("Siap laksanakan!")   -- langsung setelah animasi
            task.wait(5)                   -- jeda 3 detik
            sendChat("Satu push up!")      -- chat kedua
            task.wait(5)                   -- jeda lagi
            sendChat("Dua push up!")       -- chat ketiga
            task.wait(5)
            sendChat("Tiga push up, Komandan!") -- chat terakhir
        end)
    end
}
