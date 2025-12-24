-- Commands/Pushup.lua
-- Admin-only pushup command (chat based, fixed double trigger & animation stop)

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
            if not text then return end

            if TextChatService and TextChatService.TextChannels then
                local ch = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
                if ch then
                    pcall(function()
                        ch:SendAsync(text)
                    end)
                    return
                end
            end

            pcall(function()
                ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest
                    :FireServer(text, "All")
            end)
        end

        -- =========================
        -- ANIMATION
        -- =========================
        local function playAnimation()
            pcall(function()
                ReplicatedStorage
                    :WaitForChild("Connections")
                    :WaitForChild("dataProviders")
                    :WaitForChild("animationHandler")
                    :InvokeServer("playAnimation", "Push Up")
            end)
        end

        local function stopAnimation()
            pcall(function()
                ReplicatedStorage
                    :WaitForChild("Connections")
                    :WaitForChild("dataProviders")
                    :WaitForChild("animationHandler")
                    :InvokeServer("stopAnimation", "Push Up")
            end)
        end

        -- =========================
        -- FORCE STOP (ADMIN STOP)
        -- =========================
        local function forceStopPushup()
            vars.PushupActive = false

            if vars.PushupConnection then
                task.cancel(vars.PushupConnection)
                vars.PushupConnection = nil
            end

            stopAnimation()
        end

        -- =========================
        -- NORMAL FINISH
        -- =========================
        local function finishPushup()
            vars.PushupActive = false
            vars.PushupConnection = nil
            stopAnimation()
        end

        -- =========================
        -- START PUSHUP
        -- =========================
        local function startPushup(jumlah)
            if vars.PushupActive then
                forceStopPushup()
            end

            vars.PushupActive = true
            sendChat("Siap laksanakan!")
            task.wait(2)

            vars.PushupConnection = task.spawn(function()
                playAnimation()

                for i = 1, jumlah do
                    if not vars.PushupActive then
                        return
                    end

                    task.wait(5)

                    if i == jumlah then
                        sendChat(i .. " push up, Komandan!")
                    else
                        sendChat(i .. " push up!")
                    end
                end

                -- SELESAI NORMAL
                finishPushup()
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
                forceStopPushup()
            end
        end

        -- =========================
        -- CHAT LISTENER (SINGLE SOURCE)
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
        else
            -- FALLBACK ONLY IF TextChatService NOT AVAILABLE
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
    end
}
