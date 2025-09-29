-- Ikuti.lua
-- Command !ikuti untuk mengikuti pemain VIP dengan formasi tetap

return {
    Execute = function(msg, client)
        local vars = _G.BotVars
        local RunService = vars.RunService or game:GetService("RunService")
        local player = vars.LocalPlayer

        -- Izinkan follow dan matikan shield/row sementara
        vars.FollowAllowed = true
        vars.ShieldActive = false
        vars.RowActive = false
        vars.CurrentFormasiTarget = client

        local humanoid, myRootPart, moving

        -- 🔹 Fungsi update referensi humanoid & rootpart
        local function updateBotRefs()
            local character = player.Character or player.CharacterAdded:Wait()
            humanoid = character:WaitForChild("Humanoid")
            myRootPart = character:WaitForChild("HumanoidRootPart")
        end
        player.CharacterAdded:Connect(updateBotRefs)
        updateBotRefs()

        -- 🔹 Fungsi move ke posisi target
        local function moveToPosition(targetPos)
            if not humanoid or not myRootPart then return end
            if moving then return end
            if (myRootPart.Position - targetPos).Magnitude < 2 then return end

            moving = true
            humanoid:MoveTo(targetPos)
            humanoid.MoveToFinished:Wait()
            moving = false
        end

        -- 🔹 Putuskan koneksi lama dulu agar tidak menumpuk
        if vars.FollowConnection then vars.FollowConnection:Disconnect() end

        -- 🔹 Setup koneksi heartbeat untuk mengikuti VIP
        vars.FollowConnection = RunService.Heartbeat:Connect(function()
            if not vars.FollowAllowed or not client.Character then return end
            local targetHRP = client.Character:FindFirstChild("HumanoidRootPart")
            if not targetHRP then return end

            -- 🔹 Ambil jarak dari UI
            local jarakIkut = tonumber(vars.JarakIkut) or 5
            local followSpacing = tonumber(vars.FollowSpacing) or 2

            -- 🔹 Definisi urutan bot FIXED (bukan sort UserId)
            local orderedBots = {
                "8802945328", -- Bot1 - XBODYGUARDVIP01
                "8802949363", -- Bot2 - XBODYGUARDVIP02
                "8802939883", -- Bot3 - XBODYGUARDVIP03
                "8802998147", -- Bot4 - XBODYGUARDVIP04
            }

            -- Cari index bot ini di formasi
            local myUserId = tostring(player.UserId)
            local index = 1
            for i, uid in ipairs(orderedBots) do
                if uid == myUserId then
                    index = i
                    break
                end
            end

            -- 🔹 Hitung posisi mengikuti VIP
            local followPos = targetHRP.Position - targetHRP.CFrame.LookVector * (jarakIkut + (index - 1) * followSpacing)
            moveToPosition(followPos)
        end)

        print("[COMMAND] Bot following client:", client.Name)
    end
}
