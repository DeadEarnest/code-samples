#uses "cspa.core/comm.const"




const bool Mask_PositiveState = true;
const bool Mask_NegativeState = false;

const dyn_int Mask_PositiveStates = makeDynInt(Mask_PositiveState);
const dyn_int Mask_NegativeStates = makeDynInt(Mask_NegativeState);
const dyn_int Mask_AllStates = DynTools_Merge(
	Mask_PositiveStates, Mask_NegativeStates);

const int Mask_PositiveStatesNum = dynlen(Mask_PositiveStates);
const int Mask_NegativeStatesNum = dynlen(Mask_NegativeStates);
const int Mask_AllStatesNum = dynlen(Mask_AllStates);

const int Mask_SumCmdNone = 0;
const int Mask_SumCmdSet = 1;
const int Mask_SumCmdReset = -1;

const string M_InMaskFlags = "InMasksFlags";
const string M_OutMaskFlags = "OutMasksFlags";
const string M_InputsActivated = "InputsActivated";
const string M_NewInMasks = "NewInMasks";
const string M_InMasksNum = "InMasksNum";
const string M_InputTypeFlags = "InputTypeFlags";
const string M_InputTypeToOutMaskIdxs = "InputTypeToOutMaskIdxs";
const string M_AllOutMasks = "AllOutMasks";
const string M_CurrInMasks = "CurrInMasks";
const string M_DefsNum = "DefsNum";
const string M_InputActivatedFunc = "InputActivatedFunc";
const string M_NewOutMasks = "NewOutMasks";
const string M_OutMaskCmdRejects = "OutMaskCmdRejects";
const string M_OutMaskCmds = "OutMaskCmds";
const string M_CurrOutMasks = "CurrOutMasks";




global mapping Mask_AggregatedCmds;
global mapping M_Cache;




mapping M_IoCfgGet(mapping sectorCfg)
{
	return makeMapping(
	_Input, makeMapping(
		_General, makeMapping(
			_SectorOn, makeMapping(
				_Type, AlgoIo_Type_DpeValueAtIdx
				, _Dpe, sectorCfg[_Sector][_On][_Dpe]
				, _Idx, sectorCfg[_Sector][_On][_Idx]
			)
			, _DefsFlags, makeMapping(
				_Type, AlgoIo_Type_DpeValue
				, _Dpe, sectorCfg[_General][_DefsFlags]
			)
			, _DefIdxToActivatedIdx, makeMapping(
				_Type, AlgoIo_Type_Const
				, _Value, sectorCfg[_General][_DefIdxToActivatedIdx]
			)
		)
		
		, M_OutMaskFlags, makeMapping(
			_OutMasks, makeMapping(
				_Type, AlgoIo_Type_DpeValue
				, _Dpe, sectorCfg[_OutMasks][_MasksVerMask]
			)
			, M_OutMaskCmds, makeMapping(
				_Type, AlgoIo_Type_RuntimeCode
				, _Value, AlgoIo_RuntimeCodeMarker + AlgoIo_Delim_Code +
						"return Mask_AggregatedCmds[ioArgs[_Id]][ioArgs[_OutMasks][_Cmds]];"
			)
		)
		
		, M_InMaskFlags, makeMapping(
			_Valves, makeMapping(
				_NotUnderCtrlFlags, makeMapping(
					_Type, AlgoIo_Type_DpeValue
					, _Dpe, sectorCfg[_Valves][_NotUnderCtrlFlags]
				)
				, _Masks, makeMapping(
					_Type, AlgoIo_Type_DpeValue
					, _Dpe, sectorCfg[_Valves][_Masks]
				)
				, _MaskCmds, makeMapping(
					_Type, AlgoIo_Type_RuntimeCode
					, _Value, AlgoIo_RuntimeCodeMarker + AlgoIo_Delim_Code +
							"return Mask_AggregatedCmds[ioArgs[_Id]][ioArgs[_Valves][_MaskCmds]];"
				)
				, _InputStateFlags, makeMapping(
					_Type, AlgoIo_Type_DpeValue
					, _Dpe, sectorCfg[_Valves][_InputStateFlags]
				)
				, M_InputActivatedFunc, makeMapping(
					_Type, AlgoIo_Type_Const
					, _Value, "M_DefIsActivatedByValve"
				)
				, _OutMaskIdxs, makeMapping(
					_Type, AlgoIo_Type_Const
					, _Value,  sectorCfg[_Valves][_OutMaskIdxs]
				)
			)
			, _Pressures, makeMapping(
				_NotUnderCtrlFlags, makeMapping(
					_Type, AlgoIo_Type_DpeValue
					, _Dpe, sectorCfg[_Pressures][_NotUnderCtrlFlags]
				)
				, _Masks, makeMapping(
					_Type, AlgoIo_Type_DpeValue
					, _Dpe, sectorCfg[_Pressures][_Masks]
				)
				, _MaskCmds, makeMapping(
					_Type, AlgoIo_Type_RuntimeCode
					, _Value, AlgoIo_RuntimeCodeMarker + AlgoIo_Delim_Code +
							"return Mask_AggregatedCmds[ioArgs[_Id]][ioArgs[_Pressures][_MaskCmds]];"
				)
				, _InputStateFlags, makeMapping(
					_Type, AlgoIo_Type_DpeValue
					, _Dpe, sectorCfg[_Pressures][_InputStateFlags]
				)
				, M_InputActivatedFunc, makeMapping(
					_Type, AlgoIo_Type_Const
					, _Value, "M_DefIsActivatedByPressure"
				)
				, _OutMaskIdxs, makeMapping(
					_Type, AlgoIo_Type_Const
					, _Value,  sectorCfg[_Pressures][_OutMaskIdxs]
				)
			)
			, _Leaks, makeMapping(
				_NotUnderCtrlFlags, makeMapping(
					_Type, AlgoIo_Type_DpeValue
					, _Dpe, sectorCfg[_Leaks][_NotUnderCtrlFlags]
				)
				, _Masks, makeMapping(
					_Type, AlgoIo_Type_DpeValue
					, _Dpe, sectorCfg[_Leaks][_Masks]
				)
				, _MaskCmds, makeMapping(
					_Type, AlgoIo_Type_RuntimeCode
					, _Value, AlgoIo_RuntimeCodeMarker + AlgoIo_Delim_Code +
							"return Mask_AggregatedCmds[ioArgs[_Id]][ioArgs[_Leaks][_MaskCmds]];"
				)
				, _InputStateFlags, makeMapping(
					_Type, AlgoIo_Type_DpeValue
					, _Dpe, sectorCfg[_Leaks][_InputStateFlags]
				)
				, M_InputActivatedFunc, makeMapping(
					_Type, AlgoIo_Type_Const
					, _Value, "M_DefIsActivatedByLeak"
				)
				, _OutMaskIdxs, makeMapping(
					_Type, AlgoIo_Type_Const
					, _Value,  sectorCfg[_Leaks][_OutMaskIdxs]
				)
			)
			, _PressureDiffs, makeMapping(
				_NotUnderCtrlFlags, makeMapping(
					_Type, AlgoIo_Type_DpeValue
					, _Dpe, sectorCfg[_PressureDiffs][_NotUnderCtrlFlags]
				)
				, _Masks, makeMapping(
					_Type, AlgoIo_Type_DpeValue
					, _Dpe, sectorCfg[_PressureDiffs][_Masks]
				)
				, _MaskCmds, makeMapping(
					_Type, AlgoIo_Type_RuntimeCode
					, _Value, AlgoIo_RuntimeCodeMarker + AlgoIo_Delim_Code +
							"return Mask_AggregatedCmds[ioArgs[_Id]][ioArgs[_PressureDiffs][_MaskCmds]];"
				)
				, _InputStateFlags, makeMapping(
					_Type, AlgoIo_Type_DpeValue
					, _Dpe, sectorCfg[_PressureDiffs][_InputStateFlags]
				)
				, M_InputActivatedFunc, makeMapping(
					_Type, AlgoIo_Type_Const
					, _Value, "M_DefIsActivatedByPressureDiff"
				)
				, _OutMaskIdxs, makeMapping(
					_Type, AlgoIo_Type_Const
					, _Value,  sectorCfg[_PressureDiffs][_OutMaskIdxs]
				)
			)
		)
	)
	
	, _Output, makeMapping(
	
		_OutputTicker, makeMapping(
			_Type, AlgoIo_Type_DpeValue
			, _Dpe, sectorCfg[_Tickers][_Mask]
		)
		
		, M_OutMaskFlags, makeMapping(
			_OutMasks, makeMapping(
				_Type, AlgoIo_Type_RuntimeCode
				, _Value, AlgoIo_RuntimeCodeMarker + AlgoIo_Delim_Code +
					"dyn_bool masks = outputValue;" +
					"dyn_int idxs = ioArgs[_General][_NotEndStationOutMaskIdxs];" +
					"for(int i = 1; i <= dynlen(idxs); ++i)" +
						"masks[idxs[i]] = false;" +
					"dyn_bool oldMasks = DpTools_Get(ioArgs[_OutMasks][_MasksVerMask]);" +
					"if(masks != oldMasks)" +
						"dpSet(ioArgs[_OutMasks][_MasksVerMask], masks);"
			)
			, M_OutMaskCmdRejects, makeMapping(
				_Type, AlgoIo_Type_RuntimeCode
				, _Value, AlgoIo_RuntimeCodeMarker + AlgoIo_Delim_Code +
					"dyn_bool cmdRejects = outputValue;" +
					"dyn_int idxs = ioArgs[_General][_NotEndStationOutMaskIdxs];" +
					"for(int i = 1; i <= dynlen(idxs); ++i){" +
						"cmdRejects[2*(idxs[i]-1)+1] = false;" +
						"cmdRejects[2*(idxs[i]-1)+2] = false;" +
					"}" +
					"dyn_bool oldRejects = DpTools_Get(ioArgs[_OutMasks][_CmdRejects]);" +
					"if(cmdRejects != oldRejects)" +
						"dpSet(ioArgs[_OutMasks][_CmdRejects], cmdRejects);"
			)
			, M_OutMaskCmds, makeMapping(
				_Type, AlgoIo_Type_DpeValue
				, _Dpe, sectorCfg[_OutMasks][_Cmds]
			)
		)
		
		, M_InMaskFlags, makeMapping(
			_Valves, makeMapping(
				_Masks, makeMapping(
					_Type, AlgoIo_Type_DpeValue
					, _Dpe, sectorCfg[_Valves][_Masks]
				)
				, _MaskCmdRejects, makeMapping(
					_Type, AlgoIo_Type_DpeValue
					, _Dpe, sectorCfg[_Valves][_MaskCmdRejects]
				)
				, _MaskCmds, makeMapping(
					_Type, AlgoIo_Type_DpeValue
					, _Dpe, sectorCfg[_Valves][_MaskCmds]
				)
			)
			, _Pressures, makeMapping(
				_Masks, makeMapping(
					_Type, AlgoIo_Type_DpeValue
					, _Dpe, sectorCfg[_Pressures][_Masks]
				)
				, _MaskCmdRejects, makeMapping(
					_Type, AlgoIo_Type_DpeValue
					, _Dpe, sectorCfg[_Pressures][_MaskCmdRejects]
				)
				, _MaskCmds, makeMapping(
					_Type, AlgoIo_Type_DpeValue
					, _Dpe, sectorCfg[_Pressures][_MaskCmds]
				)
			)
			, _Leaks, makeMapping(
				_Masks, makeMapping(
					_Type, AlgoIo_Type_DpeValue
					, _Dpe, sectorCfg[_Leaks][_Masks]
				)
				, _MaskCmdRejects, makeMapping(
					_Type, AlgoIo_Type_DpeValue
					, _Dpe, sectorCfg[_Leaks][_MaskCmdRejects]
				)
				, _MaskCmds, makeMapping(
					_Type, AlgoIo_Type_DpeValue
					, _Dpe, sectorCfg[_Leaks][_MaskCmds]
				)
			)
			, _PressureDiffs, makeMapping(
				_Masks, makeMapping(
					_Type, AlgoIo_Type_DpeValue
					, _Dpe, sectorCfg[_PressureDiffs][_Masks]
				)
				, _MaskCmdRejects, makeMapping(
					_Type, AlgoIo_Type_DpeValue
					, _Dpe, sectorCfg[_PressureDiffs][_MaskCmdRejects]
				)
				, _MaskCmds, makeMapping(
					_Type, AlgoIo_Type_DpeValue
					, _Dpe, sectorCfg[_PressureDiffs][_MaskCmds]
				)
			)
		)
	)
	);
}




bool M_DefIsActivatedByValve(
	dyn_mixed &inputStateFlags, int defsCount, int inMasksCount
	, int defIdx, int inputIdx)
{
	return inputStateFlags[10*(inputIdx-1) + 4*(defIdx%2) + 2];
}

bool M_DefIsActivatedByPressure(
	dyn_mixed &inputStateFlags, int defsCount, int inMasksCount
	, int defIdx, int inputIdx)
{
	return inputStateFlags[2*(inputIdx-1) + defIdx];
}

bool M_DefIsActivatedByLeak(
	dyn_mixed &inputStateFlags, int defsCount, int inMasksCount
	, int defIdx, int inputIdx)
{
	return inputStateFlags[inputIdx] == Timers_Expired;
}

bool M_DefIsActivatedByPressureDiff(
	dyn_mixed &inputStateFlags, int defsCount, int inMasksCount
	, int defIdx, int inputIdx)
{
	return inputStateFlags[inputIdx] == Timers_Expired;
}




void Mask_CmdsAggregate(string sectorId, string cmdsDpa, dyn_bool cmds)
{
	synchronized(Mask_AggregatedCmds){
		string cmdsDpe = dpSubStr(cmdsDpa, DPSUB_DP_EL);
		
		dyn_bool aggregatedCmds = Mask_AggregatedCmds[sectorId][cmdsDpe];
		Mask_AggregatedCmds[sectorId][cmdsDpe] = ArrAggr_BoolArraysMerge(
			cmds, aggregatedCmds
		);
	}
}

void Mask_ExecAlgo(mapping userData, string tickerDpa, int tick)
{
	synchronized(Mask_AggregatedCmds){
		M_Cache = makeMapping();
		mapping ioCfg = userData[_IoCfg];
		mapping sectorCfg = userData[_SectorCfg];
		
		bool precursorsReady = Fc_WaitForPrecursors(userData[Fc_Key_WatchId], tick);
		mapping input = AlgoIo_InputRead(ioCfg[_Input], sectorCfg);
		mapping output = Mask_OutputForm(input);
		output[_OutputTicker] = tick;
		AlgoIo_OutputWrite(ioCfg[_Output], output, sectorCfg);
		
		Mask_AggregatedCmdsReset(sectorCfg[_Id]);
	}
}




void Mask_AggregatedCmdsReset(string sectorId)
{
	dyn_mixed keys = mappingKeys(Mask_AggregatedCmds[sectorId]);
	for(int i = 1; i <= dynlen(keys); ++i){
		dyn_bool cmds = Mask_AggregatedCmds[sectorId][keys[i]];
		Mask_AggregatedCmds[sectorId][keys[i]] = DynTools_MakeDynBool(
			dynlen(cmds), false
		);
	}
}




mapping Mask_OutputForm(mapping &input)
{
	return makeMapping(
		M_InMaskFlags, Mask_InputTypesFlagsForm(input),
		M_OutMaskFlags, Mask_DefsOutFlagsForm(input));
}




mapping Mask_InputTypesFlagsForm(mapping &input)
{
	dyn_mixed defKeys = mappingKeys(input[M_InMaskFlags]);
	int defsCount = dynlen(defKeys);
	
	dyn_mixed defsFlags;
	for(int i = 1; i <= defsCount; ++i)
		defsFlags[i] = MaskM_InputTypeFlagsForm(input, defKeys[i]);
	
	mapping result;
	for(int i = 1; i <= defsCount; ++i)
		result[defKeys[i]] = defsFlags[i];
	
	return result;
}




mapping MaskM_InputTypeFlagsForm(mapping &input, string defInputType)
{
	Mask_InputTypeFlagsForm_ParseInput(input, defInputType);
	
	M_Cache[M_InputsActivated] = Mask_InputsAreActivated();
	M_Cache[M_NewInMasks] = MaskM_NewInMasksGet();
	dyn_bool cmdRejects = Mask_InCmdRejectsGet();
	dyn_bool inMaskCmds = Mask_CmdsGet(M_Cache[M_InMasksNum]);
	
	return makeMapping(
		_Masks, M_Cache[M_NewInMasks],
		_MaskCmdRejects, cmdRejects,
		_MaskCmds, inMaskCmds
	);
}

void Mask_InputTypeFlagsForm_ParseInput(mapping &input, string defInputType)
{
	M_Cache[_SectorOn] = input[_General][_SectorOn];
	M_Cache[M_AllOutMasks] = input[M_OutMaskFlags][_OutMasks];
	M_Cache[M_InputTypeFlags] = input[M_InMaskFlags][defInputType];
	
	M_Cache[_InputStateFlags] = M_Cache[M_InputTypeFlags][_InputStateFlags];
	M_Cache[_NotUnderCtrlFlags] = M_Cache[M_InputTypeFlags][_NotUnderCtrlFlags];
	M_Cache[_MaskCmds] = M_Cache[M_InputTypeFlags][_MaskCmds];
	M_Cache[M_CurrInMasks] = M_Cache[M_InputTypeFlags][_Masks];
	M_Cache[_OutMaskIdxs] = M_Cache[M_InputTypeFlags][_OutMaskIdxs];
	
	M_Cache[M_InMasksNum] = dynlen(M_Cache[M_CurrInMasks]);
	M_Cache[M_DefsNum] = dynlen(M_Cache[_OutMaskIdxs]);
}

dyn_dyn_bool Mask_InputsAreActivated()
{
	string inputActivatedFunc = M_Cache[M_InputTypeFlags][M_InputActivatedFunc];
	
	dyn_dyn_bool inputsAreActivated;
	for(int inputIdx = 1; inputIdx <= M_Cache[M_InMasksNum]; ++inputIdx){
		for(int defIdx = 1; defIdx <= M_Cache[M_DefsNum]; ++defIdx){
			inputsAreActivated[inputIdx][defIdx] = callFunction(
				inputActivatedFunc, M_Cache[_InputStateFlags],
				M_Cache[M_DefsNum], M_Cache[M_InMasksNum], defIdx, inputIdx);
	}
	}
	
	return inputsAreActivated;
}

dyn_bool MaskM_NewInMasksGet()
{
	dyn_mixed sumCmds;
	for(int i = 1; i <= M_Cache[M_InMasksNum]; ++i){
		sumCmds[i] = Mask_SumCmdCalculate(
			M_Cache[_MaskCmds][2*(i-1)+1], M_Cache[_MaskCmds][2*(i-1)+2],
			!M_Cache[_NotUnderCtrlFlags][i]
		);
	}
	
	dyn_bool inputTypeOutMasks;
	for(int i = 1; i <= M_Cache[M_DefsNum]; ++i)
		inputTypeOutMasks[i] = M_Cache[M_AllOutMasks][M_Cache[_OutMaskIdxs][i]];
	
	dyn_bool masksCanBeSet;
	for(int i = 1; i <= M_Cache[M_InMasksNum]; ++i){
		masksCanBeSet[i] = Mask_InMaskCanBeSetForAllDefs(
			M_Cache[_SectorOn], M_Cache[M_InputsActivated][i],
			inputTypeOutMasks
		);
	}
	
	dyn_bool result;
	for(int i = 1; i <= M_Cache[M_InMasksNum]; ++i)
		result[i] = Mask_Form(sumCmds[i], masksCanBeSet[i], M_Cache[M_CurrInMasks][i]);
	
	return result;
}

dyn_bool Mask_InCmdRejectsGet()
{
	dyn_bool setCmdRejects;
	for(int i = 1; i <= M_Cache[M_InMasksNum]; ++i){
		setCmdRejects[i] = Mask_CmdIsRejected(
			M_Cache[_MaskCmds][2*(i-1)+1], M_Cache[M_CurrInMasks][i],
			true, M_Cache[M_NewInMasks][i]
		);
	}
	
	dyn_bool resetCmdRejects;
	for(int i = 1; i <= M_Cache[M_InMasksNum]; ++i){
		resetCmdRejects[i] = Mask_CmdIsRejected(
			M_Cache[_MaskCmds][2*(i-1)+2], M_Cache[M_CurrInMasks][i],
			false, M_Cache[M_NewInMasks][i]
		);
	}
	
	dyn_bool result;
	for(int i = 1; i <= M_Cache[M_InMasksNum]; ++i){
		dynAppend(result, setCmdRejects[i]);
		dynAppend(result, resetCmdRejects[i]);
	}
	
	return result;
}




mapping Mask_DefsOutFlagsForm(mapping &input)
{
	Mask_DefsOutFlagsForm_ParseInput(input);
	
	M_Cache[M_NewOutMasks] = MaskM_NewOutMasksGet();
	dyn_bool cmdRejects = Mask_OutCmdRejectsGet();
	dyn_bool outMaskCmds = Mask_CmdsGet(M_Cache[M_DefsNum]);
	
	return makeMapping(
		_OutMasks, M_Cache[M_NewOutMasks],
		M_OutMaskCmdRejects, cmdRejects,
		M_OutMaskCmds, outMaskCmds
	);
}

void Mask_DefsOutFlagsForm_ParseInput(mapping &input)
{
	M_Cache[_SectorOn] = input[_General][_SectorOn];
	M_Cache[M_CurrOutMasks] = input[M_OutMaskFlags][_OutMasks];
	M_Cache[M_OutMaskCmds] = input[M_OutMaskFlags][M_OutMaskCmds];
	M_Cache[M_DefsNum] = dynlen(M_Cache[M_CurrOutMasks]);
	M_Cache[_DefsFlags] = input[_General][_DefsFlags];
	M_Cache[_DefIdxToActivatedIdx] = input[_General][_DefIdxToActivatedIdx];
}

dyn_bool MaskM_NewOutMasksGet()
{
	dyn_bool defActivatedFlags;
	for(int i = 1; i <= M_Cache[M_DefsNum]; ++i){
		dynAppend(
			defActivatedFlags, M_Cache[_DefsFlags][M_Cache[_DefIdxToActivatedIdx][i]]
		);
	}
	
	dyn_int sumCmds;
	for(int i = 1; i <= M_Cache[M_DefsNum]; ++i){
		sumCmds[i] = Mask_SumCmdCalculate(
			M_Cache[M_OutMaskCmds][2*(i-1)+1],
			M_Cache[M_OutMaskCmds][2*(i-1)+2]
		);
	}
	
	dyn_bool masksCanBeSet;
	for(int i = 1; i <= M_Cache[M_DefsNum]; ++i){
		masksCanBeSet[i] = Mask_OutMaskCanBeSet(
			M_Cache[_SectorOn], defActivatedFlags[i]
		);
	}
	
	dyn_bool result;
	for(int i = 1; i <= M_Cache[M_DefsNum]; ++i)
		result[i] = Mask_Form(sumCmds[i], masksCanBeSet[i], M_Cache[M_CurrOutMasks][i]);
	
	return result;
}

dyn_bool Mask_OutCmdRejectsGet()
{
	dyn_bool setCmdRejects;
	for(int i = 1; i <= M_Cache[M_DefsNum]; ++i){
		setCmdRejects[i] = Mask_CmdIsRejected(
			M_Cache[M_OutMaskCmds][2*(i-1)+1], M_Cache[M_CurrOutMasks][i],
			true, M_Cache[M_NewOutMasks][i]
		);
	}
	
	dyn_bool resetCmdRejects;
	for(int i = 1; i <= M_Cache[M_DefsNum]; ++i){
		resetCmdRejects[i] = Mask_CmdIsRejected(
			M_Cache[M_OutMaskCmds][2*(i-1)+2], M_Cache[M_CurrOutMasks][i],
			false, M_Cache[M_NewOutMasks][i]
		);
	}
	
	dyn_bool result;
	for(int i = 1; i <= M_Cache[M_DefsNum]; ++i){
		dynAppend(result, setCmdRejects[i]);
		dynAppend(result, resetCmdRejects[i]);
	}
	
	return result;
}

dyn_bool Mask_CmdsGet(int cmdsNum)
{
	return DynTools_MakeDynBool(2 * cmdsNum, false);
}




bool Mask_InMaskCanBeSetForAllDefs(
	bool sectorIsActive, dyn_bool defIdxToInputIsActivated,
	dyn_bool defIdxToOutMask
)
{
	int defsCount = dynlen(defIdxToInputIsActivated);
	
	bool result = true;
	for(int i = 1; i <= defsCount; ++i){
		result &= Mask_InMaskCanBeSetFor1Def(
			sectorIsActive, defIdxToInputIsActivated[i], defIdxToOutMask[i]
		);
	}
	
	return result;
}




bool Mask_Form(int sumCmd, bool maskCanBeSet, bool currMask)
{
	switch(sumCmd){
		case Mask_SumCmdReset:
			return false;
		case Mask_SumCmdNone:
			return currMask;
		case Mask_SumCmdSet:
			return currMask ? currMask : maskCanBeSet;
	}
}

bool Mask_CmdIsRejected(bool cmd, bool prevMask, bool expectedMask, bool resultMask)
{
	if(!cmd)
		return false;
	
	if(prevMask != resultMask && expectedMask == resultMask)
		return false;
	
	return true;
}

bool Mask_InMaskCanBeSetFor1Def(
	bool sectorIsActive, bool defInputIsActivated, bool outMaskIsSet
)
{
	return !sectorIsActive || !defInputIsActivated || outMaskIsSet;
}

bool Mask_OutMaskCanBeSet(bool sectorIsActive, bool defIsActivated)
{
	return !sectorIsActive || !defIsActivated;
}

int Mask_SumCmdCalculate(bool setCmd, bool resetCmd, bool isControlled = true)
{
	if(setCmd && !(isControlled && resetCmd))
		return Mask_SumCmdSet;
	
	if(!setCmd && (isControlled && resetCmd))
		return Mask_SumCmdReset;
	
	return Mask_SumCmdNone;
}