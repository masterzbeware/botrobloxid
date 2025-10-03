-- Reporting.lua
-- Command: !reporting {username/displayname}
-- Contoh: !reporting Jshdh

return {
    Execute = function(msg, client)
        local vars = _G.BotVars or {}
        local TextChatService = vars.TextChatService or game:GetService("TextChatService")

        -- Ambil argumen setelah !reporting
        local args = string.split(msg, " ")
        local targetName = args[2] or "UnknownPlayer"

        -- Aktifkan Reporting Mode
        vars.ReportingActive = true
        vars.ReportingTarget = targetName

        -- Kirim chat berulang tiap 10 detik selama ReportingActive = true
        local channel = TextChatService.TextChannels and TextChatService.TextChannels:FindFirstChild("RBXGeneral")
        if channel then
            task.spawn(function()
                while vars.ReportingActive do
                    pcall(function()
                        channel:SendAsync("⚠️ Melakukan Reporting dengan akun @" .. vars.ReportingTarget .. " ke sistem moderasi Roblox...")
                        channel:SendAsync("⚠️ Data @" .. vars.ReportingTarget .. " sudah terkirim. Menunggu respon moderator...")
                    end)
                    task.wait(10) -- cooldown 10 detik
                end
            end)
        else
            warn("Channel RBXGeneral tidak ditemukan!")
        end
    end
}
