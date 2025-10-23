return {
    Execute = function(tab)
        local vars = _G.BotVars or {}
        local Tabs = vars.Tabs or {}
        local CombatTab = tab or Tabs.Combat

        if not CombatTab then
            warn("[NoSpread] Tab Combat tidak ditemukan!")
            return
        end

        local Group = CombatTab:AddLeftGroupbox("No Spread (M855)")

        vars.NoSpread = vars.NoSpread or false

        Group:AddToggle("ToggleNoSpread", {
            Text = "No Spread",
            Default = vars.NoSpread,
            Callback = function(v)
                vars.NoSpread = v
                if v then
                    -- Ubah Spread menjadi 0 saat diaktifkan
                    local success, Calibers = pcall(function()
                        return require(game:GetService("ReplicatedStorage").Shared.Configs.Calibers)
                    end)
                    
                    if success and Calibers then
                        -- Coba beberapa struktur yang mungkin
                        if Calibers.v1 and Calibers.v1.intermediaterifle_556x45mmNATO_M855 then
                            Calibers.v1.intermediaterifle_556x45mmNATO_M855["Spread"] = 0
                            print("✅ Spread M855 diubah menjadi 0 (struktur v1)")
                        elseif Calibers.intermediaterifle_556x45mmNATO_M855 then
                            Calibers.intermediaterifle_556x45mmNATO_M855["Spread"] = 0
                            print("✅ Spread M855 diubah menjadi 0 (struktur langsung)")
                        else
                            -- Cari tabel M855 secara manual
                            for name, data in pairs(Calibers) do
                                if string.find(tostring(name), "556x45mmNATO_M855") then
                                    data["Spread"] = 0
                                    print("✅ Spread " .. tostring(name) .. " diubah menjadi 0")
                                    break
                                end
                            end
                        end
                    else
                        warn("❌ Gagal memuat module Calibers")
                    end
                else
                    -- Reset ke nilai default saat dimatikan
                    local success, Calibers = pcall(function()
                        return require(game:GetService("ReplicatedStorage").Shared.Configs.Calibers)
                    end)
                    
                    if success and Calibers then
                        -- Reset ke nilai default (1.6)
                        if Calibers.v1 and Calibers.v1.intermediaterifle_556x45mmNATO_M855 then
                            Calibers.v1.intermediaterifle_556x45mmNATO_M855["Spread"] = 1.6
                            print("❌ Spread M855 dikembalikan ke 1.6")
                        elseif Calibers.intermediaterifle_556x45mmNATO_M855 then
                            Calibers.intermediaterifle_556x45mmNATO_M855["Spread"] = 1.6
                            print("❌ Spread M855 dikembalikan ke 1.6")
                        end
                    end
                end
            end
        })

        -- Hook untuk memastikan perubahan tetap berlaku
        if not getgenv().NoSpreadHooked then
            getgenv().NoSpreadHooked = true
            
            -- Periodic check untuk memastikan Spread tetap 0
            coroutine.wrap(function()
                while wait(3) do
                    if vars.NoSpread then
                        local success, Calibers = pcall(function()
                            return require(game:GetService("ReplicatedStorage").Shared.Configs.Calibers)
                        end)
                        
                        if success and Calibers then
                            if Calibers.v1 and Calibers.v1.intermediaterifle_556x45mmNATO_M855 then
                                if Calibers.v1.intermediaterifle_556x45mmNATO_M855["Spread"] ~= 0 then
                                    Calibers.v1.intermediaterifle_556x45mmNATO_M855["Spread"] = 0
                                    print("🔄 Spread diperbaiki menjadi 0")
                                end
                            elseif Calibers.intermediaterifle_556x45mmNATO_M855 then
                                if Calibers.intermediaterifle_556x45mmNATO_M855["Spread"] ~= 0 then
                                    Calibers.intermediaterifle_556x45mmNATO_M855["Spread"] = 0
                                    print("🔄 Spread diperbaiki menjadi 0")
                                end
                            end
                        end
                    end
                end
            end)()
            
            print("✅ [No Spread] Sistem periodic check aktif.")
        end

        print("✅ [No Spread] Sistem aktif. Gunakan toggle untuk mengaktifkan/mematikan no spread.")
    end
}