return {
    Execute = function(msg, client)
        local vars = _G.BotVars or {}
        local TextChatService = vars.TextChatService or game:GetService("TextChatService")
        local player = vars.LocalPlayer or game.Players.LocalPlayer

        local content = msg.Text or msg.Message or msg.Body or msg.Content or tostring(msg) or ""
        local args = string.split(content, " ")
        if args[1] ~= "!say" then
            return
        end

        table.remove(args, 1)
        local textToSend = table.concat(args, " "):gsub("^%s+", "")

        if textToSend == "" then
            textToSend = "Kamu harus menulis sesuatu setelah !say!"
        end

        local generalChannel = nil
        pcall(function()
            generalChannel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
        end)

        -- 🔹 Prioritas: tampil seperti pemain sungguhan
        local success = pcall(function()
            if player and player:FindFirstChild("PlayerGui") then
                player:Chat(textToSend)
            end
        end)

        -- 🔹 Jika gagal (misal TextChatService modern aktif), kirim pesan berwarna putih via system message
        if not success or not player then
            if generalChannel then
                pcall(function()
                    generalChannel:DisplaySystemMessage("<font color='#FFFFFF'>" .. textToSend .. "</font>")
                end)
            else
                warn("Channel RBXGeneral tidak ditemukan!")
            end
        end
    end
}
