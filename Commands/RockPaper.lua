-- RockPaper.lua
-- RockPaper command for MasterZ Beware Bot System

return {
    Execute = function(msg, client)
        local Vars = _G.BotVars

        -- 🔹 Pastikan Bot system aktif
        if not Vars.ToggleAktif then
            local channel = Vars.TextChatService.TextChannels and Vars.TextChatService.TextChannels.RBXGeneral
            if channel then
                pcall(function()
                    channel:SendAsync("Bot system not active. Cannot execute RockPaper.")
                end)
            end
            return
        end

        -- 🔹 Pastikan RockPaper system enabled
        if not Vars.RockPaperEnabled then
            local channel = Vars.TextChatService.TextChannels and Vars.TextChatService.TextChannels.RBXGeneral
            if channel then
                pcall(function()
                    channel:SendAsync("RockPaper system is disabled!")
                end)
            end
            return
        end

        -- 🔹 Cek apakah RockPaper sudah aktif untuk mencegah spam
        if Vars.RockPaperModeActive then
            local channel = Vars.TextChatService.TextChannels and Vars.TextChatService.TextChannels.RBXGeneral
            if channel then
                pcall(function()
                    channel:SendAsync("RockPaper mode is already active!")
                end)
            end
            return
        end

        -- 🔹 Ambil target player jika ada
        local targetName = msg:match("^!rockpaper%s*(.*)")
        local targetPlayer = nil
        if targetName and targetName ~= "" then
            for _, plr in ipairs(Vars.Players:GetPlayers()) do
                if plr.DisplayName:lower() == targetName:lower() or plr.Name:lower() == targetName:lower() then
                    targetPlayer = plr
                    break
                end
            end
        end

        -- 🔹 Aktifkan mode RockPaper
        Vars.RockPaperModeActive = true
        Vars.FollowAllowed = false
        Vars.RowActive = false
        Vars.ShieldActive = false
        Vars.CurrentFormasiTarget = targetPlayer or client

        -- 🔹 Kirim notifikasi lokal
        game.StarterGui:SetCore("SendNotification", {
            Title = "RockPaper",
            Text = "RockPaper mode activated by " .. client.Name
        })

        -- 🔹 Kirim notifikasi global
        local channel = Vars.TextChatService.TextChannels and Vars.TextChatService.TextChannels.RBXGeneral
        if channel then
            pcall(function()
                local msgText = "RockPaper mode activated by " .. client.Name
                if targetPlayer then
                    msgText = msgText .. " targeting " .. targetPlayer.DisplayName
                end
                channel:SendAsync(msgText)
            end)
        end

        -- 🔹 Durasi RockPaper (misal 10 detik)
        task.spawn(function()
            task.wait(10)
            Vars.RockPaperModeActive = false
            local channel2 = Vars.TextChatService.TextChannels and Vars.TextChatService.TextChannels.RBXGeneral
            if channel2 then
                pcall(function()
                    channel2:SendAsync("RockPaper mode deactivated!")
                end)
            end
            game.StarterGui:SetCore("SendNotification", {
                Title = "RockPaper",
                Text = "RockPaper mode deactivated"
            })
        end)

        print("[COMMAND] RockPaper mode activated by", client.Name, "target:", targetPlayer and targetPlayer.Name or "None")
    end
}
