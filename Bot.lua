local Rep = game:GetService("ReplicatedStorage")
local Inventory = require(Rep:WaitForChild("Modules"):WaitForChild("Inventory"))
local ItemsManager = require(Rep:WaitForChild("Managers"):WaitForChild("ItemsManager"))

-- Load Venyx
local Venyx = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Stefanuk12/Venyx-UI-Library/main/source.lua"
))()

local venyx = Venyx.new("MasterZ UX", 5013109572)

local selectedItem = nil
local uiBuilt = false

-- Simpan referensi biar bisa rebuild
local currentPage
local currentSection

-- =========================
-- Build list inventory
-- =========================
local function BuildInventoryList()
    local dropdownList = {}
    local itemMap = {}
    local labelCount = {}

    for slot, stack in pairs(Inventory.Stacks) do
        if stack and next(stack) then
            local id = stack.Id
            local amount = stack.Amount or 1
            local info = ItemsManager.RequestItemData(id)
            local name = (info and info.Name) or ("Unknown (" .. tostring(id) .. ")")

            local baseLabel = string.format("%s x%d", name, amount)

            -- Hindari duplicate label (misal item sama & jumlah sama)
            labelCount[baseLabel] = (labelCount[baseLabel] or 0) + 1
            local label = baseLabel
            if labelCount[baseLabel] > 1 then
                label = string.format("%s (%d)", baseLabel, labelCount[baseLabel])
            end

            table.insert(dropdownList, label)
            itemMap[label] = {
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
    return dropdownList, itemMap
end

-- =========================
-- Render ulang UI inventory
-- =========================
local function RenderInventoryUI()
    local dropdownList, itemMap = BuildInventoryList()

    -- Bikin page/section sekali saja
    if not uiBuilt then
        currentPage = venyx:addPage("Auto", 5012544693)
        currentSection = currentPage:addSection("Main")
        uiBuilt = true
    end

    -- Dropdown BARU (hasil refresh terbaru)
    -- IMPORTANT: addDropdown butuh defaultValue sebelum callback
    local defaultValue = dropdownList[1]

    currentSection:addDropdown("Pilih Item", dropdownList, defaultValue, function(selectedLabel)
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

    -- Tombol update cuma ditambah sekali
    if not currentSection._hasRefreshButton then
        currentSection._hasRefreshButton = true

        currentSection:addButton("Update Inventory", function()
            print("Refreshing inventory...")
            RenderInventoryUI()
        end)
    end

    venyx:SelectPage(currentPage, true)
end

-- Jalankan pertama kali
RenderInventoryUI()