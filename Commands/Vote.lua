-- Vote.lua
-- Command !voteskip: Mengirim perintah vote skip musik lewat RemoteFunction
-- Bisa dijalankan oleh semua bot sekaligus atau bot tertentu (!voteskip1, !voteskip2, dst.)

return {
    Execute = function(msg, client)
        local vars = _G.BotVars
        local player = vars.LocalPlayer

        -- 🔹 Daftar Bot
        local orderedBots = {
            ["10191476366"] = "Bot1",
            ["10191480511"] = "Bot2",
            ["10191462654"] = "Bot3",
            ["10190853828"] = "Bot4",
            ["10191023081"] = "Bot5",
            ["10191070611"] = "Bot6",
            ["10191489151"] = "Bot7",
            ["10191571531"] = "Bot8",
        }

        local myUserId = tostring(player.UserId)
        local botName = orderedBots[myUserId]

        if not botName then
            warn("[VoteSkip] Bot ini tidak terdaftar dalam daftar orderedBots.")
            return
        end

        -- 🔹 Cek jika command untuk bot tertentu (!voteskip1, !voteskip2, dst.)
        local targetBot = msg:lower():match("!voteskip(%d)")
        if targetBot then
            local targetIndex = tonumber(targetBot)
            local botIndex = tonumber(botName:match("%d+"))
            if botIndex ~= targetIndex then
                return -- Bukan bot target → abaikan
            end
        end

        -- 🔹 Jalankan VoteSkip
        local success, err = pcall(function()
            local ReplicatedStorage = game:GetService("ReplicatedStorage")

            local musicInfo = ReplicatedStorage
                :WaitForChild("Connections")
                :WaitForChild("dataProviders")
                :WaitForChild("musicInfo")

            local args = { "voteSkip" }
            musicInfo:InvokeServer(unpack(args))

            print(string.format("[VoteSkip] %s mengirim vote skip musik.", botName))
        end)

        if not success then
            warn(string.format("[VoteSkip] %s gagal mengirim vote skip:", botName), err)
        end
    end
}
