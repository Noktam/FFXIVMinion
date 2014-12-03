---------------------------------------------------------------------------------------------
--ADD_TASK CNEs
--These are cnes which are used to check the current game state and add a new task/subtask
--based on the needs of the parent task they are assigned to. They differ from the task
--completion CNEs since they don't perform any action other than to queue a new task. 
--Every task must have a CNE like this to queue it when appropriate. They can be placed
--in either the process elements or the overwatch elements for a task based on the priority
--of the task they queue. MOVETOTARGET, for instance, should be placed in the overwatch
--list since it needs to be checked continually for moving targets; COMBAT can be placed
--into the process list since there is no need to queue another combat task until the
--previous combat task is completed and control returns to the parent task.
---------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------
--ADD_KILLTARGET: If (current target hp > 0) Then (add longterm killtarget task)
--Adds a killtarget task if target hp > 0
---------------------------------------------------------------------------------------------
c_add_killtarget = inheritsFrom( ml_cause )
e_add_killtarget = inheritsFrom( ml_effect )
c_add_killtarget.oocCastTimer = 0
function c_add_killtarget:evaluate()
	-- block killtarget for grinding when user has specified "Fates Only"
	if ((ml_task_hub:CurrentTask().name == "LT_GRIND" or ml_task_hub:CurrentTask().name == "LT_PARTY" ) and gFatesOnly == "1") then
		if (ml_task_hub:CurrentTask().name == "LT_GRIND") then
			local aggro = GetNearestAggro()
			if ValidTable(aggro) then
				if (aggro.hp.current > 0 and aggro.id and aggro.id ~= 0 and aggro.distance <= 30) then
					c_add_killtarget.targetid = aggro.id
					return true
				end
			end 
		end
        return false
    end
	
	if (gBotMode == strings[gCurrentLanguage].partyMode and not IsLeader()) then
        return false
    end
	
	if not (ml_task_hub:ThisTask().name == "LT_FATE" and ml_task_hub:CurrentTask().name == "MOVETOPOS") then
		local aggro = GetNearestAggro()
		if ValidTable(aggro) then
			if (aggro.hp.current > 0 and aggro.id and aggro.id ~= 0 and aggro.distance <= 30) then
				c_add_killtarget.targetid = aggro.id
				return true
			end
		end 
	end
    
	if (SkillMgr.Cast( Player, true)) then
		c_add_killtarget.oocCastTimer = Now() + 1500
		return false
	end
	
	if (ActionList:IsCasting() or Now() < c_add_killtarget.oocCastTimer) then
		return false
	end
	
	local target = ml_task_hub:CurrentTask().targetFunction()
    if (ValidTable(target)) then
        if(target.hp.current > 0 and target.id ~= nil and target.id ~= 0) then
            c_add_killtarget.targetid = target.id
            return true
        end
    end
    
    return false
end
function e_add_killtarget:execute()
	if (ml_task_hub:ThisTask().killFunction ~= nil) then
		local newTask = ml_task_hub:ThisTask().killFunction.Create()
		newTask.targetid = c_add_killtarget.targetid
		ml_task_hub:CurrentTask():AddSubTask(newTask)
	else
		local newTask = ffxiv_task_killtarget.Create()
		Player:SetTarget(c_add_killtarget.targetid)
		newTask.targetid = c_add_killtarget.targetid
		ml_task_hub:CurrentTask():AddSubTask(newTask)
	end
end

c_killaggrotarget = inheritsFrom( ml_cause )
e_killaggrotarget = inheritsFrom( ml_effect )
c_killaggrotarget.targetid = 0
function c_killaggrotarget:evaluate()
	if (gBotMode == strings[gCurrentLanguage].partyMode and IsLeader() ) then
        return false
    end
	
	if (gBotMode == strings[gCurrentLanguage].partyMode) then
		local leader, isEntity = GetPartyLeader()	
		if (leader and leader.id ~= 0) then
			local entity = EntityList:Get(leader.id)
			if ( entity  and entity.id ~= 0) then
				if ((entity.incombat and entity.distance > 7) or (not entity.incombat and entity.distance > 10) or (entity.ismounted) or Player.ismounted) then
					return false
				end
			end
		end
	end
	
    local target = GetNearestAggro()
	if (ValidTable(target)) then
		if(target.hp.current > 0 and target.id ~= nil and target.id ~= 0) then
			c_killaggrotarget.targetid = target.id
			return true
		end
	end
    
    return false
end
function e_killaggrotarget:execute()
	local newTask = ffxiv_task_killtarget.Create()
	Player:SetTarget(c_killaggrotarget.targetid)
    newTask.targetid = c_killaggrotarget.targetid
    ml_task_hub:CurrentTask():AddSubTask(newTask)
end
---------------------------------------------------------------------------------------------
---- minion attacks the target the leader has
--Adds a task to use a combat routine to attack/kill target 
---------------------------------------------------------------------------------------------
c_assistleader = inheritsFrom( ml_cause )
e_assistleader = inheritsFrom( ml_effect )
c_assistleader.targetid = nil
function c_assistleader:evaluate()
    if (gBotMode == strings[gCurrentLanguage].partyMode and IsLeader() ) then
        return false
    end
	
    local leader, isEntity = GetPartyLeader()	
    if (ValidTable(leader) and isEntity) then
		local leadtarget = leader.targetid
		if (leader.ismounted or not leader.incombat or not leadtarget or leadtarget == 0) then
			return false			
		end

		if (ml_task_hub:ThisTask().subtask) then
			local task = ml_task_hub:ThisTask().subtask
			if (task.name == "GRIND_COMBAT" and task.targetid == leadtarget) then
				return false
			end
		end
		
		local target = EntityList:Get(leadtarget)				
		if ( ValidTable(target) and target.alive and (target.onmesh or InCombatRange(target.id))) then
			c_assistleader.targetid = target.id
			return true
		end
    end
    
    return false
end
function e_assistleader:execute()
	local id = c_assistleader.targetid
	if ( Player.ismounted ) then
		Dismount()
		return
	end
	
	if (ml_task_hub:CurrentTask().name == "GRIND_COMBAT") then
		ml_task_hub:CurrentTask().targetid = id
	else
		local newTask = ffxiv_task_grindCombat.Create()
		newTask.targetid = id 
		ml_task_hub:CurrentTask():AddSubTask(newTask)
	end
end

---------------------------------------------------------------------------------------------
--ADD_COMBAT: If (target hp > 0) Then (add combat task)
--Adds a task to use a combat routine to attack/kill target 
---------------------------------------------------------------------------------------------
c_add_combat = inheritsFrom( ml_cause )
e_add_combat = inheritsFrom( ml_effect )
function c_add_combat:evaluate()
	
    local target = EntityList:Get(ml_task_hub:CurrentTask().targetid)
	
	--Do some special checking here for hunts.
	if (target) then
		if (ml_task_hub:RootTask().name == "LT_HUNT") then
			if (ml_task_hub:CurrentTask().rank == "S") then
				local allies = EntityList("alive,friendly,chartype=4,targetable,maxdistance=50")
				if ((target.hp.percent > tonumber(gHuntSRankHP)) and (not allies or TableSize(allies) < tonumber(gHuntSRankAllies))) then
					return false
				end
			elseif (ml_task_hub:CurrentTask().rank == "A") then
				local allies = EntityList("alive,friendly,chartype=4,targetable,maxdistance=50")
				if ((target.hp.percent > tonumber(gHuntARankHP)) and (not allies or TableSize(allies) < tonumber(gHuntARankAllies))) then
					return false
				end
			elseif (ml_task_hub:CurrentTask().rank == "B") then
				if (Now() < ml_task_hub:CurrentTask().waitTimer and target.targetid == 0) then
					return false
				end
			end
		end
	end
	
	--If we made it this far without stopping, assume the target can be safely engaged.
	if (not ml_task_hub:CurrentTask().canEngage) then
		ml_task_hub:CurrentTask().canEngage = true
	end
	
	if (target and target.id ~= 0) then
		return InCombatRange(target.id) and target.alive and not IsMounting()
	end
        
    return false
end
function e_add_combat:execute()
	Dismount()
	
	if (IsMounting() or Player.ismounted) then	
		return
	end
	
    if ( gSMactive == "1" ) then
        local newTask = ffxiv_task_skillmgrAttack.Create()
        newTask.targetid = ml_task_hub:CurrentTask().targetid
        ml_task_hub:CurrentTask():AddSubTask(newTask)
    else
		ml_debug("Skill manager is not active, defaulting to class routine.")
        local newTask = ml_global_information.CurrentClass.Create()
        newTask.targetid = ml_task_hub:CurrentTask().targetid
        ml_task_hub:CurrentTask():AddSubTask(newTask)
    end
end

---------------------------------------------------------------------------------------------
--ADD_FATE: If (fate of proper level is on mesh) Then (add longterm fate task)
--Adds a fate task if there is a fate on the mesh
---------------------------------------------------------------------------------------------
c_add_fate = inheritsFrom( ml_cause )
e_add_fate = inheritsFrom( ml_effect )
c_add_fate.fate = {}
function c_add_fate:evaluate()    
    if (gBotMode == strings[gCurrentLanguage].partyMode and not IsLeader()) then
		return false
    end
	
	if (ml_task_hub:ThisTask().subtask) then
		if (ml_task_hub:ThisTask().subtask.name == "LT_FATE") then
			return false
		end
	end
    
    if (gDoFates == "1") then
		local fate = GetClosestFate(Player.pos)
		if (ValidTable(fate)) then
			c_add_fate.fate = shallowcopy(fate)
			return true
		end
    end
    
    return false
end
function e_add_fate:execute()
    local newTask = ffxiv_task_fate.Create()
    local myPos = Player.pos
    newTask.fateid = c_add_fate.fate.id
    --newTask.fateTimer = Now()
	newTask.fatePos = {x = c_add_fate.fate.x, y = c_add_fate.fate.y, z = c_add_fate.fate.z}
    ml_task_hub:CurrentTask():AddSubTask(newTask)
end

c_nextatma = inheritsFrom( ml_cause )
e_nextatma = inheritsFrom( ml_effect )
e_nextatma.atma = nil
function c_nextatma:evaluate()	
	if (gAtma == "0" or Player.incombat or ffxiv_task_grind.inFate or IsLoading()) then
		return false
	end
	
	local map = Player.localmapid
	local mapFound = false
	local mapItem = nil
	local itemFound = false
	local getNext = false
	local jpTime = GetJPTime()
	
	--First loop, check for best atma based on JP time theory.
	for a, atma in pairs(ffxiv_task_grind.atmas) do
		if ((tonumber(atma.hour) == jpTime.hour and jpTime.minute <= 55) or
			(tonumber(atma.hour) == AddHours12(jpTime.hour,1) and jpTime.minute > 55)) then
			local haveBest = false
			--local bestAtma = a
			for x=0,3 do
				local inv = Inventory("type="..tostring(x))
				for i, item in pairs(inv) do
					if (item.id == atma.item) then
						haveBest = true
					end
					if (haveBest) then	
						break
					end
				end
				if (haveBest) then
					break
				end
			end
		
			if (not haveBest) then
				if (atma.map ~= map) then
					e_nextatma.atma = atma
					return true
				end
			end
		end
	end
	
	--Second loop, check to see if we have this map's atma, and return false if we still don't have it yet.
	for a, atma in pairs(ffxiv_task_grind.atmas) do
		if (atma.map == map) then
			local haveClosest = false
			
			for x=0,3 do
				local inv = Inventory("type="..tostring(x))
				for i, item in pairs(inv) do
					if (item.id == atma.item) then
						haveClosest = true
					end
					if (haveClosest) then	
						break
					end
				end
				if (haveClosest) then
					break
				end
			end
			
			if (not haveClosest) then
				--We're already on the map with the most appropriate atma and we don't have it
				return false
			end
		end
	end
	
	--Third loop, figure out which ones we do have, then go anywhere else.
	for a, atma in pairs(ffxiv_task_grind.atmas) do
		local found = false
		for x=0,3 do
			local inv = Inventory("type="..tostring(x))
			for i, item in pairs(inv) do
				if (item.id == atma.item) then
					found = true
				end
				if (found) then	
					break
				end
			end
			if (found) then
				break
			end
		end
		
		if (not found) then
			e_nextatma.atma = atma
			return true
		end
		
	end
	
	return false
end
function e_nextatma:execute()
	local atma = e_nextatma.atma
	Player:Stop()
	Dismount()
	
	if (Player.ismounted) then
		return
	end
	
	if (ActionIsReady(5)) then
		Player:Teleport(atma.tele)
		
		local newTask = ffxiv_task_teleport.Create()
		d("Changing to new location for "..tostring(atma.name).." atma.")
		newTask.mapID = atma.map
		newTask.mesh = atma.mesh
		ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
	end
end

--=======Avoidance============

c_avoid = inheritsFrom( ml_cause )
e_avoid = inheritsFrom( ml_effect )
c_avoid.target = nil
function c_avoid:evaluate()	
	if (gAvoidAOE == "0") then
		return false
	end

	local ppos = Player.pos
	local plevel = Player:GetSyncLevel() ~= 0 and Player:GetSyncLevel() or Player.level
	-- Check for nearby enemies casting things on us.
	local el = EntityList("targetingme,aggressive,onmesh,maxdistance=25")
	if (el) then
		for i,e in pairs(el) do
			if (ValidTable(e.castinginfo) and e.castinginfo.channelingid ~= 0) then
				if (not ml_blacklist.CheckBlacklistEntry(GetString("aoe"), e.castinginfo.channelingid)) then
					local epos = shallowcopy(e.pos)
					local distance = Distance3D(Player.pos.x, Player.pos.y, Player.pos.z, epos.x, epos.y, epos.z)
					
					if not (e.castinginfo.casttime < 1.3 
						or (distance > 20 and e.castinginfo.channeltargetid == e.id) 
						or (e.castinginfo.channeltargetid ~= e.id and e.targetid ~= Player.id)
						or (e.level ~= nil and e.level ~= 0 and plevel > e.level + 7)) then
						c_avoid.target = e
						return true
					end
				end
			end
		end
	end
	
	-- If we don't have a target, we obviously can't avoid anything.
	local target = Player:GetTarget()
	if (not target or not target.castinginfo or target.castinginfo.channelingid == 0 or (plevel > target.level + 7)) then
		return false
	end
	
	if (ml_blacklist.CheckBlacklistEntry(GetString("aoe"), target.castinginfo.channelingid)) then
		return false
	end
	
	local epos = target.pos
	local distance = Distance3D(Player.pos.x, Player.pos.y, Player.pos.z, epos.x, epos.y, epos.z)
	--Check to see if our current target is casting on us.
    if (target.castinginfo.casttime < 1.3
		or (distance > 15 and target.castinginfo.channeltargetid == target.id) 
		or (target.castinginfo.channeltargetid ~= target.id and target.targetid ~= Player.id)) then
        return false
    end

	c_avoid.target = target
    return true
end

function e_avoid:execute() 	
	local target = c_avoid.target
	local ppos = Player.pos
	local epos = target.pos
	local escapePoint

	local h = ConvertHeading(ppos.h)
	local eh = ConvertHeading(epos.h)
	
	local mobRight = ConvertHeading((eh - (math.pi/2)))%(2*math.pi)
	local mobLeft = ConvertHeading((eh + (math.pi/2)))%(2*math.pi)
	local mobRear = ConvertHeading((eh - (math.pi)))%(2*math.pi)
	local mobFrontLeft = ConvertHeading((eh + (math.pi * .30)))%(2*math.pi)
	local mobFrontRight = ConvertHeading((eh - (math.pi * .30)))%(2*math.pi)
	
	local playerRight = ConvertHeading((h - (math.pi/2)))%(2*math.pi)
	local playerLeft = ConvertHeading((h + (math.pi/2)))%(2*math.pi)
	local playerRearLeft = ConvertHeading((h + (math.pi * .65)))%(2*math.pi)
	local playerRearRight = ConvertHeading((h - (math.pi * .65)))%(2*math.pi)
	local playerRear = ConvertHeading((h - (math.pi)))%(2*math.pi)
	
	local dodgeDist = 0
	if (target.hitradius < 2) then
		dodgeDist = 9
	elseif (target.hitradius >= 2 and target.hitradius < 3) then
		dodgeDist = 11
	else
		dodgeDist = 14
	end
	
	local rangeDist = nil
	if (ml_global_information.AttackRange > 5) then
		rangeDist = Distance3D(ppos.x,ppos.y,ppos.z,epos.x,epos.y,epos.z)		
	else
		rangeDist = target.hitradius + 1
	end
	
	local options1 = {
		GetPosFromDistanceHeading(epos, rangeDist, mobRear),
		GetPosFromDistanceHeading(epos, rangeDist, mobRight),
		GetPosFromDistanceHeading(epos, rangeDist, mobLeft),
	}
	
	local options2 = {
		GetPosFromDistanceHeading(ppos, 8, h),
		GetPosFromDistanceHeading(ppos, 8, playerRight),
		GetPosFromDistanceHeading(ppos, 8, playerLeft),
	}
	
	local options3 = {
		GetPosFromDistanceHeading(epos, dodgeDist, mobRear),
		GetPosFromDistanceHeading(epos, dodgeDist, mobRight),
		GetPosFromDistanceHeading(epos, dodgeDist, mobLeft),
		GetPosFromDistanceHeading(epos, dodgeDist, mobFrontLeft),
		GetPosFromDistanceHeading(epos, dodgeDist, mobFrontRight),
		GetPosFromDistanceHeading(epos, dodgeDist + 3, playerRear),
	}
	
	local maxTime = 0
	if (target.castinginfo.channeltargetid == target.id) then
		local optionTable = nil
		if (ffxiv_aoe_data.circle[target.castinginfo.channelingid]) then
			optionTable = options3
			maxTime = tonumber(target.castinginfo.casttime)
		else
			optionTable = options1
			maxTime = 0
		end
		
		-- If the casting target is the entity's own ID, it is a self-centered aoe, so either run away or move very far left and right.
		local viable = {}
		local i = 0
		for _, pos in pairs(optionTable) do
			i = i + 1
			local p,dist = NavigationManager:GetClosestPointOnMesh(pos)
			if (p and dist <= 5) then
				viable[i] = p
			end
		end
		
		local closest = nil
		local closestDistance = 99
		for _, pos in pairs(viable) do
			local distance = Distance3D(pos.x,pos.y,pos.z,ppos.x,ppos.y,ppos.z)
			if (distance < closestDistance) then
				closestDistance = distance
				closest = pos
			end
		end
		
		escapePoint = closest
	else
		-- If the casting target is not the entity's own ID, it's on us, so move left or right to dodge it.
		maxTime = tonumber(target.castinginfo.casttime)
		local viable = {}
		local i = 0
		for _, pos in pairs(options2) do
			i = i + 1
			local p,dist = NavigationManager:GetClosestPointOnMesh(pos)
			if (p and dist <= 5) then
				viable[i] = p
			end
		end
		
		local closest = nil
		local closestDistance = 99
		for _, pos in pairs(viable) do
			local distance = Distance3D(pos.x,pos.y,pos.z,ppos.x,ppos.y,ppos.z)
			if (distance < closestDistance) then
				closestDistance = distance
				closest = pos
			end
		end
		
		escapePoint = closest
	end
	
	if (ValidTable(escapePoint)) then
		local moveDist = Distance3D(ppos.x,ppos.y,ppos.z,escapePoint.x,escapePoint.y,escapePoint.z)
		if (moveDist > 1.5) then
			local newTask = ffxiv_task_avoid.Create()
			newTask.pos = escapePoint
			newTask.targetid = target.id
			newTask.interruptCasting = true
			newTask.maxTime = maxTime
			ml_task_hub:ThisTask().preserveSubtasks = true
			ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
		end
	end
end


c_autopotion = inheritsFrom( ml_cause )
e_autopotion = inheritsFrom( ml_effect )
c_autopotion.potions = "4554;4553;4552;4551"
c_autopotion.ethers = "4558;4557;4556;4555"
c_autopotion.itemid = 0
function c_autopotion:evaluate()	
	local potions = c_autopotion.potions
	if (tonumber(gPotionHP) > 0 and Player.hp.percent < tonumber(gPotionHP)) then
		for itemid in StringSplit(potions,";") do
			if (ItemIsReady(tonumber(itemid))) then
				c_autopotion.itemid = tonumber(itemid)
				return true
			end
		end
	end
	
	local ethers = c_autopotion.ethers
	if (tonumber(gPotionMP) > 0 and Player.mp.percent < tonumber(gPotionMP)) then
		for itemid in StringSplit(ethers,";") do
			if (ItemIsReady(tonumber(itemid))) then
				c_autopotion.itemid = tonumber(itemid)
				return true
			end
		end
	end
	
	return false
end
function e_autopotion:execute()
	local newTask = ffxiv_task_useitem.Create()
	newTask.itemid = c_autopotion.itemid
	ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
end

---------------------------------------------------------------------------------------------
--ADD_MOVETOTARGET: If (current target distance > combat range) Then (add movetotarget task)
--Adds a MoveToTarget task 
---------------------------------------------------------------------------------------------
c_movetotarget = inheritsFrom( ml_cause )
e_movetotarget = inheritsFrom( ml_effect )
function c_movetotarget:evaluate()
	if ( not ml_task_hub:CurrentTask().canEngage ) then
		return false
	end
	
    if ( ml_task_hub:CurrentTask().targetid ~= nil and ml_task_hub:CurrentTask().targetid ~= 0 ) then
        local target = EntityList:Get(ml_task_hub:CurrentTask().targetid)
        if (target and target.id ~= 0 and target.alive) then
            return not InCombatRange(target.id)
        end
    end
    
    return false
end
function e_movetotarget:execute()
    ml_debug( "Moving within combat range of target" )
    local target = EntityList:Get(ml_task_hub:CurrentTask().targetid)
	local newTask = ffxiv_task_movetopos.Create()
	newTask.pos = target.pos
	newTask.targetid = target.id
	newTask.useFollowMovement = false
	ml_task_hub:CurrentTask():AddSubTask(newTask)
end

c_movecloser = inheritsFrom( ml_cause )
e_movecloser = inheritsFrom( ml_effect )
function c_movecloser:evaluate()
	if ( ml_task_hub:CurrentTask().targetid ~= nil and ml_task_hub:CurrentTask().targetid ~= 0 ) then
		local target = EntityList:Get(ml_task_hub:CurrentTask().targetid)
		if (target and target.id ~= 0 and target.alive) then
			return (target.distance > 40)
		end
	end
	
	return false
end
function e_movecloser:execute()
	local target = EntityList:Get(ml_task_hub:CurrentTask().targetid)
	local newTask = ffxiv_task_movetopos.Create()
	newTask.pos = target.pos
	newTask.targetid = target.id
	newTask.useFollowMovement = false
	ml_task_hub:CurrentTask():AddSubTask(newTask)
end

c_movetotargetsafe = inheritsFrom( ml_cause )
e_movetotargetsafe = inheritsFrom( ml_effect )
function c_movetotargetsafe:evaluate()
	if ( ml_task_hub:CurrentTask().canEngage ) then
		return false
	end
	
    if ( ml_task_hub:CurrentTask().targetid and ml_task_hub:CurrentTask().targetid ~= 0 ) then
        local target = EntityList:Get(ml_task_hub:CurrentTask().targetid)
        if (target and target.id ~= 0 and target.alive) then
			local tpos = target.pos
			local pos = Player.pos
			if (Distance3D(tpos.x,tpos.y,tpos.z,pos.x,pos.y,pos.z) > (ml_task_hub:CurrentTask().safeDistance + 2)) then
				return true
			end
        end
    end
    
    return false
end
function e_movetotargetsafe:execute()
    local target = EntityList:Get(ml_task_hub:CurrentTask().targetid)
	local newTask = ffxiv_task_movetopos.Create()
	newTask.range = ml_task_hub:CurrentTask().safeDistance
	newTask.pos = target.pos
	newTask.targetid = target.id
	newTask.useFollowMovement = false
	ml_task_hub:CurrentTask():AddSubTask(newTask)
end

---------------------------------------------------------------------------------------------
--ADD_MOVETOMAP
--Adds a MoveToGate task 
---------------------------------------------------------------------------------------------
c_interactgate = inheritsFrom( ml_cause )
e_interactgate = inheritsFrom( ml_effect )
c_interactgate.lastInteract = 0
e_interactgate.id = 0
function c_interactgate:evaluate()
    if (ml_task_hub:CurrentTask().destMapID) then
		if (Player.localmapid ~= ml_task_hub:CurrentTask().destMapID and not IsLoading() and not ml_mesh_mgr.loadingMesh) then
			local pos = ml_nav_manager.GetNextPathPos(	Player.pos,	Player.localmapid,	ml_task_hub:CurrentTask().destMapID	)

			if (ValidTable(pos) and pos.g) then
				local interacts = EntityList("type=7,chartype=0,maxdistance=3")
				for i, interactable in pairs(interacts) do
					if interactable.uniqueid == tonumber(pos.g) then
						if (interactable.targetable) then
							if (c_interactgate.lastInteract == 0 or Now() > c_interactgate.lastInteract) then
								Player:SetTarget(interactable.id)
								e_interactgate.id = interactable.id
								c_interactgate.lastInteract = Now() + 1000
								return true
							else
								return false
							end
						end
					end
				end
			end
		end
	end
	
	return false
end
function e_interactgate:execute()
	Player:Stop()
	
	local gate = EntityList:Get(e_interactgate.id)
	local pos = gate.pos
	SetFacing(pos.x,pos.y,pos.z)
	Player:Interact(gate.id)
end

c_transportgate = inheritsFrom( ml_cause )
e_transportgate = inheritsFrom( ml_effect )
e_transportgate.details = nil
function c_transportgate:evaluate()
	if (ml_task_hub:ThisTask().destMapID) then
		if (Player.localmapid ~= ml_task_hub:CurrentTask().destMapID and not IsLoading() and not ml_mesh_mgr.loadingMesh) then
			local pos = ml_nav_manager.GetNextPathPos( Player.pos,	Player.localmapid,	ml_task_hub:CurrentTask().destMapID	)
			ml_task_hub:ThisTask().pos = pos
			if (not c_usenavinteraction:evaluate()) then
				if (ValidTable(pos) and pos.b) then
					local details = {}
					details.uniqueid = pos.b
					details.pos = { x = pos.x, y = pos.y, z = pos.z }
					details.conversationIndex = pos.i or 0
					e_transportgate.details = details
					return true
				elseif (ValidTable(pos) and pos.a) then
					local details = {}
					details.uniqueid = pos.a
					details.pos = { x = pos.x, y = pos.y, z = pos.z }
					details.conversationIndex = pos.i or 0
					e_transportgate.details = details
					return true
				end
			end
		end
	end
	
	return false
end
function e_transportgate:execute()
	local gateDetails = e_transportgate.details
	local newTask = ffxiv_nav_interact.Create()
	if (gTeleport == "1") then
		newTask.useTeleport = true
	end
	newTask.pos = gateDetails.pos
	newTask.uniqueid = gateDetails.uniqueid
	newTask.conversationIndex = gateDetails.conversationIndex
	ml_task_hub:CurrentTask():AddSubTask(newTask)
end

c_movetogate = inheritsFrom( ml_cause )
e_movetogate = inheritsFrom( ml_effect )
function c_movetogate:evaluate()
    if (ml_task_hub:CurrentTask().destMapID) then
        return 	Player.localmapid ~= ml_task_hub:CurrentTask().destMapID and
				not IsLoading() and
				not ml_mesh_mgr.loadingMesh
	end
end
function e_movetogate:execute()
    ml_debug( "Moving to gate for next map" )
	local pos = ml_nav_manager.GetNextPathPos(	Player.pos,
												Player.localmapid,
												ml_task_hub:CurrentTask().destMapID	)
	if (ValidTable(pos)) then
		local newTask = ffxiv_task_movetopos.Create()
		local newPos = { x = pos.x, y = pos.y, z = pos.z }
		local newPos = GetPosFromDistanceHeading(newPos, 5, pos.h)
		newTask.pos = pos
		
		if (not pos.g and not pos.b and not pos.a) then
			newTask.gatePos = newPos
		end
		
		newTask.range = 0.5
		
		if(gTeleport == "1") then
			newTask.useTeleport = true
			--newTask:SetDelay(2000)
		end
		--newTask.useFollowMovement = true
		ml_task_hub:CurrentTask():AddSubTask(newTask)
	end
end

c_teleporttomap = inheritsFrom( ml_cause )
e_teleporttomap = inheritsFrom( ml_effect )
e_teleporttomap.aethid = 0
e_teleporttomap.destMap = 0
function c_teleporttomap:evaluate()
	if (gUseAetherytes == "0") then
		return false
	end
	
	local el = EntityList("alive,attackable,onmesh,targetingme")
	if (ValidTable(el)) then
		return false
	end
	
	local teleport = ActionList:Get(5)
	if (not teleport or Player.castinginfo.channelingid == 5 or Player.castinginfo.castingid == 5) then
		return false
	end
	
	local gil = nil
	local inv = Inventory("type=2000")
	for i,item in pairs(inv) do
		if (item.slot == 0) then
			gil = item.count
		end
		if (gil) then
			break
		end
	end
	
	if (gil < 500) then
		return false
	end
	
	
    if (ml_task_hub:CurrentTask().tryTP and ml_task_hub:CurrentTask().destMapID) then
        local pos = ml_nav_manager.GetNextPathPos(	Player.pos,
                                                    Player.localmapid,
                                                    ml_task_hub:CurrentTask().destMapID	)

        if (ValidTable(ml_nav_manager.currPath)) then
            local aethid = nil
			local mapid = nil
            for _, node in pairsByKeys(ml_nav_manager.currPath) do
                if (node.id ~= Player.localmapid) then
					local map,aeth = GetAetheryteByMapID(node.id, ml_task_hub:ThisTask().pos)
                    if (aeth) then
						mapid = map
						aethid = aeth
					end
                end
            end
            
            if (aethid) then
				e_teleporttomap.destMap = mapid
                e_teleporttomap.aethid = aethid
                return true
            end
        end
    end
    
    ml_task_hub:CurrentTask().tryTP = false
    return false
end
function e_teleporttomap:execute()
	Player:Stop()
	Dismount()
	
	if (Player.ismounted) then
		return
	end
	
	if (ActionIsReady(5)) then
		Player:Teleport(e_teleporttomap.aethid)
							
		local newTask = ffxiv_task_teleport.Create()
		newTask.mapID = e_teleporttomap.destMap
		ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
	end
end

c_followleader = inheritsFrom( ml_cause )
e_followleader = inheritsFrom( ml_effect )
c_followleader.range = math.random(3,8)
c_followleader.leaderpos = nil
c_followleader.leader = nil
c_followleader.distance = nil
c_followleader.hasEntity = false
e_followleader.isFollowing = false
e_followleader.stopFollow = false
function c_followleader:evaluate()
	if (gBotMode == strings[gCurrentLanguage].partyMode and IsLeader() or ActionList:IsCasting()) then
        return false
    end
	
	local leader, isEntity = GetPartyLeader()
	local leaderPos = GetPartyLeaderPos()
	if (ValidTable(leaderPos) and ValidTable(leader)) then
		local myPos = shallowcopy(Player.pos)	
		local distance = Distance3D(myPos.x, myPos.y, myPos.z, leaderPos.x, leaderPos.y, leaderPos.z)
		
		if (((leader.incombat and distance > 5) or (distance > 10)) or (isEntity and (leader.ismounted and not Player.ismounted))) then				
			c_followleader.leaderpos = leaderPos
			c_followleader.leader = leader
			c_followleader.distance = distance
			c_followleader.hasEntity = isEntity
			return true
		end
	end
	
	if (e_followleader.isFollowing) then
		e_followleader.stopFollow = true
		return true
	end
	
    return false
end

function e_followleader:execute()
	local leader = c_followleader.leader
	local leaderPos = c_followleader.leaderpos
	local distance = c_followleader.distance
	
	if (e_followleader.isFollowing and e_followleader.stopFollow) then
		Player:Stop()
		e_followleader.isFollowing = false
		e_followleader.stopFollow = false
		return
	end
	
	if (Player.onmesh) then		
		-- mount
		
		if (gUseMount == "1" and gMount ~= "None" and c_followleader.hasEntity) then
			if (((leader.castinginfo.channelingid == 4 or leader.ismounted) or distance >= tonumber(gMountDist)) and not Player.ismounted) then
				if (not ActionList:IsCasting()) then
					Player:Stop()
					Mount()
				end
				return
			end
		end
		
		--sprint
		if (gUseSprint == "1" and distance >= tonumber(gSprintDist)) then
			if ( not HasBuff(Player.id, 50) and not Player.ismounted) then
				local sprint = ActionList:Get(3)
				if (sprint.isready) then	
					sprint:Cast()
				end
			end
		end
		
		if (gTeleport == "1") then
			if (distance > 100) then
				GameHacks:TeleportToXYZ(leaderPos.x,leaderPos.y,leaderPos.z)
				Player:SetFacingSynced(leaderPos.x,leaderPos.y,leaderPos.z)
			end
		end
		
		if (c_followleader.hasEntity and leader.los) then
			ml_debug( "Moving to Leader: "..tostring(Player:MoveTo(leaderPos.x, leaderPos.y, leaderPos.z, tonumber(c_followleader.range),true,false)))	
		else
			ml_debug( "Moving to Leader: "..tostring(Player:MoveTo(leaderPos.x, leaderPos.y, leaderPos.z, tonumber(c_followleader.range),false,false)))	
		end
		if ( not Player:IsMoving()) then
			if ( ml_global_information.AttackRange < 5 ) then
				c_followleader.range = math.random(4,6)
			else
				c_followleader.range = math.random(6,10)
			end
		end
		e_followleader.isFollowing = true
	else
		if ( not Player:IsMoving() ) then
			FollowResult = Player:FollowTarget(leader.id)
			ml_debug( "Following Leader: "..tostring(FollowResult))
		end
	end
end

---------------------------------------------------------------------------------------------
--Task Completion CNEs
--These are cnes which are added to the process element list for a task and exist only to
--complete the specified task. They should be specific to the task which contains them...
--their only purpose should be to check the current game state and adjust the behavior of 
--the task in order to ensure its completion. 
---------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------
--WALKTOPOS: If (distance to target > task.range) Then (move to pos)
---------------------------------------------------------------------------------------------
c_walktopos = inheritsFrom( ml_cause )
e_walktopos = inheritsFrom( ml_effect )
c_walktopos.pos = 0
function c_walktopos:evaluate()
    if ( ml_task_hub:CurrentTask().pos ~= nil and ml_task_hub:CurrentTask().pos ~= 0 ) then
        if ((ActionList:IsCasting() and not ml_task_hub:CurrentTask().interruptCasting) or IsMounting()) then
            return false
        end
		
        local myPos = Player.pos
        local gotoPos
		
		-- if we're doing map navigation then we have extended the moveto pos beyond the gate to 
		-- make sure the bot runs through it...use the gatePos instead of the original position
		if(ml_task_hub:CurrentTask().gatePos) then
			gotoPos = ml_task_hub:CurrentTask().gatePos
		else
			gotoPos = ml_task_hub:CurrentTask().pos
		end
		
        -- have to allow for 3d distance check because some quests have objectives on floors directly above one another  
		local distance = 0.0
		if(ml_task_hub:CurrentTask().use3d) then
			distance = Distance3D(myPos.x, myPos.y, myPos.z, gotoPos.x, gotoPos.y, gotoPos.z)
		else
			distance = Distance2D(myPos.x, myPos.z, gotoPos.x, gotoPos.z)
		end
        --d("Bot Position: ("..tostring(myPos.x)..","..tostring(myPos.y)..","..tostring(myPos.z)..")")
        --d("MoveTo Position: ("..tostring(gotoPos.x)..","..tostring(gotoPos.y)..","..tostring(gotoPos.z)..")")
        --d("Current Distance: "..tostring(distance))
        --d("Execute Distance: "..tostring(ml_task_hub:CurrentTask().range))
        
        if (distance > ml_task_hub:CurrentTask().range) then
            c_walktopos.pos = gotoPos
            return true
        end
    end
    return false
end
function e_walktopos:execute()
    if ( c_walktopos.pos ~= 0) then
        local gotoPos = c_walktopos.pos
        --d("Moving to ("..tostring(gotoPos.x)..","..tostring(gotoPos.y)..","..tostring(gotoPos.z)..")")	
		--d("Move To vars"..tostring(gotoPos.x)..","..tostring(gotoPos.y)..","..tostring(gotoPos.z)..","..tostring(ml_task_hub:CurrentTask().range *0.75)..","..tostring(ml_task_hub:CurrentTask().useFollowMovement or false)..","..tostring(gRandomPaths=="1"))
		local PathSize = Player:MoveTo(tonumber(gotoPos.x),tonumber(gotoPos.y),tonumber(gotoPos.z),tonumber(ml_task_hub:CurrentTask().range *0.75), ml_task_hub:CurrentTask().useFollowMovement or false,gRandomPaths=="1")
		--d(tostring(PathSize))
    else
        ml_error(" Critical error in e_walktopos, c_walktopos.pos == 0!!")
    end
    c_walktopos.pos = 0
end

c_usenavinteraction = inheritsFrom( ml_cause )
e_usenavinteraction = inheritsFrom( ml_effect)
e_usenavinteraction.task = nil
function c_usenavinteraction:evaluate()
	local myPos = shallowcopy(Player.pos)
	local gotoPos = ml_task_hub:ThisTask().pos
	
	requiresTransport = {
		[139] = { name = "Upper La Noscea",
			test = function()
				if (Player.pos.x < 0 and gotoPos.x > 0) then
					--d("Need  to move from west to east.")
					return true
				elseif (Player.pos.x > 0 and gotoPos.x < 0) then
					--d("Need  to move from west to east.")
					return true
				end
				return false
			end,
			reaction = function()
				if (Player.pos.x < 0 and gotoPos.x > 0) then
					local newTask = ffxiv_nav_interact.Create()
					newTask.pos = {x = -341.24, y = -1, z = 112.098}
					newTask.uniqueid = 1003586
					ml_task_hub:CurrentTask():AddSubTask(newTask)
				elseif (Player.pos.x > 0 and gotoPos.x < 0) then
					local newTask = ffxiv_nav_interact.Create()
					newTask.pos = {x = 220.899, y = 1.7, z = 257.399}
					newTask.uniqueid = 1003587
					ml_task_hub:CurrentTask():AddSubTask(newTask)
				end
			end,
		},
		[156] = { name = "Mor Dhona - Cid's Workshop",
			test = function()
				if ((myPos.y < -150 and myPos.x < 12 and myPos.x > -10 and myPos.z < 16.5 and myPos.z > -14.1) and 
					not (gotoPos.y < -150 and gotoPos.x < 12 and gotoPos.x > -10 and gotoPos.z < 16.5 and gotoPos.z > -14.1)) then
					--d("Need  to move from west to east.")
					return true
				elseif (not (myPos.y < -150 and myPos.x < 12 and myPos.x > -10 and myPos.z < 16.5 and myPos.z > -14.1) and 
						(gotoPos.y < -150 and gotoPos.x < 12 and gotoPos.x > -10 and gotoPos.z < 16.5 and gotoPos.z > -14.1)) then
					--d("Need  to move from west to east.")
					return true
				end
				return false
			end,
			reaction = function()
				if ((myPos.y < -150 and myPos.x < 12 and myPos.x > -10 and myPos.z < 16.5 and myPos.z > -14.1) and 
					not (gotoPos.y < -150 and gotoPos.x < 12 and gotoPos.x > -10 and gotoPos.z < 16.5 and gotoPos.z > -14.1)) 
				then
					local newTask = ffxiv_nav_interact.Create()
					newTask.pos = {x = .70, y = -157, z = 16.2}
					newTask.uniqueid = 2002502
					ml_task_hub:CurrentTask():AddSubTask(newTask)
				elseif (not (myPos.y < -150 and myPos.x < 12 and myPos.x > -10 and myPos.z < 16.5 and myPos.z > -14.1) and 
						(gotoPos.y < -150 and gotoPos.x < 12 and gotoPos.x > -10 and gotoPos.z < 16.5 and gotoPos.z > -14.1)) 
				then
					local newTask = ffxiv_nav_interact.Create()
					newTask.pos = {x = 21.9, y = 20.7, z = -682}
					newTask.uniqueid = 1006530
					ml_task_hub:CurrentTask():AddSubTask(newTask)
				end
			end,
		},
		[137] = { name = "Eastern La Noscea",
			test = function()
				if ((Player.pos.x > 218 and Player.pos.z > 51) and not (gotoPos.x > 218 and gotoPos.z > 51)) then
					--d("Need to move from Costa area to Wineport.")
					return true
				elseif (not (Player.pos.x > 218 and Player.pos.z > 51) and (gotoPos.x > 218 and gotoPos.z > 51)) then
					--d("Need to move from Wineport to Costa area.")
					return true
				end
				return false
			end,
			reaction = function()
				if ((Player.pos.x > 218 and Player.pos.z > 51) and not (gotoPos.x > 218 and gotoPos.z > 51)) then
					if (gUseAetherytes == "1") then
						Player:Stop()
						Dismount()
						
						if (Player.ismounted) then
							return
						end
						
						if (ActionIsReady(5) and not ActionList:IsCasting() and not IsLoading()) then
							Player:Teleport(12)
						end
					else
						local newTask = ffxiv_nav_interact.Create()
						newTask.pos = {x = 344.447, y = 32.770, z = 91.694}
						newTask.uniqueid = 1003588
						ml_task_hub:CurrentTask():AddSubTask(newTask)
					end
				elseif (not (Player.pos.x > 218 and Player.pos.z > 51) and (gotoPos.x > 218 and gotoPos.z > 51)) then
					if (gUseAetherytes == "1") then
						Player:Stop()
						Dismount()
						
						if (Player.ismounted) then
							return
						end
						
						if (ActionIsReady(5) and not ActionList:IsCasting() and not IsLoading()) then
							Player:Teleport(11)
						end
					else
						local newTask = ffxiv_nav_interact.Create()
						newTask.pos = {x = 21.919, y = 34.0788, z = 223.187}
						newTask.uniqueid = 1003589
						ml_task_hub:CurrentTask():AddSubTask(newTask)
					end
				end
			end,
		},
		[138] = { name = "Western La Noscea",
			test = function()
				if (not (Player.pos.x < -170 and Player.pos.z > 390) and (gotoPos.x <-170 and gotoPos.z > 390)) then
					return true
				elseif ((Player.pos.x < -170 and Player.pos.z > 390) and not (gotoPos.x <-170 and gotoPos.z > 390)) then
					return true
				end
				return false
			end,
			reaction = function()
				if (not (Player.pos.x < -170 and Player.pos.z > 390) and (gotoPos.x <-170 and gotoPos.z > 390)) then
					local newTask = ffxiv_nav_interact.Create()
					newTask.pos = {x = 318.314, y = -36, z = 351.376}
					newTask.uniqueid = 1003584
					newTask.conversationIndex = 3
					ml_task_hub:CurrentTask():AddSubTask(newTask)
				elseif ((Player.pos.x < -170 and Player.pos.z > 390) and not (gotoPos.x <-170 and gotoPos.z > 390)) then
					local newTask = ffxiv_nav_interact.Create()
					newTask.pos = {x = -290, y = -41.263, z = 407.726}
					newTask.uniqueid = 1005239
					ml_task_hub:CurrentTask():AddSubTask(newTask)
				end
			end,
		},
		[130] = { name = "Uldah Airstrip",
			test = function()
				if (Player.pos.y < 40 and gotoPos.y > 50) then
					return true
				elseif (Player.pos.y > 50 and gotoPos.y < 40) then
					return true
				end
				return false
			end,
			reaction = function()
				if (Player.pos.y < 40 and gotoPos.y > 50) then
					local newTask = ffxiv_nav_interact.Create()
					newTask.pos = {x = -20.760, y = 10, z = -45.3617}
					newTask.uniqueid = 1001834
					newTask.conversationIndex = 1
					ml_task_hub:CurrentTask():AddSubTask(newTask)
				elseif (Player.pos.y > 50 and gotoPos.y < 40) then
					local newTask = ffxiv_nav_interact.Create()
					newTask.pos = {x = -25.125, y = 81.799, z = -30.658}
					newTask.uniqueid = 1004339
					newTask.conversationIndex = 2
					ml_task_hub:CurrentTask():AddSubTask(newTask)
				end
			end,
		},
		[128] = { name = "Limsa Airstrip",
			test = function()
				if (Player.pos.y < 60 and gotoPos.y > 70) then
					return true
				elseif (Player.pos.y > 70 and gotoPos.y < 60) then
					return true
				end
				return false
			end,
			reaction = function()
				if (Player.pos.y < 60 and gotoPos.y > 70) then
					local newTask = ffxiv_nav_interact.Create()
					newTask.pos = {x = 7.802, y = 40, z = 16.158}
					newTask.uniqueid = 1003597
					newTask.conversationIndex = 1
					ml_task_hub:CurrentTask():AddSubTask(newTask)
				elseif (Player.pos.y > 70 and gotoPos.y < 60) then
					local newTask = ffxiv_nav_interact.Create()
					newTask.pos = {x = -8.922, y = 91.5, z = -15.193}
					newTask.uniqueid = 1003583
					newTask.conversationIndex = 1
					ml_task_hub:CurrentTask():AddSubTask(newTask)
				end
			end,
		},
		[212] = { name = "Waking Sands",
			test = function()
				if ((myPos.x < 23.85 and myPos.x > -15.46) and not (gotoPos.x < 23.85 and gotoPos.x > -15.46)) then
					return true
				elseif (not (myPos.x < 23.85 and myPos.x > -15.46) and (gotoPos.x < 23.85 and gotoPos.x > -15.46 )) then
					return true
				end
				return false
			end,
			reaction = function()
				if ((myPos.x < 23.85 and myPos.x > -15.46) and not (gotoPos.x < 23.85 and gotoPos.x > -15.46)) then
					local newTask = ffxiv_nav_interact.Create()
					newTask.pos = {x = 22.386226654053, y = 0.99999862909317, z = -0.097462706267834}
					newTask.uniqueid = 2001715
					ml_task_hub:CurrentTask():AddSubTask(newTask)
				elseif (not (myPos.x < 23.85 and myPos.x > -15.46) and (gotoPos.x < 23.85 and gotoPos.x > -15.46)) then
					local newTask = ffxiv_nav_interact.Create()
					newTask.pos = {x = 26.495914459229, y = 1.0000013113022, z = -0.018158292397857}
					newTask.uniqueid = 2001717
					ml_task_hub:CurrentTask():AddSubTask(newTask)
				end
			end,
		},
	}
	
	if (requiresTransport[Player.localmapid]) then
		e_usenavinteraction.task = requiresTransport[Player.localmapid].reaction
		return requiresTransport[Player.localmapid].test()
	end
	
	return false
end
function e_usenavinteraction:execute()
	e_usenavinteraction.task()
end

-- Checks for a better target while we are engaged in fighting an enemy and switches to it
c_bettertargetsearch = inheritsFrom( ml_cause )
e_bettertargetsearch = inheritsFrom( ml_effect )
c_bettertargetsearch.targetid = 0
function c_bettertargetsearch:evaluate()        
    if (gBotMode == strings[gCurrentLanguage].partyMode and not IsLeader()) then
        return false
    end
	
	if (gBotMode == GetString("huntMode") or gBotMode == GetString("questMode")) then
		return false
	end
    
	if (ml_task_hub:CurrentTask().name == "LT_REST" or ml_task_hub:CurrentTask().name == "LT_FLEE") then 
		return false 
	end
	
	if (ActionList:IsCasting() or Now() < c_add_killtarget.oocCastTimer) then
		return false
	end
    
	if (ml_task_hub:CurrentTask().name == "LT_KILLTARGET" and ml_task_hub:RootTask().name == "LT_GRIND") then
		if (not Player.incombat and Player.hasaggro) then
			local bettertarget = GetNearestGrindAttackable()
			if ( bettertarget ~= nil and bettertarget.id ~= ml_task_hub:CurrentTask().targetid ) then
				c_bettertargetsearch.targetid = bettertarget.id
				return true                        
			end
		end
	elseif (ml_task_hub:CurrentTask().name == "LT_SM_KILLTARGET" and gClaimFirst == "1") then
		local bettertarget = GetNearestGrindPriority()
		if ( bettertarget ~= nil and bettertarget.id ~= ml_task_hub:CurrentTask().targetid ) then
			c_bettertargetsearch.targetid = bettertarget.id
			return true                      
		end
	end
     
    return false
end
function e_bettertargetsearch:execute()
    ml_task_hub:CurrentTask().targetid = c_bettertargetsearch.targetid
	Player:SetTarget(c_bettertargetsearch.targetid)        
end



-----------------------------------------------------------------------------------------------
--MOUNT: If (distance to pos > ? or < ?) Then (mount or unmount)
---------------------------------------------------------------------------------------------
c_mount = inheritsFrom( ml_cause )
e_mount = inheritsFrom( ml_effect )
e_mount.id = 0
function c_mount:evaluate()
	noMountMaps = {
		[130] = true,[131] = true,[132] = true,[133] = true,[128] = true,[129] = true,
		[337] = true,[336] = true,[175] = true,[352] = true,
	}
	
    if (noMountMaps[Player.localmapid]) then
		return false
	end
	
	if (HasBuffs(Player,"47")) then
		return false
	end
	
    if ( ml_task_hub:CurrentTask().pos ~= nil and ml_task_hub:CurrentTask().pos ~= 0 and gUseMount == "1") then
		if (not Player.ismounted and not ActionList:IsCasting() and not IsMounting() and not Player.incombat) then
			local myPos = Player.pos
			local gotoPos = ml_task_hub:CurrentTask().pos
			local distance = Distance2D(myPos.x, myPos.z, gotoPos.x, gotoPos.z)
		
			if (distance > tonumber(gMountDist)) then
				--Added mount verifications here.
				--Realistically, the GUIVarUpdates should handle this, but just in case, we backup check it here.
				local mountID
				local mountIndex
				local mountlist = ActionList("type=13")
				
				if (ValidTable(mountlist)) then
					--First pass, look for our named mount.
					for k,v in pairsByKeys(mountlist) do
						if (v.name == gMount) then
							local acMount = ActionList:Get(v.id,13)
							if (acMount and acMount.isready) then
								e_mount.id = v.id
								return true
							end
						end
					end
					
					--Second pass, look for any mount as backup.
					if (gMount == strings[gCurrentLanguage].none) then
						for k,v in pairsByKeys(mountlist) do
							local acMount = ActionList:Get(v.id,13)
							if (acMount and acMount.isready) then
								SetGUIVar("gMount", v.name)
								e_mount.id = v.id
								return true
							end
						end		
					end
				end
			end
		end
    end
    
    return false
end
function e_mount:execute()
    Player:Stop()
    Mount(e_mount.id)
end

c_companion = inheritsFrom( ml_cause )
e_companion = inheritsFrom( ml_effect )
e_companion.lastSummon = 0
function c_companion:evaluate()
    if (gBotMode == strings[gCurrentLanguage].pvpMode or ml_task_hub:CurrentTask().name == "LT_USEITEM" or TimeSince(e_companion.lastSummon) < 5000) then
        return false
    end

    if (((gChoco == strings[gCurrentLanguage].grindMode or gChoco == strings[gCurrentLanguage].any) and (gBotMode == strings[gCurrentLanguage].grindMode or gBotMode == strings[gCurrentLanguage].partyMode)) or
		((gChoco == strings[gCurrentLanguage].assistMode or gChoco == strings[gCurrentLanguage].any) and gBotMode == strings[gCurrentLanguage].assistMode)) then
		if (not Player.ismounted and not IsMounting()) then
			local al = ActionList("type=6")
			local dismiss = al[2]
			local acDismiss = ActionList:Get(dismiss.id,6)
			local item = Inventory:Get(4868)

			if (not ValidTable(item)) then
				return false
			end

			if ( not acDismiss.isready and item.isready) then
				return true
			end
		end
    end
	
    return false
end

function e_companion:execute()
	e_companion.lastSummon = Now()
	local newTask = ffxiv_task_useitem.Create()
	newTask.itemid = 4868
	newTask.useTime = 3000
	ml_task_hub:CurrentTask():AddSubTask(newTask)
	ml_task_hub:ThisTask().preserveSubtasks = true
end

c_stance = inheritsFrom( ml_cause )
e_stance = inheritsFrom( ml_effect )
function c_stance:evaluate()
    if (gBotMode == strings[gCurrentLanguage].pvpMode) then
        return false
    end
	
	local eval = {
		[strings[gCurrentLanguage].grindMode] = true,
		[strings[gCurrentLanguage].partyMode] = true,
		[strings[gCurrentLanguage].assistMode] = true,
	}

    if ( gChoco ~= strings[gCurrentLanguage].none and eval[tostring(gBotMode)]) then

		local al = ActionList("type=6")
		local dismiss = al[2]
		local acDismiss = ActionList:Get(dismiss.id,6)

		if ( acDismiss.isready) then
			if ( ml_global_information.stanceTimer == 0 and TimeSince(ml_global_information.summonTimer) >= 6000 ) then
				return true
			elseif ( TimeSince(ml_global_information.stanceTimer) >= 30000 ) then
				return true
			end
		end
    end
    
    return false
end

function e_stance:execute()
	local stanceList = ActionList("type=6")
	local stance = stanceList[ml_global_information.chocoStance[gChocoStance]]
    local acStance = ActionList:Get(stance.id,6)		
	acStance:Cast(Player.id)
	ml_global_information.stanceTimer = Now()
	ml_task_hub:ThisTask().preserveSubtasks = true
end

-----------------------------------------------------------------------------------------------
--SPRINT: If (distance to pos > ? or < ?) Then (mount or unmount)
---------------------------------------------------------------------------------------------
c_sprint = inheritsFrom( ml_cause )
e_sprint = inheritsFrom( ml_effect )
function c_sprint:evaluate()
    if (gBotMode == "PVP") then
        return false
    end

    if not HasBuff(Player.id, 50) and not Player.ismounted and Player:IsMoving() then
        local skills = ActionList("type=1")
        local skill = skills[3]
        if (skill.isready) then
            if ( ml_task_hub:CurrentTask().pos ~= nil and ml_task_hub:CurrentTask().pos ~= 0 and gUseSprint == "1") then
                local myPos = Player.pos
                local gotoPos = ml_task_hub:CurrentTask().pos
                local distance = Distance2D(myPos.x, myPos.z, gotoPos.x, gotoPos.z)
                
                if (distance > tonumber(gSprintDist)) then		
                    return true
                end
            end
        end
    end
    
    return false
end
function e_sprint:execute()
    ActionList:Get(3):Cast()
end

--minor abuse of the cne system here to update target pos
c_updatetarget = inheritsFrom( ml_cause )
e_updatetarget = inheritsFrom( ml_effect )
function c_updatetarget:evaluate()	
    if (ml_task_hub:ThisTask().targetid~=nil and ml_task_hub:ThisTask().targetid~=0)then
        local target = EntityList:Get(ml_task_hub.ThisTask().targetid)
        if (target ~= nil) then
            if (target.alive and target.attackable) then
                if (ml_task_hub:CurrentTask().name == "MOVETOPOS" ) then
					e_updatetarget.pos = target.pos				
                end
				return false
            end
        end
    end	
end
function e_updatetarget:execute()
end

c_attarget = inheritsFrom( ml_cause )
e_attarget = inheritsFrom( ml_effect )
function c_attarget:evaluate()
    if (ml_task_hub:CurrentTask().name == "MOVETOPOS") then
        if ml_global_information.AttackRange > 20 then
            local target = EntityList:Get(ml_task_hub:ThisTask().targetid)
            if ValidTable(target) then
                local rangePercent = tonumber(gCombatRangePercent) * 0.01
                return InCombatRange(ml_task_hub:ThisTask().targetid) and target.distance2d < (ml_global_information.AttackRange * rangePercent)
            end
        else
            return InCombatRange(ml_task_hub:ThisTask().targetid)
        end
    end
    return false
end
function e_attarget:execute()
    Player:Stop()
    ml_task_hub:CurrentTask():task_complete_execute()
    ml_task_hub:CurrentTask():Terminate()
end

---------------------------------------------------------------------------------------------
--REACTIVE/IMMEDIATE Game State CNEs
--These are cnes which are used to check the current game state and perform some kind of
--emergency action. They should generally be placed in the overwatch element list at an
--appropriate level in the subtask tree so that they can monitor all subtasks below them
---------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------
--NOTARGET: If (no current target) Then (find the nearest fate mob)
--Gets a new target using the targeting function of the parent task
---------------------------------------------------------------------------------------------
c_notarget = inheritsFrom( ml_cause )
e_notarget = inheritsFrom( ml_effect )
function c_notarget:evaluate()
    
    if ( ml_task_hub:CurrentTask().targetFunction() ~= nil ) then
        if ( ml_task_hub:CurrentTask().targetid == nil or ml_task_hub:CurrentTask().targetid == 0 ) then
            return true
        end
        
        local target = EntityList:Get(ml_task_hub:CurrentTask().targetid)
        if (target ~= nil) then
            if (not target.alive or not target.targetable) then
                return true
            end
        elseif (target == nil) then
            return true
        end
    end    
    return false
end
function e_notarget:execute()
    ml_debug( "Getting new target" )
    local target = ml_task_hub:CurrentTask().targetFunction()
    if (target ~= nil and target ~= 0) then
        Player:SetFacing(target.pos.x, target.pos.y, target.pos.z)
        ml_task_hub:CurrentTask().targetid = target.id
    end
end

---------------------------------------------------------------------------------------------
--MOBAGGRO: If (detect new aggro) Then (kill mob)
--
---------------------------------------------------------------------------------------------
c_mobaggro = inheritsFrom( ml_cause )
e_mobaggro = inheritsFrom( ml_effect )
function c_mobaggro:evaluate()
    if ( Player.hasaggro ) then
        local target = GetNearestAggro()
        if (target ~= nil and target ~= 0) then
            e_mobaggro.targetid = target.id
            return true
        end
    end
    
    return false
end
function e_mobaggro:execute()
    ml_debug( "Getting new target" )
    local target = GetNearestAggro()
    if (target ~= nil) then
        local newTask = ffxiv_task_killtarget.Create()
        newTask.targetFunction = ml_task_hub:CurrentTask().targetFunction
        newTask.targetid = e_mobaggro.targetid
        ml_task_hub.Add(newTask, QUEUE_REACTIVE, TP_IMMEDIATE)
    end
end

---------------------------------------------------------------------------------------------
--REST: If (not player.hasAggro and player.hp.percent < 50) Then (do nothing)
--Blocks all subtask execution until player hp has increased
---------------------------------------------------------------------------------------------
c_rest = inheritsFrom( ml_cause )
e_rest = inheritsFrom( ml_effect )
function c_rest:evaluate()
	if (ml_task_hub:CurrentTask().name == "LT_REST") then
		return false
	end
	
	--[[
	local target = Player:GetTarget()
	if (not target and 
		ml_task_hub:CurrentTask().name ~= "LT_KILLTARGET" and 
		ml_task_hub:ThisTask().name ~= "QUEST_KILL" and 
		ml_task_hub:ThisTask().name ~= "LT_QUEST" and
		ml_task_hub:ThisTask().name ~= "QUEST_INTERACT") 
	then
		local el = EntityList("attackable,aggressive,notincombat,maxdistance=40,minlevel="..tostring(Player.level - 10))
		if (TableSize(el) == 0) then
			return false
		end
	end
	--]]
	
    -- don't rest if we have rest in fates disabled and we're in a fate or FatesOnly is enabled
    if (gRestInFates == "0") then
        if  (ml_task_hub:ThisTask().name == "LT_GRIND" and ml_task_hub:ThisTask().subtask and ml_task_hub:ThisTask().subtask.name == "LT_FATE") or (gFatesOnly == "1") then
            return false
        end
    end
	
	if (((Player.hp.percent == 100 or tonumber(gRestHP) == 0) and (Player.mp.percent == 100 or tonumber(gRestMP) == 0)) or
		Player.hasaggro or Player.incombat ) then
		return false
	end
	
	if (( tonumber(gRestHP) > 0 and Player.hp.percent < tonumber(gRestHP)) or
		( tonumber(gRestMP) > 0 and Player.mp.percent < tonumber(gRestMP)))
	then
		return true
	end
    
    return false
end
function e_rest:execute()
	Player:Stop()
	local newTask = ffxiv_task_rest.Create()
	ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
	d("Entering a resting state due to low hp/mp.")
end

---------------------------------------------------------------------------------------------
--FLEE: If (aggolist.size > 0 and health.percent < 50) Then (run to a random point)
--Attempts to shake aggro by running away and resting
---------------------------------------------------------------------------------------------
c_flee = inheritsFrom( ml_cause )
e_flee = inheritsFrom( ml_effect )
e_flee.fleePos = {}
function c_flee:evaluate()
	if (ml_task_hub:CurrentTask().name == "LT_FLEE") then
		return false
	end
	
	if ((Player.incombat or Player.hasaggro) and (Player.hp.percent < tonumber(gFleeHP) or Player.mp.percent < tonumber(gFleeMP))) then
		if (ValidTable(ml_marker_mgr.markerList["evacPoint"])) then
			local fpos = ml_marker_mgr.markerList["evacPoint"]
			local ppos = Player.pos
			if (Distance3D(ppos.x, ppos.y, ppos.z, fpos.x, fpos.y, fpos.z) > 50) then
				e_flee.fleePos = fpos
				return true
			end
		end
		
		local ppos = Player.pos
		local newPos = NavigationManager:GetRandomPointOnCircle(ppos.x,ppos.y,ppos.z,100,200)
		if (ValidTable(newPos)) then
			e_flee.fleePos = newPos
			return true
		end
	end
    
    return false
end
function e_flee:execute()
	local fleePos = e_flee.fleePos
	if (ValidTable(fleePos)) then
		local newTask = ffxiv_task_flee.Create()
		newTask.pos = fleePos
		newTask.useTeleport = (gTeleport == "1")
		newTask.task_complete_eval = 
			function ()
				return not Player.incombat or (Player.hp.percent > tonumber(gFleeHP) and Player.mp.percent > tonumber(gFleeMP))
			end
		newTask.task_fail_eval = 
			function ()
				return not Player.alive or ((not c_walktopos:evaluate() or Player:IsMoving()) and Player.incombat)
			end
		ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
	else
		ml_error("Need to flee but no evac position defined for this mesh!!")
	end
end

---------------------------------------------------------------------------------------------
--DEAD: Checks Revivestate of player and revives at nearest aetheryte, homepoint, favpoint or we shall see 
--Blocks all subtask execution until player is alive 
---------------------------------------------------------------------------------------------
c_dead = inheritsFrom( ml_cause )
e_dead = inheritsFrom( ml_effect )
c_dead.timer = 0
function c_dead:evaluate()
    if (Player.revivestate == 2 or Player.revivestate == 3) then --FFXIV.REVIVESTATE.DEAD & REVIVING
		if (gBotMode == GetString("grindMode") or gBotMode == GetString("partyMode")) then
			if (c_dead.timer == 0) then
				c_dead.timer = Now() + 30000
				return false
			end
			if (Now() > c_dead.timer or HasBuffs(Player, "148")) then
				ffxiv_task_grind.inFate = false
				return true
			end
		else
			return true
		end
    end 
    return false
end
function e_dead:execute()
    d("Respawning...")
	-- try raise first
    if(PressYesNo(true)) then
		c_dead.timer = 0
		return
    end
	-- press ok
    if(PressOK()) then
		c_dead.timer = 0
		return
    end
end

c_pressconfirm = inheritsFrom( ml_cause )
e_pressconfirm = inheritsFrom( ml_effect )
function c_pressconfirm:evaluate()
	if (gBotMode == strings[gCurrentLanguage].assistMode) then
		return (gConfirmDuty == "1" and ControlVisible("ContentsFinderConfirm") and not IsLoading())
	end
	
    return (ControlVisible("ContentsFinderConfirm") and not IsLoading() and Player.revivestate ~= 2 and Player.revivestate ~= 3)
end
function e_pressconfirm:execute()
	PressDutyConfirm(true)
	if (gBotMode == strings[gCurrentLanguage].pvpMode) then
		ml_task_hub:ThisTask().state = "DUTY_STARTED"
	elseif (gBotMode == strings[gCurrentLanguage].dutyMode and IsDutyLeader()) then
		ml_task_hub:ThisTask().state = "DUTY_ENTER"
	end
end

-- more to refactor here later most likely
c_returntomarker = inheritsFrom( ml_cause )
e_returntomarker = inheritsFrom( ml_effect )
function c_returntomarker:evaluate()
    if (gBotMode == strings[gCurrentLanguage].partyMode and not IsLeader() ) then
        return false
    end
	
	-- never switch to a new marker when the gatherableitemselect window is up, happens in some rare occasions
	if gBotMode == strings[gCurrentLanguage].gatherMode then
        local list = Player:GetGatherableSlotList()
        if (list ~= nil) then
            return false
        end
    end
    
	-- right now when randomize markers is active, it first walks to the marker and then checks for levelrange, this should probably get changed, but 
	-- making this will most likely break the behavior on some badly made meshes 
    if (ml_task_hub:CurrentTask().currentMarker ~= false and ml_task_hub:CurrentTask().currentMarker ~= nil) then
	
		local markerType = ml_task_hub:CurrentTask().currentMarker:GetType()
		if (markerType == GetString("unspoiledMarker")) then
			return false
		end
	
        local myPos = Player.pos
        local pos = ml_task_hub:CurrentTask().currentMarker:GetPosition()
        local distance = Distance2D(myPos.x, myPos.z, pos.x, pos.z)
		
		if (gBotMode == strings[gCurrentLanguage].grindMode or gBotMode == strings[gCurrentLanguage].partyMode) then
			local target = ml_task_hub:CurrentTask().targetFunction()
			if (distance > 200 or target == nil) then
				return true
			end
		end
		
		if (gBotMode == strings[gCurrentLanguage].pvpMode) then
			if (ml_task_hub:ThisTask().state ~= "COMBAT_STARTED" or Player.localmapid ~= 376) then
				local nearestTarget = GetPVPTarget()
				if (nearestTarget) then
					return false
				end
				if (distance > 25) then
					return true
				end
			else
				return false
			end
		end	
		
		if (gBotMode == strings[gCurrentLanguage].huntMode) then
			if (distance > 15) then
				return true
			end
		end		
		
        if  (gBotMode == strings[gCurrentLanguage].gatherMode and ml_task_hub:CurrentTask().maxGatherDistance and distance > ml_task_hub:CurrentTask().maxGatherDistance) or
			(gBotMode == strings[gCurrentLanguage].fishMode and distance > 3)
        then
            return true
        end
    end
    
    return false
end
function e_returntomarker:execute()
	if (gBotMode == GetString("fishMode")) then
		local fs = tonumber(Player:GetFishingState())
		if (fs ~= 0) then
			local finishcast = ActionList:Get(299,1)
			if (finishcast and finishcast.isready) then
				finishcast:Cast()
			end
			return
		end
	end
	
    local newTask = ffxiv_task_movetopos.Create()
    local markerPos = ml_task_hub:CurrentTask().currentMarker:GetPosition()
    local markerType = ml_task_hub:CurrentTask().currentMarker:GetType()
    newTask.pos = markerPos
    newTask.range = math.random(5,25)
	if (markerType == GetString("huntMarker")) then
		newTask.remainMounted = true
	end
    if (markerType == GetString("fishingMarker")) then
        newTask.pos.h = markerPos.h
        newTask.range = 0.5
        newTask.doFacing = true
    end
    ml_task_hub:CurrentTask():AddSubTask(newTask)
end

---------------------------------------------------------------------------------------------
--STEALTH: If (distance to aggro < 18) Then (cast stealth)
--Uses stealth when gathering to avoid aggro
---------------------------------------------------------------------------------------------
c_stealth = inheritsFrom( ml_cause )
e_stealth = inheritsFrom( ml_effect )
function c_stealth:evaluate()	
	local marker = ml_task_hub:RootTask().currentMarker
	if (not marker) then
		return false
	end
	
	if (ml_task_hub:CurrentTask().name == "LT_STEALTH") then
		return false
	end
	
	local list = Player:GetGatherableSlotList()
	local fs = tonumber(Player:GetFishingState())
	if (ValidTable(list) or fs ~= 0) then
		return false
	end
	
	local useStealth = marker:GetFieldValue(strings[gCurrentLanguage].useStealth) == "1" and true or false
    if  (not useStealth) then
		if (HasBuff(Player.id, 47)) then
			return true
		else
			return false
		end
    end
	
    local action = nil
    if (Player.job == FFXIV.JOBS.BOTANIST) then
        action = ActionList:Get(212)
    elseif (Player.job == FFXIV.JOBS.MINER) then
        action = ActionList:Get(229)
    elseif (Player.job == FFXIV.JOBS.FISHER) then
        action = ActionList:Get(298)
    end
    
    if (action and not action.isoncd) then
		if (gBotMode == GetString("gatherMode")) then
			if ( ml_task_hub:ThisTask().gatherid ~= nil and ml_task_hub:ThisTask().gatherid ~= 0 ) then
				local gatherable = EntityList:Get(ml_task_hub:ThisTask().gatherid)
				if (gatherable and (gatherable.distance < 15)) then
					if (not HasBuff(Player.id, 47)) then
						return true
					else
						return false
					end
				end
			end
		elseif (gBotMode == GetString("fishMode")) then
			local destPos = ml_task_hub:ThisTask().currentMarker:GetPosition()
			local myPos = Player.pos
			local distance = Distance3D(myPos.x, myPos.y, myPos.z, destPos.x, destPos.y, destPos.z)
			if (distance <= 5) then
				if (not HasBuff(Player.id, 47)) then
					return true
				else
					return false
				end
			end
		end
			
		local addMobList = EntityList("attackable,aggressive,minlevel="..tostring(Player.level - 10)..",maxdistance=20")
		local removeMobList = EntityList("attackable,aggressive,minlevel="..tostring(Player.level - 10)..",maxdistance=25")
		
		if(TableSize(addMobList) > 0 and not HasBuff(Player.id, 47)) or
		  (TableSize(removeMobList) == 0 and HasBuff(Player.id, 47)) 
		then
			return true
		end	
    end
 
    return false
end
function e_stealth:execute()
	local newTask = ffxiv_task_stealth.Create()
	if (HasBuffs(Player,"47")) then
		newTask.droppingStealth = true
	else
		newTask.addingStealth = true
	end
	ml_task_hub:ThisTask().preserveSubtasks = true
	ml_task_hub:CurrentTask():AddSubTask(newTask)
end

c_acceptquest = inheritsFrom( ml_cause )
e_acceptquest = inheritsFrom( ml_effect )
function c_acceptquest:evaluate()
	if (gBotMode == GetString("assistMode") and gQuestHelpers == "0") then
		return false
	end
	return Quest:IsQuestAcceptDialogOpen()
end
function e_acceptquest:execute()
	Quest:AcceptQuest()
end

c_handoverquest = inheritsFrom( ml_cause )
e_handoverquest = inheritsFrom( ml_effect )
function c_handoverquest:evaluate()
	if (gBotMode == GetString("assistMode") and gQuestHelpers == "0") then
		return false
	end
	return Quest:IsRequestDialogOpen()
end
function e_handoverquest:execute()
	local inv = Inventory("type=2004")

	for id, item in pairs(inv) do 
		item:HandOver() 
	end			
	Quest:RequestHandOver()
end

c_completequest = inheritsFrom( ml_cause )
e_completequest = inheritsFrom( ml_effect )
function c_completequest:evaluate()
	if (gBotMode == GetString("assistMode") and gQuestHelpers == "0") then
		return false
	end
	return Quest:IsQuestRewardDialogOpen()
end
function e_completequest:execute()
	Quest:CompleteQuestReward(1)
end

c_teleporttopos = inheritsFrom( ml_cause )
e_teleporttopos = inheritsFrom( ml_effect )
c_teleporttopos.pos = 0
function c_teleporttopos:evaluate()
    if ( ml_task_hub:CurrentTask().pos ~= nil and ml_task_hub:CurrentTask().pos ~= 0 ) then
        if (ActionList:IsCasting()) then
            return false
        end
		
		if (not ml_task_hub:CurrentTask().useTeleport) then
			return false
		end
		
        local myPos = Player.pos
        local gotoPos = ml_task_hub:CurrentTask().pos
		
        -- have to allow for 3d distance check because some quests have objectives on floors directly above one another  
		local distance = 0.0
		if(ml_task_hub:CurrentTask().use3d) then
			distance = Distance3D(myPos.x, myPos.y, myPos.z, gotoPos.x, gotoPos.y, gotoPos.z)
		else
			distance = Distance2D(myPos.x, myPos.z, gotoPos.x, gotoPos.z)
		end
        
        if (distance > 20) then
            c_teleporttopos.pos = gotoPos
			c_teleporttopos.distance = distance
            return true
        end
    end
    return false
end
function e_teleporttopos:execute()
    if ( c_teleporttopos.pos ~= 0) then
        local gotoPos = c_teleporttopos.pos
		Player:Stop()
		
		--if(gShortTeleport == "1") then
		--	if(c_teleporttopos.distance and c_teleporttopos.distance > 50) then
		--		Player:SetFacing(gotoPos.x, gotoPos.y, gotoPos.z)
		--		local myPos = Player.pos
		--		local newPos = GetPosFromDistanceHeading(myPos, 50, myPos.h)
		--		if(ValidTable(newPos)) then
		--			gotoPos = newPos
		--		end
		--	end
		--end
			
        GameHacks:TeleportToXYZ(tonumber(gotoPos.x),tonumber(gotoPos.y),tonumber(gotoPos.z))
		Player:SetFacingSynced(math.random())
		ml_task_hub:CurrentTask():SetDelay(1500)
		--d(tostring(PathSize))
    else
        ml_error(" Critical error in e_walktopos, c_walktopos.pos == 0!!")
    end
    c_teleporttopos.pos = 0
end

c_autoequip = inheritsFrom( ml_cause )
e_autoequip = inheritsFrom( ml_effect )
function c_autoequip:evaluate()
	if (gQuestAutoEquip == "0" or ControlVisible("Shop")) then
		return false
	end
	
	if (ValidTable(e_autoequip.equipIDs)) then
		return true
	end

	local equipSlots = 
	{
		[FFXIV.INVENTORYTYPE.INV_ARMORY_OFFHAND] = 1,
		[FFXIV.INVENTORYTYPE.INV_ARMORY_HEAD] = 2,
		[FFXIV.INVENTORYTYPE.INV_ARMORY_BODY] = 3,
		[FFXIV.INVENTORYTYPE.INV_ARMORY_HANDS] = 4,
		[FFXIV.INVENTORYTYPE.INV_ARMORY_WAIST] = 5,
		[FFXIV.INVENTORYTYPE.INV_ARMORY_LEGS] = 6,
		[FFXIV.INVENTORYTYPE.INV_ARMORY_FEET] = 7,
		[FFXIV.INVENTORYTYPE.INV_ARMORY_NECK] = 8,
		[FFXIV.INVENTORYTYPE.INV_ARMORY_EARS] = 9,
		[FFXIV.INVENTORYTYPE.INV_ARMORY_WRIST] = 10,
		[FFXIV.INVENTORYTYPE.INV_ARMORY_RINGS] = 11,
		[FFXIV.INVENTORYTYPE.INV_ARMORY_SOULCRYSTAL] = 12,
		[FFXIV.INVENTORYTYPE.INV_ARMORY_MAINHAND] = 0
	}
	
	local equipIDs = {}
	
	for key, slot in pairs(equipSlots) do
		local bestItem = nil
		local armoryItemList = Inventory("type="..tostring(key))
		if(ValidTable(armoryItemList)) then
			local currItemList = Inventory("type=1000")
			local currItem = nil
			for id, item in pairs(currItemList) do
				if(item.slot == slot) then
					currItem = item
					break
				end
			end
			
			for id, item in pairs(armoryItemList) do

				if(	currItem == nil or item.level > currItem.level and item.class == currItem.class) and
				  ( bestItem == nil or item.level > bestItem.level ) and
				  (	Player.level >= item.requiredlevel ) and
				  ( item.canequip )
				then
					bestItem = item
				end
			end
			
			if(ValidTable(bestItem)) then
				equipIDs[bestItem.id] = bestItem
			end
		end
	end
	
	if (TableSize(equipIDs) > 0) then
		e_autoequip.equipIDs = equipIDs
		return true
	end
	
	return false
end
function e_autoequip:execute()
	local id, item = next(e_autoequip.equipIDs)
	if(id) then
		EquipItem(id)
		e_autoequip.equipIDs[id] = nil
	else
		e_autoequip.equipIDs = nil
	end
end

c_equip = inheritsFrom( ml_cause )
e_equip = inheritsFrom( ml_effect )
function c_equip:evaluate()
	if(ActionList:IsCasting() or Player.incombat) then
		return false
	end

	if(ValidTable(e_equip.itemids)) then
		return true
	end

	local itemIDsToEquip = {}
	if(gBotMode == GetString("questMode") and gProfile ~= "") then
		local profileTable = ml_global_information.itemIDsToEquip[gProfile]
		if(ValidTable(profileTable)) then
			itemIDsToEquip = profileTable[Player.job]
		end
	end
	
	local itemids = {}
	if(ValidTable(itemIDsToEquip)) then
		for id,data in pairs(itemIDsToEquip) do
			local item = Inventory:Get(id)
			if(ValidTable(item) and item.canequip) then
				--transfer the id to the temp list for equipping and remove from the global list
				itemids[id] = data
				itemIDsToEquip[id] = nil
			end
		end
	end
	
	if(TableSize(itemids) > 0) then
		e_equip.itemids = itemids
		
		--write out changes to item equip table for settings
		ml_global_information.itemIDsToEquip = itemIDsToEquip
		Settings.FFXIVMINION.itemIDsToEquip = Settings.FFXIVMINION.itemIDsToEquip
		return true
	end
	
	return false
end
function e_equip:execute()
	local id, data = next(e_equip.itemids)
	if (id) then
		local newItem = Inventory:Get(id)
		if(ValidTable(newItem)) then
			--grab the current item in that slot
			if(newItem.type == FFXIV.INVENTORYTYPE.INV_EQUIPPED) then
				e_equip.itemids[id] = nil
				ffxiv_task_quest.ignoreLevelItemIDs[id] = nil
			else
				local currItem = nil
				if (ValidTable(data)) then
					currItem = GetItemInSlot(data.type)
				else
					currItem = GetItemInSlot(GetEquipSlotForItem(newItem))
				end
				
				local ignoreLevel = ffxiv_task_quest.ignoreLevelItemIDs[id]
				if(not currItem or (currItem and ((currItem.level <= newItem.level) or ignoreLevel))) then
					EquipItem(id, data.type)
					ml_task_hub:CurrentTask():SetDelay(500)
				else
					e_equip.itemids[id] = nil
					ffxiv_task_quest.ignoreLevelItemIDs[id] = nil
				end
			end
		end
	end
end

c_selectconvindex = inheritsFrom( ml_cause )
e_selectconvindex = inheritsFrom( ml_effect )
function c_selectconvindex:evaluate()	
	--check for vendor window open
	local index = ml_task_hub:CurrentTask().conversationIndex
	return index and index ~= 0 and (ControlVisible("SelectIconString") or ControlVisible("SelectString"))
end
function e_selectconvindex:execute()
	SelectConversationIndex(tonumber(ml_task_hub:CurrentTask().conversationIndex))
	ml_task_hub:CurrentTask():SetDelay(1500)
end
