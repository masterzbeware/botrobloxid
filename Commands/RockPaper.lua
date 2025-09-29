-- RockPaper.lua
-- RockPaper command for MasterZ Beware Bot System

return {
    Execute = function(msg, client)
        local Vars = _G.BotVars

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

        -- 🔹 Cek apakah RockPaper sudah aktif
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

        -- 🔹 Matikan formasi lain sementara
        Vars.FollowAllowed = false
        Vars.RowActive = false
        Vars.ShieldActive = false
        Vars.CurrentFormasiTarget = targetPlayer or client

        -- 🔹 Notifikasi lokal
        game.StarterGui:SetCore("SendNotification", {
            Title = "RockPaper",
            Text = "RockPaper mode activated by " .. client.Name
        })

        -- 🔹 Notifikasi global
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

            -- 🔹 Notifikasi global setelah selesai
            local channel2 = Vars.TextChatService.TextChannels and Vars.TextChatService.TextChannels.RBXGeneral
            if channel2 then
                pcall(function()
                    channel2:SendAsync("RockPaper mode deactivated!")
                end)
            end

            -- 🔹 Notifikasi lokal
            game.StarterGui:SetCore("SendNotification", {
                Title = "RockPaper",
                Text = "RockPaper mode deactivated"
            })
        end)

        print("[COMMAND] RockPaper mode activated by", client.Name, "target:", targetPlayer and targetPlayer.Name or "None")
    end
}
