-- Wedge.lua
-- Command !wedge: Bot membentuk formasi segitiga (Wedge) di belakang target atau client default
-- Sekarang mendukung 5 bot (Bot5 = posisi tengah belakang)
-- Bisa target pemain dengan DisplayName, Username, atau UserId

return {
    Execute = function(msg, client)
        local vars = _G.BotVars
        local RunService = vars.RunService
        local player = vars.LocalPlayer

        if not RunService then
            warn("[Wedge] RunService tidak tersedia!")
            return
        end

        -- 🔹 Toggle Wedge
        vars.WedgeActive = not vars.WedgeActive

        -- 🔹 Nonaktifkan mode lain agar tidak bentrok
        vars.FollowAllowed = false
        vars.RowActive = false
        vars.SquareActive = false
        vars.ShieldActive = false
        vars.FrontlineActive = false
        vars.CircleMoveActive = false
        vars.PushupActive = false
        vars.SyncActive = false
        vars.ReportingActive = false
        vars.RoomVIPActive = false

        -- 🔹 Tentukan target
        local target = client or vars.ClientRef
        local args = {}
        for word in msg:gmatch("%S+") do table.insert(args, word) end

        if #args > 1 then
            local searchNameOrId = table.concat(args, " ", 2)
            local id = tonumber(searchNameOrId)
            if id then
                local plr = game.Players:GetPlayerByUserId(id)
                if plr then target = plr end
            else
                for _, plr in ipairs(game.Players:GetPlayers()) do
                    if plr.Name:lower():find(searchNameOrId:lower())
                    or plr.DisplayName:lower():find(searchNameOrId:lower()) then
                        target = plr
                        break
                    end
                end
            end
            if not target then
                print("[WEDGE] Target tidak ditemukan. Menggunakan client default.")
                target = vars.ClientRef
            end
        end

        vars.CurrentFormasiTarget = target

        if not vars.WedgeActive then
            print("[WEDGE] Dinonaktifkan")
            if vars.WedgeConnection then
                pcall(function() vars.WedgeConnection:Disconnect() end)
                vars.WedgeConnection = nil
            end
            return
        end

        print("[WEDGE] Formasi Wedge diaktifkan. Target:", target.Name)

        -- 🔹 Referensi karakter bot
        local humanoid, myRootPart, moving
        local function updateBotRefs()
            local character = player.Character or player.CharacterAdded:Wait()
            humanoid = character:WaitForChild("Humanoid")
            myRootPart = character:WaitForChild("HumanoidRootPart")
        end
        player.CharacterAdded:Connect(updateBotRefs)
        updateBotRefs()

        local function moveToPosition(targetPos, lookAtPos)
            if not humanoid or not myRootPart then return end
            if moving then return end
            if (myRootPart.Position - targetPos).Magnitude < 1 then return end

            moving = true
            humanoid:MoveTo(targetPos)
            humanoid.MoveToFinished:Wait()
            moving = false

            if lookAtPos then
                myRootPart.CFrame = CFrame.new(
                    myRootPart.Position,
                    Vector3.new(lookAtPos.X, myRootPart.Position.Y, lookAtPos.Z)
                )
            end
        end

        -- 🔹 Putuskan koneksi lama jika ada
        if vars.WedgeConnection then
            pcall(function() vars.WedgeConnection:Disconnect() end)
            vars.WedgeConnection = nil
        end

        -- 🔹 Loop Heartbeat
        if RunService.Heartbeat then
            vars.WedgeConnection = RunService.Heartbeat:Connect(function()
                if not vars.WedgeActive or not target or not target.Character then return end
                local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
                if not targetHRP then return end

                -- 🔹 Urutan bot (termasuk Bot5)
                local orderedBots = {
                    "10191476366", -- B1 kiri dekat VIP
                    "10191462654", -- B2 kiri jauh
                    "10191480511", -- B3 kanan dekat VIP
                    "10190853828", -- B4 kanan jauh
                    "10191023081", -- B5 tengah belakang
                    "10191070611", -- B6 tambahan, bisa kanan/tengah
                    "10191489151", -- B7 tambahan, bisa kiri/tengah
                    "10191571531", -- B8 tambahan, bisa paling belakang
                }                

                local myUserId = tostring(player.UserId)
                local index = 1
                for i, uid in ipairs(orderedBots) do
                    if uid == myUserId then
                        index = i
                        break
                    end
                end

                -- 🔹 Konfigurasi jarak dari _G.BotVars
                local jarakDepan = tonumber(vars.JarakDepan) or 4
                local jarakBelakang = tonumber(vars.JarakBelakang) or 7
                local jarakSamping = tonumber(vars.SideSpacing) or 3

                -- 🔹 Offset posisi tiap bot
                local offsetMap = {
                    [1] = Vector3.new(-jarakSamping, 0, -jarakDepan),        -- kiri dekat VIP
                    [2] = Vector3.new(-jarakSamping * 2, 0, -jarakBelakang), -- kiri jauh
                    [3] = Vector3.new(jarakSamping, 0, -jarakDepan),         -- kanan dekat VIP
                    [4] = Vector3.new(jarakSamping * 2, 0, -jarakBelakang),  -- kanan jauh
                    [5] = Vector3.new(0, 0, -jarakBelakang - 2),             -- tengah belakang
                }

                local offset = offsetMap[index] or Vector3.zero
                local cframe = targetHRP.CFrame
                local targetPos = (cframe.Position
                    + cframe.RightVector * offset.X
                    + cframe.UpVector * offset.Y
                    + cframe.LookVector * offset.Z)

                moveToPosition(targetPos, targetHRP.Position)
            end)
        else
            warn("[WEDGE] RunService.Heartbeat tidak tersedia!")
        end
    end
}
