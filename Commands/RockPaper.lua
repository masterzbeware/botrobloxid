return {
    Execute = function(msg, client)
        local vars = _G.BotVars
        local Players = vars.Players
        local TextChatService = vars.TextChatService
        local localPlayer = vars.LocalPlayer

        local botModes = {
            mode1 = "8802945328",
            mode2 = "8802949363",
            mode3 = "8802939883",
            mode4 = "8802998147",
        }

        local choices = {"batu", "gunting", "kertas"}

        local function sendGlobal(msg)
            local channel = TextChatService.TextChannels and TextChatService.TextChannels.RBXGeneral
            if channel then
                pcall(function() channel:SendAsync(msg) end)
            end
        end

        Players.PlayerChatted:Connect(function(plr, message)
            message = message:lower()

            if message == "!modegame1" then
                vars.ActiveBot = botModes.mode1
                sendGlobal("Mode Game Bot1 diaktifkan oleh VIP!")
            elseif message == "!modegame2" then
                vars.ActiveBot = botModes.mode2
                sendGlobal("Mode Game Bot2 diaktifkan oleh VIP!")
            elseif message == "!modegame3" then
                vars.ActiveBot = botModes.mode3
                sendGlobal("Mode Game Bot3 diaktifkan oleh VIP!")
            elseif message == "!modegame4" then
                vars.ActiveBot = botModes.mode4
                sendGlobal("Mode Game Bot4 diaktifkan oleh VIP!")
            end

            if message == "!rockpaper" and vars.ActiveBot then
                if tostring(localPlayer.UserId) == vars.ActiveBot then
                    local botChoice = choices[math.random(1, #choices)]
                    sendGlobal(plr.Name .. " Kamu memilih batu, Saya memilih " .. botChoice .. "!")
                end
            end
        end)
    end
}
