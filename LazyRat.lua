-- Lazy Rat: auto-accept res / battle res / summons / queue pops, and one-click premade sign-up.
local ADDON = ...

-- Swap Media\icon.tga (64x64, 32-bit TGA) to change the minimap/addon-list icon.
local ICON = "Interface\\AddOns\\LazyRat\\Media\\icon"

local DEFAULTS = {
    res = true, bres = true, summon = true,
    queuePop = true, notifyChat = true, notifyWarning = true,
    autoSign = true,
    minimapShow = true, minimapAngle = 225,
}
local CHAR_DEFAULTS = { roleTank = false, roleHealer = false, roleDamage = true }
local db, charDb

local function Notify(msg)
    if db.notifyChat then print("|cffc8a165Lazy Rat:|r " .. msg) end
    if db.notifyWarning then RaidNotice_AddMessage(RaidWarningFrame, msg, ChatTypeInfo.RAID_WARNING) end
end

-- Preferred roles, limited to what this spec/class can actually queue as. Falls back to damage.
local function GetRoles()
    local canTank, canHeal, canDps = C_LFGList.GetAvailableRoles()
    local tank, heal, dps = charDb.roleTank and canTank, charDb.roleHealer and canHeal, charDb.roleDamage and canDps
    if not (tank or heal or dps) then dps = canDps end
    return tank or false, heal or false, dps or false
end

---------------------------------------------------------------------------
-- Resurrection / summons
---------------------------------------------------------------------------
local function OnResurrect(caster)
    local battle = IsEncounterInProgress() or (caster and UnitAffectingCombat(caster))
    if not db[battle and "bres" or "res"] then return end
    AcceptResurrect()
    StaticPopup_Hide("RESURRECT")
    StaticPopup_Hide("RESURRECT_NO_SICKNESS")
    StaticPopup_Hide("RESURRECT_NO_TIMER")
    Notify((battle and "Battle res" or "Res") .. " accepted from " .. (caster or "?"))
end

local events = CreateFrame("Frame")

local function OnSummon()
    if not db.summon then return end
    -- Summons can't be taken in combat; try again once combat drops.
    if UnitAffectingCombat("player") then
        events:RegisterEvent("PLAYER_REGEN_ENABLED")
        return
    end
    C_Timer.After(0.5, function()
        if (C_SummonInfo.GetSummonConfirmTimeLeft() or 0) <= 0 then return end
        local who = C_SummonInfo.GetSummonConfirmSummoner() or "?"
        C_SummonInfo.ConfirmSummon()
        StaticPopup_Hide("CONFIRM_SUMMON")
        Notify("Summon accepted from " .. who)
    end)
end

---------------------------------------------------------------------------
-- Queue pops / role checks / premade sign-up
---------------------------------------------------------------------------
-- The ready dialog's Enter button is protected; a SecureActionButton "click" is the allowed way to press it.
local acceptBtn = CreateFrame("Button", "LazyRatAcceptButton", UIParent, "SecureActionButtonTemplate")
acceptBtn:Hide()
acceptBtn:SetAttribute("type", "click")

local function OnProposal()
    if not db.queuePop then return end
    C_Timer.After(0.2, function()
        if InCombatLockdown() or not (LFGDungeonReadyDialog and LFGDungeonReadyDialog:IsShown()) then return end
        acceptBtn:SetAttribute("clickbutton", LFGDungeonReadyDialogEnterDungeonButton)
        acceptBtn:Click()
        Notify("Queue pop accepted.")
    end)
end

local function OnRoleCheck()
    if not db.queuePop then return end
    local tank, heal, dps = GetRoles()
    SetLFGRoles(GetLFGRoles(), tank, heal, dps)
    CompleteLFGRoleCheck(true)
    Notify("Role check completed.")
end

local function SetupApplicationDialog()
    local dialog = LFGListApplicationDialog
    if not dialog then return end
    local orig = dialog:GetScript("OnShow")
    -- SetScript rather than hooksecurefunc: SignUpButton:Click() must run untainted from the dialog's own handler.
    dialog:SetScript("OnShow", function(self, ...)
        if orig then orig(self, ...) end
        if not db.autoSign or IsShiftKeyDown() then return end
        local tank, heal, dps = GetRoles()
        SetLFGRoles(GetLFGRoles(), tank, heal, dps)
        self.TankButton.CheckButton:SetChecked(tank)
        self.HealerButton.CheckButton:SetChecked(heal)
        self.DamagerButton.CheckButton:SetChecked(dps)
        self.SignUpButton:Click()
        Notify("Signed up for group.")
    end)
end

---------------------------------------------------------------------------
-- Menu
---------------------------------------------------------------------------
local menu, minimapBtn

-- Flat dark palette, same look as MythicPlusCount's options panel.
local FONT = "Fonts\\FRIZQT__.TTF"
local WHITE = "Interface\\Buttons\\WHITE8X8"
local C = {
    bg        = { 0.08, 0.08, 0.10, 0.95 },
    border    = { 0.25, 0.25, 0.30, 1 },
    accent    = { 0.30, 0.70, 1.00, 1 },
    text      = { 0.85, 0.85, 0.85, 1 },
    dim       = { 0.55, 0.55, 0.60, 1 },
    tabBg     = { 0.10, 0.10, 0.12, 1 },
    tabActive = { 0.18, 0.18, 0.22, 1 },
    tabHover  = { 0.14, 0.14, 0.18, 1 },
    box       = { 0.15, 0.15, 0.18, 1 },
}

local function Text(parent, size, color, flags)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFont(FONT, size, flags or "")
    fs:SetTextColor(unpack(color))
    return fs
end

local function Backdrop(f, bg, border)
    f:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    f:SetBackdropColor(unpack(bg))
    f:SetBackdropBorderColor(unpack(border))
end

-- Builds one settings page; y walks down the page as rows are added.
local function NewPage(parent)
    local page = CreateFrame("Frame", nil, parent)
    page:SetPoint("TOPLEFT", 150, -46)
    page:SetPoint("BOTTOMRIGHT", -16, 16)
    page:Hide()
    local y = 0

    function page:Header(text)
        if y ~= 0 then y = y - 10 end
        local fs = Text(self, 13, C.accent, "OUTLINE")
        fs:SetPoint("TOPLEFT", 0, y)
        fs:SetText(text)
        local line = self:CreateTexture(nil, "ARTWORK")
        line:SetHeight(1)
        line:SetPoint("TOPLEFT", fs, "BOTTOMLEFT", 0, -4)
        line:SetPoint("RIGHT")
        line:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.3)
        y = y - 28
    end

    function page:Check(key, label, onChange, store)
        store = store or db
        local cb = CreateFrame("CheckButton", nil, self, "BackdropTemplate")
        cb:SetSize(20, 20)
        cb:SetPoint("TOPLEFT", 6, y)
        Backdrop(cb, C.box, C.border)
        cb:SetHighlightTexture(WHITE)
        cb:GetHighlightTexture():SetVertexColor(0.3, 0.6, 1, 0.2)
        local fill = cb:CreateTexture(nil, "OVERLAY")
        fill:SetSize(12, 12)
        fill:SetPoint("CENTER")
        fill:SetColorTexture(unpack(C.accent))
        local label_ = Text(cb, 12, C.text, "OUTLINE")
        label_:SetPoint("LEFT", cb, "RIGHT", 8, 0)
        label_:SetText(label)

        local function Refresh()
            local on = cb:GetChecked()
            fill:SetShown(on)
            cb:SetBackdropBorderColor(unpack(on and C.accent or C.border))
        end
        cb:SetChecked(store[key])
        Refresh()
        cb:SetScript("OnClick", function()
            store[key] = cb:GetChecked()
            Refresh()
            if onChange then onChange() end
        end)
        y = y - 32
    end

    function page:Note(text)
        local fs = Text(self, 10, C.dim)
        fs:SetPoint("TOPLEFT", 34, y + 8)
        fs:SetWidth(410) -- fixed width so GetStringHeight is right before the page is laid out
        fs:SetJustifyH("LEFT")
        fs:SetText(text)
        y = y - fs:GetStringHeight() - 6
    end

    return page
end

local function BuildMenu()
    menu = CreateFrame("Frame", "LazyRatMenu", UIParent, "BackdropTemplate")
    menu:SetSize(620, 470)
    menu:SetPoint("CENTER")
    menu:SetFrameStrata("DIALOG")
    menu:SetMovable(true)
    menu:EnableMouse(true)
    menu:SetClampedToScreen(true)
    menu:RegisterForDrag("LeftButton")
    menu:SetScript("OnDragStart", menu.StartMoving)
    menu:SetScript("OnDragStop", menu.StopMovingOrSizing)
    Backdrop(menu, C.bg, C.border)
    menu:Hide()
    tinsert(UISpecialFrames, "LazyRatMenu") -- Escape closes it

    local logo = menu:CreateTexture(nil, "ARTWORK")
    logo:SetTexture(ICON)
    logo:SetSize(24, 24)
    logo:SetPoint("TOPLEFT", 12, -8)

    local title = Text(menu, 16, { 1, 1, 1, 1 }, "OUTLINE")
    title:SetPoint("LEFT", logo, "RIGHT", 6, 0)
    title:SetText("|cff8c8c99·|r  Lazy Rat")

    local close = CreateFrame("Button", nil, menu)
    close:SetSize(24, 24)
    close:SetPoint("TOPRIGHT", -8, -8)
    local x = Text(close, 16, C.text, "OUTLINE")
    x:SetPoint("CENTER")
    x:SetText("X")
    close:SetScript("OnClick", function() menu:Hide() end)
    close:SetScript("OnEnter", function() x:SetTextColor(1, 1, 1) end)
    close:SetScript("OnLeave", function() x:SetTextColor(unpack(C.text)) end)

    local divider = menu:CreateTexture(nil, "ARTWORK")
    divider:SetHeight(1)
    divider:SetPoint("TOPLEFT", 1, -40)
    divider:SetPoint("TOPRIGHT", -1, -40)
    divider:SetColorTexture(unpack(C.border))

    local sidebar = menu:CreateTexture(nil, "BACKGROUND", nil, 1)
    sidebar:SetPoint("TOPLEFT", 1, -41)
    sidebar:SetPoint("BOTTOMLEFT", 1, 1)
    sidebar:SetWidth(132)
    sidebar:SetColorTexture(unpack(C.tabBg))

    -- Pages
    local general = NewPage(menu)
    general:Header("Resurrection")
    general:Check("res", "Auto-accept resurrections")
    general:Check("bres", "Auto-accept battle resurrections")
    general:Note("A res counts as a battle res during a boss encounter or while the caster is in combat.")
    general:Header("Summons")
    general:Check("summon", "Auto-accept summons")
    general:Note("If you're in combat, the summon is accepted once combat ends.")
    general:Header("Minimap")
    general:Check("minimapShow", "Show minimap button", function() minimapBtn:SetShown(db.minimapShow) end)

    local queue = NewPage(menu)
    queue:Header("Queue Pop")
    queue:Check("queuePop", "Auto-accept queue pops & role checks (LFG/LFR)")
    queue:Header("Auto Sign-Up (Premade Groups)")
    queue:Check("autoSign", "Auto-sign when signing up for a premade group")
    queue:Note("Skips the role dialog and instantly signs up with your selected roles. Hold |cffffffffShift|r when signing up to skip auto-sign.")
    queue:Header("Preferred Roles")
    queue:Check("roleTank", "Tank", nil, charDb)
    queue:Check("roleHealer", "Healer", nil, charDb)
    queue:Check("roleDamage", "Damage", nil, charDb)
    queue:Note("Roles are saved per character. Each character keeps its own selection.")

    local notifications = NewPage(menu)
    notifications:Header("Notifications")
    notifications:Check("notifyChat", "Chat message")
    notifications:Check("notifyWarning", "Raid warning message")
    notifications:Note("Shown whenever Lazy Rat auto-accepts a res, summon, queue pop, role check or sign-up.")

    -- Sidebar tabs
    local tabs = {}
    local function Select(sel)
        for _, t in ipairs(tabs) do
            local on = t == sel
            t.page:SetShown(on)
            t.bar:SetShown(on)
            t.bg:SetColorTexture(unpack(on and C.tabActive or C.tabBg))
            t.label:SetTextColor(unpack(on and { 1, 1, 1, 1 } or C.dim))
        end
    end
    for i, def in ipairs({ { "General", general }, { "Auto Queue", queue }, { "Notifications", notifications } }) do
        local t = CreateFrame("Button", nil, menu)
        t:SetSize(132, 36)
        t:SetPoint("TOPLEFT", 1, -41 - (i - 1) * 36)
        t.page = def[2]
        t.bg = t:CreateTexture(nil, "BACKGROUND", nil, 2)
        t.bg:SetAllPoints()
        t.bar = t:CreateTexture(nil, "ARTWORK")
        t.bar:SetPoint("TOPLEFT")
        t.bar:SetPoint("BOTTOMLEFT")
        t.bar:SetWidth(3)
        t.bar:SetColorTexture(unpack(C.accent))
        t.label = Text(t, 12, C.dim, "OUTLINE")
        t.label:SetPoint("LEFT", 14, 0)
        t.label:SetText(def[1])
        t:SetScript("OnClick", Select)
        t:SetScript("OnEnter", function() if not t.page:IsShown() then t.bg:SetColorTexture(unpack(C.tabHover)) end end)
        t:SetScript("OnLeave", function() if not t.page:IsShown() then t.bg:SetColorTexture(unpack(C.tabBg)) end end)
        tabs[i] = t
    end
    Select(tabs[1])
end

local function ToggleMenu()
    if not menu then BuildMenu() end
    menu:SetShown(not menu:IsShown())
end

---------------------------------------------------------------------------
-- Minimap button
---------------------------------------------------------------------------
local function PlaceMinimapButton()
    local a = math.rad(db.minimapAngle)
    local r = Minimap:GetWidth() / 2 + 10
    minimapBtn:ClearAllPoints()
    minimapBtn:SetPoint("CENTER", Minimap, "CENTER", math.cos(a) * r, math.sin(a) * r)
end

local function BuildMinimapButton()
    local b = CreateFrame("Button", "LazyRatMinimapButton", Minimap)
    minimapBtn = b
    b:SetSize(31, 31)
    b:SetFrameStrata("MEDIUM")
    b:SetFrameLevel(8)
    b:RegisterForClicks("AnyUp")
    b:RegisterForDrag("LeftButton")
    b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    local bg = b:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    bg:SetSize(20, 20)
    bg:SetPoint("TOPLEFT", 7, -5)

    local icon = b:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(ICON)
    icon:SetSize(20, 20)
    icon:SetPoint("TOPLEFT", 7, -5)

    local border = b:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(53, 53)
    border:SetPoint("TOPLEFT")

    b:SetScript("OnClick", ToggleMenu)
    b:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            local cx, cy = GetCursorPosition()
            local s = Minimap:GetEffectiveScale()
            db.minimapAngle = math.deg(math.atan2(cy / s - my, cx / s - mx))
            PlaceMinimapButton()
        end)
    end)
    b:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
    b:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("Lazy Rat")
        GameTooltip:AddLine("Click to open settings. Drag to move.", 1, 1, 1)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", GameTooltip_Hide)

    PlaceMinimapButton()
    b:SetShown(db.minimapShow)
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------
events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        if ... ~= ADDON then return end
        self:UnregisterEvent("ADDON_LOADED")
        LazyRatDB = LazyRatDB or {}
        db = LazyRatDB
        -- Old single "notify" toggle: carry an "off" over to both new toggles.
        if db.notify == false then db.notifyChat, db.notifyWarning = false, false end
        db.notify = nil
        for k, v in pairs(DEFAULTS) do
            if db[k] == nil then db[k] = v end
        end
        LazyRatCharDB = LazyRatCharDB or {}
        charDb = LazyRatCharDB
        -- Seed from the old account-wide roles (if any) so existing picks carry over.
        for k, v in pairs(CHAR_DEFAULTS) do
            if charDb[k] == nil then
                if db[k] ~= nil then charDb[k] = db[k] else charDb[k] = v end
            end
        end
        BuildMinimapButton()
        SetupApplicationDialog()
        self:RegisterEvent("RESURRECT_REQUEST")
        self:RegisterEvent("CONFIRM_SUMMON")
        self:RegisterEvent("LFG_PROPOSAL_SHOW")
        self:RegisterEvent("LFG_ROLE_CHECK_SHOW")
    elseif event == "RESURRECT_REQUEST" then
        OnResurrect(...)
    elseif event == "CONFIRM_SUMMON" then
        OnSummon()
    elseif event == "PLAYER_REGEN_ENABLED" then
        self:UnregisterEvent("PLAYER_REGEN_ENABLED")
        OnSummon()
    elseif event == "LFG_PROPOSAL_SHOW" then
        OnProposal()
    elseif event == "LFG_ROLE_CHECK_SHOW" then
        OnRoleCheck()
    end
end)

SLASH_LAZYRAT1 = "/lr"
SlashCmdList.LAZYRAT = ToggleMenu
