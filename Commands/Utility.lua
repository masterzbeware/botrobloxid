-- Commands/Utility/Utility.lua

return {
    Execute = function(tab)
        local vars = _G.BotVars or {}
        local Tabs = vars.Tabs or {}
        local UtilityTab = tab or Tabs.Visual
  
        if not UtilityTab then
            warn("[Utility] Tab Utility tidak ditemukan!")
            return
        end
  
        -- Load gear module
        local success, Gears = pcall(function()
            return require(game:GetService("ReplicatedStorage").Shared.Configs.Gear)
        end)
        if not success or not Gears then
            warn("❌ Gagal memuat module Gears")
            return
        end
  
        -- Default values sesuai decompiled code
        local defaultMagnify = {
            Binoculars = {30, 65},    -- nilai berbeda
            RangeFinder = {60, 60}    -- nilai sama
        }
  
        -- Groupbox
        local Group = UtilityTab:AddRightGroupbox("Binoculars Infinite Zoom")
  
        vars.InfiniteZoomEnabled = vars.InfiniteZoomEnabled or false
        vars.SelectedGear = vars.SelectedGear or "Binoculars"
        vars.ZoomMin = vars.ZoomMin or 30
  
        -- Function untuk reset ke default
        local function resetToDefault(gearName)
            local gear = Gears[gearName]
            if gear and defaultMagnify[gearName] then
                gear.Magnify = defaultMagnify[gearName]
                print("🔄 " .. gearName .. " direset ke default: " .. table.concat(defaultMagnify[gearName], ", "))
            end
        end
  
        -- Function untuk apply infinite zoom
        local function applyInfiniteZoom(gearName, zoomMin)
            local gear = Gears[gearName]
            if gear and gear.Magnify then
                if gearName == "Binoculars" then
                    -- Binoculars: {zoomMin, 500} - hanya ubah nilai pertama
                    gear.Magnify = {zoomMin, 500}
                else
                    -- RangeFinder: {zoomMin, zoomMin} - kedua nilai sama
                    gear.Magnify = {zoomMin, zoomMin}
                end
                print("✅ Infinite Zoom aktif untuk " .. gearName .. " (Min: " .. zoomMin .. ")")
            end
        end
  
        -- Toggle
        Group:AddToggle("ToggleInfiniteZoom", {
            Text = "Enable Infinite Zoom",
            Default = vars.InfiniteZoomEnabled,
            Callback = function(v)
                vars.InfiniteZoomEnabled = v
                if v then
                    -- Aktifkan infinite zoom
                    applyInfiniteZoom(vars.SelectedGear, vars.ZoomMin)
                else
                    -- Nonaktifkan - reset ke default
                    resetToDefault(vars.SelectedGear)
                    print("❌ Infinite Zoom dimatikan untuk " .. vars.SelectedGear)
                end
            end
        })
  
        -- Dropdown
        Group:AddDropdown("SelectGear", {
            Text = "Select Gear",
            Default = vars.SelectedGear,
            Values = {"Binoculars", "RangeFinder"},
            Callback = function(v)
                -- Reset gear sebelumnya ke default
                if vars.SelectedGear ~= v then
                    resetToDefault(vars.SelectedGear)
                end
                
                vars.SelectedGear = v
                
                -- Update slider default berdasarkan gear yang dipilih
                if v == "Binoculars" then
                    vars.ZoomMin = 30
                else
                    vars.ZoomMin = 60
                end
                
                -- Refresh slider value
                if Group:GetSlider("ZoomSlider") then
                    Group:GetSlider("ZoomSlider"):SetValue(vars.ZoomMin)
                end
                
                -- Jika infinite zoom aktif, apply ke gear baru
                if vars.InfiniteZoomEnabled then
                    applyInfiniteZoom(v, vars.ZoomMin)
                else
                    -- Pastikan gear baru dalam state default
                    resetToDefault(v)
                end
            end
        })
  
        -- Slider untuk bagian pertama Magnify
        Group:AddSlider("ZoomSlider", {
            Text = "Zoom Min Value",
            Default = vars.ZoomMin,
            Min = 1,
            Max = 20,
            Rounding = 0,
            Callback = function(v)
                vars.ZoomMin = v
                if vars.InfiniteZoomEnabled then
                    applyInfiniteZoom(vars.SelectedGear, v)
                end
            end
        })
  
        -- Periodic check supaya Magnify tetap
        if not getgenv().InfiniteZoomHooked then
            getgenv().InfiniteZoomHooked = true
            coroutine.wrap(function()
                while wait(5) do
                    if vars.InfiniteZoomEnabled then
                        local gear = Gears[vars.SelectedGear]
                        if gear and gear.Magnify then
                            if vars.SelectedGear == "Binoculars" then
                                if gear.Magnify[1] ~= vars.ZoomMin then
                                    gear.Magnify = {vars.ZoomMin, 500}
                                end
                            else
                                if gear.Magnify[1] ~= vars.ZoomMin or gear.Magnify[2] ~= vars.ZoomMin then
                                    gear.Magnify = {vars.ZoomMin, vars.ZoomMin}
                                end
                            end
                        end
                    end
                end
            end)()
            print("✅ [Utility] Periodic check Infinite Zoom aktif")
        end
  
        -- Pastikan state awal sesuai
        if not vars.InfiniteZoomEnabled then
            resetToDefault(vars.SelectedGear)
        end
  
        print("✅ [Utility] Infinite Zoom siap digunakan.")
    end
  }