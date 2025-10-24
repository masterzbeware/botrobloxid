return {
    Execute = function(tab)
        local vars = _G.BotVars or {}
        local Tabs = vars.Tabs or {}
        local CombatTab = tab or Tabs.Combat
  
        if not CombatTab then
            warn("[No Recoil] Tab Combat tidak ditemukan!")
            return
        end
  
        local Group = CombatTab:AddRightGroupbox("No Recoil")
  
        vars.NoRecoil = vars.NoRecoil or false
        vars.SelectedWeapon = vars.SelectedWeapon or "All"
  
        -- Daftar senjata no recoil
        local weaponList = {
            "All",
            "shotgun_12gauge_00buck",
            "shotgun_12gauge_slug",
            "pistol_9x18mmMakarov_57N181S",
            "pistol_9x19mmParabellum_M882",
            "pistol_9x21Gyurza_SP10",
            "pistol_45Auto_M1911",
            "pistol_44MillingtonMagnum_240grFMJ",
            "personaldefenseweapon_46x30mm_FMJSX",
            "personaldefenseweapon_57x28mm_SS190",
            "intermediaterifle_545x39mm_7N6M",
            "intermediaterifle_545x39mm_7T3",
            "intermediaterifle_556x45mmNATO_M855",
            "intermediaterifle_556x45mmNATO_M856",
            "intermediaterifle_556x45mmNATO_Mk262Mod1",
            "intermediaterifle_9x39mm_7N8",
            "intermediaterifle_762x39mm_57N231",
            "intermediaterifle_762x39mm_57N231P",
            "fullpowerrifle_762x54mmR_7N14",
            "fullpowerrifle_762x51mmNATO_M80",
            "fullpowerrifle_762x51mmNATO_M118LR",
            "fullpowerrifle_65x48mmFidelis_MultiPurpose",
            "fullpowerrifle_300WinchesterMagnum_Mk248Mod1",
            "fullpowerrifle_338LapuaMagnum_GB448",
            "fullpowerrifle_127x99mmNATO_M33",
            "fullpowerrifle_127x108mm_B32"
        }
  
        -- Fungsi untuk mengatur recoil senjata
        local function setWeaponRecoil(weaponName, value)
            local success, Calibers = pcall(function()
                return require(game:GetService("ReplicatedStorage").Shared.Configs.Calibers)
            end)
            
            if success and Calibers then
                -- Coba beberapa struktur yang mungkin
                if Calibers.v1 and Calibers.v1[weaponName] then
                    Calibers.v1[weaponName]["RecoilForce"] = value
                elseif Calibers[weaponName] then
                    Calibers[weaponName]["RecoilForce"] = value
                else
                    -- Cari tabel senjata secara manual
                    for name, data in pairs(Calibers) do
                        if string.find(tostring(name), weaponName) then
                            data["RecoilForce"] = value
                            break
                        end
                    end
                end
            else
                warn("❌ Gagal memuat module Calibers")
            end
        end
  
        -- Fungsi untuk mengatur semua senjata
        local function setAllWeaponsRecoil(value)
            for _, weaponName in ipairs(weaponList) do
                if weaponName ~= "All" then
                    setWeaponRecoil(weaponName, value)
                end
            end
        end
  
        -- Dropdown untuk memilih senjata
        Group:AddDropdown("WeaponSelect", {
            Text = "Select Weapon",
            Default = vars.SelectedWeapon,
            Values = weaponList,
            Callback = function(value)
                vars.SelectedWeapon = value
                
                -- Jika no recoil aktif, terapkan perubahan
                if vars.NoRecoil then
                    if value == "All" then
                        setAllWeaponsRecoil(0)
                    else
                        setWeaponRecoil(value, 0)
                    end
                end
            end
        })
  
        Group:AddToggle("ToggleNoRecoil", {
            Text = "No Recoil",
            Default = vars.NoRecoil,
            Callback = function(v)
                vars.NoRecoil = v
                if v then
                    -- Aktifkan no recoil untuk senjata yang dipilih
                    if vars.SelectedWeapon == "All" then
                        setAllWeaponsRecoil(0)
                    else
                        setWeaponRecoil(vars.SelectedWeapon, 0)
                    end
                else
                    -- Nonaktifkan no recoil (reset ke nilai default)
                    if vars.SelectedWeapon == "All" then
                        setAllWeaponsRecoil(100) -- Nilai default
                    else
                        setWeaponRecoil(vars.SelectedWeapon, 100) -- Nilai default
                    end
                end
            end
        })
  
        -- Hook untuk memastikan perubahan tetap berlaku
        if not getgenv().NoRecoilHooked then
            getgenv().NoRecoilHooked = true
            
            -- Periodic check untuk memastikan RecoilForce tetap 0
            coroutine.wrap(function()
                while wait(3) do
                    if vars.NoRecoil then
                        if vars.SelectedWeapon == "All" then
                            setAllWeaponsRecoil(0)
                        else
                            setWeaponRecoil(vars.SelectedWeapon, 0)
                        end
                    end
                end
            end)()
        end
    end
  }