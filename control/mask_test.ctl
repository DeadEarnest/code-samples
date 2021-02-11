



const string Mask_Test_Dpt1 = "Test_Mask";

string Mask_SubprojPath;
string Mask_Test_IoFile1Path;




dyn_string CspaCore_Mask_RunTestsSetup(string subprojPath)
{
	Mask_SubprojPath = StringTools_GetWithReplacements(
		subprojPath, "\\", "/");
	Mask_Test_IoFile1Path = Mask_SubprojPath +
		"data/cspa.core/test.data/cfg/general/arr.aggr.io";
	
	Mask_RecreateTestDpes();
	return Cspa_Mask_Tests;
}

CspaCore_Mask_RunTestsTeardown(string subprojPath)
{
	Mask_DeleteTestDpt();
}




Mask_RecreateTestDpes()
{
	Mask_DeleteTestDpt();
	Mask_CreateTestDpt();
	Mask_CreateTestDps();
}

Mask_DeleteTestDpt()
{
	if(DpTools_DpTypeExists(Mask_Test_Dpt1))
		DpTools_DeleteDpt(Mask_Test_Dpt1, getSystemId());
}

Mask_CreateTestDpt()
{
	dyn_dyn_string elements1 = makeDynAnytype(
		makeDynString(Mask_Test_Dpt1, "")
		, makeDynString("", "Value"));
	dyn_dyn_int types1 = makeDynAnytype(
		makeDynInt(DPEL_STRUCT, 0)
		, makeDynInt(0, DPEL_DYN_BOOL));
	dpTypeCreate(elements1, types1);
}

Mask_CreateTestDps()
{
	dpCreate(Mask_Test_Dpt1 + "_ver_Earthquake", Mask_Test_Dpt1);
	dpCreate(Mask_Test_Dpt1 + "_ver_LeakSou", Mask_Test_Dpt1);
	dpCreate(Mask_Test_Dpt1 + "_ver_Stop", Mask_Test_Dpt1);
	dpCreate(Mask_Test_Dpt1, Mask_Test_Dpt1);
}




dyn_string Cspa_Mask_Tests = makeDynString
(
	"Mask_SumCmdCalculate_TakesSetCmd_ResetCmd_ControlFlag_GivesSubj"
	
	, "Mask_OutMaskCanBeSet_SaysYes_OnlyIfSectorNotActive_OrDefNotActivated"
	, "Mask_InMaskCanBeSetFor1Def_SaysYes_OnlyIfSectorNotActive_OrDefInNotActivated_OrOutMaskSet"
	, "Mask_InMaskCanBeSetForAllDefs_SaysSubj"
	
	, "Mask_CmdIsRejected_SaysNo_IfNoCmd_PrevMaskAny_ExpectedMaskAny_ResultMaskAny"
	, "Mask_CmdIsRejected_SaysNo_IfCmd_PrevMask_IsNotResultMask_ExpectedMask_IsResultMask"
	, "Mask_CmdIsRejected_SaysYes_IfCmd_PrevMask_IsExpectedMask_PrevMask_IsResultMask"
	, "Mask_CmdIsRejected_SaysYes_IfCmd_ExpectedMask_IsNotResultMask"
	
	, "Mask_Form_ResetsMask_IfSumCmdReset_OtherFlagsAny"
	, "Mask_Form_KeepsMask_IfSumCmdNone_OtherFlagsAny"
	, "Mask_Form_KeepsMask_IfSumCmdSet_MaskCanBeSetAny_OutMask"
	, "Mask_Form_SetsMaskIfCan_IfSumCmdSet_MaskCanBeSetAny_NoOutMask"
	
	, "Mask_DefsOutFlagsForm_GivesSubjForAllDefenses"
	
	, "MaskM_InputTypeFlagsForm_GivesSubjForOneDefense"
	, "Mask_InputTypesFlagsForm_GivesSubjForAllDefenses"
	
	, "Mask_OutputForm_GivesMasksFlags_OutMasksFlags_ForAllDefenses"
	
	, "M_DefIsActivatedByValve_GivesFlagAtProperIdx"
	, "M_DefIsActivatedByPressure_GivesFlagAtProperIdx"
	, "M_DefIsActivatedByLeak_ChecksIfTimerExpired"
	, "M_DefIsActivatedByPressureDiff_ChecksIfTimerExpired"
);




M_DefIsActivatedByPressureDiff_ChecksIfTimerExpired()
{
	M_Func_ChecksIfTimerExpired("M_DefIsActivatedByPressureDiff");
}

M_DefIsActivatedByLeak_ChecksIfTimerExpired()
{
	M_Func_ChecksIfTimerExpired("M_DefIsActivatedByLeak");
}

M_Func_ChecksIfTimerExpired(string func)
{
	dyn_float inputStateFlags1 = DynTools_MakeDynFloat(4, Timers_Active1);
	int inputIdx1 = 1;
	inputStateFlags1[1] = Timers_Expired;
	bool expected1 = true;
	mixed actual1 = callFunction(func, inputStateFlags1, -1, -1, -1, inputIdx1);
	
	dyn_float inputStateFlags2 = DynTools_MakeDynFloat(4, Timers_Active1);
	int inputIdx2 = 1;
	bool expected2 = false;
	mixed actual2 = callFunction(func, inputStateFlags2, -1, -1, -1, inputIdx2);
	
	dyn_float inputStateFlags3 = DynTools_MakeDynFloat(4, Timers_Active1);
	int inputIdx3 = 4;
	inputStateFlags3[4] = Timers_Expired;
	bool expected3 = true;
	mixed actual3 = callFunction(func, inputStateFlags3, -1, -1, -1, inputIdx3);
	
	dyn_float inputStateFlags4 = DynTools_MakeDynFloat(4, Timers_Active1);
	int inputIdx4 = 4;
	inputStateFlags4[4] = Timers_Expired;
	bool expected4 = true;
	mixed actual4 = callFunction(func, inputStateFlags4, -1, -1, -1, inputIdx4);
	
	TestTools_AssertEqualsMultiple(
		expected1, actual1
		, expected2, actual2
		, expected3, actual3
		, expected4, actual4
	);
}




M_DefIsActivatedByPressure_GivesFlagAtProperIdx()
{
	dyn_bool inputStateFlags1 = DynTools_MakeDynBool(4, false);
	int defIdx1 = 1;
	int inputIdx1 = 1;
	inputStateFlags1[1] = true;
	bool expected1 = true;
	mixed actual1 = M_DefIsActivatedByPressure(
		inputStateFlags1, -1, -1, defIdx1, inputIdx1
	);
	
	dyn_bool inputStateFlags2 = DynTools_MakeDynBool(4, false);
	int defIdx2 = 2;
	int inputIdx2 = 1;
	inputStateFlags2[2] = true;
	bool expected2 = true;
	mixed actual2 = M_DefIsActivatedByPressure(
		inputStateFlags2, -1, -1, defIdx2, inputIdx2
	);
	
	dyn_bool inputStateFlags3 = DynTools_MakeDynBool(4, false);
	int defIdx3 = 1;
	int inputIdx3 = 2;
	inputStateFlags3[3] = true;
	bool expected3 = true;
	mixed actual3 = M_DefIsActivatedByPressure(
		inputStateFlags3, -1, -1, defIdx3, inputIdx3
	);
	
	dyn_bool inputStateFlags4 = DynTools_MakeDynBool(4, false);
	int defIdx4 = 2;
	int inputIdx4 = 2;
	inputStateFlags4[4] = true;
	bool expected4 = true;
	mixed actual4 = M_DefIsActivatedByPressure(
		inputStateFlags4, -1, -1, defIdx4, inputIdx4
	);
	
	TestTools_AssertEqualsMultiple(
		expected1, actual1
		, expected2, actual2
		, expected3, actual3
		, expected4, actual4
	);
}




M_DefIsActivatedByValve_GivesFlagAtProperIdx()
{
	dyn_bool inputStateFlags1 = DynTools_MakeDynBool(10, false);
	int defIdx1 = 1;
	int inputIdx1 = 1;
	inputStateFlags1[6] = true;
	bool expected1 = true;
	mixed actual1 = M_DefIsActivatedByValve(
		inputStateFlags1, -1, -1, defIdx1, inputIdx1
	);
	
	dyn_bool inputStateFlags2 = DynTools_MakeDynBool(10, false);
	int defIdx2 = 2;
	int inputIdx2 = 1;
	inputStateFlags2[2] = true;
	bool expected2 = true;
	mixed actual2 = M_DefIsActivatedByValve(
		inputStateFlags2, -1, -1, defIdx2, inputIdx2
	);
	
	dyn_bool inputStateFlags3 = DynTools_MakeDynBool(20, false);
	int defIdx3 = 1;
	int inputIdx3 = 2;
	inputStateFlags3[16] = true;
	bool expected3 = true;
	mixed actual3 = M_DefIsActivatedByValve(
		inputStateFlags3, -1, -1, defIdx3, inputIdx3
	);
	
	dyn_bool inputStateFlags4 = DynTools_MakeDynBool(20, false);
	int defIdx4 = 2;
	int inputIdx4 = 2;
	inputStateFlags4[12] = true;
	bool expected4 = true;
	mixed actual4 = M_DefIsActivatedByValve(
		inputStateFlags4, -1, -1, defIdx4, inputIdx4
	);
	
	TestTools_AssertEqualsMultiple(
		expected1, actual1
		, expected2, actual2
		, expected3, actual3
		, expected4, actual4
	);
}




Mask_OutputForm_GivesMasksFlags_OutMasksFlags_ForAllDefenses()
{
	mapping inMasksInput1 = Mask_TestInputCGet();
	mapping outMasksInput1 = Mask_TestInputAGet();
	mapping input1 = MappingTools_SumL(inMasksInput1, outMasksInput1);
	mapping expected1 = MappingTools_Sum(
		Mask_TestOutputAGet(), Mask_TestOutputCGet());
	mixed actual1 = Mask_OutputForm(input1);
	
	TestTools_AssertEqualsMultiple(
		expected1, actual1);
}




Mask_InputTypesFlagsForm_GivesSubjForAllDefenses()
{
	mapping input1 = Mask_TestInputCGet();
	mapping output1 = Mask_TestOutputCGet();
	mapping expected1 = output1[M_InMaskFlags];
	mixed actual1 = Mask_InputTypesFlagsForm(input1);
	
	mapping input2 = Mask_TestInputDGet();
	mapping output2 = Mask_TestOutputDGet();
	mapping expected2 = output2[M_InMaskFlags];
	mixed actual2 = Mask_InputTypesFlagsForm(input2);
	
	TestTools_AssertEqualsMultiple(
		expected1, actual1
		, expected2, actual2);
}

MaskM_InputTypeFlagsForm_GivesSubjForOneDefense()
{
	mapping input1 = Mask_TestInputCGet();
	mapping output1 = Mask_TestOutputCGet();
	mapping expected1 = output1[M_InMaskFlags][_Valves];
	mixed actual1 = MaskM_InputTypeFlagsForm(input1, _Valves);
	
	mapping input2 = Mask_TestInputCGet();
	mapping output2 = Mask_TestOutputCGet();
	mapping expected2 = output2[M_InMaskFlags][_Pressures];
	mixed actual2 = MaskM_InputTypeFlagsForm(input2, _Pressures);
	
	mapping input3 = Mask_TestInputDGet();
	mapping output3 = Mask_TestOutputDGet();
	mapping expected3 = output3[M_InMaskFlags][_Valves];
	mixed actual3 = MaskM_InputTypeFlagsForm(input3, _Valves);
	
	mapping input4 = Mask_TestInputDGet();
	mapping output4 = Mask_TestOutputDGet();
	mapping expected4 = output4[M_InMaskFlags][_Pressures];
	mixed actual4 = MaskM_InputTypeFlagsForm(input4, _Pressures);
	
	TestTools_AssertEqualsMultiple(
		expected1, actual1
		, expected2, actual2
		, expected3, actual3
		, expected4, actual4);
}

mapping Mask_TestInputCGet()
{
	mapping input;
	
	input[_General] = makeMapping(
		_SectorOn, true
	);
	
	input["OutMasksFlags"] = makeMapping(
		_OutMasks, makeDynBool(true, false));
	
	input[M_InMaskFlags] = makeMapping(
		_Valves, makeMapping(
			_NotUnderCtrlFlags, makeDynBool(false, true, false)
			, _Masks, makeDynBool(true, false, true)
			, _MaskCmds, makeDynBool(false, true, true, false, false, true)
			, _InputStateFlags, makeDynBool(false, true, false)
			, M_InputActivatedFunc, "Mask_Test_InputIsActivated"
			, _OutMaskIdxs, makeDynInt(1)
		)
		, _Pressures, makeMapping(
			_NotUnderCtrlFlags, makeDynBool(true, false, true)
			, _Masks, makeDynBool(false, true, false)
			, _MaskCmds, makeDynBool(true, false, false, true, true, false)
			, _InputStateFlags, makeDynBool(true, false, true)
			, M_InputActivatedFunc, "Mask_Test_InputIsActivated"
			, _OutMaskIdxs, makeDynInt(2)
		)
	);
	
	return input;
}

mapping Mask_TestOutputCGet()
{
	mapping output;
	
	output[M_InMaskFlags] = makeMapping(
		_Valves, makeMapping(
			_Masks, makeDynBool(false, true, false)
			, _MaskCmdRejects, makeDynBool(false, false, false, false, false, false)
			, _MaskCmds, makeDynBool(false, false, false, false, false, false))
		, _Pressures, makeMapping(
			_Masks, makeDynBool(false, false, false)
			, _MaskCmdRejects, makeDynBool(true, false, false, false, true, false)
			, _MaskCmds, makeDynBool(false, false, false, false, false, false)));
	
	return output;
}

mapping Mask_TestInputDGet()
{
	mapping input;
	
	input[_General] = makeMapping(
		_SectorOn, true
	);
	
	input["OutMasksFlags"] = makeMapping(
		_OutMasks, makeDynBool(true, true, false, false));
	
	input[M_InMaskFlags] = makeMapping(
		_Valves, makeMapping(
			_NotUnderCtrlFlags, makeDynBool(false, false)
			, _Masks, makeDynBool(true, true)
			, _MaskCmds, makeDynBool(false, true, true, true)
			, _InputStateFlags, makeDynBool(true, true, true, true)
			, M_InputActivatedFunc, "Mask_Test_InputIsActivated"
			, _OutMaskIdxs, makeDynInt(1, 2)
		)
		, _Pressures, makeMapping(
			_NotUnderCtrlFlags, makeDynBool(true, true)
			, _Masks, makeDynBool(false, false)
			, _MaskCmds, makeDynBool(true, false, true, true)
			, _InputStateFlags, makeDynBool(false, false, true, false)
			, M_InputActivatedFunc, "Mask_Test_InputIsActivated"
			, _OutMaskIdxs, makeDynInt(3, 4)
		)
	);
	
	return input;
}

bool Mask_Test_InputIsActivated(
	dyn_mixed &inputStateFlags, int defsCount, int inMasksCount
	, int defIdx, int inputIdx)
{
	return inputStateFlags[inMasksCount*(defIdx-1) + inputIdx];
}

mapping Mask_TestOutputDGet()
{
	mapping output;
	
	output[M_InMaskFlags] = makeMapping(
		_Valves, makeMapping(
			_Masks, makeDynBool(false, true)
			, _MaskCmdRejects, makeDynBool(false, false, true, true)
			, _MaskCmds, makeDynBool(false, false, false, false))
		, _Pressures, makeMapping(
			_Masks, makeDynBool(false, true)
			, _MaskCmdRejects, makeDynBool(true, false, false, true)
			, _MaskCmds, makeDynBool(false, false, false, false)));
	
	return output;
}




Mask_DefsOutFlagsForm_GivesSubjForAllDefenses()
{
	mapping input1 = Mask_TestInputAGet();
	mapping output1 = Mask_TestOutputAGet();
	mapping expected1 = output1["OutMasksFlags"];
	mixed actual1 = Mask_DefsOutFlagsForm(input1);
	
	mapping input2 = Mask_TestInputBGet();
	mapping output2 = Mask_TestOutputBGet();
	mapping expected2 = output2["OutMasksFlags"];
	mixed actual2 = Mask_DefsOutFlagsForm(input2);
	
	TestTools_AssertEqualsMultiple(
		expected1, actual1
		, expected2, actual2);
}




mapping Mask_TestInputAGet()
{
	mapping input;
	
	input[_General] = makeMapping(
		_SectorOn, true
		, _DefsFlags, makeDynBool(true, true, false, false)
		, _DefIdxToActivatedIdx, makeDynInt(1, 2));
	
	input["OutMasksFlags"] = makeMapping(
		_OutMasks, makeDynBool(true, false)
		, M_OutMaskCmds, makeDynBool(false, true, true, false));
	
	return input;
}

mapping Mask_TestOutputAGet()
{
	mapping output;
	
	output["OutMasksFlags"] = makeMapping(
		_OutMasks, makeDynBool(false, false)
		, M_OutMaskCmdRejects, makeDynBool(false, false, true, false)
		, M_OutMaskCmds, makeDynBool(false, false, false, false));
	
	return output;
}




mapping Mask_TestInputBGet()
{
	mapping input;
	
	input[_General] = makeMapping(
		_SectorOn, false
		, _DefsFlags, makeDynBool(true, true, false, false)
		, _DefIdxToActivatedIdx, makeDynInt(3, 4));
	
	input["OutMasksFlags"] = makeMapping(
		_OutMasks, makeDynBool(true, false)
		, M_OutMaskCmds, makeDynBool(true, false, true, false));
	
	return input;
}

mapping Mask_TestOutputBGet()
{
	mapping output;
	
	output["OutMasksFlags"] = makeMapping(
		_OutMasks, makeDynBool(true, true)
		, M_OutMaskCmdRejects, makeDynBool(true, false, false, false)
		, M_OutMaskCmds, makeDynBool(false, false, false, false));
	
	return output;
}




Mask_Form_SetsMaskIfCan_IfSumCmdSet_MaskCanBeSetAny_NoOutMask()
{
	dyn_bool expected1 = makeDynBool(true, false);
	dyn_mixed actual1 = FuncTools_MapArgsPermsCond(
		"Mask_Form(Mask_SumCmdSet, src[1], false)", "true", Mask_AllStates);
	
	TestTools_AssertEqualsMultiple(
		true, TestTools_AssertResultsEqual(expected1, actual1));
}

Mask_Form_KeepsMask_IfSumCmdSet_MaskCanBeSetAny_OutMask()
{
	dyn_bool expected1 = DynTools_MakeDynBool(2, true);
	dyn_mixed actual1 = FuncTools_MapArgsPermsCond(
		"Mask_Form(Mask_SumCmdSet, src[1], true)", "true", Mask_AllStates);
	
	TestTools_AssertEqualsMultiple(
		true, TestTools_AssertResultsEqual(expected1, actual1));
}

Mask_Form_KeepsMask_IfSumCmdNone_OtherFlagsAny()
{
	dyn_bool expected1 = makeDynBool(true, false, true, false);
	dyn_mixed actual1 = FuncTools_MapArgsPermsCond(
		"Mask_Form(Mask_SumCmdNone, src[1], src[2])", "true"
		, Mask_AllStates, Mask_AllStates);
	
	TestTools_AssertEqualsMultiple(
		true, TestTools_AssertResultsEqual(expected1, actual1));
}

Mask_Form_ResetsMask_IfSumCmdReset_OtherFlagsAny()
{
	dyn_bool expected1 = DynTools_MakeDynBool(4, false);
	dyn_mixed actual1 = FuncTools_MapArgsPermsCond(
		"Mask_Form(Mask_SumCmdReset, src[1], src[2])", "true"
		, Mask_AllStates, Mask_AllStates);
	
	TestTools_AssertEqualsMultiple(
		true, TestTools_AssertResultsEqual(expected1, actual1));
}




Mask_CmdIsRejected_SaysYes_IfCmd_ExpectedMask_IsNotResultMask()
{
	dyn_bool expected1 = DynTools_MakeDynBool(4, true);
	dyn_mixed actual1 = FuncTools_MapArgsPermsCond(
		"Mask_CmdIsRejected(true, src[1], src[2], src[3])"
		, "src[2] != src[3]"
		, Mask_AllStates, Mask_AllStates, Mask_AllStates);
	
	TestTools_AssertEqualsMultiple(
		true, TestTools_AssertResultsEqual(expected1, actual1));
}

Mask_CmdIsRejected_SaysYes_IfCmd_PrevMask_IsExpectedMask_PrevMask_IsResultMask()
{
	dyn_bool expected1 = DynTools_MakeDynBool(2, true);
	dyn_mixed actual1 = FuncTools_MapArgsPermsCond(
		"Mask_CmdIsRejected(true, src[1], src[2], src[3])"
		, "src[1] == src[2] && src[1] == src[3]"
		, Mask_AllStates, Mask_AllStates, Mask_AllStates);
	
	TestTools_AssertEqualsMultiple(
		true, TestTools_AssertResultsEqual(expected1, actual1));
}

Mask_CmdIsRejected_SaysNo_IfCmd_PrevMask_IsNotResultMask_ExpectedMask_IsResultMask()
{
	dyn_bool expected1 = DynTools_MakeDynBool(2, false);
	dyn_mixed actual1 = FuncTools_MapArgsPermsCond(
		"Mask_CmdIsRejected(true, src[1], src[2], src[3])"
		, "src[1] != src[3] && src[2] == src[3]"
		, Mask_AllStates, Mask_AllStates, Mask_AllStates);
	
	TestTools_AssertEqualsMultiple(
		true, TestTools_AssertResultsEqual(expected1, actual1));
}

Mask_CmdIsRejected_SaysNo_IfNoCmd_PrevMaskAny_ExpectedMaskAny_ResultMaskAny()
{
	dyn_bool expected1 = DynTools_MakeDynBool(8, false);
	dyn_mixed actual1 = FuncTools_MapArgsPermsCond(
		"Mask_CmdIsRejected(false, src[1], src[2], src[3])", "true"
		, Mask_AllStates, Mask_AllStates, Mask_AllStates);
	
	TestTools_AssertEqualsMultiple(
		true, TestTools_AssertResultsEqual(expected1, actual1));
}




Mask_InMaskCanBeSetForAllDefs_SaysSubj()
{
	bool sectorIsActive1 = false;
	dyn_bool defIdxToInputIsActivated1 = makeDynBool(false, false);
	dyn_bool defIdxToOutMask1 = makeDynBool(false, false);
	bool expected1 = true;
	mixed actual1 = Mask_InMaskCanBeSetForAllDefs(
		sectorIsActive1, defIdxToInputIsActivated1, defIdxToOutMask1);
	
	bool sectorIsActive2 = true;
	dyn_bool defIdxToInputIsActivated2 = makeDynBool(false, true);
	dyn_bool defIdxToOutMask2 = makeDynBool(false, false);
	bool expected2 = false;
	mixed actual2 = Mask_InMaskCanBeSetForAllDefs(
		sectorIsActive2, defIdxToInputIsActivated2, defIdxToOutMask2);
	
	TestTools_AssertEqualsMultiple(
		expected1, actual1
		, expected2, actual2);
}

Mask_InMaskCanBeSetFor1Def_SaysYes_OnlyIfSectorNotActive_OrDefInNotActivated_OrOutMaskSet()
{
	dyn_bool expected1 = DynTools_MakeDynBool(7, true);
	dyn_mixed actual1 = FuncTools_MapArgsPermsCond(
		"Mask_InMaskCanBeSetFor1Def(src[1], src[2], src[3])"
		, "!src[1] || !src[2] || src[3]"
		, Mask_AllStates, Mask_AllStates, Mask_AllStates);
	
	dyn_bool expected2 = DynTools_MakeDynBool(1, false);
	dyn_mixed actual2 = FuncTools_MapArgsPermsCond(
		"Mask_InMaskCanBeSetFor1Def(true, true, false)");
	
	TestTools_AssertEqualsMultiple(
		true, TestTools_AssertResultsEqual(expected1, actual1)
		, true, TestTools_AssertResultsEqual(expected2, actual2));
}

Mask_OutMaskCanBeSet_SaysYes_OnlyIfSectorNotActive_OrDefNotActivated()
{
	dyn_bool expected1 = DynTools_MakeDynBool(3, true);
	dyn_mixed actual1 = FuncTools_MapArgsPermsCond(
		"Mask_OutMaskCanBeSet(src[1], src[2])", "!src[1] || !src[2]"
		, Mask_AllStates, Mask_AllStates);
	
	dyn_bool expected2 = DynTools_MakeDynBool(1, false);
	dyn_mixed actual2 = FuncTools_MapArgsPermsCond(
		"Mask_OutMaskCanBeSet(true, true)");
	
	TestTools_AssertEqualsMultiple(
		true, TestTools_AssertResultsEqual(expected1, actual1)
		, true, TestTools_AssertResultsEqual(expected2, actual2));
}




Mask_SumCmdCalculate_TakesSetCmd_ResetCmd_ControlFlag_GivesSubj()
{
	bool isControlled1 = false;
	bool setCmd1 = false;
	bool resetCmd1 = false;
	int expected1 = Mask_SumCmdNone;
	mixed actual1 = Mask_SumCmdCalculate(setCmd1, resetCmd1, isControlled1);
	
	int expected2 = Mask_SumCmdNone;
	mixed actual2 = Mask_SumCmdCalculate(false, true, false);
	
	int expected3 = Mask_SumCmdSet;
	mixed actual3 = Mask_SumCmdCalculate(true, false, false);
	
	int expected4 = Mask_SumCmdSet;
	mixed actual4 = Mask_SumCmdCalculate(true, true, false);
	
	int expected5 = Mask_SumCmdNone;
	mixed actual5 = Mask_SumCmdCalculate(false, false, true);
	
	int expected6 = Mask_SumCmdReset;
	mixed actual6 = Mask_SumCmdCalculate(false, true, true);
	
	int expected7 = Mask_SumCmdSet;
	mixed actual7 = Mask_SumCmdCalculate(true, false, true);
	
	int expected8 = Mask_SumCmdNone;
	mixed actual8 = Mask_SumCmdCalculate(true, true, true);
	
	TestTools_AssertEqualsMultiple(
		expected1, actual1
		, expected2, actual2
		, expected3, actual3
		, expected4, actual4
		, expected5, actual5
		, expected6, actual6
		, expected7, actual7
		, expected8, actual8);
}



