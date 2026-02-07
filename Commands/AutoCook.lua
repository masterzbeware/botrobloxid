-- AutoCook.lua (ANTI LAG VERSION)
return {
  Execute = function(tab)

      -- =========================
      -- GLOBAL VARS
      -- =========================
      local vars = _G.BotVars or {}
      vars.AutoCook        = vars.AutoCook or false
      vars.CookDelay       = vars.CookDelay or 0.6
      vars.CookBatch       = vars.CookBatch or 1
      vars.SelectedFood    = vars.SelectedFood or "Lovely Bacon and Eggs"
      vars._AutoCookRun    = vars._AutoCookRun or false
      _G.BotVars = vars

      -- =========================
      -- TAB & UI
      -- =========================
      local Tabs = vars.Tabs or {}
      local MainTab = tab or Tabs.Main
      if not MainTab then return end

      local Group = MainTab:AddRightGroupbox("Auto Cook")

      Group:AddToggle("ToggleAutoCook", {
          Text = "Auto Cook",
          Default = vars.AutoCook,
          Callback = function(v)
              vars.AutoCook = v
              print("[AutoCook] Toggle:", v and "ON" or "OFF")
          end
      })

      Group:AddSlider("SliderCookDelay", {
          Text = "Delay Step (detik)",
          Min = 0.3,
          Max = 3,
          Default = vars.CookDelay,
          Callback = function(v)
              vars.CookDelay = v
          end
      })

      Group:AddSlider("SliderCookBatch", {
          Text = "Batch per Loop",
          Min = 1,
          Max = 10,
          Default = vars.CookBatch,
          Callback = function(v)
              vars.CookBatch = v
          end
      })

      Group:AddInput("InputFoodName", {
          Text = "Food Name",
          Default = vars.SelectedFood,
          Placeholder = "Nama makanan",
          Callback = function(v)
              if v ~= "" then
                  vars.SelectedFood = v
              end
          end
      })

      -- =========================
      -- SERVICES & MODULES
      -- =========================
      local Players = game:GetService("Players")
      local ReplicatedStorage = game:GetService("ReplicatedStorage")

      local LocalPlayer = Players.LocalPlayer

      local FoodService = require(ReplicatedStorage.Modules.FoodService)
      local Items       = require(ReplicatedStorage.Modules.ItemService)

      local CookActions = FoodService.CookActions
      local CookTypes   = FoodService.CookActionObjectTypes

      -- =========================
      -- FIND COOKING STATION
      -- =========================
      local function FindStation(stationType)
          for _, obj in ipairs(workspace:GetDescendants()) do
              if obj:IsA("Model") then
                  local item = Items:GetItemFromObject(obj)
                  if item then
                      for _, t in ipairs(CookTypes) do
                          if item:IsType(t) and t == stationType then
                              return obj
                          end
                      end
                  end
              end
          end
      end

      -- =========================
      -- INTERACT (SAFE)
      -- =========================
      local function Interact(station)
          local char = LocalPlayer.Character
          if not char then return end

          local hrp = char:FindFirstChild("HumanoidRootPart")
          if not hrp then return end

          hrp.CFrame = station:GetPivot() * CFrame.new(0, 0, 3)
          task.wait(0.4)

          pcall(function()
              local remote = ReplicatedStorage:FindFirstChild("CookingRemote")
              if remote then
                  remote:FireServer({ Object = station })
              end
          end)
      end

      -- =========================
      -- AUTO COOK FUNCTION
      -- =========================
      local function DoCook()
          local item = Items:GetItem(vars.SelectedFood)
          if not item or not item.CookRecipe then
              warn("[AutoCook] Item tidak valid:", vars.SelectedFood)
              return
          end

          for b = 1, vars.CookBatch do
              if not vars.AutoCook then break end

              for _, step in ipairs(item.CookRecipe) do
                  if not vars.AutoCook then break end

                  local action = type(step) == "table" and step[1] or step
                  local data = CookActions[action]
                  if not data then continue end

                  local stationType = data.Type or (data.Types and data.Types[1])
                  if not stationType then continue end

                  local station = FindStation(stationType)
                  if station then
                      Interact(station)
                      task.wait(data.Duration or 3)
                  else
                      warn("[AutoCook] Station tidak ditemukan:", stationType)
                      break
                  end

                  task.wait(vars.CookDelay)
              end
          end
      end

      -- =========================
      -- LOOP (ANTI DOUBLE RUN)
      -- =========================
      if vars._AutoCookRun then
          warn("[AutoCook] Loop sudah berjalan")
          return
      end
      vars._AutoCookRun = true

      task.spawn(function()
          while true do
              if vars.AutoCook then
                  pcall(DoCook)
              end
              task.wait(1)
          end
      end)

      print("[AutoCook] System Loaded (ANTI LAG)")
  end
}