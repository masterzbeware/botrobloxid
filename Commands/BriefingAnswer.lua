-- Commands/BriefingAnswer.lua
-- Auto answer briefing question
-- Jika admin memberi pertanyaan briefing, bot otomatis menjawab

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
            "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
        ))()

        ----------------------------------------------------------------
        -- BOT ORDER
        -- Dipakai agar jawabnya tidak terlalu barengan
        ----------------------------------------------------------------
        local botOrder = {
            "11001608049", -- Bot 1
            "11001625681", -- Bot 2
            "11001647769", -- Bot 3
            "11002716767", -- Bot 4
            "11002763516", -- Bot 5
            "11002833908", -- Bot 6
            "11002919499", -- Bot 7
            "11002918670", -- Bot 8
            "11007692539", -- Bot 9
            "11008102483", -- Bot 10
        }

        ----------------------------------------------------------------
        -- GLOBAL VARS
        ----------------------------------------------------------------
        _G.BotVars = _G.BotVars or {}
        local vars = _G.BotVars

        -- supaya tidak double listener kalau script di-execute ulang
        if vars.BriefingAnswerConnection then
            vars.BriefingAnswerConnection:Disconnect()
            vars.BriefingAnswerConnection = nil
        end

        if vars.BriefingAnswerLegacyConnections then
            for _, conn in ipairs(vars.BriefingAnswerLegacyConnections) do
                pcall(function()
                    conn:Disconnect()
                end)
            end
        end

        vars.BriefingAnswerLegacyConnections = {}

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
        -- NORMALIZE MESSAGE
        ----------------------------------------------------------------
        local function normalizeMessage(msg)
            msg = msg:lower()
            msg = msg:gsub("[%p%c]", "")
            msg = msg:gsub("%s+", " ")
            msg = msg:match("^%s*(.-)%s*$")

            return msg
        end

----------------------------------------------------------------
-- GET BRIEFING ANSWER
----------------------------------------------------------------
local function getBriefingAnswer(msg)
    msg = normalizeMessage(msg)

    -- Mengerti / Paham
    -- Bisa mendeteksi kalimat panjang seperti:
    -- "apakah kalian mengerti yang saya jelaskan"
    if msg:find("mengerti", 1, true)
        or msg:find("paham", 1, true)
    then
        return "Yes, Sir!"
    end

    -- Sudah jelas
    if msg:find("sudah jelas", 1, true)
        or msg:find("jelas", 1, true)
    then
        return "Clear, Sir!"
    end

    -- Siap
    if msg:find("siap", 1, true)
        or msg:find("siap melaksanakan", 1, true)
        or msg:find("siap menjalankan tugas", 1, true)
    then
        return "Ready, Sir!"
    end

    -- Ada pertanyaan
    if msg:find("ada pertanyaan", 1, true)
        or msg:find("apakah ada pertanyaan", 1, true)
        or msg:find("ada yang ingin ditanyakan", 1, true)
        or msg:find("ada yang mau bertanya", 1, true)
    then
        return "No, Sir!"
    end

    -- Laksanakan
    if msg:find("laksanakan", 1, true)
        or msg:find("jalankan tugas", 1, true)
        or msg:find("mulai bergerak", 1, true)
    then
        return "Yes, Sir!"
    end

    return nil
end

        ----------------------------------------------------------------
        -- HANDLE CHAT
        ----------------------------------------------------------------
        local function handleChat(msg, sender)
            if not msg or not sender then return end
            if sender == LocalPlayer then return end

            -- hanya admin yang bisa trigger jawaban
            if not Admin:IsAdmin(sender) then
                return
            end

            local answer = getBriefingAnswer(msg)

            if answer then
                local myIndex = table.find(botOrder, tostring(LocalPlayer.UserId)) or 1

                -- delay kecil supaya Bot1, Bot2, Bot3 jawab berurutan
                task.wait(myIndex * 0.2)

                sendChat(answer)
            end
        end

        ----------------------------------------------------------------
        -- TEXT CHAT SERVICE
        ----------------------------------------------------------------
        if TextChatService and TextChatService.MessageReceived then
            vars.BriefingAnswerConnection = TextChatService.MessageReceived:Connect(function(message)
                local uid = message.TextSource and message.TextSource.UserId
                local sender = uid and Players:GetPlayerByUserId(uid)

                if sender then
                    handleChat(message.Text, sender)
                end
            end)
        else
            ----------------------------------------------------------------
            -- FALLBACK CHAT LAMA
            ----------------------------------------------------------------
            local function connectPlayer(p)
                local conn = p.Chatted:Connect(function(msg)
                    handleChat(msg, p)
                end)

                table.insert(vars.BriefingAnswerLegacyConnections, conn)
            end

            for _, p in ipairs(Players:GetPlayers()) do
                connectPlayer(p)
            end

            local addedConn = Players.PlayerAdded:Connect(function(p)
                connectPlayer(p)
            end)

            table.insert(vars.BriefingAnswerLegacyConnections, addedConn)
        end
    end
}