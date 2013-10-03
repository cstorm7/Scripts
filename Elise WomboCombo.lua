if myHero.charName ~= "Elise" then return end
require "Collision"
function OnLoad()
	LoadMenu()
	LoadVariables()
	LoadSkillRanges()
	LoadVIPPrediction()
	LoadMinions()
	LoadSummonerSpells()
	LoadEnemies()
	LoadCollisionValues()
end
function OnUnload()
	PrintFloatText(myHero,2,"Elise WomboCombo UnLoaded!")
end
function LoadMenu()
	Config = scriptConfig("Elise WomboCombo", "Elise WomboCombo")
	Config:addParam("harass", "Harass (X)", SCRIPT_PARAM_ONKEYDOWN, false, 88)
	Config:addParam("teamFight", "TeamFight (SpaceBar)", SCRIPT_PARAM_ONKEYDOWN, false, 32)
	Config:addParam("farm", "Farm (Z)", SCRIPT_PARAM_ONKEYTOGGLE, false, 90)
	Config:addParam("UseR", "Use R (T)", SCRIPT_PARAM_ONKEYTOGGLE, true, 84)
	Config:addParam("useERappel", "Use Rappel (M)", SCRIPT_PARAM_ONKEYTOGGLE, true, 77)
	Config:addParam("DrawCircles", "Draw Circles", SCRIPT_PARAM_ONOFF, true)
	Config:addParam("DrawArrow", "Draw Arrow", SCRIPT_PARAM_ONOFF, true)
	Config:addParam("MinionMarker", "Minion Marker", SCRIPT_PARAM_ONOFF, true)
	Config:addParam("moveToMouse", "Move To Mouse", SCRIPT_PARAM_ONOFF, true)
	Config:addParam("creeps", "Creeps (J)", SCRIPT_PARAM_ONKEYDOWN, false, 74)
	Config:addParam("mindmgpercent", "Min dmg percent", SCRIPT_PARAM_SLICE, 20, 0, 100, 0)
	Config:addParam("mindmg", "Min dmg approx", SCRIPT_PARAM_INFO, 0)
	Config:permaShow("mindmg")
	Config:permaShow("UseR")
	Config:permaShow("useERappel")
	Config:permaShow("harass")
	Config:permaShow("teamFight")
	Config:permaShow("farm")
	PrintFloatText(myHero,2,"Elise WomboCombo Loaded!")
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
	humanETick = 0
	humanECD = 0
	spiderETick = 0
	spiderECD = 0
	Rappel = false
	manaQ = 0
	manaW = 0
	manaE = 0
	myHeroMana = 0
end
function LoadSkillRanges()
	rangeQ = 650
	rangeW = 1025
	rangeE = 1025
	rangeR = 1025
	killRange = 1025
end
function LoadVIPPrediction()
	tpQ = TargetPredictionVIP(rangeQ, 1600, 0.25)
	tpE = TargetPredictionVIP(rangeE, 1700, 0.25)
	tpW = TargetPredictionVIP(rangeW, 2000, 0.25)
end
function LoadCollisionValues()
	ecol = Collision(rangeE, 1700, 0.25, 90)
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
		CheckCooldown()
		CheckMana()
		RappelBuffCheck()
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
	if EREADY and humanForm() then
		killRange = 1150
	elseif RREADY and not humanForm() and HumanEOffCooldown() then
		killRange = 1150
	elseif WREADY and humanForm() then
		killRange = 1025
	elseif EREADY and not humanForm() then
		killRange = 965
	elseif QREADY and humanForm() then
		killRange = 650
	elseif QREADY and not humanForm() then
		killRange = 475
	end
	if humanForm() then
		rangeQ = 650
		rangeW = 1025
		rangeE = 1150
		rangeR = 1025
	else
		rangeQ = 475
		rangeW = 475
		rangeE = 965
		rangeR = 975
	end
end
function humanForm()
	local qData = myHero:GetSpellData(_Q).name
	if qData == "EliseHumanQ" then
		return true
	else
		return false
	end
end
function CheckCooldown()
	if humanForm() then
		local CD = myHero:GetSpellData(_E).cd
		local currentCD = myHero:GetSpellData(_E).currentCd

		if currentCD<CD and currentCD>0 then
			if currentCD> humanECD then
				humanECD = currentCD
			end
		end
		if humanECD == 0 then
			humanECD = CD
		elseif humanECD == CD and currentCD>0 then
			humanECD = currentCD
		end
	else
		local CD = myHero:GetSpellData(_E).cd
		local currentCD = myHero:GetSpellData(_E).currentCd

		if currentCD<CD and currentCD>0 then
			if currentCD> spiderECD then
				spiderECD = currentCD
			end
		end
		if spiderECD == 0 then
			spiderECD = CD
		elseif spiderECD == CD and currentCD>0 then
			spiderECD = currentCD
		end
	end
end
function CheckMana()
	if humanForm() then
		local qMana = myHero:GetSpellData(_Q).mana
		local wMana = myHero:GetSpellData(_W).mana
		local eMana = myHero:GetSpellData(_E).mana
		local myChampMana = myHero.mana
		manaQ = qMana
		manaW = wMana
		manaE = eMana
		myHeroMana = myChampMana
	end
end
function HumanEOffCooldown()
	if GetTickCount()> humanETick then
		return true
	else
		return false
	end
end
function SpiderEOffCooldown()
	if GetTickCount()> spiderETick then
		return true
	else
		return false
	end
end
function RappelBuffCheck()
	if TargetHaveBuff("elisespidere", myHero) and Rappel == false then
		Rappel = true	
	elseif not TargetHaveBuff("elisespidere", myHero) and Rappel == true then
		Rappel = false
		spiderETick = GetTickCount() + spiderECD*1000
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
			local rdmg = getDmg("R", Enemy, myHero, 3)
			local ADdmg = getDmg("AD", Enemy, myHero, 3)
			local dfgdamage = (GetInventoryItemIsCastable(3128) and getDmg("DFG",Enemy,myHero) or 0) -- Deathfire Grasp
			local hxgdamage = (GetInventoryItemIsCastable(3146) and getDmg("HXG",Enemy,myHero) or 0) -- Hextech Gunblade
			local bwcdamage = (GetInventoryItemIsCastable(3144) and getDmg("BWC",Enemy,myHero) or 0) -- Bilgewater Cutlass
			local botrkdamage = (GetInventoryItemIsCastable(3153) and getDmg("RUINEDKING", Enemy, myHero) or 0) --Blade of the Ruined King
			local onhitdmg = (GetInventoryHaveItem(3057) and getDmg("SHEEN",Enemy,myHero) or 0) + (GetInventoryHaveItem(3078) and getDmg("TRINITY",Enemy,myHero) or 0) + (GetInventoryHaveItem(3100) and getDmg("LICHBANE",Enemy,myHero) or 0) + (GetInventoryHaveItem(3025) and getDmg("ICEBORN",Enemy,myHero) or 0) + (GetInventoryHaveItem(3087) and getDmg("STATIKK",Enemy,myHero) or 0) + (GetInventoryHaveItem(3209) and getDmg("SPIRITLIZARD",Enemy,myHero) or 0)
			local onspelldamage = (GetInventoryHaveItem(3151) and getDmg("LIANDRYS",Enemy,myHero) or 0) + (GetInventoryHaveItem(3188) and getDmg("BLACKFIRE",Enemy,myHero) or 0)
			local sunfiredamage = (GetInventoryHaveItem(3068) and getDmg("SUNFIRE",Enemy,myHero) or 0)
			local comboKiller = pdmg + qdmg*2 + wdmg*2 + edmg*2 + rdmg + onhitdmg + onspelldamage + sunfiredamage + hxgdamage + bwcdamage + botrkdamage
			local killHim = pdmg + onhitdmg + onspelldamage + sunfiredamage + hxgdamage + bwcdamage + botrkdamage
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
					if qdmg >=Enemy.health and not IsIgnited() then
						table.insert(ksDamages, qdmg)
						ksQDmg = qdmg
					end
				end
			end
			if WREADY then
				killMana = killMana + myHero:GetSpellData(_W).mana	
				if GetDistance(Enemy)<=rangeW then
					killHim = killHim + wdmg
					if wdmg >=Enemy.health and not IsIgnited() then
						table.insert(ksDamages, wdmg)
						ksWDmg = wdmg
					end
				end
			end
			if EREADY then
				killMana = killMana + myHero:GetSpellData(_E).mana
			end
			if next(ksDamages)~=nil then
				table.sort(ksDamages, function (a, b) return a<b end)
				local lowestKSDmg = ksDamages[1]
				if qdmg == lowestKSDmg then
					CastQ(Enemy)
				elseif wdmg == lowestKSDmg then
					CastW(Enemy)
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
					elseif GetDistance(minion)<=rangeQ then
						local qDmg = getDmg("Q", minion, myHero, 3)
						if qDmg>=minion.health then
							CastQ(minion)
						end
					end
				elseif GetDistance(minion)<=rangeQ then
					local qDmg = getDmg("Q", minion, myHero, 3)
					if qDmg>=minion.health then
						CastQ(minion)
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
		if Config.harass then
			CastQ(newTarget)
		end
	end
end
function killTarget(target)
	if ValidTarget(target) and not IsIgnited() then
		if Config.teamFight then
			CastItems(target, true)
			CastQ(target)
			CastW(target)
			CastE(target)
			if Config.UseR then
				CastR(target)
			end
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
			if Config.UseR then
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
			if humanForm() then
				CastE(target)
			end
			if Config.UseR then
				CastR(target)
			end
		end
	end
end
function CastQ(target)
	if not QREADY then return end
	if ValidTarget(target) then
		if GetDistance(target) <= rangeQ and QREADY then
			CastSpell(_Q, target)
		end
	else
		return
	end
end
function CastW(target)
	if not WREADY then return end
	if ValidTarget(target) then
		if GetDistance(target) <= rangeW and WREADY and humanForm() then
			local WPos = tpW:GetPrediction(target)
			if WPos and GetDistance(WPos)<=rangeW then
				CastSpell(_W, WPos.x, WPos.z)
			end
		elseif GetDistance(target) <= rangeW and WREADY and not humanForm() then
			CastSpell(_W)
		end
	else
		return
	end
end
function CastE(target)
	if not EREADY then return end
	if ValidTarget(target) then
		if GetDistance(target) <= rangeE and EREADY and humanForm() then
			local EPos = tpE:GetPrediction(target)
			if EPos and GetDistance(EPos)<=rangeE then
				if not ecol:GetMinionCollision(myHero, EPos) then
					CastSpell(_E, EPos.x, EPos.z)
				end
			end
		elseif GetDistance(target) <= rangeE and EREADY and not humanForm() and Config.useERappel then
			if not useRappel() and GetDistance(target)>=700 then
				CastSpell(_E)
			elseif useRappel() then
				CastSpell(_E, target)
			end
		end
	else
		return
	end
end
function CastR(target)
	if not RREADY then return end
	if HumanEOffCooldown() and not humanForm() then
		local totalSkillMana = manaE
		if totalSkillMana<=myHeroMana then
			CastSpell(_R)
		end
	end
	if ValidTarget(target) then
		if GetDistance(target) <= rangeR and RREADY and humanForm() then
			if GetDistance(target)<= 500 or (not EREADY and SpiderEOffCooldown()) then
				CastSpell(_R)
			end
		end
	else
		return
	end
end
function useRappel()
	if humanForm() then return end
	local rappel = myHero:GetSpellData(_E).name
	if rappel =="elisespideredescent" then
		return true
	else
		return false
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
				if Config.teamFight and Config.moveToMouse then
					myHero:MoveTo(mousePos.x, mousePos.z)
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
				myHero:MoveTo(mousePos.x, mousePos.z)
			end
		end
	elseif GetTickCount() > aaTime then
		if Config.teamFight and Config.moveToMouse then
			myHero:MoveTo(mousePos.x, mousePos.z)
		end
	end
end
function OnDraw()
	Config.mindmg = math.floor(myHero.health*Config.mindmgpercent/100)
	if not myHero.dead then
		if ValidTarget(newTarget) and Config.DrawArrow then
			DrawArrows(myHero, newTarget, 30, 0x099B2299, 50)
		end
		if Config.DrawCircles then
			DrawCircle(myHero.x, myHero.y, myHero.z, killRange, ARGB(87,183,60,244))
			if ValidTarget(newTarget) then
				DrawCircle(newTarget.x, newTarget.y, newTarget.z, 100, ARGB(244,66,155,255))
			end
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
	if unit.isMe and unit.valid then
		if spell.name == "EliseHumanE" then
			humanETick = GetTickCount() + humanECD*1000
		end	
	end
	spellName = spell.name
	spellLevel =spell.level
	P2 = spell.endPos
	adamage = getDmg("AD",unit,myHero)
	
	Muramana = false
	onhitdmg = 0
	onhittdmg = 0
	skilldamage = 0
	onhitspelldmg = 0
	onhitspelltdmg = 0
	InfinityEdge = 0
	muramanadmg = 0
	shottype = 0
	radius = 0
	maxdistance = 0
	hitchampion = false
	
	if ValidTarget(unit) and unit.type == "obj_AI_Hero" then
		spelltype = getSpellType(unit, spellName)
		if EREADY and not humanForm() and not myHero.dead then
			if unit.type ~= "obj_AI_Hero" then
				if spellName:find("BasicAttack") then 
					skilldamage = adamage
				elseif spellName:find("CritAttack") then
					skilldamage = adamage*2 
				end
			end
			if spelltype == "BAttack" or spelltype == "CAttack" then
				if GetInventoryHaveItem(3186,unit) then 
					onhitdmg = getDmg("KITAES",myHero,unit) 
				end
				if GetInventoryHaveItem(3114,unit) then 
					onhitdmg = onhitdmg+getDmg("MALADY",myHero,unit) 
				end
				if GetInventoryHaveItem(3091,unit) then 
					onhitdmg = onhitdmg+getDmg("WITSEND",myHero,unit) 
				end
				if GetInventoryHaveItem(3057,unit) then 
					onhitdmg = onhitdmg+getDmg("SHEEN",myHero,unit) 
				end
				if GetInventoryHaveItem(3078,unit) then 
					onhitdmg = onhitdmg+getDmg("TRINITY",myHero,unit) 
				end
				if GetInventoryHaveItem(3100,unit) then 
					onhitdmg = onhitdmg+getDmg("LICHBANE",myHero,unit)
				end
				if GetInventoryHaveItem(3025,unit) then 
					onhitdmg = onhitdmg+getDmg("ICEBORN",myHero,unit)
				end
				if GetInventoryHaveItem(3087,unit) then 
					onhitdmg = onhitdmg+getDmg("STATIKK",myHero,unit) 
				end
				if GetInventoryHaveItem(3153,unit) then 
					onhitdmg = onhitdmg+getDmg("RUINEDKING",myHero,unit) 
				end
				if GetInventoryHaveItem(3042,unit) then 
				 onhitdmg = onhitdmg+getDmg("MURAMANA",myHero,unit) 
				end
				if GetInventoryHaveItem(3209,unit) then 
					onhittdmg = getDmg("SPIRITLIZARD",myHero,unit) 
				end
				if GetInventoryHaveItem(3184,unit) then 
					onhittdmg = onhittdmg+80 
				end
			end
			if spelltype == "BAttack" then
				skilldamage = (adamage+onhitdmg)*1.07+onhittdmg
			elseif spelltype == "CAttack" then
				skilldamage = (adamage*(2.1+InfinityEdge)+onhitdmg)*1.07+onhittdmg
			elseif spelltype == "Q" or spelltype == "W" or spelltype == "E" or spelltype == "R" or spelltype == "P" or spelltype == "QM" or spelltype == "WM" or spelltype == "EM" then
				if GetInventoryHaveItem(3151,unit) then 
					onhitspelldmg = getDmg("LIANDRYS",myHero,unit)
				end
				if GetInventoryHaveItem(3188,unit) then 
					onhitspelldmg = getDmg("BLACKFIRE",myHero,unit)
				end
				if GetInventoryHaveItem(3209,unit) then 
					onhitspelltdmg = getDmg("SPIRITLIZARD",myHero,unit)
				end
				if GetInventoryHaveItem(3042,unit) then 
					muramanadmg = getDmg("MURAMANA",unit,myHero)
				end
				Muramana = skillShield[unit.charName][spelltype]["Muramana"]
				shottype = skillData[unit.charName][spelltype]["type"]
				radius = skillData[unit.charName][spelltype]["radius"]
				maxdistance = skillData[unit.charName][spelltype]["maxdistance"]
				muramanadmg = Muramana and muramanadmg or 0
				skilldamage = getDmg(spelltype,myHero,unit,3,spellLevel)
				if skilldamage > 0 then 
					skilldamage = (skilldamage+onhitspelldmg+muramanadmg)*1.07+onhitspelltdmg 
				end
			elseif spellName:find("SummonerDot") then
				skilldamage = getDmg("IGNITE",myHero,unit)
			end
			if shottype == 0 then hitchampion = checkhitaoe(unit, P2, 80, myHero, 0)
			elseif shottype == 1 then 
				hitchampion = checkhitlinepass(unit, P2, radius, maxdistance, myHero, 50)
			elseif shottype == 2 then 
				hitchampion = checkhitlinepoint(unit, P2, radius, myHero, 50)
			elseif shottype == 3 then 
				hitchampion = checkhitaoe(unit, P2, radius, myHero, 50)
			elseif shottype == 4 then 
				hitchampion = checkhitcone(unit, P2, radius, maxdistance, myHero, 50)
			elseif shottype == 5 then 
				hitchampion = checkhitwall(unit, P2, radius, maxdistance, myHero, 50)
			elseif shottype == 6 then 
				hitchampion = checkhitlinepass(unit, P2, radius, maxdistance, myHero, 50) or checkhitlinepass(unit, Vector(unit)*2-P2, radius, maxdistance, myHero, 50)
			end
			local dmgpercent = skilldamage*100/myHero.health
			local dmgneeded = dmgpercent >= Config.mindmgpercent
			if hitchampion then
				if dmgneeded and Config.useERappel then
					CastSpell(_E)
				end
			end	
		end
	end
end