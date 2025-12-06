return {
  Execute = function(tab)
      local vars = _G.BotVars or {}
      local Tabs = vars.Tabs or {}
      local OvenTab = tab or Tabs.Main

      if not OvenTab then
          warn("[Auto Harvest Oven] Tab Oven tidak ditemukan!")
          return
      end

      local Group = OvenTab:AddRightGroupbox("Auto Harvest Oven")
      vars.AutoHarvestOven = vars.AutoHarvestOven or false

      Group:AddToggle("ToggleAutoHarvestOven", {
          Text = "Auto Harvest Oven",
          Default = vars.AutoHarvestOven,
          Callback = function(v)
              vars.AutoHarvestOven = v
          end
      })

      local ReplicatedStorage = game:GetService("ReplicatedStorage")
      local HarvestCrop = ReplicatedStorage:WaitForChild("Relay"):WaitForChild("Blocks"):WaitForChild("HarvestCrop")
      local LoadedBlocks = workspace:WaitForChild("LoadedBlocks")

      coroutine.wrap(function()
          while true do
              if vars.AutoHarvestOven then
                  for _, oven in ipairs(LoadedBlocks:GetChildren()) do
                      if oven.Name == "Baker's Oven" and oven:IsA("Model") then
                          local pos = oven:GetAttribute("VoxelPosition")
                          if pos then
                              pcall(function()
                                  HarvestCrop:InvokeServer(pos)
                              end)
                              task.wait(0.2)
                          end
                      end
                  end
                  print("Semua oven selesai dipanen!")
              else
                  task.wait(1)
              end
          end
      end)()

      print("Sistem Auto Harvest Oven aktif.")
  end
}
