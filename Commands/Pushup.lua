-- Pushup.lua (animasi push-up sesuai jumlah, default 3x)
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

        -- ambil angka dari command (!pushup 5 -> 5)
        local jumlah = tonumber(msg:match("!pushup%s+(%d+)")) or 3

        -- Simpan connection biar bisa dihentikan dari Stop.lua
        vars.PushupConnection = task.spawn(function()
            -- Chat awal
            sendChat("Siap laksanakan!")
            task.wait(2)
            if not vars.PushupActive then return end

            -- 🔹 Mulai animasi push-up
            pcall(function()
                local args = { "playAnimation", "Push Up" }
                game:GetService("ReplicatedStorage")
                    :WaitForChild("Connections")
                    :WaitForChild("dataProviders")
                    :WaitForChild("animationHandler")
                    :InvokeServer(unpack(args))
            end)

            -- Loop push-up sesuai jumlah
            for i = 1, jumlah do
                task.wait(5)
                if not vars.PushupActive then break end

                if i == jumlah then
                    sendChat(tostring(i) .. " push up, Komandan!")
                else
                    sendChat(tostring(i) .. " push up!")
                end
            end

            -- 🔹 Stop animasi setelah selesai
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
