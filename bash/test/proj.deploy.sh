#! /bin/bash




function Pd_Test_VarsSetup
{
	declare -g Pd_T_Version=$1
	declare -g Pd_T_ResourcesDir=$2
	declare -g Pd_T_TempDir=$3
	declare -g Pd_T_Utils=$4
	
	declare -g Pd_T_CiLogin='ci.bot'
	declare -g Pd_T_CiPass='hgr$5sEQE31w35_8&&'
	declare -g Pd_T_MainProjName='main.proj'
	declare -g Pd_T_MainProjUrl='http://10.0.0.5/repos/root/test.stubs/main.proj/'
	declare -g Pd_T_SubAUrl='http://10.0.0.5/repos/root/test.stubs/subproj.a/'
	declare -g Pd_T_SubBUrl='http://10.0.0.5/repos/root/test.stubs/subproj.b/'
	

	declare -g Pd_T_AuthFile=$Pd_T_ResourcesDir'svn.auth.txt'
	declare -g Pd_T_SubsFile=$Pd_T_ResourcesDir'svn.src.dest.txt'
	declare -g Pd_T_DbFillFile=$Pd_T_ResourcesDir'db.fill.txt'
	declare -g Pd_T_BaseRegFile=$Pd_T_ResourcesDir'reg.file.base.txt'
	declare -g Pd_T_ExpectedRegFile=$Pd_T_ResourcesDir'reg.file.expected.txt'
	declare -g Pd_T_CfgTemplateDir=$Pd_T_ResourcesDir'config.template/'

	declare -g Pd_T_TestRegFile=$Pd_T_TempDir'reg.file.txt'
	declare -g Pd_T_ResultRegFile=$Pd_T_TempDir'reg.file.result.txt'
	declare -g Pd_T_MainProjDir=$Pd_T_TempDir'main.proj/'
	declare -g Pd_T_SubsDir=$Pd_T_TempDir'_subs/'
	declare -g Pd_T_CfgDir=$Pd_T_MainProjDir'config/'
	declare -g Pd_T_SubADir=$Pd_T_SubsDir'subproj.a/'
	declare -g Pd_T_SubBDir=$Pd_T_SubsDir'subproj.b/'
	declare -g Pd_T_MainDplistDir=$Pd_T_MainProjDir'dplist/'
	declare -g Pd_T_DbExportFile=$Pd_T_MainDplistDir'db.export.json'

	declare -g Pd_Win_WccoaDir='C:/Siemens/Automation/WinCC_OA/'"$Pd_T_Version/"
	declare -g Pd_Win_PvssInstDir='C:/ProgramData/Siemens/WinCC_OA/'
	declare -g Pd_Win_RegFile=$Pd_Win_PvssInstDir'pvssInst.conf'
	declare -g Pd_Win_RegFileCopy=$Pd_Win_PvssInstDir'pvssInst.conf.copy'
	# declare -g Pd_Win_MainProjDir=`cygpath -w -a $Pd_T_MainProjDir`
	# declare -g Pd_Win_CfgDir=`cygpath -w -a $Pd_T_CfgDir`
}




function oneTimeSetUp()
{
	if [ -f debug.txt ]
	then
		rm debug.txt
	fi
	
	touch debug.txt
	
	# cp $Pd_Win_RegFile $Pd_Win_RegFileCopy
}




function setUp()
{
	[ -d $Pd_T_TempDir ] && rm -r -d $Pd_T_TempDir
	
	mkdir $Pd_T_TempDir
	mkdir $Pd_T_MainProjDir
	mkdir $Pd_T_CfgDir
	mkdir $Pd_T_MainDplistDir
	
	touch $Pd_T_TestRegFile
}




function tearDown()
{
	# rm $Pd_Win_RegFile
	# cp $Pd_Win_RegFileCopy $Pd_Win_RegFile
	
	[ -d $Pd_T_TempDir ] && rm -r -d $Pd_T_TempDir
}




function suite()
{
	suite_addTest Pd_ParamGetFromFile_DoesSubj
	suite_addTest Pd_FileSectionRead_ReadsPaths_FromGivenFileSection
	# suite_addTest Pd_PathNormalize_GivesMixedPath_DirEndsWithSlash
	# suite_addTest Pd_ProjCfg_Setup_CopiesCfgFiles_SetsUpSections
	suite_addTest Pd_ProjRegister_AddsProjInfoToFile
	
	# ### requires perl
	# suite_addTest Pd_ProjUnregister_RemovesAllProjEntriesFromFile
	
	### require svn
	# suite_addTest Pd_SvnItemExport_ExportsFromSvn_ToGivenDir
	# suite_addTest Pd_SvnItemsExport_DoesSubj
	
	### requires wccoa
	### runs a long time
	# suite_addTest Pd_DbCreate_DoesSubj_Ver3dot14_OnWindows
	
	### requires svn, wccoa
	### runs a long time
	# suite_addTest Pd_Win_ProjDeploy_DeploysProj_OnWindows
	
	# ### requires a runnable project, netcat
	# suite_addTest Pmon_StartsProj_InWaitMode_OnWindows
	
	# ### requires a running project with 'tools' subproject
	# ### runs a long time
	# suite_addTest Pd_DbFill_ImportsJsonDatabaseDumps
}




function Pd_Win_ProjDeploy_DeploysProj_OnWindows()
{
	local importFile=$Pd_T_MainDplistDir'demiurge.dpts.json'
	local exportFile=`cygpath -w -a $Pd_T_DbExportFile`
	
	Pd_Win_ProjDeploy $Pd_T_Version $Pd_T_MainProjDir $Pd_T_MainProjName \
		5010 $Pd_T_ResourcesDir $Pd_T_Utils
	
	local actual1=false
	$Pd_WccoaDir'bin/WCCILpmon.exe' -proj $Pd_ProjName -port $Pd_PmonPort &
	sleep 5
	$Pd_T_Utils $Pd_T_Version 'json.export.external.dpts' "$exportFile" '-full'
	diff $importFile $exportFile > /dev/null && actual1=true || actual1=false
	
	$Pd_Win_WccoaDir'bin/WCCILpmon.exe' -proj $Pd_T_MainProjName -port 5010 -stopWait
	
	$_ASSERT_EQUALS_ true $actual1
}

function Pmon_StartsProj_InWaitMode_OnWindows()
{
	$Pd_Win_WccoaDir'bin/WCCILpmon.exe' -proj 'general_3.14p08' -port 5010 -noAutostart &
	
	local actual1=`echo '##PROJECT:' | nc localhost 5010`
	
	$Pd_Win_WccoaDir'bin/WCCILpmon.exe' -proj 'general_3.14p08' -port 5010 -stopWait
	
	$_ASSERT_EQUALS_ 'general_3.14p08' $actual1
}

function Pd_DbFill_ImportsJsonDatabaseDumps()
{
	local exportFile=`cygpath -w -a $Pd_T_DbExportFile`
	local actual1
	
	Pd_DbFill $Pd_T_Version $Pd_T_DbFillFile $Pd_T_MainDplistDir \
		$Pd_T_CiLogin $Pd_T_CiPass $Pd_T_Utils
	
	$Pd_T_Utils $Pd_T_Version 'json.export.external.dpts' "$exportFile" '-full'
	local importFile=$Pd_T_MainDplistDir'demiurge.dpts.json'
	diff $importFile $exportFile > /dev/null && actual1=true || actual1=false
	
	$_ASSERT_EQUALS_ true $actual1
}

function Pd_DbCreate_DoesSubj_Ver3dot14_OnWindows()
{
	local actualA1
	local actualB1
	local actualC1
	local actualD1
	
	Pd_ProjRegister $Pd_Win_RegFile $Pd_T_MainProjName $Pd_Win_MainProjDir \
		$Pd_T_Version 'time' 'user'
	Pd_ProjCfg_Setup $Pd_T_CfgTemplateDir $Pd_T_CfgDir \
		$Pd_T_Version $Pd_Win_MainProjDir "" 'linux'
	
	Pd_DbCreate $Pd_T_MainProjName $Pd_Win_MainProjDir $Pd_Win_WccoaDir
	
	test -d $Pd_T_MainProjDir'db' && actualA1=true || actualA1=false
	test -d $Pd_T_MainProjDir'db/wincc_oa' && actualB1=true || actualB1=false
	test -d $Pd_T_MainProjDir'log' && actualC1=true || actualC1=false
	test -f $Pd_T_MainProjDir'log/createDb.log' && actualD1=true || actualD1=false
	
	$_ASSERT_EQUALS_ true $actualA1
	$_ASSERT_EQUALS_ true $actualB1
	$_ASSERT_EQUALS_ true $actualC1
	$_ASSERT_EQUALS_ true $actualD1
}

function Pd_ProjUnregister_RemovesAllProjEntriesFromFile()
{
	Pd_ProjUnregister $Pd_T_BaseRegFile $Pd_T_ResultRegFile $Pd_T_MainProjName
	
	diff $Pd_T_ExpectedRegFile $Pd_T_ResultRegFile > /dev/null && actual1=true || actual1=false
	
	$_ASSERT_EQUALS_ true $actual1
}

function Pd_ProjRegister_AddsProjInfoToFile()
{
	local time='12345'
	local user='testUserName'
	local expected1
	expected1[0]='[Software\ETM\PVSS II\Configs\main.proj]'
	expected1[1]="notRunnable = 0"
	expected1[2]="InstallationDate = \"12345\""
	expected1[3]="InstallationUser = \"testUserName\""
	expected1[4]="InstallationVersion = \"$Pd_T_Version\""
	expected1[5]="PVSS_II = \"$Pd_T_MainProjDir"'config\config"'
	expected1[6]="InstallationDir = \"$Pd_T_MainProjDir\""
	
	Pd_ProjRegister $Pd_T_TestRegFile $Pd_T_MainProjName $Pd_T_MainProjDir \
		$Pd_T_Version $time $user
	
	Tf_FileReadLines $Pd_T_TestRegFile 1
	
	for i in ${!expected1[*]}; do
		Tf_AssertElemsEqual "${expected1[$i]}" "${Tf_SavedLines[$i]}"
	done
}

function Pd_ProjCfg_Setup_CopiesCfgFiles_SetsUpSections()
{
	local subprojDirs=($Pd_T_SubAUrl $Pd_T_SubADir $Pd_T_SubBUrl $Pd_T_SubBDir)
	
	local expectedA1=(pvss_path = \"C:/Siemens/Automation/WinCC_OA/$Pd_T_Version\")
	local expectedB1=(proj_path = \"$Pd_T_MainProjDir\" proj_version = \"$Pd_T_Version\")
	local expectedC1=(proj_path = \"$Pd_T_SubBDir\" proj_path = \"$Pd_T_SubADir\")
	
	Pd_ProjCfg_Setup $Pd_T_CfgTemplateDir $Pd_T_CfgDir $Pd_T_Version \
		$Pd_T_MainProjDir "${subprojDirs[*]}" 'linux'
	local actualA1=(`Pd_FileSectionRead $Pd_T_CfgDir'config' "#base"`)
	local actualB1=(`Pd_FileSectionRead $Pd_T_CfgDir'config' "#main"`)
	local actualC1=(`Pd_FileSectionRead $Pd_T_CfgDir'config' "#sub"`)
	
	$_ASSERT_EQUALS_ '"${expectedA1[*]}"' '"${actualA1[*]}"'
	$_ASSERT_EQUALS_ '"${expectedB1[*]}"' '"${actualB1[*]}"'
	$_ASSERT_EQUALS_ '"${expectedC1[*]}"' '"${actualC1[*]}"'
}

function Pd_PathNormalize_GivesMixedPath_DirEndsWithSlash()
{
	local path1='./temp/dirA'
	local expected1='temp/dirA/'
	local actual1=`Pd_PathNormalize $path1 'dir'`
	
	local path2='./temp/dirA/'
	local expected2='temp/dirA/'
	local actual2=`Pd_PathNormalize $path2 'dir'`
	
	local path3='C:\\temp\\dirA'
	local expected3='C:/temp/dirA/'
	local actual3=`Pd_PathNormalize $path3 'dir'`
	
	local path4='C:\\temp\\dirA\\'
	local expected4='C:/temp/dirA/'
	local actual4=`Pd_PathNormalize $path4 'dir'`
	
	local path5='./temp/dirA/fileA.txt'
	local expected5='temp/dirA/fileA.txt'
	local actual5=`Pd_PathNormalize $path5 'file'`
	
	local path6='C:\\temp\\dirA\\fileA.txt'
	local expected6='C:/temp/dirA/fileA.txt'
	local actual6=`Pd_PathNormalize $path6 'file'`
	
	$_ASSERT_EQUALS_ $expected1 $actual1
	$_ASSERT_EQUALS_ $expected2 $actual2
	$_ASSERT_EQUALS_ $expected3 $actual3
	$_ASSERT_EQUALS_ $expected4 $actual4
	$_ASSERT_EQUALS_ $expected5 $actual5
	$_ASSERT_EQUALS_ $expected6 $actual6
}

function Pd_SvnItemsExport_DoesSubj()
{
	local projectsSrcDest[0]=$Pd_T_SubAUrl
	projectsSrcDest[1]=$Pd_T_SubADir
	projectsSrcDest[2]=$Pd_T_SubBUrl
	projectsSrcDest[3]=$Pd_T_SubBDir
	local actualA1
	local actualB1
	
	Pd_SvnItemsExport "${projectsSrcDest[*]}" $Pd_T_CiLogin $Pd_T_CiPass
	
	test -f $Pd_T_SubADir'file.a.txt' && actualA1=true || actualA1=false
	test -f $Pd_T_SubBDir'file.b.txt' && actualB1=true || actualB1=false
	
	$_ASSERT_EQUALS_ true $actualA1
	$_ASSERT_EQUALS_ true $actualB1
}

function Pd_SvnItemExport_ExportsFromSvn_ToGivenDir()
{
	type svn > /dev/null && local svnPresent=true || local svnPresent=false
	if [[ $svnPresent == false ]]; then
		fail "error: svn is not present."
		return 1
	fi
	
	local file1=$Pd_T_SubADir'file.a.txt'
	
	Pd_SvnItemExport $Pd_T_SubAUrl $Pd_T_SubADir $Pd_T_CiLogin $Pd_T_CiPass
	
	local actualA1=`test -f $file1; echo $?`
	
	$_ASSERT_EQUALS_ 0 $actualA1
}

function Pd_FileSectionRead_ReadsPaths_FromGivenFileSection()
{
	local expected1=($Pd_T_MainProjUrl $Pd_T_MainProjDir)
	local actual1=(`Pd_FileSectionRead $Pd_T_SubsFile "#main"`)
	
	local expected2=($Pd_T_SubAUrl $Pd_T_SubADir $Pd_T_SubBUrl $Pd_T_SubBDir)
	local actual2=(`Pd_FileSectionRead $Pd_T_SubsFile "#sub"`)
	
	$_ASSERT_EQUALS_ '"${expected1[*]}"' '"${actual1[*]}"'
	$_ASSERT_EQUALS_ '"${expected2[*]}"' '"${actual2[*]}"'
}

function Pd_ParamGetFromFile_DoesSubj()
{
	local actual1=`Pd_ParamGetFromFile $Pd_T_AuthFile login`
	
	local actual2=`Pd_ParamGetFromFile $Pd_T_AuthFile pass`
	
	test $Pd_T_CiLogin = $actual1 && local test1=true || local test1=false
	test $Pd_T_CiPass = $actual2 && local test2=true || local test2=false
	$_ASSERT_EQUALS_ true $test1
	$_ASSERT_EQUALS_ true $test2
}



