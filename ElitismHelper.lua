--version 0.0.1

local Users = {}
local activeUser = nil
local playerUser = GetUnitName("player",true).."-"..GetRealmName()

local Spells = {
	-- Affixes
	[209862] = true,		-- Volcanic Plume (Environment)

	-- Blackrook Hold
	[200261] = true,		-- Bonebreaking Strike (Soul-Torn Champion)
	[197974] = true,		-- Bonecrushing Strike (Soul-torn Vanguard) \\ credit to Grâve-Kazzak
	[222397] = true,		-- Boulder Crush (Environment)
	[198820] = true,		-- Dark Blast (Latosius)
	[214001] = true,		-- Raven's Dive (Risen Lancer)
	[199567] = true,		-- Dark Obliteration (Image of Latosius)
	[200256] = true,		-- Phased Explosion (Arcane Minion) \\ credit to Darlinda-Kazzak, Grâve-Kazzak, Banefury-Kazzak and Solacè-Kazzak
	[198781] = true,		-- Whirling Blade (Kur'talos Ravencrest) \\ credit to Darlinda-Kazzak and Grâve-Kazzak

	-- Court of Stars
	[207979] = true,		-- Shockwave (Jazshariu)
	[209027] = true,		-- Quelling Strike (Duskwatch Guard)

	-- Darkheart Thicket
	[204402] = true,		-- Star Shower (Dreadsoul Ruiner)
	[201273] = true,		-- Blood Bomb (Bloodtainted Fury)
	[201227] = true,		-- Blood Assault (Bloodtainted Fury)
	[201123] = true,		-- Root Burst (Vilethorn Blossom)

	-- Eye of Azshara
	[195473] = true,		-- Abrasive Slime (Gritslime Snail)

	-- Maw of Souls
	[194218] = true,		-- Cosmic Scythe (Harbaron)
	[195309] = true,		-- Swirling Water (MoS Helya)
	[202098] = true,		-- Brackwater Barrage (MoS Helya) 
	[195036] = true,		-- Defiant Strike #1 (Seacursed Soulkeeper)
	[195033] = true,		-- Defiant Strike #2 (Seacursed Soulkeeper)
	[195035] = true,		-- Defiant Strike #3 (Seacursed Soulkeeper)
	[195038] = true,		-- Defiant Strike #4 (Seacursed Soulkeeper)
	[194443] = true,		-- Six Pound Barrel (Waterlogged Soul Guard)

	-- The Arcway
	[211209] = true,		-- Arcane Slicer (Arcane Anomaly)
	[196142] = true,		-- Exterminate (Corstilax)

	-- Neltharion's Lair
	[183100] = true,		-- Avalanche (Mightstone Breaker)

	-- Halls of Valor
	[192206] = true,		-- Sanctify (Olmyr & Hyrja)
	[199210] = true,		-- Penetrating Shot (Valarjar Marksman)
	[199337] = true,		-- Bear Trap (Valarjar Trapper)
	[199818] = true,		-- Crackle (Stormforged Sentinel)
	[210875] = true,		-- Charged Pulse (Stormforged Sentinel)
	[193234] = true,		-- Dancing Blade (Hymdall)

	-- The Nighthold
	[208659] = true,		-- Arcanetic Ring (Grand Magistrix Elisande)
	[207631] = true,		-- Annihilation (Trilliax)
	[205391] = true,		-- Fel Beam (Krosus)
	[215988] = true,		-- Carrion Nightmare (Tichondrius)
	[207720] = true,		-- Witness the Void (Thing That Should Not Be, Star Augur Etraeus)
	[218463] = true,		-- Controlled Chaos (High Botanist Tel'arn, 10 yards explosion?)
	[218466] = true,		-- Controlled Chaos (High Botanist Tel'arn, 20 yards explosion?)
	[218470] = true,		-- Controlled Chaos (High Botanist Tel'arn, 30 yards explosion?)
	[218155] = true,		-- Solar Collapse (High Botanist Tel'arn)
	[206515] = true,		-- Fel Efflux (Gul'dan)
	[212262] = true,		-- Hand of Gul'dan (Gul'dan)
}

local Auras = {
	-- Court of Stars
	[209667] = true,		-- Blade Surge (Advisor Melandrus)

	-- Darkheart Thicket
	[200771] = true,		-- Propelling Charge (Crazed Razorbeak)

	-- Halls of Valor
	[198088] = true,		-- Glowing Fragment (HoV Odyn)

	-- Lower Karazhan
	[227977] = true,		-- Flashlight (Skeletal Usher)

	-- Emerald Nightmare
	[210315] = true,		-- Nightmare Brambles (Cenarius)
	[203110] = true,		-- Slumbering Nightmare (Dragons of Nightmare)

	-- Trial of Valor
	[227781] = true,		-- Glowing Fragment (ToV Odyn)

	-- The Nighthold
	[204483] = true,		-- Focused Blast (Skorpyron)
	[206896] = true,		-- Torn Soul (Gul'dan)
}

local ElitismFrame = CreateFrame("Frame", "ElitismFrame")
ElitismFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
local MSG_PREFIX = "ElitismHelper"
local success = RegisterAddonMessagePrefix(MSG_PREFIX)
ElitismFrame:RegisterEvent("CHAT_MSG_ADDON")
ElitismFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
ElitismFrame:RegisterEvent("ADDON_LOADED")

ElitismFrame:ClearAllPoints()
ElitismFrame:SetHeight(300)
ElitismFrame:SetWidth(1000)
ElitismFrame.text = ElitismFrame:CreateFontString(nil, "BACKGROUND", "PVPInfoTextFont")
ElitismFrame.text:SetAllPoints()
ElitismFrame.text:SetTextHeight(13)
ElitismFrame:SetAlpha(1)

function table.pack(...)
  return { n = select("#", ...), ... }
end

ElitismFrame:SetScript("OnEvent", function(self, event_name, ...)
	if self[event_name] then
		return self[event_name](self, event_name, ...)
	end
end)

SlashCmdList["ELITISMHELPER"] = function(msg,editBox)
	if msg == "activeuser" then
		print("activeUser is "..activeUser)
	elseif msg == "resync" then
		ElitismFrame:RebuildTable()
	elseif msg == "table" then
		for k,v in pairs(Users) do
			print(k.." ;;; "..v)
		end
	end
end

SLASH_ELITISMHELPER1 = "/eh"

function ElitismFrame:RebuildTable()
	Users = {}
	activeUser = nil
	-- print("Reset Addon Users table")
	if IsInGroup() or IsInRaid() or IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
		SendAddonMessage(MSG_PREFIX,"VREQ",RAID)
	else
		name = GetUnitName("player",true)
		activeUser = name.."-"..GetRealmName()
		-- print("We are alone, activeUser: "..activeUser)
	end
end

function ElitismFrame:ADDON_LOADED(event,addon)
	if addon == "ElitismHelper" then
		ElitismFrame:RebuildTable()
	end
end

function ElitismFrame:GROUP_ROSTER_UPDATE(event,...)
	-- print("GROUP_ROSTER_UPDATE")
	ElitismFrame:RebuildTable()
end

function ElitismFrame:CHAT_MSG_ADDON(event,...)
	local prefix, message, channel, sender = select(1,...)
	if prefix ~= MSG_PREFIX then
		return
	end
	if message == "VREQ" then
		SendAddonMessage(MSG_PREFIX,"VANS;0.1",RAID)
	elseif message:match("^VANS") then
		Users[sender] = message
		for k,v in pairs(Users) do
			if activeUser == nil then
				activeUser = k
			end
			if k < activeUser then
				activeUser = k
			end
		end
	else
		-- print("Unknown message: "..message)
	end
end

function ElitismFrame:SpellDamage(timestamp, eventType, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, aAmount)
	if Spells[spellId] and UnitIsPlayer(dstName) then
		if IsInRaid() then
			SendChatMessage("<EH> "..dstName.." got hit by "..GetSpellLink(spellId).." for "..aAmount..".",RAID)
		elseif IsInGroup() then
			SendChatMessage("<EH> "..dstName.." got hit by "..GetSpellLink(spellId).." for "..aAmount..".",PARTY)
		elseif IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
			SendChatMessage("<EH> "..dstName.." got hit by "..GetSpellLink(spellId).." for "..aAmount..".",INSTANCE)
		end
	end
end

function ElitismFrame:SwingDamage(timestamp, eventType, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, aAmount)
end

function ElitismFrame:AuraApply(timestamp, eventType, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, auraType, auraAmount)
	if Auras[spellId] and UnitIsPlayer(dstName) then
		if auraAmount then
			if IsInRaid() then
				SendChatMessage("<EH> "..dstName.." got hit by "..GetSpellLink(spellId)..". "..auraAmount.." Stacks.",RAID)
			elseif IsInGroup() then
				SendChatMessage("<EH> "..dstName.." got hit by "..GetSpellLink(spellId)..". "..auraAmount.." Stacks.",PARTY)
			elseif IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
				SendChatMessage("<EH> "..dstName.." got hit by "..GetSpellLink(spellId)..". "..auraAmount.." Stacks.",INSTANCE)
			end
		else
			if IsInRaid() then
				SendChatMessage("<EH> "..dstName.." got hit by "..GetSpellLink(spellId)..".",RAID)
			elseif IsInGroup() then
				SendChatMessage("<EH> "..dstName.." got hit by "..GetSpellLink(spellId)..".",PARTY)
			elseif IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
				SendChatMessage("<EH> "..dstName.." got hit by "..GetSpellLink(spellId)..".",INSTANCE)
			end
		end
	end
end

function ElitismFrame:COMBAT_LOG_EVENT_UNFILTERED(event,...)
	if activeUser ~= playerUser then
		return
	end
	local timestamp, eventType, hideCaster, srcGUID, srcName, srcFlags, srcFlags2, dstGUID, dstName, dstFlags, dstFlags2 = select(1,...); -- Those arguments appear for all combat event variants.
	local eventPrefix, eventSuffix = eventType:match("^(.-)_?([^_]*)$");
	if (eventPrefix:match("^SPELL") or eventPrefix:match("^RANGE")) and eventSuffix == "DAMAGE" then
		local spellId, spellName, spellSchool, sAmount, aOverkill, sSchool, sResisted, sBlocked, sAbsorbed, sCritical, sGlancing, sCrushing, sOffhand, _ = select(12,...)
		ElitismFrame:SpellDamage(timestamp, eventType, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, sAmount)
	elseif eventPrefix:match("^SWING") and eventSuffix == "DAMAGE" then
		local aAmount, aOverkill, aSchool, aResisted, aBlocked, aAbsorbed, aCritical, aGlancing, aCrushing, aOffhand, _ = select(12,...)
		ElitismFrame:SwingDamage(timestamp, eventType, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, aAmount)
	elseif eventPrefix:match("^SPELL") and eventSuffix == "MISSED" then
		local spellId, spellName, spellSchool, missType, isOffHand, mAmount  = select(12,...)
		if mAmount then
			ElitismFrame:SpellDamage(timestamp, eventType, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, mAmount)
		end
	elseif eventType == "SPELL_AURA_APPLIED" then
		local spellId, spellName, spellSchool, auraType = select(12,...)
		ElitismFrame:AuraApply(timestamp, eventType, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, auraType)
	elseif eventType == "SPELL_AURA_APPLIED_DOSE" then
		local spellId, spellName, spellSchool, auraType, auraAmount = select(12,...)
		ElitismFrame:AuraApply(timestamp, eventType, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, auraType, auraAmount)
	else
	end
end