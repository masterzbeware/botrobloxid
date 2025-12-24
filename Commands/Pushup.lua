-- Commands/Pushup.lua
-- Pushup command mandiri, aman dari nil msg, kompatibel chat & animasi

return {
    Execute = function(msg, client)

        -- =========================
        -- SERVICES
        -- =========================
        local Players = game:GetService("Players")
        local TextChatService = game:GetService("TextChatService")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")

        local LocalPlayer = Players.LocalPlayer
        if not LocalPlayer then return end

        -- =========================
        -- GLOBAL BOT VARS
        -- =========================
        _G.BotVars = _G.BotVars or {}
        local vars = _G.BotVars

        -- =========================
        -- CHAT CHANNEL
        -- =========================
        local channel
        if TextChatService.TextChannels then
            channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
        end

        local function sendChat(text)
            if channel and text then
                pcall(function()
                    channel:SendAsync(tostring(text))
                end)
            end
        end

        -- =========================
        -- STOP PUSHUP JIKA MASIH AKTIF
        -- =========================
        if vars.PushupActive then
            vars.PushupActive = false
            if vars.PushupConnection then
                task.cancel(vars.PushupConnection)
                vars.PushupConnection = nil
            end
        end

        vars.PushupActive = true

        -- =========================
        -- JUMLAH PUSHUP (AMAN DARI NIL)
        -- =========================
        local text = tostring(msg or "")
        local jumlah = tonumber(text:match("!pushup%s+(%d+)")) or 3

        -- =========================
        -- MAIN TASK
        -- =========================
        vars.PushupConnection = task.spawn(function()

            sendChat("Siap laksanakan!")
            task.wait(2)

            if not vars.PushupActive then return end

            -- ▶ PLAY ANIMATION
            pcall(function()
                ReplicatedStorage
                    :WaitForChild("Connections")
                    :WaitForChild("dataProviders")
                    :WaitForChild("animationHandler")
                    :InvokeServer("playAnimation", "Push Up")
            end)

            for i = 1, jumlah do
                task.wait(5)
                if not vars.PushupActive then break end

                if i == jumlah then
                    sendChat(i .. " push up, Komandan!")
                else
                    sendChat(i .. " push up!")
                end
            end

            -- ⏹ STOP ANIMATION
            pcall(function()
                ReplicatedStorage
                    :WaitForChild("Connections")
                    :WaitForChild("dataProviders")
                    :WaitForChild("animationHandler")
                    :InvokeServer("stopAnimation", "Push Up")
            end)

            vars.PushupActive = false
            vars.PushupConnection = nil
        end)
    end
}
