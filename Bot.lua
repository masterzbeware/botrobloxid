local Rep = game:GetService("ReplicatedStorage")
local Inventory = require(Rep:WaitForChild("Modules"):WaitForChild("Inventory"))
local ItemsManager = require(Rep:WaitForChild("Managers"):WaitForChild("ItemsManager"))

local Venyx = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/masterzbeware/peta-peta/refs/heads/main/petapeta"
))()

local venyx = Venyx.new("MasterZ UX", 5013109572)
local page = venyx:addPage("Auto", 5012544693)
local section = page:addSection("Main")

local selectedItem = nil
local itemMap = {}
local dropdownObj = nil
local dropdownListRef = {} -- <<< penting: table yang dipakai dropdown

local function BuildInventoryList()
    local dropdownList = {}
    local newItemMap = {}
    local labelCount = {}

    for slot, stack in pairs(Inventory.Stacks) do
        if stack and next(stack) then
            local id = stack.Id
            local amount = stack.Amount or 1
            local info = ItemsManager.RequestItemData(id)
            local name = (info and info.Name) or ("Unknown (" .. tostring(id) .. ")")

            local baseLabel = string.format("%s x%d", name, amount)
            labelCount[baseLabel] = (labelCount[baseLabel] or 0) + 1

            local label = baseLabel
            if labelCount[baseLabel] > 1 then
                label = string.format("%s (%d)", baseLabel, labelCount[baseLabel])
            end

            table.insert(dropdownList, label)
            newItemMap[label] = {
                Slot = slot,
                Id = id,
                Name = name,
                Amount = amount,
                Stack = stack
            }
        end
    end

    if #dropdownList == 0 then
        table.insert(dropdownList, "Inventory kosong")
    end

    table.sort(dropdownList)
    return dropdownList, newItemMap
end

-- helper: overwrite isi table lama (biar referensi tetap sama)
local function ReplaceTableContents(target, source)
    table.clear(target)
    for i, v in ipairs(source) do
        target[i] = v
    end
end

-- helper: coba update teks dropdown yang terlihat
local function UpdateDropdownVisibleText(dropdown, text)
    if not dropdown or not text then return end

    -- scan semua object yg mungkin
    local function scan(obj)
        if typeof(obj) == "Instance" then
            for _, c in ipairs(obj:GetDescendants()) do
                if (c:IsA("TextLabel") or c:IsA("TextButton")) then
                    -- biasanya label utama dropdown mengandung nama pilihan
                    c.Text = tostring(text)
                    return true
                end
            end
        elseif typeof(obj) == "table" then
            for _, v in pairs(obj) do
                if typeof(v) == "Instance" then
                    for _, c in ipairs(v:GetDescendants()) do
                        if (c:IsA("TextLabel") or c:IsA("TextButton")) then
                            c.Text = tostring(text)
                            return true
                        end
                    end
                end
            end
        end
        return false
    end

    scan(dropdown)
end

-- init pertama
do
    local firstList, firstMap = BuildInventoryList()
    itemMap = firstMap
    ReplaceTableContents(dropdownListRef, firstList)

    dropdownObj = section:addDropdown("Pilih Item", dropdownListRef, dropdownListRef[1], function(selectedLabel)
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
    end)
end

section:addButton("Update Inventory", function()
    local newList, newMap = BuildInventoryList()
    itemMap = newMap

    -- penting: update isi table yg sama (dropdownListRef)
    ReplaceTableContents(dropdownListRef, newList)

    -- reset selected kalau item lama hilang
    local selectedLabel = nil
    if selectedItem then
        for _, label in ipairs(dropdownListRef) do
            local data = itemMap[label]
            if data and data.Id == selectedItem.Id and data.Slot == selectedItem.Slot then
                selectedLabel = label
                break
            end
        end
    end

    if not selectedLabel then
        selectedLabel = dropdownListRef[1]
        selectedItem = itemMap[selectedLabel]
    end

    -- update teks yg tampil (visual)
    UpdateDropdownVisibleText(dropdownObj, selectedLabel or "Pilih Item")

    print("Update Inventory diklik. Jumlah item dropdown:", #dropdownListRef)
    for i, v in ipairs(dropdownListRef) do
        print(i, v)
    end
end)

section:addButton("Tiles Selector", function()
    print("Tiles Selector diklik")
    -- logic tiles selector nanti taruh di sini
end)

venyx:SelectPage(page, true)