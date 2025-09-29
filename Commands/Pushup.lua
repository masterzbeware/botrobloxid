-- Pushup.lua (animasi push-up + stop benar setelah chat terakhir)
return {
    Execute = function(msg, client)
        local vars = _G.BotVars or {}
        local TextChatService = vars.TextChatService or game:GetService("TextChatService")

        -- tandai pushup aktif
        vars.PushupActive = true

        -- Ambil channel chat
        local channel = TextChatService.TextChannels and TextChatService.TextChannels:FindFirstChild("RBXGeneral")

        local function sendChat(text)
            if channel then
                pcall(function()
                    channel:SendAsync(text)
                end)
            end
        end

        -- Simpan connection biar bisa dihentikan dari Stop.lua
        vars.PushupConnection = task.spawn(function()
            -- Chat awal
            sendChat("Siap laksanakan!")
            task.wait(5)
            if not vars.PushupActive then return end

            -- 🔹 Play animasi push-up sekali
            pcall(function()
                local args = { "playAnimation", "Push Up" }
                game:GetService("ReplicatedStorage")
                    :WaitForChild("Connections")
                    :WaitForChild("dataProviders")
                    :WaitForChild("animationHandler")
                    :InvokeServer(unpack(args))
            end)

            -- Chat dengan jeda 5 detik
            task.wait(5) if not vars.PushupActive then return end sendChat("Satu push up!")
            task.wait(5) if not vars.PushupActive then return end sendChat("Dua push up!")
            task.wait(5) if not vars.PushupActive then return end sendChat("Tiga push up, Komandan!")

            -- 🔹 Stop animasi setelah chat terakhir
            pcall(function()
                local args = { "stopAnimation", "Push Up" }
                game:GetService("ReplicatedStorage")
                    :WaitForChild("Connections")
                    :WaitForChild("dataProviders")
                    :WaitForChild("animationHandler")
                    :InvokeServer(unpack(args))
            end)

            vars.PushupActive = false
            vars.PushupConnection = nil
        end)
    end
}
