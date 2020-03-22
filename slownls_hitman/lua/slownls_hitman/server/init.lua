--[[  
    Addon: Hitman
    By: SlownLS
]]

SlownLS.Hitman.Contracts = SlownLS.Hitman.Contracts or {}

if( SlownLS.Hitman.Config.FastDL ) then
    resource.AddWorkshop("764395035")
    resource.AddWorkshop("1962912203")
end

--[[ Functions ]]

function SlownLS.Hitman:sendContracts(pPlayer)
    local tblContracts = self.Contracts or {}

    if( pPlayer and IsValid(pPlayer) ) then
        self:sendEvent('update_contracts', tblContracts, pPlayer)
        return
    end

    for k,v in pairs(player.GetAll()) do
        if( not v:isHitman() ) then continue end

        self:sendEvent('update_contracts', tblContracts, v)
    end
end

function SlownLS.Hitman:sendContract(pPlayer,intKey)
    local tblContract = self.Contracts[intKey] or false 

    if( not tblContract ) then return end

    self:sendEvent('send_contract', tblContract, pPlayer)
end

function SlownLS.Hitman:isVictim(pPlayer)
    local intKey = false 

    for k,v in pairs(self.Contracts or {}) do
        if( v.victim == pPlayer ) then
            intKey = k
            break
        end
    end

    return intKey
end

function SlownLS.Hitman:getHitman(intContract)
    local tbl = self.Contracts[intContract]

    if( not tbl ) then return false end

    if( not tbl.taken_by or not IsValid(tbl.taken_by) ) then return false end

    return tbl.taken_by
end

function SlownLS.Hitman:hasContract(pPlayer)
    local intKey = false 

    for k,v in pairs(self.Contracts or {}) do
        if( v.by == pPlayer or v.victim == pPlayer ) then
            intKey = k
            break
        end
    end

    return intKey
end

function SlownLS.Hitman:refund(intContract)
    local tbl = self.Contracts[intContract]

    if( not tbl ) then return false end

    local pPlayer = tbl.by

    if( not IsValid(pPlayer) ) then return false end

    pPlayer:addMoney( tbl.price )
end

function SlownLS.Hitman:removeContract(intKey)
    local tbl = self.Contracts[intKey]

    if( not tbl ) then return false end

    if( tbl.taken_by and IsValid(tbl.taken_by) ) then
        local pHitman = tbl.taken_by

        pHitman.SlownLS_Hitman_Current = nil 

        self:sendEvent('remove_contract', {}, pHitman)
    end

    SlownLS.Hitman.Contracts[intKey] = nil

    self:sendContracts()
end

function SlownLS.Hitman:sendToHitman(intContract, intType, strMsg)
    local tbl = self.Contracts[intContract]

    if( not tbl ) then return false end
    if( not tbl.taken_by or not IsValid(tbl.taken_by) ) then return false end

    DarkRP.notify(tbl.taken_by, intType, 5, strMsg)
end

function SlownLS.Hitman:sendToClient(intContract, intType, strMsg)
    local tbl = self.Contracts[intContract]

    if( not tbl ) then return false end
    if( not tbl.by or not IsValid(tbl.by) ) then return false end

    DarkRP.notify(tbl.by, intType, 5, strMsg)
end

function SlownLS.Hitman:sendToHitmans(intType, strMsg)
    for k,v in pairs(player.GetAll()) do
        if( not v:isHitman() ) then continue end

        DarkRP.notify(v, intType, 5, strMsg)
    end
end

--[[ Hooks ]]

hook.Add("PlayerDisconnected", "SlownLS:Hitman:Player:Disconnect", function(pPlayer)
    local intContract = SlownLS.Hitman:isVictim(pPlayer)

    if( intContract == false ) then return end

    SlownLS.Hitman:sendToHitman(intContract, 1, SlownLS.Hitman:getLanguage("contractCanceledDisconnect"))

    SlownLS.Hitman:refund(intContract)
    SlownLS.Hitman:removeContract(intContract)
end)

hook.Add("PlayerDeath", "SlownLS:Hitman:Player:Death", function(pPlayer, _, entAttacker)
    SlownLS.Hitman:sendEvent("close_tablet", {}, pPlayer)
    
    if( pPlayer:isHitman() ) then
        local intContract = pPlayer:getHitman("contract")

        if( intContract ) then 
            SlownLS.Hitman:sendToHitman(intContract, 1, SlownLS.Hitman:getLanguage("contractCanceledDeath"))
            SlownLS.Hitman:sendToClient(intContract, 1, SlownLS.Hitman:getLanguage("contractCanceledDeathClient"))

            SlownLS.Hitman:refund(intContract)
            SlownLS.Hitman:removeContract(intContract)
        end
    end

    local intContract = SlownLS.Hitman:isVictim(pPlayer)

    if( intContract == false ) then return end
    
    if( IsValid(entAttacker) and entAttacker:IsPlayer() ) then
        local pHitman = SlownLS.Hitman:getHitman(intContract)

        if( pHitman and entAttacker == pHitman ) then
            local intPrice = SlownLS.Hitman.Contracts[intContract].price

            entAttacker:addMoney(intPrice) 

            SlownLS.Hitman:sendToHitman(intContract, 0, SlownLS.Hitman:getLanguage("contractFinished"))
            SlownLS.Hitman:sendToClient(intContract, 0, SlownLS.Hitman:getLanguage("contractFinishedClient"))

            SlownLS.Hitman:removeContract(intContract)

            return 
        end
    end

    SlownLS.Hitman:sendToHitman(intContract, 1, SlownLS.Hitman:getLanguage("contractCanceledVictimDeath"))

    SlownLS.Hitman:removeContract(intContract)
end)

hook.Add("OnPlayerChangedTeam", "SlownLS:Hitman:OnPlayerChangedTeam", function(pPlayer,intBefore,intAfter)
    local strTeam = team.GetName(intAfter)

    if( not SlownLS.Hitman.Config.Jobs[strTeam] ) then return end

    SlownLS.Hitman:sendContracts(pPlayer)
end)

--[[ Networks ]]

SlownLS.Hitman:addEvent('send_contract', function(self, pPlayer, tblInfos)
    if( pPlayer:isHitman() ) then return end

    if( SlownLS.Hitman.Config.BlackList[team.GetName(pPlayer:Team())] ) then return end

    pPlayer.SlownLS_Hitman_LastContract = pPlayer.SlownLS_Hitman_LastContract or 0

    if( pPlayer.SlownLS_Hitman_LastContract > CurTime() ) then
        DarkRP.notify(pPlayer, 1, 5, self:getLanguage("contractDelay"))    
        return
    end

    local ent = tblInfos.ent
    local pVictim = tblInfos.player
    local intPrice = tblInfos.price
    local strDescription = tblInfos.description

    local tblVerifications = self:getConfig('Verifications')

    -- Check variables
    intPrice = tonumber(intPrice)

    if( not intPrice ) then return end

    -- Check entity
    if( not IsValid(ent) ) then return end
    if( ent:GetClass() != "slownls_hitman_phone" ) then return end
    if( ent:GetPos():Distance(pPlayer:GetPos()) > 300 ) then return end

    -- Check player
    if( not IsValid(pVictim) ) then return end
    if( not pVictim:IsPlayer() ) then return end
    if( pVictim == pPlayer ) then return end

    -- Check price
    local tblPrice = tblVerifications.price

    if( tblPrice.min and intPrice < tblPrice.min ) then
        return DarkRP.notify(pPlayer, 1, 5, string.format(self:getLanguage("priceMin"), DarkRP.formatMoney(tblPrice.min)))
    end

    if( tblPrice.max and intPrice > tblPrice.max ) then
        return DarkRP.notify(pPlayer, 1, 5, string.format(self:getLanguage("priceMax"), DarkRP.formatMoney(tblPrice.max)))
    end

    if( !pPlayer:canAfford(intPrice) ) then
        return DarkRP.notify(pPlayer, 1, 5, self:getLanguage("noMoney")) 
    end

    -- Check description
    local tblDescription = tblVerifications.description

    strDescription = strDescription or ""

    if( tblDescription.required ) then
        local intLength = string.len(strDescription)

        if(tblDescription.min and intLength < tblDescription.min) then
            return DarkRP.notify(pPlayer, 1, 5, self:getLanguage("descriptionShort"))
        end

        if(tblDescription.max and intLength > tblDescription.max) then
            return DarkRP.notify(pPlayer, 1, 5, self:getLanguage("descriptionLong"))
        end
    end

    pPlayer:addMoney(- intPrice)

    pPlayer.SlownLS_Hitman_LastContract = CurTime() + 5

    self.Contracts[#self.Contracts + 1] = {
        victim = pVictim,
        by = pPlayer,
        price = intPrice,
        description = strDescription
    }

    self:sendToHitmans(0, self:getLanguage("contractSendedHitman"))
    self:sendContracts()

    DarkRP.notify(pPlayer, 0, 5, self:getLanguage("contractSended"))
end)

SlownLS.Hitman:addEvent('take_contract', function(self, pPlayer, tblInfos)
    if( not pPlayer:isHitman() ) then return end

    local intKey = tblInfos.key
    local tbl = self.Contracts[intKey] or false

    -- Check if player has contract
    if( pPlayer:getHitman('hasContract') ) then
        return DarkRP.notify(pPlayer, 1, 5, self:getLanguage("contractAlready"))
    end

    -- Check entry exist
    if( not tbl ) then return end

    if( tbl.taken_by and tbl.taken_by ~= pPlayer ) then
        return DarkRP.notify(pPlayer, 1, 5, self:getLanguage("contractAlreadyTaken"))
    end

    if( tbl.victim == pPlayer ) then
        return DarkRP.notify(pPlayer, 1, 5, self:getLanguage("contractNoTake"))
    end

    tbl.taken_by = pPlayer

    -- Contract time
    if( self.Config.Time ~= 0 ) then        
        timer.Create("SlownLS:Hitman:Contracts:" .. intKey, self.Config.Time, 1, function()
            if( not self.Contracts[intKey] ) then return end
            
            if( IsValid(pPlayer) ) then
                DarkRP.notify(pPlayer, 1, 5, self:getLanguage("contractCanceledTime"))
            end

            local pBy = self.Contracts[intKey].by

            if( IsValid(pBy) ) then
                DarkRP.notify(pBy, 0, 5, self:getLanguage("contractCanceledRefunded"))
                self:refund(intKey)
            end

            self:removeContract(intKey)
        end)
    end

    pPlayer.SlownLS_Hitman_Current = intKey

    self:sendContracts()
    self:sendContract(pPlayer,intKey)

    DarkRP.notify(pPlayer, 0, 5, self:getLanguage("contractTaken"))
end)

--[[ Commands ]]

concommand.Add("slownls_hitman_rcontracts", function(pPlayer)
    if( not pPlayer:IsSuperAdmin() ) then return end

    for k,v in pairs(SlownLS.Hitman.Contracts or {}) do
        SlownLS.Hitman:refund(k)
        SlownLS.Hitman:removeContract(k)
    end 
end)

--[[ Metatables ]]

timer.Simple(1, function()
    local PLAYER = FindMetaTable("Player")
    
    function PLAYER:isHitman()
        if( not SlownLS.Hitman:hasJob(self) ) then return false end

        return true
    end

    function PLAYER:getHitman(str)
        if( str == "contract" ) then
            local intKey = self.SlownLS_Hitman_Current
            local tbl = SlownLS.Hitman.Contracts[intKey]

            if( not tbl ) then return false end
            
            return self.SlownLS_Hitman_Current
        end

        if( str == "hasContract" ) then
            return self.SlownLS_Hitman_Current and true or false
        end
    end
end)