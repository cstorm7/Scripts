if myHero.charName ~= "Riven" then return end
function OnLoad()
	LoadMenu()
	LoadVariables()
	LoadSkillRanges()
	LoadVIPPrediction()
	LoadMinions()
	LoadSummonerSpells()
	LoadEnemies()
end
function OnUnload()
	PrintFloatText(myHero,2,"Riven WomboCombo UnLoaded!")
end
function LoadMenu()
	Config = scriptConfig("Riven WomboCombo", "Riven WomboCombo")
	Config:addParam("teamFight", "TeamFight (SpaceBar)", SCRIPT_PARAM_ONKEYDOWN, false, 32)
	Config:addParam("farm", "Farm (Z)", SCRIPT_PARAM_ONKEYTOGGLE, false, 90)
	Config:addParam("DrawCircles", "Draw Circles", SCRIPT_PARAM_ONOFF, true)
	Config:addParam("DrawArrow", "Draw Arrow", SCRIPT_PARAM_ONOFF, true)
	Config:addParam("useUlt", "Use Ult (U)", SCRIPT_PARAM_ONKEYTOGGLE, true, 85)
	Config:addParam("moveToMouse", "Move To Mouse", SCRIPT_PARAM_ONOFF, true)
	Config:addParam("spamQFarm", "Spam Q Whilst Farming", SCRIPT_PARAM_ONOFF, true)
	Config:addParam("creeps", "Creeps (J)", SCRIPT_PARAM_ONKEYDOWN, false, 74)
	Config:addParam("escgap", "Escape or Gap Closer (X)", SCRIPT_PARAM_ONKEYDOWN, false, 88)
	Config:addParam("KsQ", "Ks Q", SCRIPT_PARAM_ONOFF, true)
	Config:addParam("KsW", "Ks W", SCRIPT_PARAM_ONOFF, true)
	Config:addParam("KsR", "Ks R", SCRIPT_PARAM_ONOFF, true)
	Config:permaShow("useUlt")
	Config:permaShow("escgap")
	Config:permaShow("teamFight")
	Config:permaShow("farm")
	PrintFloatText(myHero,2,"Riven WomboCombo Loaded!")
end
function LoadVariables()
	ignite = nil
	enemyHeros = {}
	enemyHerosCount = 0
	NextShot = 0
	aaTime = 0
	minionRange = false
	tick = 0
	igniteTick = 0
	ksDamages = {}
	newTarget = nil
	usingQ = false
	qStacks = 0
	passiveActive = false
	qTick = 0
	windSlashReady = false
end
function LoadSkillRanges()
	rangeQ = 375
	rangeW = 260
	rangeE = 325
	rangeR = 1075
	killRange = 1075
end
function LoadVIPPrediction()
	tpR = TargetPredictionVIP(rangeR, 1450, 0.3)
end
function LoadMinions()
	enemyMinion = minionManager(MINION_ENEMY, rangeQ, player, MINION_SORT_HEALTH_ASC)
	jungleMinion = minionManager(MINION_JUNGLE, rangeQ, player, MINION_SORT_HEALTH_ASC)
end
function LoadSummonerSpells()
	if myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") then 
		ignite = SUMMONER_1
	elseif myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") then
		ignite = SUMMONER_2
	else 
		ignite = nil
  	end
end
function LoadEnemies()
	for i = 1, heroManager.iCount do
		local hero = heroManager:GetHero(i)
		if hero.team ~= player.team then
			local enemyCount = enemyHerosCount + 1
			enemyHeros[enemyCount] = {object = hero, waittxt = 0, killable = 0 }
			enemyHerosCount = enemyCount
		end
	end
end
function OnTick()
	if not myHero.dead then
		QREADY = (myHero:CanUseSpell(_Q) == READY)
		WREADY = (myHero:CanUseSpell(_W) == READY)
		EREADY = (myHero:CanUseSpell(_E) == READY)
		RREADY = (myHero:CanUseSpell(_R) == READY)
		IREADY = (ignite ~= nil and myHero:CanUseSpell(ignite) == READY)
		checkKillRange()
		execute()
		orbWalk()
		jungleFarm()
		if Config.farm and not Config.teamFight and not Config.escgap then
			farmKey()
		end
		if Config.escgap then
			escgapKey()
		end
	end
end
function checkKillRange()
	rangeQ = 375
	if QREADY and not usingQ then qStacks = 3 end
	if EREADY then
		if qStacks == 3 then
			rangeQ = rangeQ*3
			killRange = rangeQ + rangeE
		elseif RREADY then
			killRange = rangeR + rangeE
		elseif qStacks == 2 then
			rangeQ = rangeQ*2
			killRange = rangeQ + rangeE
		elseif qStacks == 1 then
			rangeQ = rangeQ
			killRange = rangeQ + rangeE
		elseif WREADY then
			killRange = rangeW + rangeE
		else
			killRange = rangeE
		end
	elseif qStacks == 3 then
		rangeQ = rangeQ*3
		killRange = rangeQ
	elseif RREADY then
		killRange = rangeR
	elseif qStacks == 2 then
		rangeQ = rangeQ*2
		killRange = rangeQ
	elseif qStacks == 1 then
		rangeQ = rangeQ
		killRange = rangeQ
	elseif WREADY then
		killRange = rangeW
	end
end
function Target()
	local currentTarget = nil
	local killMana = 0
	if ValidTarget(newTarget) then
		if GetDistance(newTarget)>killRange then
			newTarget = nil
		end
	else
		newTarget = nil
	end
	for i = 1, enemyHerosCount do
		local Enemy = enemyHeros[i].object
		if ValidTarget(Enemy) then
			local pdmg = getDmg("P", Enemy, myHero, 3)
			local qdmg = getDmg("Q", Enemy, myHero, 1)
			local wdmg = getDmg("W", Enemy, myHero, 3)
			local edmg = getDmg("E", Enemy, myHero, 3)
			local rdmg = getDmg("R", Enemy, myHero, 3)
			local ADdmg = getDmg("AD", Enemy, myHero, 3)
			local dfgdamage = (GetInventoryItemIsCastable(3128) and getDmg("DFG",Enemy,myHero) or 0) -- Deathfire Grasp
			local hxgdamage = (GetInventoryItemIsCastable(3146) and getDmg("HXG",Enemy,myHero) or 0) -- Hextech Gunblade
			local bwcdamage = (GetInventoryItemIsCastable(3144) and getDmg("BWC",Enemy,myHero) or 0) -- Bilgewater Cutlass
			local botrkdamage = (GetInventoryItemIsCastable(3153) and getDmg("RUINEDKING", Enemy, myHero) or 0) --Blade of the Ruined King
			local onhitdmg = (GetInventoryHaveItem(3057) and getDmg("SHEEN",Enemy,myHero) or 0) + (GetInventoryHaveItem(3078) and getDmg("TRINITY",Enemy,myHero) or 0) + (GetInventoryHaveItem(3100) and getDmg("LICHBANE",Enemy,myHero) or 0) + (GetInventoryHaveItem(3025) and getDmg("ICEBORN",Enemy,myHero) or 0) + (GetInventoryHaveItem(3087) and getDmg("STATIKK",Enemy,myHero) or 0) + (GetInventoryHaveItem(3209) and getDmg("SPIRITLIZARD",Enemy,myHero) or 0)
			local onspelldamage = (GetInventoryHaveItem(3151) and getDmg("LIANDRYS",Enemy,myHero) or 0) + (GetInventoryHaveItem(3188) and getDmg("BLACKFIRE",Enemy,myHero) or 0)
			local sunfiredamage = (GetInventoryHaveItem(3068) and getDmg("SUNFIRE",Enemy,myHero) or 0)
			local comboKiller = pdmg + qdmg + wdmg + edmg + rdmg + onhitdmg + onspelldamage + sunfiredamage + hxgdamage + bwcdamage + botrkdamage
			local killHim = pdmg + onhitdmg + onspelldamage + sunfiredamage + hxgdamage + bwcdamage + botrkdamage
			if QREADY and not usingQ then qStacks = 3 end
			if qStacks == 3 then
				qdmg = qdmg*3
			elseif qStacks == 2 then
				qdmg = qdmg*2
			end
			if IREADY then
				local idmg = getDmg("IGNITE",Enemy,myHero, 3)
				comboKiller = comboKiller + idmg
				killHim = killHim + idmg
				if GetDistance(Enemy)< 600 then
					if idmg>=Enemy.health then
						CastSpell(ignite, Enemy)
					end
				end
			end
			if QREADY then	
				killMana = killMana + myHero:GetSpellData(_Q).mana
				if GetDistance(Enemy)<=rangeQ then
					killHim = killHim + qdmg
					if qdmg >=Enemy.health and not IsIgnited() and Config.KsQ then
						table.insert(ksDamages, qdmg)
					end
				end
			end
			if WREADY then
				killMana = killMana + myHero:GetSpellData(_W).mana	
				if GetDistance(Enemy)<=rangeW then
					killHim = killHim + wdmg
					if wdmg >=Enemy.health and not IsIgnited() and Config.KsW then
						table.insert(ksDamages, wdmg)
					end
				end
			end
			if RREADY then
				killMana = killMana + myHero:GetSpellData(_R).mana
				if GetDistance(Enemy)<=rangeR then
					killHim = killHim + rdmg
					if rdmg>=Enemy.health and not IsIgnited() and Config.useUlt and Config.KsR then
						table.insert(ksDamages, rdmg)
					end
				end
			end
			if next(ksDamages)~=nil then
				table.sort(ksDamages, function (a, b) return a<b end)
				local lowestKSDmg = ksDamages[1]
				if qdmg == lowestKSDmg then
					CastSpell(_Q, Enemy.x, Enemy.z)
				elseif wdmg == lowestKSDmg then
					CastW(Enemy)
				elseif rdmg == lowestKSDmg then
					CastR(Enemy)
				end
				table.clear(ksDamages)
			end
			if GetInventoryItemIsCastable(3128) then  -- DFG      
				comboKiller = comboKiller + dfgdamage + (comboKiller*0.2)
				killHim = killHim + dfgdamage + (killHim*0.2) 
				if GetInventoryItemIsCastable(3146) then -- Hxg
					comboKiller = comboKiller + (hxgdamage*0.2)
					killHim = killHim + (hxgdamage*0.2)
				end
				if GetInventoryItemIsCastable(3144) then -- bwc
					comboKiller = comboKiller + (bwcdamage*0.2)
					killHim = killHim + (bwcdamage*0.2)
				end
				if GetInventoryItemIsCastable(3153) then -- botrk
					comboKiller = comboKiller + (botrkdamage*0.2)
					killHim = killHim + (botrkdamage*0.2)
				end
			end
			currentTarget = Enemy
			if killHim >= currentTarget.health and killMana<= myHero.mana then
				enemyHeros[i].killable = 3
				if GetDistance(currentTarget) <= killRange then
					if newTarget == nil then
						newTarget = currentTarget
					elseif newTarget.health > killHim then
						newTarget = currentTarget
					else
						local currentTargetDmg = currentTarget.health - killHim
						local newTargetDmg = newTarget.health - killHim
						if currentTargetDmg < newTargetDmg then
							newTarget = currentTarget
						end
					end
					if ValidTarget(newTarget) then
						killTarget(newTarget)
					end
				end
			elseif comboKiller >= currentTarget.health then
				enemyHeros[i].killable = 2
				if GetDistance(currentTarget) <= killRange then
					if newTarget == nil then
						newTarget = currentTarget
					elseif newTarget.health > comboKiller then
						newTarget = currentTarget
					else
						local currentTargetDmg = currentTarget.health - comboKiller
						local newTargetDmg = newTarget.health - comboKiller
						if currentTargetDmg < newTargetDmg then
							newTarget = currentTarget
						end
					end
					if ValidTarget(newTarget) then
						comboTarget(newTarget)
					end
				end
			else
				enemyHeros[i].killable = 1
				if GetDistance(currentTarget) <= killRange then
					if newTarget == nil then
						newTarget = currentTarget
					elseif newTarget.health > comboKiller then
						local currentTargetDmg = currentTarget.health - comboKiller
						local newTargetDmg = newTarget.health - comboKiller
						if currentTargetDmg < newTargetDmg then
							newTarget = currentTarget
						end
					end
					if ValidTarget(newTarget) then
						harassTarget(newTarget)
					end
				end	
			end
		else
			killable = 0
		end
	end
end
function OnGainBuff (unit, buff)
	if unit.isMe and unit.valid then
		if buff.name == "RivenTriCleave" then
			qStacks = 2
			usingQ = true
		end
		if buff.name == "rivenpassiveaaboost" then
			passiveActive = true
		end
		if buff.name == "rivenwindslashready" then
			windSlashReady = true
		end
	end
end
function OnLoseBuff (unit, buff)
	if unit.isMe and unit.valid then
		if buff.name == "RivenTriCleave" then
			qStacks = 0
			usingQ = false
		end
		if buff.name == "rivenpassiveaaboost" then
			passiveActive = false
		end
		if buff.name == "rivenwindslashready" then
			windSlashReady = false
		end
	end
end
function OnUpdateBuff (unit, buff)
	if unit.isMe and unit.valid then
		if buff.name == "RivenTriCleave" then
			qStacks = 1
		end
	end
end
function execute()
	Target()
end
function IsIgnited(target)
	if TargetHaveBuff("SummonerDot", target) then
		igniteTick = GetTickCount()
		return true
	elseif igniteTick == nil or GetTickCount()-igniteTick>500 then
		return false
	end
end
function escgapKey()
	local QPos = mousePos
	local MPos = {x = QPos.x, y = QPos.y, z = QPos.z}
	local HeroPos = Vector(myHero.x, myHero.y, myHero.z)
	if GetDistance(QPos)>375 then
		local Pos = HeroPos +(HeroPos -MPos)*(-375/GetDistance(QPos))
		CastSpell(_Q, Pos.x, Pos.z)
		CastSpell(_E, Pos.x, Pos.z)
		qTick = GetTickCount()
		NextShot = 0
	else
		local Pos = HeroPos +(HeroPos -MPos)*(-20/GetDistance(QPos))
		CastSpell(_Q, Pos.x, Pos.z)
		CastSpell(_E, Pos.x, Pos.z)
		qTick = GetTickCount()
		NextShot = 0
	end
end
function farmKey()
	enemyMinion:update()
	if next(enemyMinion.objects)~= nil then
		for j, minion in pairs(enemyMinion.objects) do
			if minion.valid then
				local ADdmg = getDmg("AD", minion, myHero, 3)
				local Qdmg = 0
				if QREADY then
					Qdmg = getDmg("Q", minion, myHero, 1)
					if usingQ == false then
						qStacks = 3
					end
				end
				if qStacks == 3 then
					Qdmg = Qdmg*3
				elseif qStacks == 2 then
					Qdmg = Qdmg*2
				end
				if GetDistance(minion)<=myHero.range +65 and ADdmg>=minion.health then
					if GetTickCount() > NextShot then
						myHero:Attack(minion)
					end
				elseif GetDistance(minion)<=500 and Qdmg>=minion.health and qStacks>0 then
					CastSpell(_Q, minion.x, minion.z)
				elseif qStacks>0 and GetDistance(minion)<=375 and Config.spamQFarm then
					CastSpell(_Q, minion.x, minion.z)
				end
			end
		end
	end
end
function jungleFarm()
	if not ValidTarget(newTarget) then
		jungleMinion:update()
		if next(jungleMinion.objects)~= nil then
			for j, minion in pairs(jungleMinion.objects) do
				if minion.valid then
					if Config.creeps then
						local ADdmg = getDmg("AD", minion, myHero, 3)
						local Qdmg = 0
						if QREADY then
							Qdmg = getDmg("Q", minion, myHero, 1)
							if usingQ == false then
								qStacks = 3
							end
						end
						if qStacks == 3 then
							Qdmg = Qdmg*3
						elseif qStacks == 2 then
							Qdmg = Qdmg*2
						end
						if GetDistance(minion)<=myHero.range +65 and ADdmg>=minion.health then
							if GetTickCount() > NextShot then
								myHero:Attack(minion)
							end
						elseif GetDistance(minion)<=500 and Qdmg>=minion.health and qStacks>0 then
							CastSpell(_Q, minion.x, minion.z)
						elseif qStacks>0 and GetDistance(minion)<=375 and Config.spamQFarm then
							CastSpell(_Q, minion.x, minion.z)
						end
					end
				end
			end
		end
	else
		return
	end
end
function killTarget(target)
	if ValidTarget(target) and not IsIgnited() then
		if Config.teamFight then
			CastItems(target, true)
			CastQ(target)
			CastW(target)
			CastE(target)
			CastR(target)
		end
	end
end
function comboTarget(target)
	if ValidTarget(target) then
		if Config.teamFight then
			CastItems(target, true)
			CastQ(target)
			CastW(target)
			CastE(target)
			if windSlashReady == false then
				CastR(target)
			end
		end
	end
end
function harassTarget(target)
	if ValidTarget(target) then
		if Config.teamFight then
			CastItems(target)
			CastQ(target)
			CastW(target)
			CastE(target)
			if windSlashReady == false then
				CastR(target)
			end
		end
	end
end
function CastQ(target)
	if qStacks == 0 then return end
	if ValidTarget(target) and not EREADY then
		if GetDistance(target) <= rangeQ and passiveActive == false then
			local QPos = target
			if ValidTarget(QPos) then
				local EnemyPos = {x = QPos.x, y = QPos.y, z = QPos.z}
				local HeroPos = Vector(myHero.x, myHero.y, myHero.z)
				if GetDistance(target)>375 then
					local Pos = HeroPos +(HeroPos -EnemyPos)*(-375/GetDistance(QPos))
					CastSpell(_Q, Pos.x, Pos.z)
					qTick = GetTickCount()
					NextShot = 0
				else
					local Pos = HeroPos +(HeroPos -EnemyPos)*(-20/GetDistance(QPos))
					CastSpell(_Q, Pos.x, Pos.z)
					qTick = GetTickCount()
					NextShot = 0
				end
			end
		elseif GetTickCount()-qTick>=1000 and passiveActive == true then
			local QPos = target
			if ValidTarget(QPos) then
				local EnemyPos = {x = QPos.x, y = QPos.y, z = QPos.z}
				local HeroPos = Vector(myHero.x, myHero.y, myHero.z)
				if GetDistance(target)>375 then
					local Pos = HeroPos +(HeroPos -EnemyPos)*(-375/GetDistance(QPos))
					CastSpell(_Q, Pos.x, Pos.z)
					qTick = GetTickCount()
					NextShot = 0
				else
					local Pos = HeroPos +(HeroPos -EnemyPos)*(-20/GetDistance(QPos))
					CastSpell(_Q, Pos.x, Pos.z)
					qTick = GetTickCount()
					NextShot = 0
				end
			end
		end
	else
		return
	end
end
function CastW(target)
	if not WREADY then return end
	if ValidTarget(target) and not EREADY then
		if GetDistance(target) <= rangeW and WREADY then
			CastSpell(_W)
			NextShot = 0
		end
	else
		return
	end
end
function CastE(target)
	if not EREADY then return end
	if ValidTarget(target) then
		if GetDistance(target) <= killRange and EREADY then
			local EPos = target
			if ValidTarget(EPos) then
				local EnemyPos = {x = EPos.x, y = EPos.y, z = EPos.z}
				local HeroPos = Vector(myHero.x, myHero.y, myHero.z)
				local Pos = HeroPos +(HeroPos -EnemyPos)*(-rangeE/GetDistance(EPos))
				CastSpell(_E, Pos.x, Pos.z)
			end
		end
	else
		return
	end
end
function CastR(target)
	if not RREADY then return end
	if ValidTarget(target) and not EREADY and Config.useUlt then
		if GetDistance(target) <= killRange and RREADY and not windSlashReady then
			CastSpell(_R)
		elseif windSlashReady then
			if GetDistance(target) <= rangeR then
				local RPos = tpR:GetPrediction(target)
				if RPos and GetDistance(RPos)<=rangeR then
					CastSpell(_R, RPos.x, RPos.z)
				end
			end
		end
	else
		return
	end
end
function CastItems(target, allItems)
	if not ValidTarget(target) then 
		return
	else
		if GetDistance(target) <=800 and allItems == true then
			CastItem(3144, target) --Bilgewater Cutlass
			CastItem(3153, target) --Blade Of The Ruin King
			CastItem(3128, target) --Deathfire Grasp
			CastItem(3146, target) --Hextech Gunblade
			CastItem(3188, target) --Blackfire Torch  
		end
		if GetDistance(target) <= 275 then
			CastItem(3184, target) --Entropy
			CastItem(3143, target) --Randuin's Omen
			CastItem(3074, target) --Ravenous Hydra
			CastItem(3131, target) --Sword of the Devine
			CastItem(3077, target) --Tiamat
			CastItem(3142, target) --Youmuu's Ghostblade
		end
		if GetDistance(target) <= 1000 then
			CastItem(3023, target) --Twin Shadows
		end
	end
end
function orbWalk()		
	if GetTickCount() > NextShot then
		if ValidTarget(newTarget) then
			if GetDistance(newTarget)<=myHero.range +65 and Config.teamFight then
				myHero:Attack(newTarget)
			else
				if (Config.teamFight or Config.escgap) and Config.moveToMouse then
					local pos = {x = mousePos.x, y = mousePos.y, z = mousePos.z}
					local HeroPos = Vector(myHero.x, myHero.y, myHero.z)
					if GetDistance(mousePos)>175 then
						local movePos = HeroPos +(HeroPos -pos)*(-175/GetDistance(mousePos))
						myHero:MoveTo(movePos.x, movePos.z)
					else
						myHero:MoveTo(mousePos.x, mousePos.z)
					end
				end
			end
		elseif not ValidTarget(newTarget) then
			minionRange = false
			enemyMinion:update()
			jungleMinion:update()
			for i, minion in pairs(enemyMinion.objects) do
				if minion.valid then
					if GetDistance(minion)<=myHero.range+65 and Config.creeps then
						myHero:Attack(minion)
						minionRange = true
					else
						minionRange = false
					end
				end
			end
			for j, minion in pairs(jungleMinion.objects) do
				if minion.valid then
					if GetDistance(minion)<=myHero.range+65 and Config.creeps then
						myHero:Attack(minion)
						minionRange = true
					else
						minionRange = false
					end
				end
			end
		end
		if not minionRange and not ValidTarget(newTarget) and Config.moveToMouse then
			if Config.teamFight or Config.escgap then
				local pos = {x = mousePos.x, y = mousePos.y, z = mousePos.z}
				local HeroPos = Vector(myHero.x, myHero.y, myHero.z)
				if GetDistance(mousePos)>175 then
					local movePos = HeroPos +(HeroPos -pos)*(-175/GetDistance(mousePos))
					myHero:MoveTo(movePos.x, movePos.z)
				else
					myHero:MoveTo(mousePos.x, mousePos.z)
				end
			end
		end
	elseif GetTickCount() > aaTime then
		if Config.teamFight and Config.moveToMouse then
			local pos = {x = mousePos.x, y = mousePos.y, z = mousePos.z}
			local HeroPos = Vector(myHero.x, myHero.y, myHero.z)
			if GetDistance(mousePos)>175 then
				local movePos = HeroPos +(HeroPos -pos)*(-175/GetDistance(mousePos))
				myHero:MoveTo(movePos.x, movePos.z)
			else
				myHero:MoveTo(mousePos.x, mousePos.z)
			end
		end
	end
end
function OnDraw()
	if not myHero.dead then
		if ValidTarget(newTarget) and Config.DrawArrow then
			DrawArrows(myHero, newTarget, 30, 0x099B2299, 50)
		end
		if Config.DrawCircles then
			DrawCircle(myHero.x, myHero.y, myHero.z, killRange, ARGB(87,183,60,244))
		end
		for i = 1, enemyHerosCount do
			local Enemy = enemyHeros[i].object
			local killable = enemyHeros[i].killable
			if ValidTarget(Enemy) then
				if killable == 4 then
					DrawText3D(tostring("Ks him"),Enemy.x,Enemy.y, Enemy.z,16,ARGB(255,255,10,20), true)
				elseif killable == 3 then
					DrawText3D(tostring("killable"),Enemy.x,Enemy.y, Enemy.z,16,ARGB(255,255,143,20), true)
				elseif killable == 2 then
					DrawText3D(tostring("Combo killer"),Enemy.x,Enemy.y, Enemy.z,16,ARGB(255,248,255,20), true) 
				elseif killable == 1 then
					DrawText3D(tostring("Harass Him"),Enemy.x,Enemy.y, Enemy.z,16,ARGB(255,10,255,20), true)
				else
					DrawText3D(tostring("Not killable"),Enemy.x,Enemy.y, Enemy.z,16,ARGB(244,66,155,255), true)
				end
			end
		end 
	end
end

function OnProcessSpell(unit, spell)
	if unit.isMe and unit.valid and spell.name:lower():find("attack") and spell.animationTime then
		aaTime = GetTickCount() + spell.windUpTime * 1000 - GetLatency() / 2 + 10 + 50
		NextShot = GetTickCount() + spell.animationTime * 1000
	end
end