-- Refill.lua
-- Auto refill semua magazine ketika hampir habis
return {
  Execute = function()
      local ReplicatedStorage = game:GetService("ReplicatedStorage")
      local RunService = game:GetService("RunService")
      local Players = game:GetService("Players")

      local LocalPlayer = Players.LocalPlayer
      local RemoteEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("RemoteEvent")

      -- Settings
      local RefillThreshold = 5 -- jumlah peluru tersisa sebelum refill otomatis
      local RefillCooldown = 1 -- detik delay antara refill agar tidak spam
      local LastRefill = 0

      -- Helper: ambil semua magazine dari inventory player
      local function GetPlayerMags()
          local mags = {}
          local inv = LocalPlayer:FindFirstChild("Inventory")
          if inv then
              for _, item in ipairs(inv:GetChildren()) do
                  if item:IsA("ModuleScript") then
                      local data = require(item)
                      if data.Capacity and data.UID and data.Caliber then
                          table.insert(mags, data)
                      end
                  end
              end
          end
          return mags
      end

      -- Fungsi refill 1 magazine
      local function RefillMag(mag)
          if not mag then return end
          local payload = {
              "InventoryReceive",
              {
                  {
                      {
                          "Main",
                          {
                              {
                                  1,
                                  {
                                      mag.Name,
                                      {
                                          Capacity = mag.Capacity,
                                          Name = mag.Name,
                                          Caliber = mag.Caliber,
                                          UID = mag.UID
                                      },
                                      false
                                  }
                              }
                          },
                          1
                      }
                  },
                  HttpService:GenerateGUID(false), -- simpan UID dummy
                  tick(),
                  HttpService:GenerateGUID(false)
              }
          }
          pcall(function()
              firesignal(RemoteEvent.OnClientEvent, unpack(payload))
          end)

          -- Notifikasi refill
          pcall(function()
              firesignal(RemoteEvent.OnClientEvent,
                  "Notify",
                  {
                      {"Alert", mag.Name .. " refilled", Color3.fromRGB(255, 221, 129)}
                  }
              )
          end)
      end

      -- Loop otomatis: cek magazine tiap heartbeat
      RunService.Heartbeat:Connect(function(dt)
          LastRefill = LastRefill + dt
          if LastRefill < RefillCooldown then return end

          local mags = GetPlayerMags()
          for _, mag in ipairs(mags) do
              if mag.CurrentAmmo and mag.CurrentAmmo <= RefillThreshold then
                  RefillMag(mag)
                  LastRefill = 0
                  break -- refill 1 mag per loop
              end
          end
      end)

      print("✅ Refill.lua aktif — auto refill magazine ketika hampir habis")
  end
}
