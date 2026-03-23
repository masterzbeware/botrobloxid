-- AutoCraft.lua
return {
    Execute = function(tab)

        -- =========================
        -- GLOBAL VARS
        -- =========================
        local vars = _G.BotVars or {}
        vars.AutoCraft      = vars.AutoCraft or false
        vars.CraftDelay     = vars.CraftDelay or 1.5
        vars.SelectedItem   = vars.SelectedItem or "Chocolate Bar"
        vars._AutoCraftRun  = vars._AutoCraftRun or false
        _G.BotVars = vars

        -- =========================
        -- TAB & UI
        -- =========================
        local Tabs = vars.Tabs or {}
        local CraftTab = tab or Tabs.Craft

        if not CraftTab then
            warn("[AutoCraft] Tab Craft tidak ditemukan")
            return
        end

        local Group = (CraftTab.AddRightGroupbox and CraftTab:AddRightGroupbox("Auto Craft"))
            or CraftTab:AddLeftGroupbox("Auto Craft")

        -- =========================
        -- TOGGLE
        -- =========================
        Group:AddToggle("ToggleAutoCraft", {
            Text = "Auto Craft",
            Default = vars.AutoCraft,
            Callback = function(v)
                vars.AutoCraft = v
                print("[AutoCraft] Toggle:", v and "ON" or "OFF")
            end
        })

        -- =========================
        -- ITEM LIST
        -- =========================
        local craftableItems = {
            "Chocolate Bar"
        }

        -- =========================
        -- DROPDOWN
        -- =========================
        Group:AddDropdown("DropdownCraftItem", {
            Text = "Pilih Item Craft",
            Values = craftableItems,
            Default = vars.SelectedItem,
            Multi = false,
            Callback = function(v)
                vars.SelectedItem = v
                print("[AutoCraft] Item:", v)
            end
        })

        -- =========================
        -- SLIDER DELAY
        -- =========================
        Group:AddSlider("SliderCraftDelay", {
            Text = "Delay Craft",
            Min = 0.3,
            Max = 3,
            Default = vars.CraftDelay,
            Rounding = 1,
            Callback = function(v)
                vars.CraftDelay = v
            end
        })

        -- =========================
        -- SERVICES
        -- =========================
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local LoadedBlocks = workspace:WaitForChild("LoadedBlocks")

        local CraftRemote = ReplicatedStorage
            :WaitForChild("Relay")
            :WaitForChild("Inventory")
            :WaitForChild("CraftItem")

        -- =========================
        -- FUNCTION SCAN OVEN
        -- =========================
local function GetOvenPositions()
    local ovens = {}
    local seen = {}

    for _, obj in ipairs(LoadedBlocks:GetDescendants()) do
        if obj.Name == "Baker's Oven" then
            local voxel = obj:GetAttribute("VoxelPosition")

            if not voxel and obj.Parent then
                voxel = obj.Parent:GetAttribute("VoxelPosition")
            end

            if voxel then
                local key = tostring(voxel)
                if not seen[key] then
                    seen[key] = true
                    table.insert(ovens, voxel)
                end
            else
                warn("[AutoCraft] Oven tanpa VoxelPosition:", obj:GetFullName())
            end
        end
    end

    return ovens
end

        -- =========================
        -- CRAFT FUNCTION
        -- =========================
local function ScanAndCraft()
    local ovens = GetOvenPositions()

    if #ovens == 0 then
        warn("[AutoCraft] Tidak ada Baker's Oven!")
        return
    end

    print("[AutoCraft] Oven ditemukan:", #ovens)

    for i, pos in ipairs(ovens) do
        if not vars.AutoCraft then
            break
        end

        local ok, err = pcall(function()
            CraftRemote:InvokeServer(
                "Baker's Oven",
                vars.SelectedItem,
                pos
            )
        end)

        if ok then
            print(("[AutoCraft] Craft %s | Oven %d | Pos %s"):format(
                vars.SelectedItem,
                i,
                tostring(pos)
            ))
        else
            warn("[AutoCraft] Gagal craft:", err)
        end

        task.wait(vars.CraftDelay)
    end
end

        -- =========================
        -- AUTO LOOP
        -- =========================
        if vars._AutoCraftRun then
            warn("[AutoCraft] Loop sudah berjalan")
            return
        end

        vars._AutoCraftRun = true

task.spawn(function()
    while true do
        if vars.AutoCraft then
            ScanAndCraft()
            task.wait(0.2)
        else
            task.wait(0.2)
        end
    end
end)

        print("[AutoCraft] System Loaded (Fixed)")
    end
}