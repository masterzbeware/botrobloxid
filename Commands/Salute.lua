-- Salute.lua (animasi hormat + chat)
return {
    Execute = function(msg, client)
        local vars = _G.BotVars or {}
        local TextChatService = vars.TextChatService or game:GetService("TextChatService")

        -- tandai salute aktif
        vars.SaluteActive = true

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
        vars.SaluteConnection = task.spawn(function()
            -- Chat awal
            sendChat("Siap hormat, Komandan!")
            task.wait(3)
            if not vars.SaluteActive then return end

            -- 🔹 Play animasi hormat (ID: 3360689775)
            local success, err = pcall(function()
                local args = { "playAnimation", "3360689775" }
                game:GetService("ReplicatedStorage")
                    :WaitForChild("Connections")
                    :WaitForChild("dataProviders")
                    :WaitForChild("animationHandler")
                    :InvokeServer(unpack(args))
            end)
            if not success then warn("[Salute] gagal play animasi:", err) end

            -- Chat berurutan saat hormat
            task.wait(3) if not vars.SaluteActive then return end sendChat("Hormat untuk Komandan!")
            task.wait(3) if not vars.SaluteActive then return end sendChat("Kami siap menerima perintah!")

            -- 🔹 Stop animasi hormat setelah selesai
            local success2, err2 = pcall(function()
                local args = { "stopAnimation", "3360689775" }
                game:GetService("ReplicatedStorage")
                    :WaitForChild("Connections")
                    :WaitForChild("dataProviders")
                    :WaitForChild("animationHandler")
                    :InvokeServer(unpack(args))
            end)
            if not success2 then warn("[Salute] gagal stop animasi:", err2) end

            vars.SaluteActive = false
            vars.SaluteConnection = nil
        end)
    end
}
