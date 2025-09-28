-- Absen.lua
return {
    Execute = function(msg, client)
        local vars = _G.BotVars or {}
        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        local TextChatService = game:GetService("TextChatService")

        local localPlayer = vars.LocalPlayer or Players.LocalPlayer
        local identity = vars.BotIdentity or "Unknown Bot"

        -- Daftar bot tetap urut
        local botOrder = {
            "Bot1 - XBODYGUARDVIP01",
            "Bot2 - XBODYGUARDVIP02",
            "Bot3 - XBODYGUARDVIP03",
            "Bot4 - XBODYGUARDVIP04"
        }

        -- Flag untuk memastikan absen hanya sekali
        if vars.AbsenActive then
            return
        end
        vars.AbsenActive = true

        -- 🔹 Notifikasi lokal
        game.StarterGui:SetCore("SendNotification", {
            Title = "Absen Command",
            Text = identity .. " mulai absen!"
        })

        -- 🔹 Kirim chat "Siap absen!" ke global
        local channel = TextChatService.TextChannels and TextChatService.TextChannels.RBXGeneral
        if channel then
            pcall(function()
                channel:SendAsync("Siap absen!")
            end)
        end

        -- 🔹 Hitung urutan bot sesuai identity
        local myIndex = table.find(botOrder, identity) or 1
        local delayBetweenBots = 1.5

        task.delay(delayBetweenBots * (myIndex - 1), function()
            if channel then
                pcall(function()
                    channel:SendAsync(identity .. " hadir! Urutan ke-" .. myIndex)
                end)
            end
        end)

        -- 🔹 Reset flag setelah semua bot selesai absen
        local totalBots = #botOrder
        task.delay(delayBetweenBots * totalBots, function()
            vars.AbsenActive = false
            if channel then
                pcall(function()
                    channel:SendAsync("Semua bot sudah absen!")
                end)
            end
        end)
    end
}
