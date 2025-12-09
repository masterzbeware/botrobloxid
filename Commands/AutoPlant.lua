-- AutoPlant.lua (Fast & Optimized)
return {
  Execute = function(tab)
      local vars = _G.BotVars or {}
      local Tabs = vars.Tabs or {}
      local MainTab = tab or Tabs.Main

      if not MainTab then
          warn("[Auto Plant] Tab tidak ditemukan!")
          return
      end

      -- =========================
      -- UI GROUP
      -- =========================
      local Group = MainTab:AddRightGroupbox("Auto Plant")

      -- DEFAULT SETTINGS
      vars.AutoPlant  = vars.AutoPlant or false
      vars.PlantDelay = vars.PlantDelay or 0.3
      vars.PlantSeed  = vars.PlantSeed or "Wheat Seeds"
      _G.BotVars = vars

      -- =========================
      -- TOGGLE
      -- =========================
      Group:AddToggle("ToggleAutoPlant", {
          Text = "Auto Plant",
          Default = vars.AutoPlant,
          Callback = function(v)
              vars.AutoPlant = v
              print("[Auto Plant] Toggle:", v and "ON" or "OFF")
          end
      })

      -- =========================
      -- DROPDOWN Seed
      -- =========================
      local SeedsList = {"Wheat Seeds", "Carrot Seeds", "Corn Seeds", "Cacao Seeds"} -- sesuaikan

      task.defer(function()
          local dd = Group:AddDropdown("DropdownPlantSeed", {
              Text = "Pilih Benih",
              Values = SeedsList,
              Default = vars.PlantSeed,
              Callback = function(v)
                  vars.PlantSeed = v
              end
          })
          dd:SetValue(vars.PlantSeed)
      end)

      -- =========================
      -- DELAY SLIDER
      -- =========================
      Group:AddSlider("SliderPlantDelay", {
          Text = "Delay Tanam",
          Default = vars.PlantDelay,
          Min = 0.1,
          Max = 3,
          Rounding = 1,
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

      -- Check block di atas farmland
      local function isOccupied(voxel)
          for _, b in ipairs(LoadedBlocks:GetChildren()) do
              local v2 = b:GetAttribute("VoxelPosition")
              if v2 and v2.X == voxel.X and v2.Y == voxel.Y and v2.Z == voxel.Z then
                  return true
              end
          end
          return false
      end

      -- =========================
      -- AUTO PLANT LOOP (FAST)
      -- =========================
      coroutine.wrap(function()
          while true do
              if vars.AutoPlant then
                  for _, block in ipairs(LoadedBlocks:GetChildren()) do
                      if not vars.AutoPlant then break end

                      if block.Name == "Farmland" then
                          local voxel = block:GetAttribute("VoxelPosition")
                          if voxel then
                              local above = Vector3.new(voxel.X, voxel.Y + 1, voxel.Z)
                              if not isOccupied(above) then
                                  task.spawn(function()
                                      pcall(function()
                                          PlantCrop:InvokeServer(above, vars.PlantSeed)
                                      end)
                                  end)
                                  task.wait(0.05) -- super cepat tapi aman
                              end
                          end
                      end
                  end
                  task.wait(vars.PlantDelay)
              else
                  repeat task.wait(1) until vars.AutoPlant
              end
          end
      end)()

      print("[Auto Plant] Aktif! Seed:", vars.PlantSeed)
  end
}
