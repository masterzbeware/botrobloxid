-- Wedge.lua
-- Command !wedge: Bot membentuk formasi segitiga (Wedge) di belakang target atau client jika tidak ada target
-- Sekarang mendukung 5 bot (Bot5 = posisi tengah belakang)

return {
    Execute = function(msg, client)
        local vars = _G.BotVars
        local RunService = vars.RunService
        local player = vars.LocalPlayer

        if not RunService then
            warn("[Wedge] RunService tidak tersedia!")
            return
        end

        -- 🔹 Nonaktifkan mode lain
        vars.WedgeActive = not vars.WedgeActive
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
        local target
        local args = {}
        for word in msg:gmatch("%S+") do
            table.insert(args, word)
        end

        if #args > 1 then
            local searchName = table.concat(args, " ", 2)
            for _, plr in ipairs(game.Players:GetPlayers()) do
                if plr.DisplayName:lower():find(searchName:lower()) or plr.Name:lower():find(searchName:lower()) then
                    target = plr
                    break
                end
            end
            if not target then
                print("[WEDGE] Target tidak ditemukan. Menggunakan client sebagai target.")
                target = client
            end
        else
            target = client
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

        -- 🔹 Putuskan koneksi lama
        if vars.WedgeConnection then
            pcall(function() vars.WedgeConnection:Disconnect() end)
            vars.WedgeConnection = nil
        end

        -- 🔹 Loop Heartbeat
        if RunService.Heartbeat then
            vars.WedgeConnection = RunService.Heartbeat:Connect(function()
                if not vars.WedgeActive or not target.Character then return end
                local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
                if not targetHRP then return end

                -- 🔹 Urutan bot (termasuk Bot5)
                local orderedBots = {
                    "8802945328", -- B1 kiri dekat VIP
                    "8802939883", -- B2 kiri jauh
                    "8802949363", -- B3 kanan dekat VIP
                    "8802998147", -- B4 kanan jauh
                    "8802991722", -- ✅ B5 tengah belakang
                }

                local myUserId = tostring(player.UserId)
                local index = 1
                for i, uid in ipairs(orderedBots) do
                    if uid == myUserId then
                        index = i
                        break
                    end
                end

                -- 🔹 Konfigurasi jarak
                local jarakDepan = tonumber(vars.JarakDepan) or 4
                local jarakBelakang = tonumber(vars.JarakBelakang) or 7
                local jarakSamping = tonumber(vars.SideSpacing) or 3

                -- 🔹 Offset posisi tiap bot
                local offsetMap = {
                    [1] = Vector3.new(-jarakSamping, 0, -jarakDepan),       -- kiri dekat VIP
                    [2] = Vector3.new(-jarakSamping * 2, 0, -jarakBelakang), -- kiri jauh
                    [3] = Vector3.new(jarakSamping, 0, -jarakDepan),        -- kanan dekat VIP
                    [4] = Vector3.new(jarakSamping * 2, 0, -jarakBelakang), -- kanan jauh
                    [5] = Vector3.new(0, 0, -jarakBelakang - 2),            -- ✅ tengah belakang
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
            warn("[Wedge] RunService.Heartbeat tidak tersedia!")
        end
    end
}
