local Rep = game:GetService("ReplicatedStorage")
local Inventory = require(Rep:WaitForChild("Modules"):WaitForChild("Inventory"))
local ItemsManager = require(Rep:WaitForChild("Managers"):WaitForChild("ItemsManager"))

-- Load Venyx
local Venyx = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Stefanuk12/Venyx-UI-Library/main/source.lua"
))()

local venyx = Venyx.new("MasterZ UX", 5013109572)
local page = venyx:addPage("Auto", 5012544693)
local section = page:addSection("Main")

local selectedItem = nil
local itemMap = {}
local dropdownList = {}
local currentSignature = ""
local isRefreshing = false

-- Simpan object dropdown kalau library return object
local dropdownObj = nil

local function buildInventoryData()
    local newList = {}
    local newMap = {}
    local labelCount = {}

    -- signature buat deteksi perubahan inventory
    local sigParts = {}

    for slot, stack in pairs(Inventory.Stacks) do
        if stack and next(stack) then
            local id = stack.Id
            local amount = stack.Amount or 1
            local info = ItemsManager.RequestItemData(id)
            local name = (info and info.Name) or ("Unknown (" .. tostring(id) .. ")")

            -- TAMPILAN TANPA SLOT
            local baseLabel = string.format("%s x%d", name, amount)

            -- Hindari label kembar (nama + jumlah sama)
            labelCount[baseLabel] = (labelCount[baseLabel] or 0) + 1
            local label = baseLabel
            if labelCount[baseLabel] > 1 then
                label = string.format("%s (%d)", baseLabel, labelCount[baseLabel])
            end

            table.insert(newList, label)

            newMap[label] = {
                Slot = slot, -- tetap disimpan internal
                Id = id,
                Name = name,
                Amount = amount,
                Stack = stack
            }

            table.insert(sigParts, tostring(slot) .. ":" .. tostring(id) .. ":" .. tostring(amount))
        end
    end

    if #newList == 0 then
        table.insert(newList, "Inventory kosong")
    end

    table.sort(newList)
    table.sort(sigParts)

    local signature = table.concat(sigParts, "|")
    return newList, newMap, signature
end

local function onSelect(selectedLabel)
    selectedItem = itemMap[selectedLabel]
    if selectedItem then
        print("=== ITEM DIPILIH ===")
        print("Nama  :", selectedItem.Name)
        print("ID    :", selectedItem.Id)
        print("Slot  :", selectedItem.Slot)
        print("Jumlah:", selectedItem.Amount)
    else
        print("Tidak ada item valid dipilih.")
    end
end

local function createOrRefreshDropdown()
    if isRefreshing then return end
    isRefreshing = true

    dropdownList, itemMap = buildInventoryData()

    -- Coba cara 1: kalau object dropdown support update/refresh
    local updated = false
    if dropdownObj then
        pcall(function()
            if dropdownObj.Refresh then
                dropdownObj:Refresh(dropdownList, true)
                updated = true
            elseif dropdownObj.Update then
                dropdownObj:Update(dropdownList)
                updated = true
            elseif dropdownObj.SetOptions then
                dropdownObj:SetOptions(dropdownList)
                updated = true
            end
        end)
    end

    -- Cara 2 (fallback): buat ulang section + dropdown
    if not updated then
        -- Tidak semua Venyx support destroy section, jadi safest: bikin page/section baru sekali
        -- Kalau kamu refresh sering, sebaiknya cari method update dropdown di source.lua
        -- Untuk sementara, kita bikin dropdown sekali lalu kalau belum ada object-nya:
        if not dropdownObj then
            dropdownObj = section:addDropdown("Pilih Item", dropdownList, onSelect)
        else
            -- Kalau tidak support refresh dan dropdown sudah ada, minimal data backend tetap update
            -- (UI list tidak berubah sampai script di-run ulang / pakai library yang support refresh)
            print("[INFO] Dropdown UI tidak support refresh langsung di versi Venyx ini.")
        end
    end

    isRefreshing = false
end

-- Init pertama
createOrRefreshDropdown()
venyx:SelectPage(page, true)

-- Realtime via polling (ringan)
task.spawn(function()
    while task.wait(0.7) do
        local _, _, newSignature = buildInventoryData()
        if newSignature ~= currentSignature then
            currentSignature = newSignature
            createOrRefreshDropdown()
            print("[Inventory] Dropdown di-refresh")
        end
    end
end)