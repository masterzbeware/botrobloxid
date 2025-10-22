-- Commands/Utility/Utility.lua

return {
  Execute = function(tab)
      local vars = _G.BotVars or {}
      local Tabs = vars.Tabs or {}
      local UtilityTab = tab or Tabs.Utility

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

      -- Groupbox
      local Group = UtilityTab:AddLeftGroupbox("Binoculars Infinite Zoom")

      vars.InfiniteZoomEnabled = vars.InfiniteZoomEnabled or false
      vars.SelectedGear = vars.SelectedGear or "Binoculars"
      vars.ZoomMin = vars.ZoomMin or 30

      -- Toggle
      Group:AddToggle("ToggleInfiniteZoom", {
          Text = "Enable Infinite Zoom",
          Default = vars.InfiniteZoomEnabled,
          Callback = function(v)
              vars.InfiniteZoomEnabled = v
              local gear = Gears[vars.SelectedGear]
              if gear then
                  if v then
                      gear.Magnify = {vars.ZoomMin, 500}
                      print("✅ Infinite Zoom aktif untuk " .. vars.SelectedGear)
                  else
                      gear.Magnify = {30, 500} -- reset default
                      print("❌ Infinite Zoom dimatikan untuk " .. vars.SelectedGear)
                  end
              end
          end
      })

      -- Dropdown
      Group:AddDropdown("SelectGear", {
          Text = "Select Gear",
          Default = vars.SelectedGear,
          Values = {"Binoculars", "RangeFinder", "CSEL"},
          Callback = function(v)
              vars.SelectedGear = v
              local gear = Gears[v]
              if gear and vars.InfiniteZoomEnabled then
                  gear.Magnify = {vars.ZoomMin, 500}
                  print("🔄 Infinite Zoom diterapkan ke " .. v)
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
              local gear = Gears[vars.SelectedGear]
              if gear and vars.InfiniteZoomEnabled then
                  gear.Magnify = {v, 500}
                  print("🔄 Zoom Min diubah menjadi " .. v .. " untuk " .. vars.SelectedGear)
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
                      if gear and gear.Magnify[1] ~= vars.ZoomMin then
                          gear.Magnify = {vars.ZoomMin, 500}
                          print("🔄 Zoom Min diperbaiki menjadi " .. vars.ZoomMin)
                      end
                  end
              end
          end)()
          print("✅ [Utility] Periodic check Infinite Zoom aktif")
      end

      print("✅ [Utility] Infinite Zoom siap digunakan.")
  end
}
