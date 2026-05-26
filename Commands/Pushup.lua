-- Commands/Pushup.lua
-- Admin-only pushup command
-- Fixed: new RemoteSpy args, no double trigger, safer stop

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
        vars.PushupTask = nil
        vars.PushupToken = 0

        -- bersihkan listener lama biar tidak double trigger
        if vars.PushupChatConnection then
            vars.PushupChatConnection:Disconnect()
            vars.PushupChatConnection = nil
        end

        if vars.PushupLegacyConnections then
            for _, conn in ipairs(vars.PushupLegacyConnections) do
                pcall(function()
                    conn:Disconnect()
                end)
            end
        end

        vars.PushupLegacyConnections = {}

        -- =========================
        -- CHAT SEND
        -- =========================
        local function sendChat(text)
            if not text then return end

            local channels = TextChatService:FindFirstChild("TextChannels")
            if channels then
                local ch = channels:FindFirstChild("RBXGeneral")
                if ch then
                    pcall(function()
                        ch:SendAsync(text)
                    end)
                    return
                end
            end

            pcall(function()
                ReplicatedStorage
                    :WaitForChild("DefaultChatSystemChatEvents")
                    :WaitForChild("SayMessageRequest")
                    :FireServer(text, "All")
            end)
        end

        -- =========================
        -- REMOTE
        -- =========================
        local function getAnimationRemote()
            return ReplicatedStorage
                :WaitForChild("Connections")
                :WaitForChild("dataProviders")
                :WaitForChild("animationHandler")
        end

        -- =========================
        -- ANIMATION
        -- RemoteSpy baru:
        -- local args = {
        --     "playAnimation",
        --     "Push Up"
        -- }
        -- animationHandler:InvokeServer(unpack(args))
        -- =========================
        local function playAnimation()
            pcall(function()
                local args = {
                    "playAnimation",
                    "Push Up"
                }

                getAnimationRemote():InvokeServer(unpack(args))
            end)
        end

        local function stopAnimation()
            pcall(function()
                local args = {
                    "stopAnimation",
                    "Push Up"
                }

                getAnimationRemote():InvokeServer(unpack(args))
            end)
        end

        -- =========================
        -- FORCE STOP
        -- =========================
        local function forceStopPushup()
            vars.PushupActive = false
            vars.PushupToken += 1

            if vars.PushupTask then
                pcall(function()
                    task.cancel(vars.PushupTask)
                end)

                vars.PushupTask = nil
            end

            stopAnimation()
        end

        -- =========================
        -- FINISH NORMAL
        -- =========================
        local function finishPushup(token)
            if token ~= vars.PushupToken then return end

            vars.PushupActive = false
            vars.PushupTask = nil
            stopAnimation()
        end

        -- =========================
        -- START PUSHUP
        -- =========================
        local function startPushup(jumlah)
            if vars.PushupActive then
                forceStopPushup()
                task.wait(0.2)
            end

            vars.PushupActive = true
            vars.PushupToken += 1

            local myToken = vars.PushupToken

            sendChat("Yes, Sir!")
            task.wait(2)

            if not vars.PushupActive or myToken ~= vars.PushupToken then
                return
            end

            vars.PushupTask = task.spawn(function()
                playAnimation()

                for i = 1, jumlah do
                    if not vars.PushupActive or myToken ~= vars.PushupToken then
                        return
                    end

                    task.wait(5)

                    if not vars.PushupActive or myToken ~= vars.PushupToken then
                        return
                    end

                    if i == jumlah then
                        sendChat(i .. " push up, Sir!")
                    else
                        sendChat(i .. " push up!")
                    end
                end

                finishPushup(myToken)
            end)
        end

        -- =========================
        -- COMMAND HANDLER
        -- =========================
        local function handleCommand(msg, sender)
            if not msg or not sender then return end

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
                return
            end
        end

        -- =========================
        -- CHAT LISTENER
        -- =========================
        if TextChatService and TextChatService.MessageReceived then
            vars.PushupChatConnection = TextChatService.MessageReceived:Connect(function(message)
                local uid = message.TextSource and message.TextSource.UserId
                local sender = uid and Players:GetPlayerByUserId(uid)

                if sender then
                    handleCommand(message.Text, sender)
                end
            end)
        else
            -- fallback chat lama
            local function connectPlayer(p)
                local conn = p.Chatted:Connect(function(msg)
                    handleCommand(msg, p)
                end)

                table.insert(vars.PushupLegacyConnections, conn)
            end

            for _, p in ipairs(Players:GetPlayers()) do
                connectPlayer(p)
            end

            local addedConn = Players.PlayerAdded:Connect(function(p)
                connectPlayer(p)
            end)

            table.insert(vars.PushupLegacyConnections, addedConn)
        end
    end
}