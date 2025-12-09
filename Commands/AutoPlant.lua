-- AutoPlant.lua
return {
  Execute = function(tab)
      local vars = _G.BotVars or {}
      local Tabs = vars.Tabs or {}
      local MainTab = tab or Tabs.Main
      
      if not MainTab then
          warn("[Auto Plant] Tab tidak ditemukan!")
          return
      end

      -- ==============================
      -- UI GROUP
      -- ==============================
      local Group = (MainTab.AddRightGroupbox and MainTab:AddRightGroupbox("Auto Plant"))
          or MainTab:AddLeftGroupbox("Auto Plant")

      -- DEFAULT VALUES
      vars.AutoPlant       = vars.AutoPlant or false
      vars.PlantDelay      = vars.PlantDelay or 1.5
      vars.PlantSeed       = vars.PlantSeed or "Wheat Seeds"
      _G.BotVars = vars


      -- === Toggle ===
      Group:AddToggle("ToggleAutoPlant", {
          Text = "Auto Plant",
          Default = vars.AutoPlant,
          Callback = function(v)
              vars.AutoPlant = v
              print("[Auto Plant] Toggle:", v and "ON" or "OFF")
          end
      })


      -- === Dropdown Seeds ===
      local SeedsList = {"Wheat Seeds", "Carrot Seeds", "Corn Seeds"} -- isi sesuai item tersedia

      task.defer(function()
          local dd = Group:AddDropdown("DropdownPlantSeed", {
              Text = "Pilih Benih",
              Values = SeedsList,
              Default = vars.PlantSeed,
              Callback = function(v)
                  vars.PlantSeed = v
                  print("[Auto Plant] Seed:", v)
              end
          })
          dd:SetValue(vars.PlantSeed)
      end)


      -- === Slider Delay ===
      Group:AddSlider("SliderPlantDelay", {
          Text = "Delay Tanam",
          Min = 0.3, Max = 4,
          Default = vars.PlantDelay,
          Rounding = 1,
          Callback = function(v) vars.PlantDelay = v end
      })


      -- ==============================
      -- SERVER & FUNCTIONS
      -- ==============================
      local ReplicatedStorage = game:GetService("ReplicatedStorage")
      local LoadedBlocks = workspace:WaitForChild("LoadedBlocks")

      local PlantCrop = ReplicatedStorage
          :WaitForChild("Relay")
          :WaitForChild("Blocks")
          :WaitForChild("PlantCrop")

      local function isOccupied(voxel)
          for _, block in ipairs(LoadedBlocks:GetChildren()) do
              local v2 = block:GetAttribute("VoxelPosition")
              if v2 and v2.X == voxel.X and v2.Y == voxel.Y and v2.Z == voxel.Z then
                  return true
              end
          end
          return false
      end


      -- ==============================
      -- AUTO PLANT LOOP
      -- ==============================
      coroutine.wrap(function()
          while task.wait() do
              if not vars.AutoPlant then
                  repeat task.wait(0.5) until vars.AutoPlant
              end

              for _, block in ipairs(LoadedBlocks:GetChildren()) do
                  if not vars.AutoPlant then break end
                  if block.Name == "Farmland" then
                      local voxel = block:GetAttribute("VoxelPosition")
                      if voxel then
                          local above = Vector3.new(voxel.X, voxel.Y + 1, voxel.Z)
                          if not isOccupied(above) then
                              pcall(function()
                                  PlantCrop:InvokeServer(above, vars.PlantSeed)
                              end)

                              print("[Auto Plant] Tanam",
                                  vars.PlantSeed,
                                  "di", above
                              )

                              task.wait(vars.PlantDelay)
                          end
                      end
                  end
              end
              task.wait()
          end
      end)()

      print("[Auto Plant] Aktif. Seed:", vars.PlantSeed)
  end
}
