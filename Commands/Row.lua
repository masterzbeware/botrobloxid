-- Row.lua
-- Command !row: Bot membentuk dua barisan (kiri & kanan) di belakang pemain target

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

        -- 🔹 Notifikasi status
        game.StarterGui:SetCore("SendNotification", {
            Title = "Formation Command",
            Text = "Row " .. (vars.RowActive and "Activated" or "Deactivated")
        })

        if not vars.RowActive then
            print("[ROW] Dinonaktifkan")
            return
        end

        print("[ROW] Formasi Row diaktifkan. Target:", client.Name)

        -- Kirim pesan ke chat
        local channel = vars.TextChatService and vars.TextChatService.TextChannels and vars.TextChatService.TextChannels.RBXGeneral
        if channel then
            pcall(function()
                channel:SendAsync("Siap barisan kiri & kanan dibentuk!")
            end)
        end

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
            if (myRootPart.Position - targetPos).Magnitude < 2 then return end

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

        -- Putuskan koneksi lama
        if vars.RowConnection then pcall(function() vars.RowConnection:Disconnect() end) vars.RowConnection = nil end

        -- 🔹 Loop utama barisan 2 kiri-kanan
        if RunService.Heartbeat then
            vars.RowConnection = RunService.Heartbeat:Connect(function()
                if not vars.RowActive or not client.Character then return end
                local targetHRP = client.Character:FindFirstChild("HumanoidRootPart")
                if not targetHRP then return end

                -- Mapping bot
                local orderedBots = {
                    "8802945328", -- Bot1
                    "8802949363", -- Bot2
                    "8802939883", -- Bot3
                    "8802998147", -- Bot4
                }

                local myUserId = tostring(player.UserId)
                local index = 1
                for i, uid in ipairs(orderedBots) do
                    if uid == myUserId then
                        index = i
                        break
                    end
                end

                -- 🔹 Posisi dua barisan kiri & kanan
                local jarakBelakang = tonumber(vars.JarakIkut) or 6
                local jarakAntarBaris = tonumber(vars.RowSpacing) or 4
                local jarakSamping = tonumber(vars.SideSpacing) or 5

                -- Baris dihitung per 2 bot: (1 kiri, 2 kanan), (3 kiri, 4 kanan)
                local rowIndex = math.floor((index - 1) / 2)
                local isLeft = ((index - 1) % 2 == 0)

                local backOffset = jarakBelakang + (rowIndex * jarakAntarBaris)
                local sideOffset = (isLeft and -1 or 1) * jarakSamping

                -- Posisi akhir formasi
                local targetPos =
                    targetHRP.Position
                    - targetHRP.CFrame.LookVector * backOffset
                    + targetHRP.CFrame.RightVector * sideOffset

                moveToPosition(targetPos, targetHRP.Position + targetHRP.CFrame.LookVector * 50)
            end)
        else
            warn("[Row] RunService.Heartbeat tidak tersedia!")
        end
    end
}
