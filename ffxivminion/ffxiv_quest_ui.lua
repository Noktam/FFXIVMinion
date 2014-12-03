QM = {}
--onOpen can be added if a certain function should run when the window is opened, otherwise it should be left as nil.
--baseY is used to tell the window to position itself below the specified window.
--baseX is used to tell the window to position itself right of the specified window.
QM.Windows = {
	Main = {visible = false, name = strings[gCurrentLanguage].profileManager, visibleDefault = false, onOpen = "QM.LoadProfile",
		x = 500, y = 40, width = 250, height = 520
	},
	QuestEditor = {visible = false, name = strings[gCurrentLanguage].questEditor, visibleDefault = false,
		base = "Main", width = 250, height = 275
	},
	StepManager = {visible = false, name = strings[gCurrentLanguage].questSteps, visibleDefault = false, onOpen = "QM.LoadTaskFields",
		base = "QuestEditor", width = 250, height = 400
	},
	StepEditor = {visible = false, name = strings[gCurrentLanguage].questStepEditor, visibleDefault = false,
		base = "StepManager", width = 250, height = 300
	},
	ItemEditor = {visible = false, name = strings[gCurrentLanguage].questItemEditor, visibleDefault = false, onOpen = "QM.RefreshStepItems",
		base = "StepEditor", width = 250, height = 300
	},
	EncounterEditor = {visible = false, name = strings[gCurrentLanguage].dutyEncounterEditor, visibleDefault = false,
		base = "QuestManager", width = 250, height = 300
	},
	TurnInEditor = {visible = false, name = strings[gCurrentLanguage].questTurnoverEditor, visibleDefault = false, onOpen = "QM.PullTurnoverItem;QM.RefreshTurnovers",
		base = "StepManager", width = 250, height = 275
	},
	PreReqEditor = {visible = false, name = strings[gCurrentLanguage].questPreReqEditor, visibleDefault = false, onOpen = "QM.RefreshPreReqs",
		base = "QuestEditor", width = 250, height = 275
	},
}
QM.Wrappers = {
	Quest = "quests",
	Duty = "Encounters",
}

QM.QuestPath = GetStartupPath()..[[\LuaMods\ffxivminion\QuestProfiles\]];
QM.DutyPath = GetStartupPath()..[[\LuaMods\ffxivminion\DutyProfiles\]];
QM.WindowTick = 0

--Initialize all tracking tables.
QM.Quests = {}
QM.Encounters = {}
QM.CurrentStep = 1
QM.LastQuest = nil

--All variables should be added here, along with their cast type, profile equivalent (if any), and an onChange event, if any functions should be called when the variable is updated.
QM.Variables = {
	qProfileType = 	{ default = "Duty", 	profile = "", 				cast = "string", onChange = "QM.LoadTypeOptions" },
	qProfileName = 	{ default = "None", 	profile = "" , 				cast = "string", onChange = "QM.LoadProfile"},
	qProfileNew = 	{ default = "", 		profile = "" , 				cast = "string"},
	qDutyTask = 	{ default = "Kill", 	profile = "" , 				cast = "string"},
	qDutyCustom = 	{ default = "", 		profile = "" , 				cast = "string"},
	qQuestID = 		{ default = "", 		profile = "" , 				cast = "number"},
	eQuestID = 		{ default = "", 		profile = "" , 				cast = "number"},
	qQuestJob = 	{ default = "None", 	profile = "job", 			cast = "number"},
	eQuestJob = 	{ default = "None", 	profile = "job", 			cast = "number"},
	qQuestLevel = 	{ default = 1,	 		profile = "level", 			cast = "number"},
	eQuestLevel = 	{ default = 1, 			profile = "level", 			cast = "number"},
	qPreReqJob = 	{ default = "All",  	profile = "" , 				cast = "string"},
	qPreReqStep = 	{ default = 1, 			profile = "", 				cast = "number"},
	qPreReqID = 	{ default = "",	 		profile = "" , 				cast = "number"},
	qStepNum = 		{ default = "", 		profile = "" , 				cast = "number"},
	eStepNum = 		{ default = "", 		profile = "" , 				cast = "number"},
	qStepTask = 	{ default = "start",	profile = "type", 			cast = "string", onChange = "QM.LoadTaskFields"},
	eStepTask = 	{ default = "start",	profile = "type", 			cast = "string", onChange = "QM.LoadTaskFields"}, -- new
	qTaskCustom = 	{ default = "", 		profile = "", 				cast = "string"},
	qTaskCommandString = 	{ default = "", 		profile = "commandstring", 		cast = "string"},
	eTaskCommandString = 	{ default = "", 		profile = "commandstring", 		cast = "string"},
	qTaskItemSelector = 	{default = 1, 		profile = "", 			cast = "number", onChange = "QM.PullTaskAddItem"},
	eTaskItemSelector = 	{default = 1, 		profile = "", 			cast = "number", onChange = "QM.PullTaskEditItem"},
	qTaskItemID = 	{ default = 0, 			profile = "itemid", 		cast = "number"},
	eTaskItemID = 	{ default = 0, 			profile = "itemid", 		cast = "number"},
	qTaskMesh = 	{ default = "", 		profile = "meshname", 		cast = "string"},
	eTaskMesh = 	{ default = "", 		profile = "meshname", 		cast = "string"},
	qTaskMap = 		{ default = "", 		profile = "mapid", 			cast = "number"},
	eTaskMap = 		{ default = "", 		profile = "mapid", 			cast = "number"},
	qTaskNPC = 		{ default = "", 		profile = "id", 			cast = "number"},
	eTaskNPC = 		{ default = "", 		profile = "id", 			cast = "number"},
	qTaskAction = 	{ default = "",			profile = "actionid",		cast = "number"},
	eTaskAction = 	{ default = "",			profile = "actionid",		cast = "number"},
	qTaskQuestID = 	{ default = 0, 			profile = "questid", 		cast = "number"},
	eTaskQuestID = 	{ default = 0, 			profile = "questid", 		cast = "number"},
	qTaskKillTarget = 	{ default = "",		profile = "id", 			cast = "number"},
	eTaskKillTarget = 	{ default = "",		profile = "id", 			cast = "number"},
	qTaskKillPriorities = 	{ default = "",		profile = "ids", 			cast = "string"},
	eTaskKillPriorities = 	{ default = "",		profile = "ids", 			cast = "string"},
	qTaskKillCount = 	{ default = 0, 		profile = "killcount", 		cast = "number"},
	eTaskKillCount = 	{ default = 0, 		profile = "killcount", 		cast = "number"},
	qTaskDelay = 		{ default = 0, 		profile = "delay", 			cast = "number"},
	eTaskDelay = 		{ default = 0, 		profile = "delay", 			cast = "number"},
	qTaskRewardSlot = 	{ default = 0, 		profile = "itemrewardslot", cast = "number"},
	eTaskRewardSlot = 	{ default = 0, 		profile = "itemrewardslot", cast = "number"},
	qTaskConvoIndex = 	{ default = 0,		profile = "conversationindex", cast = "number"},
	eTaskConvoIndex = 	{ default = 0,		profile = "conversationindex", cast = "number"},
	qTaskItemJobReq = 	{ default = -1, 	profile = ""				, cast = "number"},
	qTaskItemAmount = 	{ default = 1, 		profile = "buyamount"		, cast = "number"},
	eTaskItemAmount = 	{ default = 1, 		profile = "buyamount"		, cast = "number"},	
	
	qEncounterName = 	{ default = "", 	profile = "", 			cast = "string"},
	qEncounterType = 	{ default = "kill",	profile = "", 			cast = "string", onChange = "QM.LoadEncounterFields"},
	
	qTurnoverStep = 	{ default = 1, 		profile = "" , 				cast = "number"},
	qTurnoverID = 		{ default = "",		profile = "itemturninid", 	cast = "number"},
	qTurnoverSlot = 	{default = 1, 		profile = "", 				cast = "number", onChange = "QM.PullTurnoverItem"},
}

QM.Strings = {
	Meshes = 
		function()
			local meshlist = "none"
			local meshfilelist = dirlist(ml_mesh_mgr.navmeshfilepath,".*obj")
			if ( TableSize(meshfilelist) > 0) then
				local i,meshname = next ( meshfilelist)
				while i and meshname do
					meshname = string.gsub(meshname, ".obj", "")
					--table.insert(mm.meshfiles, meshname) not needed anymore with new ml_mesh_mgr.lua
					meshlist = meshlist..","..meshname
					i,meshname = next ( meshfilelist,i)
				end
			end
			return meshlist
		end,
	QuestIDs = 
		function()
			local questlist = ""
			local questnames = ""
			local ql = Quest:GetQuestList()
			local i,q = next(ql)
			while (i and q) do
				questlist = questlist..","..tostring(i)
				i,q = next(ql,i)
			end
			return questlist
		end,
	QuestTasks = "start,accept,nav,interact,kill,dutykill,textcommand,useitem,useaction,vendor,finish,complete",
	DutyTasks = "kill,loot,interact",
	QuestJobs = "None,ARCANIST,ARCHER,BARD,BLACKMAGE,CONJURER,DRAGOON,GLADIATOR,LANCER,MARAUDER,MONK,PALADIN,PUGILIST,SCHOLAR,SUMMONER,THAUMATURGE,WARRIOR,WHITEMAGE",
	PreReqJobs = "All,ARCANIST,ARCHER,BARD,BLACKMAGE,CONJURER,DRAGOON,GLADIATOR,LANCER,MARAUDER,MONK,PALADIN,PUGILIST,SCHOLAR,SUMMONER,THAUMATURGE,WARRIOR,WHITEMAGE",
}

QM.Builds = {
	Main = {
		[1] = {5, "GUI_NewComboBox",QM.Windows.Main.name,strings[gCurrentLanguage].profileType,		"qProfileType",	strings[gCurrentLanguage].details, strings[gCurrentLanguage].dutyMode..","..strings[gCurrentLanguage].questMode},
		[2] = {5, "GUI_NewComboBox",QM.Windows.Main.name,strings[gCurrentLanguage].existingProfile, "qProfileName",	strings[gCurrentLanguage].details, "None"},
		[3] = {4, "GUI_NewField", 	QM.Windows.Main.name,strings[gCurrentLanguage].newProfileName,	"qProfileNew",	strings[gCurrentLanguage].details},
		[4] = {4, "GUI_NewButton", 	QM.Windows.Main.name,strings[gCurrentLanguage].createProfile, 	"QM.CreateProfile", strings[gCurrentLanguage].details},
		[5] = {3, "GUI_NewButton", 	QM.Windows.Main.name,strings[gCurrentLanguage].saveProfile, 	"QM.SaveProfile"},
	},
	LoadTypeOptions = {
		[1] = {QM.Windows.Main.name, strings[gCurrentLanguage].newEncounter},
		[2] = {QM.Windows.Main.name, strings[gCurrentLanguage].newQuest},
		[3] = {QM.Windows.Main.name, "Encounters"},
		[4] = {QM.Windows.Main.name, strings[gCurrentLanguage].quests},
	},
	Duty = {
		--[1] = {5, "GUI_NewComboBox",QM.Windows.Main.name,strings[gCurrentLanguage].task,		"qDutyTask",	strings[gCurrentLanguage].newEncounter, QM.Strings.DutyTasks},
		[1] = {4, "GUI_NewField",	QM.Windows.Main.name,strings[gCurrentLanguage].questName,	"qEncounterName",	strings[gCurrentLanguage].newEncounter},
		[2] = {4, "GUI_NewButton", 	QM.Windows.Main.name,strings[gCurrentLanguage].addEncounter, "QM.AddEncounter", strings[gCurrentLanguage].newEncounter},
	},
	Quest = {
		[1] = {4, "GUI_NewField",	QM.Windows.Main.name,strings[gCurrentLanguage].questID,		"qQuestID",		strings[gCurrentLanguage].newQuest},
		[2] = {4, "GUI_NewButton",	QM.Windows.Main.name,strings[gCurrentLanguage].questPullID, "QM.PullQuest",	strings[gCurrentLanguage].newQuest},
		[3] = {5, "GUI_NewComboBox",QM.Windows.Main.name,strings[gCurrentLanguage].questJob,	"qQuestJob",	strings[gCurrentLanguage].newQuest, QM.Strings.QuestJobs},
		[4] = {4, "GUI_NewField",	QM.Windows.Main.name,strings[gCurrentLanguage].questLevel,	"qQuestLevel",	strings[gCurrentLanguage].newQuest},
		[5] = {4, "GUI_NewButton",	QM.Windows.Main.name,strings[gCurrentLanguage].questAddQuest, "QM.AddQuest",  strings[gCurrentLanguage].newQuest},
	},
	QuestEditor = {
		[1] = {4, "GUI_NewField",	QM.Windows.QuestEditor.name,strings[gCurrentLanguage].questID,		"eQuestID",		 strings[gCurrentLanguage].details},
		[2] = {4, "GUI_NewButton",	QM.Windows.QuestEditor.name,strings[gCurrentLanguage].questPullID, 	"QM.PullQuest",	 strings[gCurrentLanguage].details},
		[3] = {5, "GUI_NewComboBox",QM.Windows.QuestEditor.name,strings[gCurrentLanguage].questJob,		"eQuestJob",	 strings[gCurrentLanguage].details, QM.Strings.QuestJobs},
		[4] = {4, "GUI_NewField",	QM.Windows.QuestEditor.name,strings[gCurrentLanguage].questLevel,	"eQuestLevel",	 strings[gCurrentLanguage].details},
		[5] = {3, "GUI_NewButton",	QM.Windows.QuestEditor.name,strings[gCurrentLanguage].questDelete,	"QM.DeleteQuest"},
		[6] = {3, "GUI_NewButton",	QM.Windows.QuestEditor.name,strings[gCurrentLanguage].questSave, 	"QM.ModifyQuest"},
		[7] = {3, "GUI_NewButton",	QM.Windows.QuestEditor.name,strings[gCurrentLanguage].questEditSteps, 	"QMToggleStepManager"},
		[8] = {3, "GUI_NewButton",	QM.Windows.QuestEditor.name,strings[gCurrentLanguage].questEditPreReqs,	"QMTogglePreReqEditor"},
	},
	PreReqEditor = {
		[1] = {5, "GUI_NewComboBox",QM.Windows.PreReqEditor.name,strings[gCurrentLanguage].prereqJob,	"qPreReqJob",	strings[gCurrentLanguage].newQuestPreReq, QM.Strings.PreReqJobs},		
		[2] = {4, "GUI_NewField",	QM.Windows.PreReqEditor.name,strings[gCurrentLanguage].prereqStep,"qPreReqStep", 	strings[gCurrentLanguage].newQuestPreReq},
		[3] = {4, "GUI_NewField",	QM.Windows.PreReqEditor.name,strings[gCurrentLanguage].prereqID,	"qPreReqID",  	strings[gCurrentLanguage].newQuestPreReq},
		[4] = {3, "GUI_NewButton", 	QM.Windows.PreReqEditor.name,strings[gCurrentLanguage].prereqClear,	"QM.ClearPreReqs"},
		[5] = {3, "GUI_NewButton",	QM.Windows.PreReqEditor.name,strings[gCurrentLanguage].questAddPreReq,			"QM.AddPreReq"},
	},
	StepManager = {
		[1] = {4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepCurrent,	"qStepNum",		strings[gCurrentLanguage].newQuestStep},
		[2] = {5, "GUI_NewComboBox",QM.Windows.StepManager.name,strings[gCurrentLanguage].stepTask,		"qStepTask",	strings[gCurrentLanguage].newQuestStep,	QM.Strings.QuestTasks},
		[3] = {3, "GUI_NewButton", 	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepClear, 	"QM.ClearSteps"},
		[4] = {3, "GUI_NewButton",	QM.Windows.StepManager.name,strings[gCurrentLanguage].questEditTurnovers,	"QMToggleTurnInEditor"},
	},
	StepEditor = {
		[1] = {4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepCurrent,	"eStepNum",		strings[gCurrentLanguage].editQuestStep},
		[2] = {5, "GUI_NewComboBox",QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepTask,		"eStepTask",	strings[gCurrentLanguage].editQuestStep,	QM.Strings.QuestTasks},
		[3] = {3, "GUI_NewButton", 	QM.Windows.StepEditor.name,strings[gCurrentLanguage].questStepSave, 	"QM.SaveStep"},
		[4] = {3, "GUI_NewButton", 	QM.Windows.StepEditor.name,strings[gCurrentLanguage].questStepDelete, 	"QM.RemoveStep"},
		[5] = {3, "GUI_NewButton", 	QM.Windows.StepEditor.name,strings[gCurrentLanguage].questDown, 	"QM.StepPriorityDown"},
		[6] = {3, "GUI_NewButton", 	QM.Windows.StepEditor.name,strings[gCurrentLanguage].questUp, 		"QM.StepPriorityUp"},
	},
	ItemEditor = {
		[1] = {5, "GUI_NewComboBox",QM.Windows.ItemEditor.name,strings[gCurrentLanguage].questJob,			"qTaskItemJobReq",	strings[gCurrentLanguage].newItem, QM.Strings.QuestJobs},
		[2] = {4, "GUI_NewField",	QM.Windows.ItemEditor.name,strings[gCurrentLanguage].stepItemID,		"qTaskItemID",		strings[gCurrentLanguage].newItem},
		[3] = {3, "GUI_NewButton", 	QM.Windows.ItemEditor.name,strings[gCurrentLanguage].questClearItems, 	"QM.ClearStepItems"},
		[4] = {3, "GUI_NewButton",	QM.Windows.ItemEditor.name,strings[gCurrentLanguage].questAddItem, 	"QM.AddStepItem"},
	},
	TurnInEditor = {
		[1] = {4, "GUI_NewField",	QM.Windows.TurnInEditor.name,strings[gCurrentLanguage].turnoverStep,"qTurnoverStep",strings[gCurrentLanguage].newQuestTurnover},
		[2] = {4, "GUI_NewField",	QM.Windows.TurnInEditor.name,strings[gCurrentLanguage].turnoverID,	"qTurnoverID",	strings[gCurrentLanguage].newQuestTurnover},
		[3] = {4, "GUI_NewNumeric",	QM.Windows.TurnInEditor.name,strings[gCurrentLanguage].turnoverSlot,"qTurnoverSlot",strings[gCurrentLanguage].newQuestTurnover},
		[4] = {3, "GUI_NewButton", 	QM.Windows.TurnInEditor.name,strings[gCurrentLanguage].turnoverClear, "QM.ClearTurnovers"},
		[5] = {3, "GUI_NewButton",	QM.Windows.TurnInEditor.name,strings[gCurrentLanguage].questAddTurnover, 		"QM.AddTurnover"},
	},
	QuestTasks = {
		["start"] = {
			[1] = {4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepCurrent,	"qStepNum",	strings[gCurrentLanguage].newQuestStep},
			[2] = {5, "GUI_NewComboBox",QM.Windows.StepManager.name,strings[gCurrentLanguage].stepTask,	"qStepTask",strings[gCurrentLanguage].newQuestStep,	QM.Strings.QuestTasks},
			[3] = {4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepMap,"qTaskMap",	strings[gCurrentLanguage].newQuestStep},
			[4] = {5, "GUI_NewComboBox",QM.Windows.StepManager.name,strings[gCurrentLanguage].stepMesh,"qTaskMesh",strings[gCurrentLanguage].newQuestStep, QM.Strings.Meshes },
			[5] = {4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepTarget,"qTaskNPC",strings[gCurrentLanguage].newQuestStep},
			[6] = {4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepDelay,"qTaskDelay",strings[gCurrentLanguage].newQuestStep},
			[7] = {4, "GUI_NewButton",	QM.Windows.StepManager.name,strings[gCurrentLanguage].questPullValues, "QM.LoadAddCurrentValues",strings[gCurrentLanguage].newQuestStep},
			[8] = {4, "GUI_NewButton",	QM.Windows.StepManager.name,strings[gCurrentLanguage].questAddStep, "QM.AddStep",strings[gCurrentLanguage].newQuestStep},
		},
		["accept"] = {
			[1] = {4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepCurrent,	"qStepNum",	strings[gCurrentLanguage].newQuestStep},
			[2] = {5, "GUI_NewComboBox",QM.Windows.StepManager.name,strings[gCurrentLanguage].stepTask,	"qStepTask",strings[gCurrentLanguage].newQuestStep,	QM.Strings.QuestTasks},
			[3] = {4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepQuestID,	"qTaskQuestID",	strings[gCurrentLanguage].newQuestStep},
			[4] = {4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepMap,"qTaskMap",	strings[gCurrentLanguage].newQuestStep},
			[5] = {5, "GUI_NewComboBox",QM.Windows.StepManager.name,strings[gCurrentLanguage].stepMesh,"qTaskMesh",strings[gCurrentLanguage].newQuestStep, QM.Strings.Meshes },
			[6] = {4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepTarget,"qTaskNPC",strings[gCurrentLanguage].newQuestStep},
			[7] = {4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepDelay,"qTaskDelay",strings[gCurrentLanguage].newQuestStep},
			[8] = {4, "GUI_NewButton",	QM.Windows.StepManager.name,strings[gCurrentLanguage].questPullValues, "QM.LoadAddCurrentValues",strings[gCurrentLanguage].newQuestStep},
			[9] = {4, "GUI_NewButton",	QM.Windows.StepManager.name,strings[gCurrentLanguage].questAddStep, "QM.AddStep",strings[gCurrentLanguage].newQuestStep},
		},
		["nav"] = {
			[1] = {4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepCurrent,	"qStepNum",	strings[gCurrentLanguage].newQuestStep},
			[2] = {5, "GUI_NewComboBox",QM.Windows.StepManager.name,strings[gCurrentLanguage].stepTask,	"qStepTask",strings[gCurrentLanguage].newQuestStep,	QM.Strings.QuestTasks},
			[3] = {4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepMap,	"qTaskMap",	strings[gCurrentLanguage].newQuestStep},
			[4] = {5, "GUI_NewComboBox",QM.Windows.StepManager.name,strings[gCurrentLanguage].stepMesh,"qTaskMesh",strings[gCurrentLanguage].newQuestStep, QM.Strings.Meshes },
			[5] = {4, "GUI_NewButton",	QM.Windows.StepManager.name,strings[gCurrentLanguage].questPullValues, "QM.LoadAddCurrentValues",strings[gCurrentLanguage].newQuestStep},
			[6] = {4, "GUI_NewButton",	QM.Windows.StepManager.name,strings[gCurrentLanguage].questAddStep, "QM.AddStep",strings[gCurrentLanguage].newQuestStep},
		},
		["kill"] = {
			[1] = {4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepCurrent,	"qStepNum",	strings[gCurrentLanguage].newQuestStep},
			[2] = {5, "GUI_NewComboBox",QM.Windows.StepManager.name,strings[gCurrentLanguage].stepTask,	"qStepTask",strings[gCurrentLanguage].newQuestStep,	QM.Strings.QuestTasks},
			[3] = {4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepMap,		"qTaskMap",strings[gCurrentLanguage].newQuestStep},
			[4] = {5, "GUI_NewComboBox",QM.Windows.StepManager.name,strings[gCurrentLanguage].stepMesh,	"qTaskMesh",strings[gCurrentLanguage].newQuestStep, QM.Strings.Meshes },
			[5] = {4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepTarget,	"qTaskKillTarget",strings[gCurrentLanguage].newQuestStep},
			[6] = {4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepKillCount,  "qTaskKillCount",strings[gCurrentLanguage].newQuestStep},
			[7] = {4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepDelay,"qTaskDelay",strings[gCurrentLanguage].newQuestStep},
			[8] = {4, "GUI_NewButton",	QM.Windows.StepManager.name,strings[gCurrentLanguage].questPullValues, "QM.LoadAddCurrentValues",strings[gCurrentLanguage].newQuestStep},
			[9] = {4, "GUI_NewButton",	QM.Windows.StepManager.name,strings[gCurrentLanguage].questAddStep, "QM.AddStep",strings[gCurrentLanguage].newQuestStep},
		},
		["dutykill"] = {
			[1] = {4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepCurrent,	"qStepNum",	strings[gCurrentLanguage].newQuestStep},
			[2] = {5, "GUI_NewComboBox",QM.Windows.StepManager.name,strings[gCurrentLanguage].stepTask,	"qStepTask",strings[gCurrentLanguage].newQuestStep,	QM.Strings.QuestTasks},
			[3] = {4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepMap,		"qTaskMap",strings[gCurrentLanguage].newQuestStep},
			[4] = {5, "GUI_NewComboBox",QM.Windows.StepManager.name,strings[gCurrentLanguage].stepMesh,	"qTaskMesh",strings[gCurrentLanguage].newQuestStep, QM.Strings.Meshes },
			[5] = {4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepTarget,	"qTaskKillPriorities",strings[gCurrentLanguage].newQuestStep},
			[6] = {4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepDelay,"qTaskDelay",strings[gCurrentLanguage].newQuestStep},
			[7] = {4, "GUI_NewButton",	QM.Windows.StepManager.name,strings[gCurrentLanguage].questPullValues, "QM.LoadAddCurrentValues",strings[gCurrentLanguage].newQuestStep},
			[8] = {4, "GUI_NewButton",	QM.Windows.StepManager.name,strings[gCurrentLanguage].questAddStep, "QM.AddStep",strings[gCurrentLanguage].newQuestStep},
		},
		["interact"] = {
			[1] = {4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepCurrent,	"qStepNum",	strings[gCurrentLanguage].newQuestStep},
			[2] = {5, "GUI_NewComboBox",QM.Windows.StepManager.name,strings[gCurrentLanguage].stepTask,	"qStepTask",strings[gCurrentLanguage].newQuestStep,	QM.Strings.QuestTasks},
			[3] = {4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepMap,"qTaskMap",strings[gCurrentLanguage].newQuestStep},
			[4] = {5, "GUI_NewComboBox",QM.Windows.StepManager.name,strings[gCurrentLanguage].stepMesh,"qTaskMesh",strings[gCurrentLanguage].newQuestStep, QM.Strings.Meshes },
			[5] = {4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepTarget,"qTaskNPC",strings[gCurrentLanguage].newQuestStep},
			[6] = {4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepDelay,"qTaskDelay",strings[gCurrentLanguage].newQuestStep},
			[7] = {4, "GUI_NewButton",	QM.Windows.StepManager.name,strings[gCurrentLanguage].questPullValues, "QM.LoadAddCurrentValues",strings[gCurrentLanguage].newQuestStep},
			[8] = {4, "GUI_NewButton",	QM.Windows.StepManager.name,strings[gCurrentLanguage].questAddStep, "QM.AddStep",strings[gCurrentLanguage].newQuestStep},
		},
		["textcommand"] = {
			[1] = {4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepCurrent,	"qStepNum",	strings[gCurrentLanguage].newQuestStep},
			[2] = {5, "GUI_NewComboBox",QM.Windows.StepManager.name,strings[gCurrentLanguage].stepTask,	"qStepTask",strings[gCurrentLanguage].newQuestStep,	QM.Strings.QuestTasks},
			[3] = {4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepMap,"qTaskMap",strings[gCurrentLanguage].newQuestStep},
			[4] = {5, "GUI_NewComboBox",QM.Windows.StepManager.name,strings[gCurrentLanguage].stepMesh,"qTaskMesh",strings[gCurrentLanguage].newQuestStep, QM.Strings.Meshes },
			[5] = {4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepTarget,"qTaskNPC",strings[gCurrentLanguage].newQuestStep},
			[6] = {4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepCommandString,"qTaskCommandString",strings[gCurrentLanguage].newQuestStep},
			[7] = {4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepDelay,"qTaskDelay",strings[gCurrentLanguage].newQuestStep},
			[8] = {4, "GUI_NewButton",	QM.Windows.StepManager.name,strings[gCurrentLanguage].questPullValues, "QM.LoadAddCurrentValues",strings[gCurrentLanguage].newQuestStep},
			[9] = {4, "GUI_NewButton",	QM.Windows.StepManager.name,strings[gCurrentLanguage].questAddStep, "QM.AddStep",strings[gCurrentLanguage].newQuestStep},
		},
		["useitem"] = {
			[1] = {4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepCurrent,	"qStepNum",	strings[gCurrentLanguage].newQuestStep},
			[2] = {5, "GUI_NewComboBox",QM.Windows.StepManager.name,strings[gCurrentLanguage].stepTask,	"qStepTask",strings[gCurrentLanguage].newQuestStep,	QM.Strings.QuestTasks},
			[3] = {4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepMap,"qTaskMap",strings[gCurrentLanguage].newQuestStep},
			[4] = {5, "GUI_NewComboBox",QM.Windows.StepManager.name,strings[gCurrentLanguage].stepMesh,"qTaskMesh",strings[gCurrentLanguage].newQuestStep, QM.Strings.Meshes },
			[5] = {4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepTarget,"qTaskNPC",strings[gCurrentLanguage].newQuestStep},
			[6] = {4, "GUI_NewNumeric",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepItemSelector,"qTaskItemSelector",strings[gCurrentLanguage].newQuestStep},
			[7] = {4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepItemID,"qTaskItemID", strings[gCurrentLanguage].newQuestStep},
			[8] = {4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepDelay,"qTaskDelay",strings[gCurrentLanguage].newQuestStep},
			[9] = {4, "GUI_NewButton",	QM.Windows.StepManager.name,strings[gCurrentLanguage].questPullValues, "QM.LoadAddCurrentValues",strings[gCurrentLanguage].newQuestStep},
			[10] = {4, "GUI_NewButton",	QM.Windows.StepManager.name,strings[gCurrentLanguage].questAddStep, "QM.AddStep",strings[gCurrentLanguage].newQuestStep},
		},
		["useaction"] = {
			[1] = {4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepCurrent,	"qStepNum",	strings[gCurrentLanguage].newQuestStep},
			[2] = {5, "GUI_NewComboBox",QM.Windows.StepManager.name,strings[gCurrentLanguage].stepTask,	"qStepTask",strings[gCurrentLanguage].newQuestStep,	QM.Strings.QuestTasks},
			[3] = {4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepMap,"qTaskMap",strings[gCurrentLanguage].newQuestStep},
			[4] = {5, "GUI_NewComboBox",QM.Windows.StepManager.name,strings[gCurrentLanguage].stepMesh,"qTaskMesh",strings[gCurrentLanguage].newQuestStep, QM.Strings.Meshes },
			[5] = {4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepTarget,"qTaskNPC",strings[gCurrentLanguage].newQuestStep},
			[6] = {4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepAction,"qTaskAction", strings[gCurrentLanguage].newQuestStep},
			[7] = {4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepDelay,"qTaskDelay",strings[gCurrentLanguage].newQuestStep},
			[8] = {4, "GUI_NewButton",	QM.Windows.StepManager.name,strings[gCurrentLanguage].questPullValues, "QM.LoadAddCurrentValues",strings[gCurrentLanguage].newQuestStep},
			[9] = {4, "GUI_NewButton",	QM.Windows.StepManager.name,strings[gCurrentLanguage].questAddStep, "QM.AddStep",strings[gCurrentLanguage].newQuestStep},
		},
		["vendor"] = {
			[1] = {4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepCurrent,	"qStepNum",	strings[gCurrentLanguage].newQuestStep},
			[2] = {5, "GUI_NewComboBox",QM.Windows.StepManager.name,strings[gCurrentLanguage].stepTask,	"qStepTask",strings[gCurrentLanguage].newQuestStep,	QM.Strings.QuestTasks},
			[3] = {4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepMap,"qTaskMap",strings[gCurrentLanguage].newQuestStep},
			[4] = {5, "GUI_NewComboBox",QM.Windows.StepManager.name,strings[gCurrentLanguage].stepMesh,"qTaskMesh",strings[gCurrentLanguage].newQuestStep, QM.Strings.Meshes },
			[5] = {4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepTarget,"qTaskNPC",strings[gCurrentLanguage].newQuestStep},
			[6] = {4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].convoIndex,"qTaskConvoIndex", strings[gCurrentLanguage].newQuestStep},
			[7] = {4, "GUI_NewNumeric",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepItemAmount,"qTaskItemAmount",	strings[gCurrentLanguage].newQuestStep},			
			[8] = {4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepDelay,"qTaskDelay",strings[gCurrentLanguage].newQuestStep},
			[9] = {4, "GUI_NewButton",	QM.Windows.StepManager.name,strings[gCurrentLanguage].questPullValues, "QM.LoadAddCurrentValues",strings[gCurrentLanguage].newQuestStep},
			[10] = {4, "GUI_NewButton",	QM.Windows.StepManager.name,strings[gCurrentLanguage].questAddStep, "QM.AddStep",strings[gCurrentLanguage].newQuestStep},
		},
		["finish"] = {
			[1] = {4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepCurrent,	"qStepNum",	strings[gCurrentLanguage].newQuestStep},
			[2] = {5, "GUI_NewComboBox",QM.Windows.StepManager.name,strings[gCurrentLanguage].stepTask,	"qStepTask",strings[gCurrentLanguage].newQuestStep,	QM.Strings.QuestTasks},
			[3] = {4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepMap,"qTaskMap",strings[gCurrentLanguage].newQuestStep},
			[4] = {5, "GUI_NewComboBox",QM.Windows.StepManager.name,strings[gCurrentLanguage].stepMesh,"qTaskMesh",strings[gCurrentLanguage].newQuestStep, QM.Strings.Meshes },
			[5] = {4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepTarget,"qTaskNPC",strings[gCurrentLanguage].newQuestStep},
			[6] = {4, "GUI_NewNumeric",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepReward,"qTaskRewardSlot",strings[gCurrentLanguage].newQuestStep},
			[7] = {4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepDelay,"qTaskDelay",strings[gCurrentLanguage].newQuestStep},
			[8] = {4, "GUI_NewButton",	QM.Windows.StepManager.name,strings[gCurrentLanguage].questPullValues, "QM.LoadAddCurrentValues",strings[gCurrentLanguage].newQuestStep},
			[9] = {4, "GUI_NewButton",	QM.Windows.StepManager.name,strings[gCurrentLanguage].questAddStep, "QM.AddStep",strings[gCurrentLanguage].newQuestStep},
		},
		["complete"] = {
			[1] = {4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepCurrent,	"qStepNum",	strings[gCurrentLanguage].newQuestStep},
			[2] = {5, "GUI_NewComboBox",QM.Windows.StepManager.name,strings[gCurrentLanguage].stepTask,	"qStepTask",strings[gCurrentLanguage].newQuestStep,	QM.Strings.QuestTasks},
			[3] = {4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepMap,"qTaskMap",strings[gCurrentLanguage].newQuestStep},
			[4] = {5, "GUI_NewComboBox",QM.Windows.StepManager.name,strings[gCurrentLanguage].stepMesh,"qTaskMesh",strings[gCurrentLanguage].newQuestStep, QM.Strings.Meshes },
			[5] = {4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepTarget,"qTaskNPC",strings[gCurrentLanguage].newQuestStep},
			[6] = {4, "GUI_NewNumeric",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepReward,"qTaskRewardSlot",strings[gCurrentLanguage].newQuestStep},
			[7] = {4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepDelay,"qTaskDelay",strings[gCurrentLanguage].newQuestStep},
			[8] = {4, "GUI_NewButton",	QM.Windows.StepManager.name,strings[gCurrentLanguage].questPullValues, "QM.LoadAddCurrentValues",strings[gCurrentLanguage].newQuestStep},
			[9] = {4, "GUI_NewButton",	QM.Windows.StepManager.name,strings[gCurrentLanguage].questAddStep, "QM.AddStep",strings[gCurrentLanguage].newQuestStep},
		},	
	},
	QuestTasksEdit = {
		["start"] = {
			[1] = {5, "GUI_NewComboBox",QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepTask,	"eStepTask",strings[gCurrentLanguage].editQuestStep,	QM.Strings.QuestTasks},
			[2] = {4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepMap,"eTaskMap",	strings[gCurrentLanguage].editQuestStep},
			[3] = {5, "GUI_NewComboBox",QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepMesh,"eTaskMesh",strings[gCurrentLanguage].editQuestStep, QM.Strings.Meshes },
			[4] = {4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepTarget,"eTaskNPC",strings[gCurrentLanguage].editQuestStep},
			[5] = {4, "GUI_NewButton",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].questPullValues, "QM.LoadEditCurrentValues",strings[gCurrentLanguage].editQuestStep},
		},
		["accept"] = {
			[1] = {5, "GUI_NewComboBox",QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepTask,	"eStepTask",strings[gCurrentLanguage].editQuestStep,	QM.Strings.QuestTasks},
			[2] = {4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepQuestID,	"eTaskQuestID",	strings[gCurrentLanguage].editQuestStep},
			[3] = {4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepMap,"eTaskMap",	strings[gCurrentLanguage].editQuestStep},
			[4] = {5, "GUI_NewComboBox",QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepMesh,"eTaskMesh",strings[gCurrentLanguage].editQuestStep, QM.Strings.Meshes },
			[5] = {4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepTarget,"eTaskNPC",strings[gCurrentLanguage].editQuestStep},
			[6] = {4, "GUI_NewButton",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].questPullValues, "QM.LoadEditCurrentValues",strings[gCurrentLanguage].editQuestStep},
		},
		["nav"] = {
			[1] = {5, "GUI_NewComboBox",QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepTask,	"eStepTask",strings[gCurrentLanguage].editQuestStep,	QM.Strings.QuestTasks},
			[2] = {4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepMap,	"eTaskMap",	strings[gCurrentLanguage].editQuestStep},
			[3] = {5, "GUI_NewComboBox",QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepMesh,"eTaskMesh",strings[gCurrentLanguage].editQuestStep, QM.Strings.Meshes },
			[4] = {4, "GUI_NewButton",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].questPullValues, "QM.LoadEditCurrentValues",strings[gCurrentLanguage].editQuestStep},
		},
		["kill"] = {
			[1] = {5, "GUI_NewComboBox",QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepTask,	"eStepTask",strings[gCurrentLanguage].editQuestStep,	QM.Strings.QuestTasks},
			[2] = {4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepMap,		"eTaskMap",strings[gCurrentLanguage].editQuestStep},
			[3] = {5, "GUI_NewComboBox",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepMesh,	"eTaskMesh",strings[gCurrentLanguage].editQuestStep, QM.Strings.Meshes },
			[4] = {4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepTarget,	"eTaskKillTarget",strings[gCurrentLanguage].editQuestStep},
			[5] = {4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepKillCount,  "eTaskKillCount",strings[gCurrentLanguage].editQuestStep},
			[6] = {4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepDelay,"eTaskDelay",strings[gCurrentLanguage].editQuestStep},
			[7] = {4, "GUI_NewButton",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].questPullValues, "QM.LoadEditCurrentValues",strings[gCurrentLanguage].editQuestStep},
		},
		["dutykill"] = {
			[1] = {5, "GUI_NewComboBox",QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepTask,	"eStepTask",strings[gCurrentLanguage].editQuestStep,	QM.Strings.QuestTasks},
			[2] = {4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepMap,		"eTaskMap",strings[gCurrentLanguage].editQuestStep},
			[3] = {5, "GUI_NewComboBox",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepMesh,	"eTaskMesh",strings[gCurrentLanguage].editQuestStep, QM.Strings.Meshes },
			[4] = {4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepTarget,	"eTaskKillPriorities",strings[gCurrentLanguage].editQuestStep},
			[5] = {4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepDelay,"eTaskDelay",strings[gCurrentLanguage].editQuestStep},
			[6] = {4, "GUI_NewButton",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].questPullValues, "QM.LoadEditCurrentValues",strings[gCurrentLanguage].editQuestStep},
		},
		["interact"] = {
			[1] = {5, "GUI_NewComboBox",QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepTask,	"eStepTask",strings[gCurrentLanguage].editQuestStep,	QM.Strings.QuestTasks},
			[2] = {4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepMap,"eTaskMap",strings[gCurrentLanguage].editQuestStep},
			[3] = {5, "GUI_NewComboBox",QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepMesh,"eTaskMesh",strings[gCurrentLanguage].editQuestStep, QM.Strings.Meshes },
			[4] = {4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepTarget,"eTaskNPC",strings[gCurrentLanguage].editQuestStep},
			[5] = {4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepDelay,"eTaskDelay",strings[gCurrentLanguage].editQuestStep},
			[6] = {4, "GUI_NewButton",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].questPullValues, "QM.LoadEditCurrentValues",strings[gCurrentLanguage].editQuestStep},
		},
		["textcommand"] = {
			[1] = {5, "GUI_NewComboBox",QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepTask,	"eStepTask",strings[gCurrentLanguage].editQuestStep,	QM.Strings.QuestTasks},
			[2] = {4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepMap,"eTaskMap",strings[gCurrentLanguage].editQuestStep},
			[3] = {5, "GUI_NewComboBox",QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepMesh,"eTaskMesh",strings[gCurrentLanguage].editQuestStep, QM.Strings.Meshes },
			[4] = {4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepTarget,"eTaskNPC",strings[gCurrentLanguage].editQuestStep},
			[5] = {4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepCommandString,"eTaskCommandString",strings[gCurrentLanguage].editQuestStep},
			[6] = {4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepDelay,"eTaskDelay",strings[gCurrentLanguage].editQuestStep},
			[7] = {4, "GUI_NewButton",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].questPullValues, "QM.LoadEditCurrentValues",strings[gCurrentLanguage].editQuestStep},
		},
		["useitem"] = {
			[1] = {5, "GUI_NewComboBox",QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepTask,	"eStepTask",strings[gCurrentLanguage].editQuestStep,	QM.Strings.QuestTasks},
			[2] = {4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepMap,"eTaskMap",strings[gCurrentLanguage].editQuestStep},
			[3] = {5, "GUI_NewComboBox",QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepMesh,"eTaskMesh",strings[gCurrentLanguage].editQuestStep, QM.Strings.Meshes },
			[4] = {4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepTarget,"eTaskNPC",strings[gCurrentLanguage].editQuestStep},
			[5] = {4, "GUI_NewNumeric",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepItemSelector,"eTaskItemSelector",strings[gCurrentLanguage].editQuestStep},
			[6] = {4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepItemID,"eTaskItemID", strings[gCurrentLanguage].editQuestStep},
			[7] = {4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepDelay,"eTaskDelay",strings[gCurrentLanguage].editQuestStep},
			[8] = {4, "GUI_NewButton",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].questPullValues, "QM.LoadEditCurrentValues",strings[gCurrentLanguage].editQuestStep},
		},
		["useaction"] = {
			[1] = {5, "GUI_NewComboBox",QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepTask,	"eStepTask",strings[gCurrentLanguage].editQuestStep,	QM.Strings.QuestTasks},
			[2] = {4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepMap,"eTaskMap",strings[gCurrentLanguage].editQuestStep},
			[3] = {5, "GUI_NewComboBox",QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepMesh,"eTaskMesh",strings[gCurrentLanguage].editQuestStep, QM.Strings.Meshes },
			[4] = {4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepTarget,"eTaskNPC",strings[gCurrentLanguage].editQuestStep},
			[5] = {4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepAction,"eTaskAction", strings[gCurrentLanguage].editQuestStep},
			[6] = {4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepDelay,"eTaskDelay",strings[gCurrentLanguage].editQuestStep},
			[7] = {4, "GUI_NewButton",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].questPullValues, "QM.LoadEditCurrentValues",strings[gCurrentLanguage].editQuestStep},
		},
		["vendor"] = {
			[1] = {5, "GUI_NewComboBox",QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepTask,	"eStepTask",strings[gCurrentLanguage].editQuestStep,	QM.Strings.QuestTasks},
			[2] = {4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepMap,"eTaskMap",strings[gCurrentLanguage].editQuestStep},
			[3] = {5, "GUI_NewComboBox",QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepMesh,"eTaskMesh",strings[gCurrentLanguage].editQuestStep, QM.Strings.Meshes },
			[4] = {4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepTarget,"eTaskNPC",strings[gCurrentLanguage].editQuestStep},
			[5] = {4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].convoIndex,"eTaskConvoIndex", strings[gCurrentLanguage].editQuestStep},
			[6] = {4, "GUI_NewNumeric",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepItemAmount,"eTaskItemAmount",	strings[gCurrentLanguage].editQuestStep},
			[7] = {4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepDelay,"eTaskDelay",strings[gCurrentLanguage].editQuestStep},
			[8] = {4, "GUI_NewButton",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].questItemEditor, "QMToggleItemEditor",strings[gCurrentLanguage].editQuestStep},
			[9] = {4, "GUI_NewButton",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].questPullValues, "QM.LoadEditCurrentValues",strings[gCurrentLanguage].editQuestStep},
		},
		["finish"] = {
			[1] = {5, "GUI_NewComboBox",QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepTask,	"eStepTask",strings[gCurrentLanguage].editQuestStep,	QM.Strings.QuestTasks},
			[2] = {4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepMap,"eTaskMap",strings[gCurrentLanguage].editQuestStep},
			[3] = {5, "GUI_NewComboBox",QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepMesh,"eTaskMesh",strings[gCurrentLanguage].editQuestStep, QM.Strings.Meshes },
			[4] = {4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepTarget,"eTaskNPC",strings[gCurrentLanguage].editQuestStep},
			[5] = {4, "GUI_NewNumeric",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepReward,"eTaskRewardSlot",strings[gCurrentLanguage].editQuestStep},
			[6] = {4, "GUI_NewButton",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].questPullValues, "QM.LoadEditCurrentValues",strings[gCurrentLanguage].editQuestStep},
		},	
		["complete"] = {
			[1] = {5, "GUI_NewComboBox",QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepTask,	"eStepTask",strings[gCurrentLanguage].editQuestStep,	QM.Strings.QuestTasks},
			[2] = {4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepMap,"eTaskMap",strings[gCurrentLanguage].editQuestStep},
			[3] = {5, "GUI_NewComboBox",QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepMesh,"eTaskMesh",strings[gCurrentLanguage].editQuestStep, QM.Strings.Meshes },
			[4] = {4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepTarget,"eTaskNPC",strings[gCurrentLanguage].editQuestStep},
			[5] = {4, "GUI_NewNumeric",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepReward,"eTaskRewardSlot",strings[gCurrentLanguage].editQuestStep},
			[6] = {4, "GUI_NewButton",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].questPullValues, "QM.LoadEditCurrentValues",strings[gCurrentLanguage].editQuestStep},
		},	
	},
}

function QM.Init()

	if (Settings.FFXIVMINION.qmWindow == nil or Settings.FFXIVMINION.qmWindow == {}) then 
		local windowInfo = {} 
		windowInfo.width = 250
		windowInfo.height = 300
		windowInfo.x = 200
		windowInfo.y = 40
		
		Settings.FFXIVMINION.qmWindow = windowInfo
	end
	
	--Make sure all variables are initialized.
	for k,v in pairs(QM.Variables) do
		if Settings.FFXIVMINION[k] == nil then Settings.FFXIVMINION[k] = v.default end
	end
	
	--Create Windows
	QM.LoadWindows()
	
	--Pull starting values from settings file.
	QM.LoadVariables()
	
	--Pull starting window fields for whichever type is selected.
	QM.LoadTypeOptions()
end
--**************************************************************************************************************************************
function QM.GUIVarUpdate(Event, NewVals, OldVals)
	for k,v in pairs(NewVals) do
		local var = QM.Variables[tostring(k)]
		if (var ~= nil) then
			Settings.FFXIVMINION[k] = v
			if (var.onChange ~= nil) then
				QM.ExecuteFunction(var.onChange)
			end
		end
	end
	
	for k,v in pairs(QM.Windows) do
		GUI_RefreshWindow(v.name)
	end
end
--**************************************************************************************************************************************
function QM.LoadProfile()
	
	local info = {}
	
	if (qProfileName == "" or qProfileName == nil) then
		return
	end
	
	if (qProfileType == "Duty") then
		info = persistence.load(QM.DutyPath..qProfileName..".info")
		if (ValidTable(info) and ValidTable(info.Encounters)) then
			QM.Encounters = info.Encounters
		else
			QM.Encounters = {}
		end
	else
		info = persistence.load(QM.QuestPath..qProfileName..".info")
		if (ValidTable(info) and ValidTable(info.quests)) then
			QM.Quests = info.quests
		else
			QM.Quests = {}
		end
		QM.RefreshQuests()
	end
end
--**************************************************************************************************************************************
function QM.CreateProfile()
	local starter = {}
	starter[tostring(QM.Wrappers[qProfileType])] = {}
	
	if (qProfileType == "Duty") then
		persistence.store(QM.DutyPath..qProfileNew..".info",starter)
	else
		persistence.store(QM.QuestPath..qProfileNew..".info",starter)
	end
	
	QM.LoadTypeOptions()
	
	qProfileName = qProfileNew
	qProfileNew = ""
end
--**************************************************************************************************************************************
function QM.SaveProfile()
	if (qProfileType == "Duty") then
		local info = {}
		info.Encounters = QM.Encounters
		persistence.store(QM.DutyPath..qProfileName..".info",info)
	else
		local info = {}
		info.quests = QM.Quests
		persistence.store(QM.QuestPath..qProfileName..".info",info)
	end
end
--**************************************************************************************************************************************
function QM.AddQuest()
	local quest = {}
	local k = tonumber(qQuestID)
	quest.steps = {}
	if (qQuestJob ~= "None") then quest.job = tonumber(FFXIV.JOBS[tonumber(qQuestJob)]) end
	quest.level = tonumber(qQuestLevel)
	quest.prereq = false
	QM.Quests[k] = quest
	
	QM.RefreshQuests()
end
--**************************************************************************************************************************************
function QM.PullQuest()
	QM.LastQuest = tonumber(qQuestID)
	local quest = Quest:GetSelectedJournalQuest()
	qQuestID = tonumber(quest)
	Settings.FFXIVMINION.qQuestID = qQuestID
end
--**************************************************************************************************************************************
function QM.EditQuest(id)
	local id = tonumber(id)
    local wnd = GUI_GetWindowInfo(QM.Windows.Main.name)	
    
	GUI_MoveWindow( QM.Windows.QuestEditor.name, wnd.x+wnd.width,wnd.y)

    local quest = QM.Quests[id]
	eQuestID = id
	eQuestJob = (quest.job ~= nil and quest.job or QM.Variables.eQuestJob.default)
	eQuestLevel = quest.level
	
	Settings.FFXIVMINION.eQuestID = eQuestID
	Settings.FFXIVMINION.eQuestJob = eQuestJob
	Settings.FFXIVMINION.eQuestLevel = eQuestLevel
	
	GUI_WindowVisible(QM.Windows.QuestEditor.name,true)
end
--**************************************************************************************************************************************
function QM.ModifyQuest()
	local k = tonumber(eQuestID)
	local quest = QM.Quests[k]
	
	if (eQuestJob ~= "None") then quest.job = tonumber(FFXIV.JOBS[eQuestJob]) end
	quest.level = tonumber(eQuestLevel)
	
	QM.Quests[k] = quest
	QM.LastQuest = k

	QM.RefreshQuests()
end
--**************************************************************************************************************************************
function QM.DeleteQuest()
	local k = tonumber(eQuestID)
	QM.Quests[k] = nil
	
	QM.RefreshQuests()
end
--**************************************************************************************************************************************
function QM.RefreshQuests()
	GUI_DeleteGroup(QM.Windows.Main.name,strings[gCurrentLanguage].quests)
	if (TableSize(QM.Quests) > 0) then
		for k,v in spairs(QM.Quests) do
			--Check the quest list to see if we have it, tack on the quest name if we do.
			local found = false
			for id,quest in pairs(Quest:GetQuestList()) do
				if (id == k) then
					GUI_NewButton(QM.Windows.Main.name, tostring(k).."["..quest.name.."]", "QMQuestEdit"..tostring(k), strings[gCurrentLanguage].quests)
					found = true
				end
				if (found) then
					break
				end
			end
			if (not found) then
				GUI_NewButton(QM.Windows.Main.name, tostring(k), "QMQuestEdit"..tostring(k), strings[gCurrentLanguage].quests)
			end
		end
		GUI_UnFoldGroup(QM.Windows.Main.name,strings[gCurrentLanguage].quests)
	end
	
	GUI_SizeWindow(QM.Windows.Main.name,Settings.FFXIVMINION.qmWindow.width,Settings.FFXIVMINION.qmWindow.height)
	GUI_RefreshWindow(QM.Windows.Main.name)
end
--**************************************************************************************************************************************
function QM.AddEncounter()
	local newEncounterIndex = TableSize(QM.Encounters) + 1
	QM.Encounters[newEncounterIndex] = { name = qEncounterName }
	QM.RefreshEncounters()
end
--**************************************************************************************************************************************
function QM.RefreshEncounters()
	GUI_DeleteGroup(QM.Windows.Main.name,strings[gCurrentLanguage].dutyEncounters)
	if (TableSize(QM.Encounters) > 0) then
		for k,v in spairs(QM.Encounters) do
			GUI_NewButton(QM.Windows.Main.name, tostring(k).."("..v.name..")", "QMEncounterEdit"..tostring(k), strings[gCurrentLanguage].dutyEncounters)
		end
		GUI_UnFoldGroup(QM.Windows.Main.name,strings[gCurrentLanguage].dutyEncounters)
	end
	
	GUI_SizeWindow(QM.Windows.Main.name,Settings.FFXIVMINION.qmWindow.width,Settings.FFXIVMINION.qmWindow.height)
	GUI_RefreshWindow(QM.Windows.Main.name)
end
--**************************************************************************************************************************************
function QM.EditEncounter(id)
	local encounterid = tonumber(id)
	local encounter = QM.Encounters[encounterid]
	
    local wnd = GUI_GetWindowInfo(QM.Windows.EncounterEditor.name)	
	
	QM.LoadTaskEditFields(step.type)
	GUI_MoveWindow( QM.Windows.StepEditor.name, wnd.x+wnd.width,wnd.y)
    
	eStepNum = stepid
	Settings.FFXIVMINION.eStepNum = eStepNum
	
	for task,fields in ipairs (QM.Builds.QuestTasksEdit[step.type]) do
		if (fields[2] ~= "GUI_NewButton") then
			local varName = fields[5]
			local varSetup = QM.Variables[varName]
			local profileString = varSetup.profile
			_G[varName] = step[profileString] or varSetup.default
			Settings.FFXIVMINION[varName] = _G[varName]
		end
	end
	
	GUI_WindowVisible(QM.Windows.StepEditor.name,true)
end
--**************************************************************************************************************************************
function QM.AddPreReq()
	local id = tonumber(eQuestID)
	
	if (qPreReqJob == "None" or qPreReqID == "") then 
		return 
	end
	
	local prID = tonumber(qPreReqID)
	local prJob = qPreReqJob == "All" and -1 or tonumber(FFXIV.JOBS[qPreReqJob])
	local prStep = tonumber(qPreReqStep)
	
	assert(type(prID) == "number", "PreReqID must be numeric.")
	if (type(QM.Quests[id].prereq) == "boolean") then
		if (prStep == 1) then
			QM.Quests[id].prereq = nil
			QM.Quests[id].prereq = {} 
		else
			d("Step is out of range.")
			return
		end
	end

	if (prStep > (TableSize(QM.Quests[id].prereq[prJob]) + 1)) then
		d("Step is out of range.")
		return
	end
	
	if (TableSize(QM.Quests[id].prereq[prJob]) == 0) then QM.Quests[id].prereq[prJob] = {} end
	
	if (QM.Quests[id].prereq[prJob][prStep] ~= nil) then
		QM.Quests[id].prereq[prJob] = QM.TableInsertSort(QM.Quests[id].prereq[prJob], prStep, prID)
	else
		QM.Quests[id].prereq[prJob][prStep] = prID
	end
	
	QM.RefreshPreReqs()
end
--**************************************************************************************************************************************
function QM.RemovePreReq(key)
	local id = tonumber(eQuestID)
	
	local t = QM.StringToTable(key,";")
	local prJob = tonumber(t[1])
	local prStep = tonumber(t[2])
	local tSize = TableSize(QM.Quests[id].prereq[prJob])
	
	if (tSize == 1) then
		--Last entry for the job, just nix the table.
		QM.Quests[id].prereq[prJob] = nil
		
		--If it was our only table, nix the prereqs completely.
		if (TableSize(QM.Quests[id].prereq) == 0) then
			QM.Quests[id].prereq = nil
			QM.Quests[id].prereq = false
		end
	elseif (tSize == prStep) then
		--Highest entry in the list, just nix the entry.
		QM.Quests[id].prereq[prJob][prStep] = nil
	else
		--Entry is somewhere in the middle, need to reorder it.
		QM.Quests[id].prereq[prJob] = QM.TableRemoveSort(QM.Quests[id].prereq[prJob], prStep)
	end
	QM.RefreshPreReqs()
end
--**************************************************************************************************************************************
function QM.RefreshPreReqs()
	local id = tonumber(eQuestID)
	
	GUI_DeleteGroup(QM.Windows.PreReqEditor.name,"PreReqs")
	local unfold = false
	if (type(QM.Quests[id].prereq) ~= "boolean") then
		for job,list in pairs(QM.Quests[id].prereq) do
			if TableSize(list) > 0 then
				for step, preReq in spairs(list) do
					GUI_NewButton(QM.Windows.PreReqEditor.name, tostring(job).."["..tostring(step).."] - "..tostring(preReq), "QMPreReqRemove"..tostring(job)..";"..tostring(step), "PreReqs")
					unfold = true
				end
			end 
		end
	end
		
	if (unfold) then
		GUI_UnFoldGroup(QM.Windows.PreReqEditor.name,"PreReqs")
	end
	
	local wnd = QM.Windows.PreReqEditor
	GUI_SizeWindow(wnd.name,wnd.width,wnd.height)
	GUI_RefreshWindow(wnd.name)
end
--**************************************************************************************************************************************
function QM.ClearPreReqs()
	local id = tonumber(eQuestID)
	QM.Quests[id].prereq = nil
	QM.Quests[id].prereq = false
	QM.RefreshPreReqs()
end
--**************************************************************************************************************************************
function QM.AddStepItem()
	local stepid = tonumber(eStepNum)
	local quest = tonumber(eQuestID)
	local step = QM.Quests[quest].steps[stepid]
	
	if (not ValidTable(step.itemid)) then
		step.itemid = {}
	end
	
	local job = qTaskItemJobReq == "None" and -1 or tonumber(FFXIV.JOBS[qTaskItemJobReq])
	local item = tonumber(qTaskItemID)
	
	step.itemid[job] = item
	
	QM.Quests[quest].steps[stepid] = step
	QM.RefreshStepItems()
end
--**************************************************************************************************************************************
function QM.RefreshStepItems()
	local stepid = tonumber(eStepNum)
	local quest = tonumber(eQuestID)
	local step = QM.Quests[quest].steps[stepid]
	
	GUI_DeleteGroup(QM.Windows.ItemEditor.name,GetString("items"))
	
	if (ValidTable(step.itemid)) then
		for job,item in pairs(step.itemid) do
			GUI_NewButton(QM.Windows.ItemEditor.name, tostring(item).."["..tostring(job).."]","QMItemRemove"..tostring(quest)..";"..tostring(stepid)..";"..tostring(job), GetString("items"))
		end
			
		GUI_UnFoldGroup(QM.Windows.ItemEditor.name,GetString("items"))
	end
	
	for k,v in pairs(QM.Quests[quest].steps[stepid]) do
		d("k="..tostring(k)..",v="..tostring(v))
	end
	
	local wnd = QM.Windows.ItemEditor
	GUI_SizeWindow(wnd.name,wnd.width,wnd.height)
	GUI_RefreshWindow(wnd.name)
end
--**************************************************************************************************************************************
function QM.ClearStepItems()
	local stepid = tonumber(eStepNum)
	local quest = tonumber(eQuestID)
	
	QM.Quests[quest].steps[stepid].itemid = nil
	QM.RefreshStepItems()
end
--**************************************************************************************************************************************
function QM.RemoveStepItem(itemstring)
	local i = 0
	local components = {}
	for _, component in StringSplit(itemstring,";") do
		components[i] = tonumber(component)
		i = i + 1
	end
	
	local quest = components[0]
	local stepid = components[1]
	local job = components[2]
	
	QM.Quests[quest].steps[stepid].itemid[job] = nil
	QM.RefreshStepItems()
end
--**************************************************************************************************************************************
function QM.AddTurnover()
	local id = tonumber(eQuestID)
	local step = tonumber(qTurnoverStep)
	local key = 1
	
	--In case the step has not yet been created, add the turnin to the blank step.
	--When the step is added, have it detect this scenario.
	if (TableSize(QM.Quests[id].steps[step]) == 0) then
		QM.Quests[id].steps[step] = {}
	end
	
	if (TableSize(QM.Quests[id].steps[step].itemturninid) == 0) then 
		QM.Quests[id].steps[step].itemturninid = {} 
	end
	
	key = TableSize(QM.Quests[id].steps[step].itemturninid) + 1
	
	QM.Quests[id].steps[step].itemturninid[key] = tonumber(qTurnoverID)
	QM.RefreshTurnovers()
end
--**************************************************************************************************************************************
function QM.RefreshTurnovers()
	local id = tonumber(eQuestID)
	
	GUI_DeleteGroup(QM.Windows.TurnInEditor.name,"Turnovers")
	
	local unfold = false
	for k,v in ipairs(QM.Quests[id].steps) do
		if (TableSize(v.itemturninid) > 0) then
			QM.Quests[id].steps[k].itemturnin = true
			for i,item in pairs(v.itemturninid) do
				GUI_NewButton(QM.Windows.TurnInEditor.name, tostring(item).."["..tostring(k).."]["..tostring(i).."]", "QMTurnoverRemove"..tostring(item), "Turnovers")
				unfold = true
			end
		else
			QM.Quests[id].steps[k].itemturnin = false
		end
	end
		
	if (unfold) then
		GUI_UnFoldGroup(QM.Windows.TurnInEditor.name,"Turnovers")
	end
	
	local wnd = QM.Windows.TurnInEditor
	GUI_SizeWindow(wnd.name,wnd.width,wnd.height)
	GUI_RefreshWindow(wnd.name)
end
--**************************************************************************************************************************************
function QM.RemoveTurnover(item)
	local id = tonumber(eQuestID)
	local step = nil
	local key = nil
	local item = tonumber(item)
	local tSize = 0
	
	for k,v in spairs(QM.Quests[id].steps) do
		if (TableSize(v.itemturninid) > 0) then
			tSize = TableSize(v.itemturninid)
			for x,y in pairs(v.itemturninid) do
				if (tonumber(y) == item) then
					step = tonumber(k)
					key = tonumber(x)
					break
				end
			end
		end
	end
	
	if (tSize == 1) then
		QM.Quests[id].steps[step].itemturninid = nil
		QM.Quests[id].steps[step].itemturninid = 0
	else
		QM.Quests[id].steps[step].itemturninid[key] = nil
	end
	QM.RefreshTurnovers()
end
--**************************************************************************************************************************************
function QM.ClearTurnovers()
	local id = tonumber(eQuestID)
	local step = tonumber(qTurnoverStep)
	
	QM.Quests[id].steps[step].itemturninid = nil
	QM.Quests[id].steps[step].itemturninid = 0
	QM.RefreshTurnovers()
end
--**************************************************************************************************************************************
function QM.AddStep()
	local task = {}
	
	for k,v in ipairs (QM.Builds.QuestTasks[qStepTask]) do
		local value = _G[v[5]]
		if (v[2] ~= "GUI_NewButton" and value ~= nil and value ~= "") then
			local var = QM.Variables[v[5]]
			if var.profile ~= "" and value ~= "" then
				if var.cast == "number" then
					task[var.profile] = tonumber(value)
				elseif var.cast == "string" then
					task[var.profile] = tostring(value)
				end
			end
		end
	end
	
	if (task.itemrewardslot ~= nil and task.itemrewardslot > 0) then
		task.itemrewardslot = task.itemrewardslot - 1
		task.itemreward = true
	else
		task.itemreward = false
	end
	
	
	local pos = Player.pos
	task.pos = {
		["x"] = pos.x;
		["y"] = pos.y;
		["z"] = pos.z;
	};
	
	local id = tonumber(eQuestID)
	local step = tonumber(qStepNum)
	
	--If this is not the first step, and the previous step's map is the same, nix the mesh to prevent extra loading.
	--[[
	if (step > 1 and task.meshname ~= nil) then
		if (QM.Quests[id].steps[step-1].mapid == task.mapid) then
			task.meshname = nil
		end
	end	
	--]]
	
	if (ValidTable(QM.Quests[id].steps[step])) then
		--If the task is nil and there's an itemturnin, add it in with the current task we are adding, and insert as-is.
		if (QM.Quests[id].steps[step].type == nil) then
			if (TableSize(QM.Quests[id].steps[step].itemturninid) > 0) then 
				task.itemturninid = {}
				task.itemturninid = QM.Quests[id].steps[step].itemturninid
				task.itemturnin = true
			end
			QM.Quests[id].steps[step] = task
		else
			QM.Quests[id].steps = QM.TableInsertSort(QM.Quests[id].steps, step, task)
		end
	else
		QM.Quests[id].steps[step] = {}
		QM.Quests[id].steps[step] = task
	end
	
	QM.LoadTaskFields()
end
--**************************************************************************************************************************************
function QM.SaveStep()
	local id = tonumber(eQuestID)
	local step = tonumber(eStepNum)
	local task = QM.Quests[id].steps[step]
	
	for k,v in ipairs (QM.Builds.QuestTasksEdit[eStepTask]) do
		local value = _G[v[5]]
		if (v[2] ~= "GUI_NewButton" and value ~= nil and value ~= "") then
			local var = QM.Variables[v[5]]
			if var.profile ~= "" and value ~= "" then
				if var.cast == "number" then
					task[var.profile] = tonumber(value)
				elseif var.cast == "string" then
					task[var.profile] = tostring(value)
				end
			end
		end
	end
	
	if (task.itemrewardslot ~= nil and task.itemrewardslot > 0) then
		task.itemrewardslot = task.itemrewardslot - 1
		task.itemreward = true
	else
		task.itemreward = false
	end
	
	local pos = Player.pos
	task.pos = {
		["x"] = pos.x;
		["y"] = pos.y;
		["z"] = pos.z;
	};
	
	QM.Quests[id].steps[step] = task
	
	QM.LoadTaskFields()
	GUI_WindowVisible(QM.Windows.ItemEditor.name,false)
	GUI_WindowVisible(QM.Windows.StepEditor.name,false)
end
--**************************************************************************************************************************************
function QM.EditStep(id)
	local stepid = tonumber(id)
	local quest = tonumber(eQuestID)
    local wnd = GUI_GetWindowInfo(QM.Windows.StepManager.name)	
	local step = QM.Quests[quest].steps[stepid]
	
	QM.LoadTaskEditFields(step.type)
	GUI_MoveWindow( QM.Windows.StepEditor.name, wnd.x+wnd.width,wnd.y)
    
	eStepNum = stepid
	Settings.FFXIVMINION.eStepNum = eStepNum
	
	for task,fields in ipairs (QM.Builds.QuestTasksEdit[step.type]) do
		if (fields[2] ~= "GUI_NewButton") then
			local varName = fields[5]
			local varSetup = QM.Variables[varName]
			local profileString = varSetup.profile
			_G[varName] = step[profileString] or varSetup.default
			Settings.FFXIVMINION[varName] = _G[varName]
		end
	end
	
	GUI_WindowVisible(QM.Windows.StepEditor.name,true)
end
--**************************************************************************************************************************************
function QM.RemoveStep()
	local quest = tonumber(eQuestID)
	local step = tonumber(eStepNum)
	local tSize = TableSize(QM.Quests[quest].steps)
	
	if (tSize == 1) then
		--Last entry, nix the table.
		QM.Quests[quest].steps = nil
	elseif (tSize == step) then
		--Highest entry, nix the entry.
		QM.Quests[quest].steps[step] = nil
	else
		--Table needs to be reordered
		QM.Quests[quest].steps = QM.TableRemoveSort(QM.Quests[quest].steps, step)
	end
	GUI_WindowVisible( QM.Windows.StepEditor.name, false)
	QM.LoadTaskFields()
end
--**************************************************************************************************************************************
function QM.StepPriorityUp()
	local quest = tonumber(eQuestID)
    local step = tonumber(eStepNum)
	
	if (step > 1) then
		QM.Quests[quest].steps = QM.TableShiftEntry(QM.Quests[quest].steps, step, "up")
		QM.LoadTaskFields()
		QM.EditStep(step-1)
	end
end
--**************************************************************************************************************************************
function QM.StepPriorityDown()
	local quest = tonumber(eQuestID)
    local step = tonumber(eStepNum)
	
	if (step < TableSize(QM.Quests[quest].steps)) then
		QM.Quests[quest].steps = QM.TableShiftEntry(QM.Quests[quest].steps, step, "down")
		QM.LoadTaskFields()
		QM.EditStep(step+1)
	end
end
--**************************************************************************************************************************************
function QM.ClearSteps()
    QM.Quests[tonumber(eQuestID)].steps = {}
	QM.LoadTaskFields()
end
--**************************************************************************************************************************************
function QM.LoadTypeOptions()
	QM.CurrentStep = 1
	
	--Reload the profile list for the selected type.
	local profiles = "None"
	local profilelist = {}
	
	if (qProfileType == "Duty") then
		profilelist = dirlist(QM.DutyPath,".*info")
	else
		profilelist = dirlist(QM.QuestPath,".*info")
	end
	
	if ( TableSize(profilelist) > 0) then			
		local i,profile = next ( profilelist)
		while i and profile do				
			profile = string.gsub(profile, ".info", "")
			profiles = profiles..","..profile
			i,profile = next ( profilelist,i)
		end		
	end
	qProfileName_listitems = profiles

	
	for k,v in ipairs(QM.Builds.LoadTypeOptions) do
		GUI_DeleteGroup(v[1],v[2])
	end
	
	local unfoldGroups = {}
	local t = QM.Builds[qProfileType]
	for k,v in ipairs(t) do
		local args = v[1]
		if (args == 3) then
			_G[v[2]](v[3],v[4],v[5])
		elseif (args == 4) then
			_G[v[2]](v[3],v[4],v[5],v[6])
			unfoldGroups[v[6]] = true
		elseif (args == 5) then
			local list
			if (type(v[7]) == "string") then
				list = v[7]
			else
				list = v[7]()
			end
			_G[v[2]](v[3],v[4],v[5],v[6],list)
			unfoldGroups[v[6]] = true
		end
	end
	
	QM.LoadVariables()
	
	for k,v in pairs(unfoldGroups) do
		GUI_UnFoldGroup(QM.Windows.Main.name,tostring(k))
	end
	GUI_SizeWindow(QM.Windows.Main.name,Settings.FFXIVMINION.qmWindow.width,Settings.FFXIVMINION.qmWindow.height)
	GUI_RefreshWindow(QM.Windows.Main.name)
end
--**************************************************************************************************************************************
function QM.LoadTaskFields()	

	GUI_DeleteGroup(QM.Windows.StepManager.name,strings[gCurrentLanguage].newQuestStep)
	local t = QM.Builds.QuestTasks[qStepTask]
	for k,v in ipairs(t) do
		local args = v[1]
		if (args == 3) then
			_G[v[2]](v[3],v[4],v[5])
		elseif (args == 4) then
			_G[v[2]](v[3],v[4],v[5],v[6])
		elseif (args == 5) then
			local list
			if (type(v[7]) == "string") then
				list = v[7]
			else
				list = v[7]()
			end
			_G[v[2]](v[3],v[4],v[5],v[6],list)
		end
	end
	
	QM.LoadVariables()
	
	GUI_UnFoldGroup(QM.Windows.StepManager.name,strings[gCurrentLanguage].newQuestStep)
	
	local id = tonumber(eQuestID)
	local maxStep = 0
	
	GUI_DeleteGroup(QM.Windows.StepManager.name,"Steps")
	if (TableSize(QM.Quests[id].steps) > 0) then
		for k,v in spairs(QM.Quests[tonumber(eQuestID)].steps) do
			GUI_NewButton(QM.Windows.StepManager.name, tostring(v.type).."["..tostring(k).."]", "QMStepEdit"..tostring(k), "Steps")
			if k > maxStep then maxStep = tonumber(k) end
		end
		GUI_UnFoldGroup(QM.Windows.StepManager.name,"Steps")
	end	
	
	maxStep = maxStep + 1
	qStepNum = maxStep
	Settings.FFXIVMINION.qStepNum = qStepNum
	qTurnoverStep = maxStep
	Settings.FFXIVMINION.qTurnoverStep = qTurnoverStep
	
	local wnd = QM.Windows.StepManager
	GUI_SizeWindow(wnd.name,wnd.width,wnd.height)
	GUI_RefreshWindow(wnd.name)
end
--**************************************************************************************************************************************
function QM.LoadTaskEditFields(steptype, preserve)
	preserve = preserve or false

	GUI_DeleteGroup(QM.Windows.StepEditor.name,strings[gCurrentLanguage].editQuestStep)
	local t = QM.Builds.QuestTasksEdit[steptype]
	for k,v in ipairs(t) do
		local args = v[1]
		if (args == 3) then
			_G[v[2]](v[3],v[4],v[5])
		elseif (args == 4) then
			_G[v[2]](v[3],v[4],v[5],v[6])
		elseif (args == 5) then
			local list
			if (type(v[7]) == "string") then
				list = v[7]
			else
				list = v[7]()
			end
			_G[v[2]](v[3],v[4],v[5],v[6],list)
		end
	end
	
	GUI_UnFoldGroup(QM.Windows.StepEditor.name,strings[gCurrentLanguage].editQuestStep)
	QM.LoadVariables()
	
	local wnd = QM.Windows.StepEditor
	GUI_SizeWindow(wnd.name,wnd.width,wnd.height)
	GUI_RefreshWindow(wnd.name)
end
--**************************************************************************************************************************************
function QM.LoadVariables()
	for k,v in pairs(QM.Variables) do
		--d("k="..tostring(k)..", setting="..tostring(Settings.FFXIVMINION[k]))
		_G[k] = Settings.FFXIVMINION[k]
	end
end
--**************************************************************************************************************************************
function QM.PushVariables()
	for k,v in pairs(QM.Variables) do
		if Settings.FFXIVMINION[tostring(k)] ~= _G[tostring(k)] then
			Settings.FFXIVMINION[tostring(k)] = _G[tostring(k)]
		end
	end
end
--**************************************************************************************************************************************
function QM.LoadCurrentValues(strWindow)
	if (strWindow == "add") then
		local target = Player:GetTarget()
		if (target ~= nil) then
			qTaskKillTarget = target.uniqueid
			qTaskNPC = target.uniqueid
		end
		qTaskMesh = tostring(gmeshname)
		qTaskMap = Player.localmapid
	elseif (strWindow == "edit") then
		local target = Player:GetTarget()
		if (target ~= nil) then
			eTaskKillTarget = target.uniqueid
			eTaskNPC = target.uniqueid
		end
		eTaskMesh = tostring(gmeshname)
		eTaskMap = Player.localmapid
	end
		
	QM.PushVariables()
end
--**************************************************************************************************************************************
function QM.LoadAddCurrentValues()
	QM.LoadCurrentValues("add")
end
--**************************************************************************************************************************************
function QM.LoadEditCurrentValues()
	QM.LoadCurrentValues("edit")
end
--**************************************************************************************************************************************
function QM.PullTurnoverItem()
	local slot = tonumber(qTurnoverSlot)
	QM.LoadItemSlot(slot, "qTurnoverID")
end
function QM.PullTaskAddItem()
	local slot = tonumber(qTaskItemSelector)
	QM.LoadItemSlot(slot, "qTaskItemID")
end
function QM.PullTaskEditItem()
	local slot = tonumber(eTaskItemSelector)
	QM.LoadItemSlot(slot, "eTaskItemID")
end

function QM.LoadItemSlot( numSlot, strVar )
	local inv = Inventory("type=2004")
	if (inv) then
		local item = inv[numSlot]
		if (item) then
			_G[strVar] = tonumber(item.id)
		else
			_G[strVar] = 0
		end
	end
end
--**************************************************************************************************************************************
function QM.LoadWindowFields(window)

	local unfoldGroups = {}
	local t = QM.Builds[window]
	
	--Cycle through the GUI elements for this window and load them, and unfold any necessary groups.
	for k,v in spairs(t) do
		local args = v[1]
		if (args == 2) then
			_G[v[2]](v[3],v[4])
		elseif (args == 3) then
			_G[v[2]](v[3],v[4],v[5])
		elseif (args == 4) then
			_G[v[2]](v[3],v[4],v[5],v[6])
			unfoldGroups[v[6]] = true
		elseif (args == 5) then
			local list
			if (type(v[7]) == "string") then
				list = v[7]
			else
				list = v[7]()
			end
			_G[v[2]](v[3],v[4],v[5],v[6],list)
			unfoldGroups[v[6]] = true
		end
	end
	
	QM.LoadVariables()
	
	for k,v in pairs(unfoldGroups) do
		GUI_UnFoldGroup(QM.Windows[window].name,tostring(k))
	end
end
--**************************************************************************************************************************************
function QM.LoadWindows()	
	local windows = QM.Windows
	local WI = Settings.FFXIVMINION.qmWindow
	--The main window is used as the base x,y.
	--We use sizes and window offsets in the windows QM.Windows table to manage exact sizing/positions if necessary.
	
	for k,v in pairs(windows) do
		if (TableSize(QM.Builds[k]) > 0) then
			local wname = v.name
			if (wname == strings[gCurrentLanguage].profileManager) then
				GUI_NewWindow	(wname,WI.x,WI.y,v.width,v.height)
			else
				GUI_NewWindow	(wname,WI.x,WI.y,v.width,v.height,"",true)
			end 
			QM.LoadWindowFields(k)
			GUI_SizeWindow	(wname,v.width,v.height)
			GUI_RefreshWindow(wname)
			GUI_WindowVisible(wname, v.visibleDefault)
		end
	end
end
--**************************************************************************************************************************************
function QM.WindowUpdate()	
	
	local WI = Settings.FFXIVMINION.qmWindow
	local W = GUI_GetWindowInfo(QM.Windows.Main.name)
	local WindowInfo = {}
	
	if (WI.width ~= W.width) then WindowInfo.width = W.width else WindowInfo.width = WI.width end
	if (WI.height ~= W.height) then WindowInfo.height = W.height else WindowInfo.height = WI.height	end
	if (WI.x ~= W.x) then WindowInfo.x = W.x else WindowInfo.x = WI.x end
	if (WI.y ~= W.y) then WindowInfo.y = W.y else WindowInfo.y = WI.y end

	if (WindowInfo ~= nil and WindowInfo ~= WI) then Settings.FFXIVMINION.qmWindow = WindowInfo end
end
--**************************************************************************************************************************************
function QM.WindowToggle(event)
	local window = string.gsub(event,"QMToggle","")
	
	if (QM.Windows[window].base ~= nil) then
		local wnd = GUI_GetWindowInfo(QM.Windows[QM.Windows[window].base].name)
		GUI_MoveWindow(QM.Windows[window].name, wnd.x+wnd.width, wnd.y)
	end
	
	GUI_WindowVisible(QM.Windows[window].name,not QM.Windows[window].visible)
	QM.Windows[window].visible = not QM.Windows[window].visible
	
	if (QM.Windows[window].onOpen ~= nil) then
		QM.ExecuteFunction(tostring(QM.Windows[window].onOpen))
	end
end
--**************************************************************************************************************************************
function QM.OnUpdateHandler( Event, ticks ) 		
	if (TimeSince(QM.WindowTick) > 10000) then
		QM.WindowTick = ticks
		QM.WindowUpdate()
	end
end
--**************************************************************************************************************************************
function QM.HandleButtons( Event, Button )	
	if ( Event == "GUI.Item" ) then
		if (string.find(Button,"QMQuestEdit") ~= nil) then
			QM.EditQuest(string.gsub(Button,"QMQuestEdit",""))
		elseif (string.find(Button,"QMEncounterEdit") ~= nil) then
			QM.EditEncounter(string.gsub(Button,"QMEncounterEdit",""))
		elseif (string.sub(Button,1,10) == "QMStepEdit") then
			QM.EditStep(string.gsub(Button,"QMStepEdit",""))
		elseif (string.sub(Button,1,12) == "QMStepRemove") then
			QM.RemoveStep(string.gsub(Button,"QMStepRemove",""))
		elseif (string.sub(Button,1,12) == "QMItemRemove") then
			QM.RemoveStepItem(string.gsub(Button,"QMItemRemove",""))
		elseif (string.sub(Button,1,14) == "QMPreReqRemove") then
			QM.RemovePreReq(string.gsub(Button,"QMPreReqRemove",""))
		elseif (string.sub(Button,1,16) == "QMTurnoverRemove") then
			QM.RemoveTurnover(string.gsub(Button,"QMTurnoverRemove",""))
		elseif (string.sub(Button,1,8) == "QMToggle") then
			QM.WindowToggle(Button)
		elseif (string.sub(Button,1,3) == "QM.") then
			QM.ExecuteFunction(Button)
		end
	end
end
--**************************************************************************************************************************************
function QM.ExecuteFunction(strFunction)
	if strFunction == nil then
		return
	end
	
	local t = QM.StringToTable(strFunction,";")
	local start = 1
	local finish = TableSize(t)
	
	for x = start,finish do
		local f = _G
		for v in t[x]:gmatch("[^%.]+") do
			f=f[v]
		end
		f()
	end
end
--**************************************************************************************************************************************
function QM.StringToTable(str, delimiter)
    local t = {}
    local search = "(.-)" .. delimiter
	local last_char = 1
	local i = 1
	str = string.gsub(str,"\r","")
	
	local index, char, data = str:find(search,1)
	while index do
		if data ~= "" then
			t[i] = data
		end
		last_char = char+1
		index, char, data = str:find(search, last_char)
		i = i + 1
	end
	
	if last_char <= #str then
		data = str:sub(last_char)
		t[i] = data
	end
	
	return t
end

function QM.TableShiftEntry(tblSort, iKey, strDirection)
	local temp = {}
	local t = tblSort
	local p = iKey
	local size = TableSize(t)
	
	if (strDirection == "up" and p > 1) then
		temp = t[p-1]
		t[p-1] = t[p]
		t[p] = temp
		
		return t
	elseif (strDirection == "down" and p < size) then
		temp = t[p+1]
		t[p+1] = t[p]
		t[p] = temp
		
		return t
	else
		return t
	end
end

function QM.TableInsertSort(tblSort, iInsertPoint, vInsertValue)
	assert(type(tblSort) == "table", "First parameter must be the table to sort.")
	assert(type(iInsertPoint) == "number", "Second parameter must be an integer insertion point.")
	assert(vInsertValue ~= nil, "Third parameter must be a non-null variant to be inserted.")
	
	local orderedTable = {}
	local tempTable = {}
	local t = tblSort
	local p = iInsertPoint
	local size = TableSize(t)
	
	if (size < p) then
		t[p] = vInsertValue
		orderedTable = t
	else
		for k,v in spairs(t) do
			if (tonumber(k) >= p) then
				tempTable[tonumber(k)+1] = v
			end
		end
			
		local x = (TableSize(t) + 1)
		for i=1,x do
			if i < p then
				orderedTable[i] = t[i]
			elseif i == p then
				orderedTable[i] = vInsertValue
			elseif i > p then
				orderedTable[i] = tempTable[i]
			end
		end
	end
	return orderedTable
end

function QM.TableRemoveSort(tblSort, iRemovePoint)
	assert(type(tblSort) == "table", "First parameter must be the table to sort.")
	assert(type(iRemovePoint) == "number", "Second parameter must be an integer insertion point.")
	
	local orderedTable = {}
	local tempTable = {}
	local t = tblSort
	local p = iRemovePoint
	local size = TableSize(t)
	
	assert(not(p > size or p < 1), "Removal point is out of range.")
	
	if (size == p) then
		t[p] = nil
		orderedTable = t
	else
		for k,v in spairs(t) do
			if tonumber(k) > p then
				tempTable[tonumber(k)-1] = v
			end
		end
		
		local x = (TableSize(t) - 1)
		
		for i=1,x do
			if i < p then
				orderedTable[i] = t[i]
			elseif i >= p then
				orderedTable[i] = tempTable[i]
			end
		end
	end
	return orderedTable
end

function spairs(t, order)
    -- collect the keys
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end

    -- if order function given, sort by it by passing the table and keys a, b,
    -- otherwise just sort the keys 
    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end

RegisterEventHandler("GUI.Item", QM.HandleButtons )
RegisterEventHandler("Module.Initalize",QM.Init)
RegisterEventHandler("Gameloop.Update", QM.OnUpdateHandler)
RegisterEventHandler("GUI.Update",QM.GUIVarUpdate)
