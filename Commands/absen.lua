-- ✅ Absen.lua (Auto chat absen sesuai jumlah bot online + debug)
return {
    Execute = function(msg, client)
        local vars = _G.BotVars or {}
        local Players = game:GetService("Players")
        local TextChatService = game:GetService("TextChatService")
        local RunService = game:GetService("RunService")

        local localPlayer = vars.LocalPlayer or Players.LocalPlayer
        local botMapping = vars.BotMapping or {
            ["8802945328"] = "Bot1",
            ["8802949363"] = "Bot2",
            ["8802939883"] = "Bot3",
            ["8802998147"] = "Bot4",
        }

        print("[Absen] Executing Absen command for", localPlayer.Name)

        -- 🔹 Ambil daftar bot online
        local onlineBots = {}
        for idStr, _ in pairs(botMapping) do
            local plr = Players:GetPlayerByUserId(tonumber(idStr))
            if plr and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                table.insert(onlineBots, plr)
                print("[Absen] Bot online:", plr.Name)
            end
        end
        table.sort(onlineBots, function(a,b) return a.UserId < b.UserId end)

        -- 🔹 Pastikan localPlayer termasuk di onlineBots
        local isOnline = false
        for _, bot in ipairs(onlineBots) do
            if bot == localPlayer then
                isOnline = true
                break
            end
        end
        if not isOnline then
            table.insert(onlineBots, localPlayer)
            print("[Absen] Local player added to onlineBots:", localPlayer.Name)
        end

        print("[Absen] Total bots online:", #onlineBots)

        -- 🔹 Hanya jalankan jika localPlayer termasuk onlineBots
        local myIndex = 1
        for i, bot in ipairs(onlineBots) do
            if bot == localPlayer then
                myIndex = i
                print("[Absen] Local player index:", myIndex)
                break
            end
        end

        -- 🔹 Chat awal global
        local channel = TextChatService.TextChannels and TextChatService.TextChannels.RBXGeneral
        if channel and myIndex == 1 then
            pcall(function()
                print("[Absen] Sending initial message: Siap laksanakan! Mulai Berhitung")
                channel:SendAsync("Siap laksanakan! Mulai Berhitung")
            end)
        end

        -- 🔹 Delay singkat sebelum mulai hitung
        task.delay(2, function()
            for i, bot in ipairs(onlineBots) do
                if bot == localPlayer then
                    task.delay((i-1) * 2, function()
                        if channel then
                            pcall(function()
                                print("[Absen] Sending number:", i, "from", localPlayer.Name)
                                channel:SendAsync(tostring(i))
                            end)
                        end
                    end)
                end
            end
        end)
    end
}
