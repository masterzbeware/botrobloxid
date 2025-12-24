return {
    Execute = function(msg, client)
        local vars = _G.BotVars
        local RunService = vars.RunService
        local player = vars.LocalPlayer

        if not RunService then
            warn("[Barrier] RunService tidak tersedia!")
            return
        end

        -- 🔹 Nonaktifkan formasi lain agar tidak bentrok
        vars.FollowAllowed = false
        if vars.FollowConnection then
            pcall(function() vars.FollowConnection:Disconnect() end)
            vars.FollowConnection = nil
        end

        vars.RowActive = false
        vars.SquareActive = false
        vars.WedgeActive = false
        vars.ShieldActive = false
        vars.FrontlineActive = false
        vars.CircleMoveActive = false
        vars.PushupActive = false
        vars.SyncActive = false
        vars.ReportingActive = false
        vars.RoomVIPActive = false

        -- 🔹 Toggle Barrier
        vars.BarrierActive = not vars.BarrierActive
        vars.CurrentFormasiTarget = client

        if not vars.BarrierActive then
            print("[BARRIER] Dinonaktifkan")
            if vars.BarrierConnection then
                pcall(function() vars.BarrierConnection:Disconnect() end)
                vars.BarrierConnection = nil
            end
            return
        end

        print("[BARRIER] Formasi Barrier diaktifkan. Target:", client.Name)

        -- 🔹 Referensi karakter
        local humanoid, myRootPart
        local function updateBotRefs()
            local character = player.Character or player.CharacterAdded:Wait()
            humanoid = character:WaitForChild("Humanoid")
            myRootPart = character:WaitForChild("HumanoidRootPart")
        end
        player.CharacterAdded:Connect(updateBotRefs)
        updateBotRefs()

        local moving = false
        local function moveToPosition(targetPos, lookVector)
            if not humanoid or not myRootPart then return end
            if moving then return end

            local distance = (myRootPart.Position - targetPos).Magnitude
            if distance < 2.5 then return end

            moving = true
            local hipOffset = humanoid.HipHeight / 2
            targetPos = targetPos + Vector3.new(0, hipOffset, 0)
            humanoid:MoveTo(targetPos)

            if humanoid:GetState() == Enum.HumanoidStateType.Jumping then
                humanoid:ChangeState(Enum.HumanoidStateType.Running)
            end

            humanoid.MoveToFinished:Wait()
            moving = false

            if lookVector then
                myRootPart.CFrame = CFrame.new(targetPos, targetPos + lookVector)
            end
        end

        -- 🔹 Hapus koneksi lama jika ada
        if vars.BarrierConnection then
            pcall(function() vars.BarrierConnection:Disconnect() end)
            vars.BarrierConnection = nil
        end

        -- 🔹 Heartbeat loop
        if RunService.Heartbeat then
            vars.BarrierConnection = RunService.Heartbeat:Connect(function()
                if not vars.BarrierActive or not client.Character then return end

                local targetHRP = client.Character:FindFirstChild("HumanoidRootPart")
                if not targetHRP then return end

                -- 🔹 Urutan bot
                local orderedBots = {
                    "8802945328",
                    "8802939883",
                    "8802949363",
                    "8802998147",
                    "8802991722",
                }

                local myUserId = tostring(player.UserId)
                local index = 1
                for i, uid in ipairs(orderedBots) do
                    if uid == myUserId then
                        index = i
                        break
                    end
                end

                -- 🔹 Jarak dan posisi offset
                local jarakSamping = tonumber(vars.SideSpacing) or 3
                local jarakDepanBelakang = tonumber(vars.FrontBackSpacing) or 0
                local jarakDepanVIP = tonumber(vars.FrontSpacing) or 4

                local offsetMap = {
                    [1] = Vector3.new(-2 * jarakSamping, 0, jarakDepanBelakang),
                    [2] = Vector3.new(-jarakSamping, 0, jarakDepanBelakang),
                    [3] = Vector3.new(jarakSamping, 0, jarakDepanBelakang),
                    [4] = Vector3.new(2 * jarakSamping, 0, jarakDepanBelakang),
                    [5] = Vector3.new(0, 0, -jarakDepanVIP),
                }

                local offset = offsetMap[index] or Vector3.zero
                local cframe = targetHRP.CFrame
                local targetPos = (
                    cframe.Position
                    + cframe.RightVector * offset.X
                    + cframe.UpVector * offset.Y
                    + cframe.LookVector * offset.Z
                )

                local distance = (myRootPart.Position - targetPos).Magnitude
                if distance > 2 then
                    moveToPosition(targetPos, targetHRP.CFrame.LookVector)
                end
            end)
        else
            warn("[Barrier] RunService.Heartbeat tidak tersedia!")
        end
    end
}
