-- Row.lua
-- Command !row: Bot membentuk barisan kiri & kanan di belakang pemain target (5 bot dukungan)

return {
    Execute = function(msg, client)
        local vars = _G.BotVars
        local RunService = vars.RunService
        local player = vars.LocalPlayer

        if not RunService then
            warn("[Row] RunService tidak tersedia!")
            return
        end

        -- 🔹 Nonaktifkan mode lain
        vars.RowActive = not vars.RowActive
        vars.FollowAllowed = false
        vars.ShieldActive = false
        vars.FrontlineActive = false
        vars.CurrentFormasiTarget = client

        if not vars.RowActive then
            print("[ROW] Dinonaktifkan")
            if vars.RowConnection then
                pcall(function() vars.RowConnection:Disconnect() end)
                vars.RowConnection = nil
            end
            return
        end

        print("[ROW] Formasi Row diaktifkan. Target:", client.Name)

        -- Referensi bot
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
        if vars.RowConnection then
            pcall(function() vars.RowConnection:Disconnect() end)
            vars.RowConnection = nil
        end

        -- 🔹 Loop utama barisan (5 bot total)
        if RunService.Heartbeat then
            vars.RowConnection = RunService.Heartbeat:Connect(function()
                if not vars.RowActive or not client.Character then return end
                local targetHRP = client.Character:FindFirstChild("HumanoidRootPart")
                if not targetHRP then return end

                -- 🔹 Urutan Bot termasuk Bot5
                local orderedBots = {
                    "10191476366", -- B1 depan kiri
                    "10191480511", -- B2 depan kanan
                    "10191462654", -- B3 belakang kiri
                    "10190853828", -- B4 belakang kanan
                    "10191023081", -- B5 tengah belakang (Bot5)
                    "10191070611", -- B6 tambahan
                    "10191489151", -- B7 tambahan
                    "10191571531", -- B8 tambahan
                }

                local myUserId = tostring(player.UserId)
                local index = 1
                for i, uid in ipairs(orderedBots) do
                    if uid == myUserId then
                        index = i
                        break
                    end
                end

                -- 🔹 Jarak formasi
                local jarakBelakang = tonumber(vars.JarakIkut) or 4
                local jarakAntarBaris = tonumber(vars.RowSpacing) or 3
                local jarakSamping = tonumber(vars.SideSpacing) or 3

                -- 🔹 Offset posisi per bot
                local offsetMap = {
                    [1] = Vector3.new(-jarakSamping, 0, -jarakBelakang),                          -- kiri depan
                    [2] = Vector3.new(jarakSamping, 0, -jarakBelakang),                           -- kanan depan
                    [3] = Vector3.new(-jarakSamping * 1.2, 0, -jarakBelakang - jarakAntarBaris),  -- kiri belakang
                    [4] = Vector3.new(jarakSamping * 1.2, 0, -jarakBelakang - jarakAntarBaris),   -- kanan belakang
                    [5] = Vector3.new(0, 0, -jarakBelakang - (jarakAntarBaris * 1.5)),            -- ✅ Bot5 di tengah belakang
                }

                local offset = offsetMap[index] or Vector3.zero
                local cframe = targetHRP.CFrame
                local targetPos =
                    cframe.Position
                    + cframe.RightVector * offset.X
                    + cframe.UpVector * offset.Y
                    + cframe.LookVector * offset.Z

                moveToPosition(targetPos, targetHRP.Position + targetHRP.CFrame.LookVector * 50)
            end)
        else
            warn("[Row] RunService.Heartbeat tidak tersedia!")
        end
    end
}
