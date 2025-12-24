-- Commands/Pushup.lua
-- Admin-only pushup command (chat based, safe startup)

return {
    Execute = function()

        -- =========================
        -- SERVICES
        -- =========================
        local Players = game:GetService("Players")
        local TextChatService = game:GetService("TextChatService")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")

        local LocalPlayer = Players.LocalPlayer
        if not LocalPlayer then return end

        -- =========================
        -- LOAD ADMIN MODULE
        -- =========================
        local Admin = loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
        ))()

        -- =========================
        -- GLOBAL BOT VARS
        -- =========================
        _G.BotVars = _G.BotVars or {}
        local vars = _G.BotVars

        vars.PushupActive = false
        vars.PushupConnection = nil

        -- =========================
        -- CHAT SEND
        -- =========================
        local function sendChat(text)
            local ok = false

            if TextChatService and TextChatService.TextChannels then
                local ch = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
                if ch then
                    pcall(function()
                        ch:SendAsync(text)
                    end)
                    ok = true
                end
            end

            if not ok then
                pcall(function()
                    ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest
                        :FireServer(text, "All")
                end)
            end
        end

        -- =========================
        -- STOP PUSHUP
        -- =========================
        local function stopPushup()
            vars.PushupActive = false
            if vars.PushupConnection then
                task.cancel(vars.PushupConnection)
                vars.PushupConnection = nil
            end

            pcall(function()
                ReplicatedStorage
                    :WaitForChild("Connections")
                    :WaitForChild("dataProviders")
                    :WaitForChild("animationHandler")
                    :InvokeServer("stopAnimation", "Push Up")
            end)
        end

        -- =========================
        -- START PUSHUP
        -- =========================
        local function startPushup(jumlah)
            stopPushup()
            vars.PushupActive = true

            sendChat("Siap laksanakan!")
            task.wait(2)

            vars.PushupConnection = task.spawn(function()

                -- ▶ PLAY ANIMATION
                pcall(function()
                    ReplicatedStorage
                        :WaitForChild("Connections")
                        :WaitForChild("dataProviders")
                        :WaitForChild("animationHandler")
                        :InvokeServer("playAnimation", "Push Up")
                end)

                for i = 1, jumlah do
                    if not vars.PushupActive then break end
                    task.wait(5)

                    if i == jumlah then
                        sendChat(i .. " push up, Komandan!")
                    else
                        sendChat(i .. " push up!")
                    end
                end

                stopPushup()
            end)
        end

        -- =========================
        -- COMMAND HANDLER
        -- =========================
        local function handleCommand(msg, sender)
            msg = msg:lower()

            if not Admin:IsAdmin(sender) then
                return
            end

            local jumlah = tonumber(msg:match("^!pushup%s+(%d+)$"))
            if jumlah then
                startPushup(jumlah)
                return
            end

            if msg == "!pushup stop" or msg == "!stop pushup" then
                stopPushup()
            end
        end

        -- =========================
        -- TEXT CHAT SERVICE
        -- =========================
        if TextChatService and TextChatService.TextChannels then
            local ch = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
            if ch then
                ch.OnIncomingMessage = function(message)
                    local uid = message.TextSource and message.TextSource.UserId
                    local sender = uid and Players:GetPlayerByUserId(uid)
                    if sender then
                        handleCommand(message.Text, sender)
                    end
                end
            end
        end

        -- =========================
        -- FALLBACK CHAT
        -- =========================
        for _, p in ipairs(Players:GetPlayers()) do
            p.Chatted:Connect(function(msg)
                handleCommand(msg, p)
            end)
        end

        Players.PlayerAdded:Connect(function(p)
            p.Chatted:Connect(function(msg)
                handleCommand(msg, p)
            end)
        end)
    end
}
