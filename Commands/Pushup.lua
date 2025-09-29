-- Pushup.lua (Push-up training dengan stop animasi di akhir)
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
            -- 🔹 1. Chat awal
            sendChat("Siap laksanakan!")

            -- 🔹 2. Tunggu 5 detik
            task.wait(5)

            -- 🔹 3. Jalankan animasi push-up
            pcall(function()
                local args = { "playAnimation", "Push Up" }
                game:GetService("ReplicatedStorage")
                    :WaitForChild("Connections")
                    :WaitForChild("dataProviders")
                    :WaitForChild("animationHandler")
                    :InvokeServer(unpack(args))
            end)

            -- 🔹 4. Chat berurutan
            task.wait(5)
            sendChat("Satu push up!")
            task.wait(5)
            sendChat("Dua push up!")
            task.wait(5)
            sendChat("Tiga push up, Komandan!")

            -- 🔹 5. Stop animasi setelah chat terakhir
            pcall(function()
                local args = { "stopAnimation", "Push Up" }
                game:GetService("ReplicatedStorage")
                    :WaitForChild("Connections")
                    :WaitForChild("dataProviders")
                    :WaitForChild("animationHandler")
                    :InvokeServer(unpack(args))
            end)
        end)
    end
}
