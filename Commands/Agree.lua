return {
    Execute = function()

        local Players = game:GetService("Players")
        local TextChatService = game:GetService("TextChatService")

        local LocalPlayer = Players.LocalPlayer
        if not LocalPlayer then
            return
        end

        _G.BotVars = _G.BotVars or {}
        _G.BotVars.ModeControllers = _G.BotVars.ModeControllers or {}

        local Admin = loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
        ))()

        local AGREE_MESSAGES = {
            "Yes, Sir!",
            "I understand, sir",
            "Got it, Sir",
            "Noted, Sir"
        }

        local agreeing = false
        local agreeGeneration = 0

        local function sendChat(message)
            if not message then
                return false
            end

            if TextChatService and TextChatService.TextChannels then
                local channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
                if channel then
                    local success = pcall(function()
                        channel:SendAsync(message)
                    end)
                    if success then
                        return true
                    end
                end
            end

            return false
        end

        local function stopAgree()
            agreeGeneration += 1
            agreeing = false
        end

        _G.BotVars.ModeControllers.agree = stopAgree

        local function stopOtherModes()
            for modeName, controller in pairs(_G.BotVars.ModeControllers) do
                if modeName ~= "agree" and type(controller) == "function" then
                    pcall(controller)
                end
            end
        end

        local function startAgree()
            agreeGeneration += 1
            local generation = agreeGeneration

            agreeing = true
            _G.BotVars.ActiveMode = "agree"
            stopOtherModes()

            if generation ~= agreeGeneration or not agreeing then
                return
            end

            -- Bot pertama yang menerima command memilih pesan.
            -- Bot lain menggunakan pilihan global yang sama.
            local selectedMessage = _G.BotVars.AgreeMessage

            if not selectedMessage then
                local randomObject = Random.new()
                selectedMessage = AGREE_MESSAGES[
                    randomObject:NextInteger(1, #AGREE_MESSAGES)
                ]
                _G.BotVars.AgreeMessage = selectedMessage
            end

            sendChat(selectedMessage)
        end

        local function handleCommand(message, sender)
            if not message or not sender then
                return
            end

            local isAdmin = false
            pcall(function()
                isAdmin = Admin:IsAdmin(sender)
            end)

            if not isAdmin then
                return
            end

            local lower = message:lower()
            lower = lower:gsub("^%s+", "")
            lower = lower:gsub("%s+$", "")

            if lower == "!agree" then
                _G.BotVars.AgreeMessage = nil
                startAgree()
                return
            end

            if lower == "!unagree" or lower == "!stop" then
                if _G.BotVars.ActiveMode == "agree" then
                    _G.BotVars.ActiveMode = nil
                end

                _G.BotVars.AgreeMessage = nil
                stopAgree()
                return
            end
        end

        local connectedPlayers = {}

        local function connectPlayerChat(player)
            if connectedPlayers[player] then
                return
            end

            connectedPlayers[player] = true

            player.Chatted:Connect(function(message)
                handleCommand(message, player)
            end)
        end

        for _, player in ipairs(Players:GetPlayers()) do
            connectPlayerChat(player)
        end

        Players.PlayerAdded:Connect(function(player)
            connectPlayerChat(player)
        end)

        Players.PlayerRemoving:Connect(function(player)
            connectedPlayers[player] = nil
        end)

        LocalPlayer.CharacterAdded:Connect(function()
            task.wait(1)

            if _G.BotVars.ActiveMode == "agree" then
                agreeing = true

                local selectedMessage = _G.BotVars.AgreeMessage
                if selectedMessage then
                    task.wait(0.2)
                    sendChat(selectedMessage)
                end
            end
        end)

        return {
            Execute = function()
                return true
            end
        }

    end
}
