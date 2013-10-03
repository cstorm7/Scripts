if myHero.charName ~= "Zed" then return end
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
	PrintFloatText(myHero,2,"Zed WomboCombo UnLoaded!")
end
function LoadMenu()
	Config = scriptConfig("Zed WomboCombo", " WomboCombo")
	Config:addParam("harass", "Harass (X)", SCRIPT_PARAM_ONKEYDOWN, false, 88)
	Config:addParam("teamFight", "TeamFight (SpaceBar)", SCRIPT_PARAM_ONKEYDOWN, false, 32)
	Config:addParam("farm", "Farm (Z)", SCRIPT_PARAM_ONKEYTOGGLE, false, 90)
	Config:addParam("DrawCircles", "Draw Circles", SCRIPT_PARAM_ONOFF, true)
	Config:addParam("drawTargetCircle", "Draw Target Circle", SCRIPT_PARAM_ONOFF, true)
	Config:addParam("MinionMarker", "Minion Marker", SCRIPT_PARAM_ONOFF, true)
	Config:addParam("moveToMouse", "Move To Mouse", SCRIPT_PARAM_ONOFF, true)
	Config:addParam("creeps", "Creeps (J)", SCRIPT_PARAM_ONKEYDOWN, false, 74)
	Config:addParam("ultAnytime", "Ult Anytime (U)", SCRIPT_PARAM_ONKEYTOGGLE, false, 85)
	Config:addParam("autoE", "Auto E (T)", SCRIPT_PARAM_ONKEYTOGGLE, true, 84)
	Config:addParam("UseWHarass", "Use W Harass", SCRIPT_PARAM_ONOFF, true)
	Config:addParam("UseWTeamfight", "Use W TeamFight", SCRIPT_PARAM_ONOFF, true)
	Config:addParam("use2ndR", "Use 2nd R (M)", SCRIPT_PARAM_ONKEYTOGGLE, true, 77)
	Config:addParam("KsQ", "Ks Q", SCRIPT_PARAM_ONOFF, true)
	Config:addParam("KsE", "Ks E", SCRIPT_PARAM_ONOFF, true)
	Config:addParam("KsR", "Ks R", SCRIPT_PARAM_ONOFF, true)
	Config:permaShow("autoE")
	Config:permaShow("use2ndR")
	Config:permaShow("ultAnytime")
	Config:permaShow("harass")
	Config:permaShow("teamFight")
	Config:permaShow("farm")
	PrintFloatText(myHero,2,"Zed WomboCombo Loaded!")
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
	clones = {}
	markedTarget = nil
end
function LoadSkillRanges()
	rangeQ = 925
	rangeW = 600
	rangeE = 290
	rangeR = 625
	killRange = 925
end
function LoadVIPPrediction()
	tpQ = TargetPredictionVIP(rangeQ, 902, 0.5, 45)
	tpQC = TargetPredictionVIP(1500, 902, 0.5, 45, obj)
end
function LoadMinions()
	enemyMinion = minionManager(MINION_ENEMY, rangeQ, player, MINION_SORT_HEALTH_ASC)
	jungleMinion = minionManager(MINION_JUNGLE, rangeQ, player, MINION_SORT_MAXHEALTH_DEC)
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
		removeClones()
		execute()
		orbWalk()
		jungleFarm()
		if Config.farm and not Config.teamFight and not Config.harass then
			farmKey()
		end
		if Config.harass then
			harassKey()
		end
	end
end
function checkKillRange()
	local WQCombo = myHero:GetSpellData(_Q).mana + myHero:GetSpellData(_W).mana
	if QREADY and WREADY and WQCombo<=myHero.mana then
		killRange = 1500
	elseif QREADY then
		killRange = 925
	else
		killRange = 600
	end

end
function removeClones()
	if next(clones)~=nil then
		for i, obj in pairs(clones) do
			if not obj.valid then
				table.remove(clones, i)
			end
		end
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
			local qdmg = getDmg("Q", Enemy, myHero, 3)
			local wdmg = getDmg("W", Enemy, myHero, 3)
			local edmg = getDmg("E", Enemy, myHero, 3)
			local rdmg = getDmg("R", Enemy, myHero, 1)
			local ADdmg = getDmg("AD", Enemy, myHero, 3)
			local dfgdamage = (GetInventoryItemIsCastable(3128) and getDmg("DFG",Enemy,myHero) or 0) -- Deathfire Grasp
			local hxgdamage = (GetInventoryItemIsCastable(3146) and getDmg("HXG",Enemy,myHero) or 0) -- Hextech Gunblade
			local bwcdamage = (GetInventoryItemIsCastable(3144) and getDmg("BWC",Enemy,myHero) or 0) -- Bilgewater Cutlass
			local botrkdamage = (GetInventoryItemIsCastable(3153) and getDmg("RUINEDKING", Enemy, myHero) or 0) --Blade of the Ruined King
			local onhitdmg = (GetInventoryHaveItem(3057) and getDmg("SHEEN",Enemy,myHero) or 0) + (GetInventoryHaveItem(3078) and getDmg("TRINITY",Enemy,myHero) or 0) + (GetInventoryHaveItem(3100) and getDmg("LICHBANE",Enemy,myHero) or 0) + (GetInventoryHaveItem(3025) and getDmg("ICEBORN",Enemy,myHero) or 0) + (GetInventoryHaveItem(3087) and getDmg("STATIKK",Enemy,myHero) or 0) + (GetInventoryHaveItem(3209) and getDmg("SPIRITLIZARD",Enemy,myHero) or 0)
			local onspelldamage = (GetInventoryHaveItem(3151) and getDmg("LIANDRYS",Enemy,myHero) or 0) + (GetInventoryHaveItem(3188) and getDmg("BLACKFIRE",Enemy,myHero) or 0)
			local sunfiredamage = (GetInventoryHaveItem(3068) and getDmg("SUNFIRE",Enemy,myHero) or 0)
			local maxUltDamage = 0
			local ultDamage = 0
			local rLevel = myHero:GetSpellData(_R).level
			if RREADY then
				if rLevel==1 then
					maxUltDamage = ADdmg + ((pdmg + qdmg + wdmg + edmg + ADdmg + onhitdmg + onspelldamage)*0.2)
					ultDamage = ADdmg + ((pdmg + onhitdmg + onspelldamage + ADdmg)*0.2)
					if QREADY then
						ultDamage = ultDamage + qdmg*0.2
					end
					if EREADY then
						ultDamage = ultDamage + edmg*0.2
					end
					if GetInventoryItemIsCastable(3128) then  -- DFG      
						ultDamage = ultDamage + dfgdamage + (ultDamage*0.2)*0.2
					end
					if GetInventoryItemIsCastable(3146) then -- Hxg
						ultDamage = ultDamage + hxgdamage*0.2
					end
					if GetInventoryItemIsCastable(3144) then -- bwc
						ultDamage = ultDamage + bwcdamage*0.2
					end
					if GetInventoryItemIsCastable(3153) then -- botrk
						ultDamage = ultDamage + botrkdamage*0.2
					end
				elseif rLevel==2 then
					maxUltDamage = ADdmg + ((pdmg + qdmg + wdmg + edmg + onhitdmg + onspelldamage + ADdmg)*0.35)
					ultDamage = ADdmg + ((pdmg + ADdmg + onhitdmg + onspelldamage)*0.35)
					if QREADY then
						ultDamage = ultDamage + qdmg*0.35
					end
					if EREADY then
						ultDamage = ultDamage + edmg*0.35
					end
					if GetInventoryItemIsCastable(3128) then  -- DFG      
						ultDamage = ultDamage + dfgdamage + (ultDamage*0.2)*0.35
					end
					if GetInventoryItemIsCastable(3146) then -- Hxg
						ultDamage = ultDamage + hxgdamage*0.35
					end
					if GetInventoryItemIsCastable(3144) then -- bwc
						ultDamage = ultDamage + bwcdamage*0.35
					end
					if GetInventoryItemIsCastable(3153) then -- botrk
						ultDamage = ultDamage + botrkdamage*0.35
					end
				elseif rLevel==3 then
					maxUltDamage = ADdmg + ((pdmg + ADdmg + qdmg + wdmg + edmg + onhitdmg + onspelldamage)*0.5)
					ultDamage = ADdmg + ((pdmg + ADdmg + onhitdmg + onspelldamage)*0.5)
					if QREADY then
						ultDamage = ultDamage + qdmg*0.5
					end
					if EREADY then
						ultDamage = ultDamage + edmg*0.5
					end
					if GetInventoryItemIsCastable(3128) then  -- DFG      
						ultDamage = ultDamage + dfgdamage + (ultDamage*0.2)*0.5
					end
					if GetInventoryItemIsCastable(3146) then -- Hxg
						ultDamage = ultDamage + hxgdamage*0.5
					end
					if GetInventoryItemIsCastable(3144) then -- bwc
						ultDamage = ultDamage + bwcdamage*0.5
					end
					if GetInventoryItemIsCastable(3153) then -- botrk
						ultDamage = ultDamage + botrkdamage*0.5
					end
				else 
					maxUltDamage = 0
					ultDamage = 0
				end
			end
			local comboKiller = pdmg + qdmg + wdmg + edmg + rdmg + onhitdmg + onspelldamage + sunfiredamage + hxgdamage + bwcdamage + botrkdamage + maxUltDamage
			local killHim = pdmg + onhitdmg + onspelldamage + sunfiredamage + hxgdamage + bwcdamage + botrkdamage + ultDamage
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
					if qdmg >=Enemy.health and not IsIgnited() and Config.KsQ and (TargetHaveBuff("zedulttargetmark", Enemy) or not RREADY) then
						table.insert(ksDamages, qdmg)
						
					end
				end
			end
			if WREADY then
				killMana = killMana + myHero:GetSpellData(_W).mana	
			end
			if EREADY then
				killMana = killMana + myHero:GetSpellData(_E).mana
				killHim = killHim + edmg
				if edmg>=Enemy.health and not IsIgnited() and Config.KsE and (TargetHaveBuff("zedulttargetmark", Enemy) or not RREADY) then
					table.insert(ksDamages, edmg)
				end
			end
			if RREADY then
				killMana = killMana + myHero:GetSpellData(_R).mana
				if GetDistance(Enemy)<=rangeR then
					killHim = killHim + rdmg
					if ultDamage>=Enemy.health and not IsIgnited() and Config.KsR and (TargetHaveBuff("zedulttargetmark", Enemy) or not RREADY) then
						table.insert(ksDamages, ultDamage)
					end
				end
			end
			if next(ksDamages)~=nil then
				table.sort(ksDamages, function (a, b) return a<b end)
				local lowestKSDmg = ksDamages[1]
				if not RREADY or rUsed() then
					if qdmg == lowestKSDmg then
						CastQ(Enemy)
					elseif edmg == lowestKSDmg then
						CastE(Enemy)
					elseif rdmg == lowestKSDmg then
						CastR(Enemy)
					end
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
			if TargetHaveBuff("zedulttargetmark", Enemy) then
				if Config.teamFight then
					CastItems(Enemy, true)
					CastQ(Enemy)
					if Config.UseWTeamfight then
						CastW(Enemy)
						CastW2(Enemy)
					end
					CastE(Enemy)
					CastR2(Enemy)
				end
				if Config.autoE then
					CastE(Enemy)
				end
				return
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
			if Config.autoE or Config.teamFight or Config.harass then
				if next(clones)~=nil then
					for i, obj in pairs(clones) do
						if obj.valid then
							if GetDistance(obj, Enemy)<=rangeE and EREADY and (Config.teamFight or Config.harass) and (TargetHaveBuff("zedulttargetmark", Enemy) or not RREADY) then
								CastSpell(_E)
							end
						end
					end
				end
			end
		else
			killable = 0
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
function farmKey()
	enemyMinion:update()
	if next(enemyMinion.objects)~= nil then
		for j, minion in pairs(enemyMinion.objects) do
			if minion.valid then
				if GetDistance(minion)<=myHero.range +65 then
					local ADdmg = getDmg("AD", minion, myHero, 3)
					if ADdmg>=minion.health then
						if GetTickCount() > NextShot then
							myHero:Attack(minion)
						end
					end
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
						
					end
				end
			end
		end
	else
		return
	end
end
function harassKey()
	if ValidTarget(newTarget) then
		if Config.UseWHarass then
			local WQCombo = myHero:GetSpellData(_Q).mana + myHero:GetSpellData(_W).mana
			if WQCombo<=myHero.mana then
				CastW(newTarget)
				CastQ(newTarget)
			end
		else
			CastQ(newTarget)
		end
		CastE(newTarget)
	end
end
function killTarget(target)
	if ValidTarget(target) and not IsIgnited() and not TargetHaveBuff("zedulttargetmark", target) then
		if Config.teamFight and not RREADY or rUsed() then
			CastItems(target, true)
			CastQ(target)
			if Config.UseWTeamfight then
				CastW(target)
				CastW2(target)
			end
			CastE(target)
			CastR2(target)
		elseif Config.teamFight then
			CastR(target)
		end
		if Config.autoE then
			CastE(target)
		end
	end
end
function comboTarget(target)
	if ValidTarget(target) and not IsIgnited() and not TargetHaveBuff("zedulttargetmark", target) then
		if Config.teamFight and not RREADY or rUsed() then
			CastItems(target, true)
			CastQ(target)
			if Config.UseWTeamfight then
				CastW(target)
				CastW2(target)
			end
			CastE(target)
			CastR2(target)
		elseif Config.teamFight then
			CastR(target)
		end
		if Config.autoE then
			CastE(target)
		end
	end
end
function harassTarget(target)
	if ValidTarget(target) and not TargetHaveBuff("zedulttargetmark", target) then
		if Config.ultAnytime then
			if Config.teamFight and not RREADY or rUsed() then
				CastItems(target, true)
				CastQ(target)
				if Config.UseWTeamfight then
					CastW(target)
					CastW2(target)
				end
				CastE(target)
				CastR2(target)
			elseif Config.teamFight then
				CastR(target)
			end
		else
			local WQCombo = myHero:GetSpellData(_Q).mana + myHero:GetSpellData(_W).mana
			if Config.teamFight then
				CastItems(target)
				CastQ(target)
				if Config.UseWTeamfight then
					if WQCombo<=myHero.mana then
						CastW(target)
					end
				end
				CastE(target)
			end
		end
		if Config.autoE then
			CastE(target)
		end
	end
end
function CastQ(target)
	if not QREADY then return end
	if ValidTarget(target) then
		if GetDistance(target) <= rangeQ and QREADY then
			local QPos = tpQ:GetPrediction(target)
			if QPos and GetDistance(QPos)<=rangeQ then
				CastSpell(_Q, QPos.x, QPos.z)
			end
		elseif next(clones)~=nil and wUsed() then
			for i, obj in pairs(clones) do
				if obj.valid then
					local QPos = tpQC:GetPrediction(target)
					if QPos and GetDistance(obj, QPos)<=rangeQ then
						CastSpell(_Q, QPos.x, QPos.z)
					end
				end
			end
		end
	else
		return
	end
end
function CastW(target)
	if not WREADY then return end
	if ValidTarget(target) then
		if WREADY and not wUsed() then
			local WPos = target
			if WPos then
				EnemyPos = Vector(WPos.x, WPos.y, WPos.z)
				HeroPos = Vector(myHero.x, myHero.y, myHero.z)
				Pos = HeroPos + (HeroPos-EnemyPos)*(-600/GetDistance(target))
				CastSpell(_W, Pos.x, Pos.z)
			end
		else
			return
		end
	else
		return
	end
end
function CastW2(target)
	if not WREADY then return end
	if ValidTarget(target) then
		if WREADY and wUsed() then
			if next(clones)~=nil then
				for i, obj in pairs(clones) do
					if obj.valid and not target.dead then
						if GetDistance(target, obj) < GetDistance(myHero, target) then
							CastSpell(_W)
						end
					end
				end
			end
		else
			return
		end
	else
		return
	end
end
function CastE(target)
	if not EREADY then return end
	if ValidTarget(target) then
		if GetDistance(target) <= rangeE and EREADY then
			CastSpell(_E)
		end
	else
		return
	end
end
function CastR(target)
	if not RREADY then return end
	if ValidTarget(target) then
		if GetDistance(target) <= rangeR and RREADY and not rUsed() then
			CastSpell(_R, target)
		end
	else
		return
	end
end
function CastR2(target)
	if not RREADY then return end
	if ValidTarget(target) then
		if rUsed() and Config.use2ndR then
			if next(clones)~=nil then
				for i, obj in pairs(clones) do
					if obj.valid and not target.dead then
						if GetDistance(target, obj) < GetDistance(myHero, target) then
							CastSpell(_R)
						end
					end
				end
			end
		else
			return
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
function wUsed()
	if myHero:GetSpellData(_W).name == "zedw2" then
		return true
	else
		return false
	end
end
function rUsed()
	if myHero:GetSpellData(_R).name == "ZedR2" then
		return true
	else
		return false
	end
end
function OnCreateObj(obj)	
	if obj ~= nil and obj.name:find("Zed_Clone_idle.troy") then
		table.insert(clones, obj)
	end
end
function orbWalk()		
	if GetTickCount() > NextShot then
		if ValidTarget(newTarget) then
			if GetDistance(newTarget)<=myHero.range +65 and Config.teamFight then
				myHero:Attack(newTarget)
			else
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
			if Config.teamFight then
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
		if ValidTarget(newTarget) and Config.drawTargetCircle then
			DrawCircle(newTarget.x, newTarget.y, newTarget.z, 100, ARGB(244,66,155,255))
			DrawCircle(newTarget.x, newTarget.y, newTarget.z, 100, ARGB(244,66,155,255))
			DrawCircle(newTarget.x, newTarget.y, newTarget.z, 100, ARGB(244,66,155,255))
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
	if unit.isMe and unit.valid and spell.name:lower():find("attack") and spell.animationTime and spell.windUpTime then
		aaTime = GetTickCount() + spell.windUpTime * 1000 - GetLatency() / 2 + 10 + 50
		NextShot = GetTickCount() + spell.animationTime * 1000
	end
end