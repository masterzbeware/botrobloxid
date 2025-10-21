-- Bullet.lua
-- 💥 Headshot Auto (pakai BulletServiceMultithread.Send) dengan Range sangat besar

return {
    Execute = function()
        local vars = _G.BotVars
        local Window = vars.MainWindow
        local ReplicatedFirst = game:GetService("ReplicatedFirst")
        local Camera = workspace.CurrentCamera
        local UserInputService = game:GetService("UserInputService")

        -- Cari Send remote (Sigma Spy style)
        local ok, Actor = pcall(function() return ReplicatedFirst:WaitForChild("Actor", 2) end)
        if not ok or not Actor then
            warn("[Bullet] Actor tidak ditemukan di ReplicatedFirst.")
            return
        end

        local ok2, BulletSvc = pcall(function() return Actor:WaitForChild("BulletServiceMultithread", 2) end)
        if not ok2 or not BulletSvc then
            warn("[Bullet] BulletServiceMultithread tidak ditemukan di Actor.")
            return
        end

        local ok3, Send = pcall(function() return BulletSvc:WaitForChild("Send", 2) end)
        if not ok3 or not Send then
            warn("[Bullet] Remote 'Send' tidak ditemukan.")
            return
        end

        -- UI
        local Tabs = { Bullet = Window:AddTab("BULLET", "zap") }
        local Group = Tabs.Bullet:AddLeftGroupbox("Headshot Control")

        Group:AddToggle("EnableHeadshot", {
            Text = "Aktifkan Headshot Semua NPC (Range Tak Terbatas)",
            Default = false,
            Callback = function(Value)
                vars.ToggleHeadshot = Value
            end
        })

        -- Ambil semua kepala NPC Male AI_
        local function getAllNPCHeads()
            local result = {}
            for _, model in ipairs(workspace:GetDescendants()) do
                if model:IsA("Model") and model.Name == "Male" then
                    for _, c in ipairs(model:GetChildren()) do
                        if string.sub(c.Name,1,3) == "AI_" then
                            local head = model:FindFirstChild("Head")
                            if head then table.insert(result, head) end
                            break
                        end
                    end
                end
            end
            return result
        end

        -- Helper: buat payload sesuai contoh Sigma Spy (dengan Range besar)
        local function makePayload(originCFrame, uid)
            return {
                Velocity = 3110.666858146635,
                Caliber = "intermediaterifle_556x45mmNATO_M855",
                UID = uid,
                Ignore = workspace.Male, -- sesuai contoh; sesuaikan kalau perlu
                OriginCFrame = originCFrame,
                Tracer = "Default",
                Replicate = true,
                Local = true,
                Range = 1e9, -- hampir tak terbatas
            }
        end

        -- Fungsi tembak kepala menggunakan Send:Fire
        local function shootAllHeads()
            if not vars.ToggleHeadshot then return end

            local heads = getAllNPCHeads()
            if #heads == 0 then return end

            local originPos = Camera.CFrame.Position
            local originCFrame = Camera.CFrame

            for _, head in ipairs(heads) do
                if head and head.Parent then
                    -- UID: bisa digenerate per tembakan supaya unik
                    local uid = tostring(game:GetService("HttpService"):GenerateGUID(false))

                    -- Build payload & kirim
                    local payload = makePayload(originCFrame, uid)

                    -- Versi 1: Fire sebagai "1, UID, payload" (format Sigma Spy)
                    pcall(function()
                        Send:Fire(1, uid, payload)
                    end)

                    -- Versi 2 (opsional fallback): Fire posisi origin->target (beberapa game juga memakai ini)
                    -- pcall(function()
                    --     Send:Fire(0, originPos, head.Position)
                    -- end)
                end
            end
        end

        -- Klik kiri untuk menembak semua kepala NPC
        UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                shootAllHeads()
            end
        end)

        -- Optional: auto-fire loop (non-blocking)
        task.spawn(function()
            while true do
                task.wait(0.05)
                if vars.ToggleHeadshot then
                    shootAllHeads()
                end
            end
        end)
    end
}
