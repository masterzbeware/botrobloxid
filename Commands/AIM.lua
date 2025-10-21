-- Aim.lua
-- Safe Target Visualizer (non-aimbot). 
-- Menandai NPC terdekat untuk keperluan debug / development saja.
-- Tidak mengubah Camera.CFrame atau input pemain.

return {
    Execute = function(tab)
        -- Guard: pastikan tab ada
        local vars = _G.BotVars or {}
        _G.BotVars = vars
        local Tabs = vars.Tabs or {}
        tab = tab or Tabs.Combat

        if not tab then
            warn("[Visualizer] Tab Combat tidak ditemukan! Pastikan WindowTab.lua sudah dimuat.")
            return
        end

        -- Jika sudah pernah dijalankan, matikan koneksi lama dulu agar tidak duplikat
        if vars._VisualizerCleanup then
            -- panggil fungsi cleanup yang tersimpan
            pcall(vars._VisualizerCleanup)
            vars._VisualizerCleanup = nil
        end

        local RunService = game:GetService("RunService")
        local Camera = workspace.CurrentCamera
        local Players = game:GetService("Players")
        local LocalPlayer = Players.LocalPlayer

        -- Default variabel (dapat disimpan di _G.BotVars)
        vars.ShowVisualizer = vars.ShowVisualizer or false
        vars.TargetPart = vars.TargetPart or "Head"
        vars.CircleSize = vars.CircleSize or 150
        vars.HighlightColor = vars.HighlightColor or Color3.fromRGB(0, 255, 255)
        vars.DebugMode = vars.DebugMode or false
        vars.ScreenTargetRadius = vars.ScreenTargetRadius or vars.CircleSize

        -- UI group
        local Group = tab:AddLeftGroupbox("Auto Aim / Headshot (Visualizer)")

        Group:AddToggle("ShowVisualizer", {
            Text = "Tampilkan Visual Target",
            Default = vars.ShowVisualizer,
            Callback = function(v)
                vars.ShowVisualizer = v
                print("[Visualizer]", v and "Aktif ✅" or "Nonaktif ❌")
            end
        })

        Group:AddDropdown("TargetPart", {
            Text = "Pilih Target Part",
            Default = vars.TargetPart,
            Values = { "Head", "Torso", "HumanoidRootPart" },
            Callback = function(value)
                vars.TargetPart = value
                print("[Visualizer] Target part:", value)
            end
        })

        Group:AddToggle("ShowCircle", {
            Text = "Tampilkan Circle Tengah",
            Default = true,
            Callback = function(v) vars.ShowCircle = v end
        })

        Group:AddSlider("CircleSize", {
            Text = "Ukuran Circle (px)",
            Default = vars.CircleSize,
            Min = 50,
            Max = 400,
            Rounding = 0,
            Callback = function(v)
                vars.CircleSize = v
                vars.ScreenTargetRadius = v
            end
        })

        Group:AddToggle("DebugMode", {
            Text = "Debug Mode (console)",
            Default = vars.DebugMode,
            Callback = function(v) vars.DebugMode = v end
        })

        -- Utility: validasi NPC (sesuaikan nama/model sesuai game)
        local function isValidNPC(model)
            if not model or not model:IsA("Model") then return false end
            if model == LocalPlayer.Character then return false end
            local humanoid = model:FindFirstChildOfClass("Humanoid")
            if not humanoid or humanoid.Health <= 0 then return false end
            -- Contoh kriteria: punya target part
            if model:FindFirstChild(vars.TargetPart) then
                return true
            end
            return false
        end

        -- Struktur data target (menyimpan BasePart)
        local validTargets = {}          -- array of parts
        local targetLookup = {}          -- map part -> true (memudahkan cek/removal)

        -- Menambahkan target jika valid
        local function tryAddTarget(model)
            -- model may be any descendant; ensure it's Model
            if not model or not model:IsA("Model") then return end
            if not isValidNPC(model) then return end
            local part = model:FindFirstChild(vars.TargetPart)
            if part and part:IsA("BasePart") and not targetLookup[part] then
                table.insert(validTargets, part)
                targetLookup[part] = true
                if vars.DebugMode then
                    print("[Visualizer] Added target:", model:GetFullName())
                end
            end
        end

        -- Remove all parts that belong to model
        local function removeTargetModel(model)
            if not model then return end
            for i = #validTargets, 1, -1 do
                local part = validTargets[i]
                if part and part.Parent == model then
                    targetLookup[part] = nil
                    table.remove(validTargets, i)
                    if vars.DebugMode then
                        print("[Visualizer] Removed target (model):", model:GetFullName())
                    end
                end
            end
        end

        -- Remove a specific part (cleanup)
        local function removeTargetPart(part)
            if not part then return end
            if not targetLookup[part] then return end
            for i = #validTargets, 1, -1 do
                if validTargets[i] == part then
                    table.remove(validTargets, i)
                    break
                end
            end
            targetLookup[part] = nil
            if vars.DebugMode then
                print("[Visualizer] Removed target (part):", tostring(part))
            end
        end

        -- Inisialisasi: tambahkan model-model yang sudah ada di workspace
        for _, child in ipairs(workspace:GetChildren()) do
            tryAddTarget(child)
        end

        -- Event listener: ChildAdded / ChildRemoved (workspace)
        local connAdded, connRemoved
        connAdded = workspace.ChildAdded:Connect(function(child)
            -- child bisa Model atau folder; coba tambahkan
            -- many games spawn inside subfolders; jika child bukan model, cek descendants (optional)
            if child:IsA("Model") then
                tryAddTarget(child)
            else
                -- jika child adalah Folder atau lain, periksa immediate children
                for _, v in ipairs(child:GetChildren()) do
                    if v:IsA("Model") then
                        tryAddTarget(v)
                    end
                end
            end
        end)

        connRemoved = workspace.ChildRemoved:Connect(function(child)
            if child:IsA("Model") then
                removeTargetModel(child)
            else
                for _, v in ipairs(child:GetChildren()) do
                    if v:IsA("Model") then
                        removeTargetModel(v)
                    end
                end
            end
        end)

        -- Selain itu, juga perlu mendeteksi jika part di dalam model dihapus atau diganti
        -- Kita akan attach event ke model saat terdeteksi untuk mendeteksi part removal/humanoid death
        local modelConns = {} -- model -> { ChildRemovedConn, HumDiedConn }

        local function attachModelListeners(model)
            if not model or not model:IsA("Model") then return end
            if modelConns[model] then return end

            local childRemovedConn
            childRemovedConn = model.ChildRemoved:Connect(function(child)
                if child and child.Name == vars.TargetPart then
                    -- part yang dipakai sebagai target hilang -> hapus part dari daftar
                    for i = #validTargets, 1, -1 do
                        local p = validTargets[i]
                        if p and p.Parent == model and p.Name == child.Name then
                            removeTargetPart(p)
                        end
                    end
                end
            end)

            local hum = model:FindFirstChildOfClass("Humanoid")
            local humDiedConn
            if hum then
                humDiedConn = hum:GetPropertyChangedSignal("Health"):Connect(function()
                    if hum.Health <= 0 then
                        removeTargetModel(model)
                    end
                end)
            end

            modelConns[model] = {
                ChildRemoved = childRemovedConn,
                HumDied = humDiedConn,
            }
        end

        local function detachModelListeners(model)
            local t = modelConns[model]
            if not t then return end
            if t.ChildRemoved then pcall(t.ChildRemoved.Disconnect, t.ChildRemoved) end
            if t.HumDied then pcall(t.HumDied.Disconnect, t.HumDied) end
            modelConns[model] = nil
        end

        -- Attach listeners for models that already exist
        for _, child in ipairs(workspace:GetChildren()) do
            if child:IsA("Model") then
                attachModelListeners(child)
            end
        end

        -- Also attach when new model added
        local connAttach = workspace.ChildAdded:Connect(function(child)
            if child:IsA("Model") then
                attachModelListeners(child)
            else
                for _, v in ipairs(child:GetChildren()) do
                    if v:IsA("Model") then
                        attachModelListeners(v)
                    end
                end
            end
        end)

        -- Lightweight periodic validation to remove invalid parts (race conditions)
        local validationRunning = true
        local validationTask = task.spawn(function()
            while validationRunning do
                for i = #validTargets, 1, -1 do
                    local part = validTargets[i]
                    if not part or not part.Parent or not part:IsDescendantOf(workspace) then
                        -- remove invalid part
                        targetLookup[part] = nil
                        table.remove(validTargets, i)
                    else
                        -- check parent humanoid health
                        local hum = part.Parent:FindFirstChildOfClass("Humanoid")
                        if not hum or hum.Health <= 0 then
                            targetLookup[part] = nil
                            table.remove(validTargets, i)
                        end
                    end
                end
                task.wait(0.25)
            end
        end)

        -- Drawing setup (jaga jika Drawing API tidak tersedia)
        local success, Drawing = pcall(function() return Drawing end)
        local drawAvailable = success and typeof(Drawing) == "table"
        local aimCircle, targetCircle
        if drawAvailable then
            pcall(function()
                aimCircle = Drawing.new("Circle")
                aimCircle.Visible = false
                aimCircle.Filled = false
                aimCircle.Transparency = 0.8
                aimCircle.Thickness = 1.5
                aimCircle.Radius = vars.CircleSize

                targetCircle = Drawing.new("Circle")
                targetCircle.Visible = false
                targetCircle.Filled = false
                targetCircle.Transparency = 0.95
                targetCircle.Thickness = 2
                targetCircle.Radius = 8
            end)
        else
            if vars.DebugMode then
                warn("[Visualizer] Drawing API tidak tersedia di lingkungan ini. Visual tidak akan muncul.")
            end
        end

        -- Fungsi cari target terdekat pada layar (center-based)
        local function getClosestTarget()
            if #validTargets == 0 then return nil end
            local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            local best, bestDist = nil, vars.ScreenTargetRadius
            for _, part in ipairs(validTargets) do
                if part and part.Parent then
                    local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
                    if onScreen then
                        local screenPos = Vector2.new(pos.X, pos.Y)
                        local dist = (screenPos - center).Magnitude
                        if dist < bestDist then
                            best = { part = part, screenPos = screenPos, depth = pos.Z }
                            bestDist = dist
                        end
                    end
                end
            end
            return best
        end

        -- Render loop (visual only)
        local renderConn
        renderConn = RunService.RenderStepped:Connect(function()
            if not vars.ShowVisualizer then
                if drawAvailable then
                    pcall(function()
                        aimCircle.Visible = false
                        targetCircle.Visible = false
                    end)
                end
                return
            end

            -- Update circle di center
            if drawAvailable and vars.ShowCircle then
                pcall(function()
                    local center = Camera.ViewportSize / 2
                    aimCircle.Position = Vector2.new(center.X, center.Y)
                    aimCircle.Radius = vars.CircleSize
                    aimCircle.Color = vars.HighlightColor
                    aimCircle.Visible = true
                end)
            end

            -- Tampilkan target terdekat
            local closest = getClosestTarget()
            if closest and drawAvailable then
                pcall(function()
                    targetCircle.Position = closest.screenPos
                    targetCircle.Visible = true
                    -- color berbeda tergantung depth (opsional)
                    targetCircle.Color = Color3.fromHSV(math.clamp((1 / math.max(closest.depth,1)) * 0.1, 0, 1), 1, 1)
                end)
            else
                if drawAvailable then
                    pcall(function() targetCircle.Visible = false end)
                end
            end
        end)

        -- Cleanup function — untuk supaya bisa dijalankan jika skrip dieksekusi ulang
        local function cleanup()
            -- stop validation
            validationRunning = false
            -- disconnect render
            if renderConn and renderConn.Connected then
                pcall(renderConn.Disconnect, renderConn)
            end
            -- disconnect workspace listeners
            if connAdded and connAdded.Connected then pcall(connAdded.Disconnect, connAdded) end
            if connRemoved and connRemoved.Connected then pcall(connRemoved.Disconnect, connRemoved) end
            if connAttach and connAttach.Connected then pcall(connAttach.Disconnect, connAttach) end
            -- detach per-model listeners
            for model, _ in pairs(modelConns) do
                detachModelListeners(model)
            end
            -- destroy drawings
            if drawAvailable then
                pcall(function()
                    if aimCircle then aimCircle:Remove() end
                    if targetCircle then targetCircle:Remove() end
                end)
            end
            -- clear tables
            validTargets = {}
            targetLookup = {}
            modelConns = {}
            if vars.DebugMode then
                print("[Visualizer] Cleanup selesai.")
            end
        end

        -- Save cleanup function supaya jika dieksekusi lagi bisa membersihkan instance lama
        vars._VisualizerCleanup = cleanup

        print("✅ [Visualizer] Target Visualizer siap — hanya visual, aman untuk development/debug.")
    end
}
