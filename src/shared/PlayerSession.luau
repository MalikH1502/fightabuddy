-- src/shared/PlayerSession.luau
-- One instance per connected player. Server creates it, client reads via remote if needed.

local DataStoreService = game:GetService("DataStoreService")
local DataStore = DataStoreService:GetDataStore("PlayerData_v2")

local DEFAULT_DATA = {
    money    = 0,
    KO       = 0,
    Equipped = "BasicGloves",
    inventory = {"BasicGloves"},
}

local PlayerSession = {}
PlayerSession.__index = PlayerSession

-- Constructor — called by DataService on PlayerAdded
function PlayerSession.new(player: Player): PlayerSession
    local self = setmetatable({}, PlayerSession)
    self._player  = player
    self._data    = {}
    self._dirty   = false   -- only save if something actually changed
    self.OnChanged = Instance.new("BindableEvent")
    return self
end

-- Load from DataStore with correct retry logic
function PlayerSession:Load(): boolean
    local id = self._player.UserId
    local ok, result

    for attempt = 1, 3 do
        ok, result = pcall(DataStore.GetAsync, DataStore, id)
        if ok then break end
        task.wait(2 ^ attempt)  -- exponential backoff: 2s, 4s, 8s
    end

    if ok and result then
        -- Merge saved data over defaults so new keys get their defaults
        self._data = table.clone(DEFAULT_DATA)
        for k, v in result do
            self._data[k] = v
        end
    else
        if not ok then
            warn("[PlayerSession] Failed to load data for", self._player.Name, result)
        end
        self._data = table.clone(DEFAULT_DATA)
    end

    self:_syncLeaderstats()
    return ok
end

-- Save — only hits DataStore if data changed
function PlayerSession:Save(): boolean
    if not self._dirty then return true end

    local id   = self._player.UserId
    local data = table.clone(self._data)
    local ok, err

    for attempt = 1, 3 do
        ok, err = pcall(DataStore.SetAsync, DataStore, id, data)
        if ok then break end
        task.wait(2 ^ attempt)
    end

    if ok then
        self._dirty = false
    else
        warn("[PlayerSession] Failed to save data for", self._player.Name, err)
    end

    return ok
end

-- Getters / setters
function PlayerSession:Get(key: string): any
    return self._data[key]
end

function PlayerSession:Set(key: string, value: any)
    self._data[key]  = value
    self._dirty      = true
    self:_syncLeaderstats()
    self.OnChanged:Fire(key, value)
end

function PlayerSession:AddMoney(amount: number)
    if amount == 0 then return end
    self:Set("money", (self._data.money or 0) + amount)
end

function PlayerSession:AddKO(amount: number)
    amount = amount or 1
    self:Set("KO", (self._data.KO or 0) + amount)
end

function PlayerSession:HasItem(itemName: string): boolean
    for _, v in self._data.inventory do
        if v == itemName then return true end
    end
    return false
end

function PlayerSession:GiveItem(itemName: string)
    if self:HasItem(itemName) then return end
    local inv = table.clone(self._data.inventory)
    table.insert(inv, itemName)
    self:Set("inventory", inv)
end

function PlayerSession:Equip(itemName: string)
    if not self:HasItem(itemName) then
        warn("[PlayerSession] Player doesn't own", itemName)
        return
    end
    self:Set("Equipped", itemName)
end

-- Destroy — fires on PlayerRemoving after final save
function PlayerSession:Destroy()
    self.OnChanged:Destroy()
end

-- Private: keep leaderstats in sync, no polling needed
function PlayerSession:_syncLeaderstats()
    local ls = self._player:FindFirstChild("leaderstats")
    if not ls then return end
    for _, stat in ls:GetChildren() do
        if self._data[stat.Name] ~= nil then
            stat.Value = self._data[stat.Name]
        end
    end
end

export type PlayerSession = typeof(PlayerSession.new(Instance.new("Part") :: any))
return PlayerSession