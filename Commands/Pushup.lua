-- Pushup.lua (Push-up training: chat -> delay -> animasi -> chat berurutan -> stop)
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

        task.spawn(function()
            -- 🔹 Langkah 1: Chat awal
            sendChat("Siap laksanakan!")

            -- 🔹 Langkah 2: Tunggu 5 detik
            task.wait(5)

            -- 🔹 Langkah 3: Jalankan animasi push-up
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

            -- 🔹 Langkah 4: Chat berurutan dengan jeda 5 detik
            task.wait(5)
            sendChat("Satu push up!")
            task.wait(5)
            sendChat("Dua push up!")
            task.wait(5)
            sendChat("Tiga push up, Komandan!")

            -- 🔹 Langkah 5: Stop (selesai, tidak ada loop lagi)
        end)
    end
}
