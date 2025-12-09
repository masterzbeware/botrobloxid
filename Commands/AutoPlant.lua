-- AutoPlant.lua (FINAL STRUCTURE)
return {
  Execute = function(tab)
      local vars = _G.BotVars or {}
      local Tabs = vars.Tabs or {}
      local MainTab = tab or Tabs.Main

      if not MainTab then
          warn("[AutoPlant] Tab tidak ditemukan!")
          return
      end

      -- =========================
      -- UI SETUP
      -- =========================
      local Group = (MainTab.AddRightGroupbox and MainTab:AddRightGroupbox("Auto Plant"))
          or MainTab:AddLeftGroupbox("Auto Plant")

      vars.AutoPlant = vars.AutoPlant or false
      vars.PlantDelay = vars.PlantDelay or 0.3
      vars.SelectedSeed = vars.SelectedSeed or "Wheat Seeds"
      _G.BotVars = vars

      -- Toggle ON/OFF
      Group:AddToggle("ToggleAutoPlant", {
          Text = "Auto Plant",
          Default = vars.AutoPlant,
          Callback = function(v)
              vars.AutoPlant = v
              print("[AutoPlant] Status:", v and "ON" or "OFF")
          end
      })

      -- Dropdown pilih seed
      local seedList = {
          "Wheat Seeds",
          "Carrot Seeds"
      }
      task.defer(function()
          local dd = Group:AddDropdown("DropdownSeed", {
              Text = "Pilih Benih",
              Values = seedList,
              Default = vars.SelectedSeed,
              Callback = function(v)
                  vars.SelectedSeed = v
                  print("[AutoPlant] Benih:", v)
              end
          })
          dd:SetValue(vars.SelectedSeed)
      end)

      -- Slider delay
      Group:AddSlider("SliderPlantDelay", {
          Text = "Delay Tanam",
          Min = 0.1, Max = 2,
          Rounding = 2,
          Default = vars.PlantDelay,
          Callback = function(v)
              vars.PlantDelay = v
          end
      })

      -- =========================
      -- SERVICES
      -- =========================
      local ReplicatedStorage = game:GetService("ReplicatedStorage")
      local LoadedBlocks = workspace:WaitForChild("LoadedBlocks")

      local PlantCrop = ReplicatedStorage
          :WaitForChild("Relay")
          :WaitForChild("Blocks")
          :WaitForChild("PlantCrop")

      -- =========================
      -- AUTO PLANT LOOP
      -- =========================
      coroutine.wrap(function()
          while true do
              if vars.AutoPlant then
                  for _, block in ipairs(LoadedBlocks:GetChildren()) do
                      if block.Name == "Farmland" then
                          local voxel = block:GetAttribute("VoxelPosition")

                          if voxel then
                              pcall(function()
                                  PlantCrop:InvokeServer(
                                      Vector3.new(voxel.X, voxel.Y, voxel.Z)
                                  )
                              end)

                              print("[AutoPlant] Tanam di:", voxel)
                              task.wait(vars.PlantDelay)

                              if not vars.AutoPlant then break end
                          end
                      end
                  end
              else
                  repeat task.wait(0.5) until vars.AutoPlant
              end
              task.wait()
          end
      end)()

      print("[AutoPlant] Loaded ✔ | Benih Default:", vars.SelectedSeed)
  end,
}
