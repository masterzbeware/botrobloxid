-- Commands/Salute.lua
-- Admin-only salute command
-- Supports: !salute
-- Jika admin ketik !salute, bot akan kirim /e salute

return {
    Execute = function()
        local Players = game:GetService("Players")
        local TextChatService = game:GetService("TextChatService")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")

        local LocalPlayer = Players.LocalPlayer
        if not LocalPlayer then return end

        ----------------------------------------------------------------
        -- LOAD ADMIN MODULE
        ----------------------------------------------------------------
        local Admin = loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua?v=" .. tostring(tick())
        ))()

        ----------------------------------------------------------------
        -- SEND CHAT
        ----------------------------------------------------------------
        local function sendChat(msg)
            local ok = false

            if TextChatService and TextChatService.TextChannels then
                local ch = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
                if ch then
                    pcall(function()
                        ch:SendAsync(msg)
                    end)
                    ok = true
                end
            end

            if not ok then
                pcall(function()
                    ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest
                        :FireServer(msg, "All")
                end)
            end
        end

        ----------------------------------------------------------------
        -- COMMAND HANDLER
        ----------------------------------------------------------------
        local function handleCommand(msg, sender)
            if not sender then return end
            if not Admin:IsAdmin(sender) then return end

            local lower = msg:lower()

if lower == "!salute" then
    sendChat("Yes, Sir!")

    task.wait(0.5)

    sendChat("/e salute")
    return
end
        end

        ----------------------------------------------------------------
        -- TEXT CHAT SERVICE UNTUK EXECUTOR
        ----------------------------------------------------------------
        task.spawn(function()
            local textChannels = TextChatService:WaitForChild("TextChannels", 10)
            if not textChannels then
                warn("[SALUTE] TextChannels tidak ditemukan")
                return
            end

            local ch = textChannels:FindFirstChild("RBXGeneral") or textChannels:WaitForChild("RBXGeneral", 10)

            if not ch then
                warn("[SALUTE] RBXGeneral tidak ditemukan")
                return
            end

            ch.MessageReceived:Connect(function(message)
                local uid = message.TextSource and message.TextSource.UserId
                local sender = uid and Players:GetPlayerByUserId(uid)

                if sender then
                    handleCommand(message.Text, sender)
                end
            end)

            warn("[SALUTE] Listener aktif")
        end)

        ----------------------------------------------------------------
        -- FALLBACK CHAT
        ----------------------------------------------------------------
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