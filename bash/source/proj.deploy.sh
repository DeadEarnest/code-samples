#! /bin/bash




function Pd_Win_ProjDeploy()
{
	echo
	Pd_FuncStart 'Pd_Win_VarsSetup' $1 $2 $3 $4 $5 $6
	Pd_FuncStart 'Pd_Win_ProjStop'
	Pd_FuncStart 'Pd_Win_DirsSetup'
	Pd_FuncStart 'Pd_Win_CfgFilesSetup'
	Pd_FuncStart 'Pd_Win_SubsLoad'
	Pd_FuncStart 'Pd_Win_DbSetup'
}




function Pd_FuncStart()
{
	local funcName=$1
	
	echo '['`date +'%m-%d %H:%M:%S'`'] '"$funcName start."
	$funcName $2 $3 $4 $5 $6 $7 $8 $9 \
		&& echo '['`date +'%m-%d %H:%M:%S'`'] '"$funcName successfull." \
		|| echo '['`date +'%m-%d %H:%M:%S'`'] '"$funcName failed."
	echo
}




function Pd_Win_DbSetup()
{
	Pd_DbCreate $Pd_ProjName $Pd_ProjDir $Pd_WccoaDir
	$Pd_WccoaDir'bin/WCCILpmon.exe' -proj $Pd_ProjName -port $Pd_PmonPort &
	sleep 5
	
	# extra 2 are needed, because the first one doesn't delete all standard dpts
	$Pd_Utils $Pd_Version dpts.purge.external
	$Pd_Utils $Pd_Version dpts.purge.external
	$Pd_Utils $Pd_Version dpts.purge.external
	
	Pd_DbFill $Pd_Version $Pd_DbFillFile $Pd_MainDplistDir \
		$Pd_SvnLogin $Pd_SvnPass $Pd_Utils
	
	$Pd_WccoaDir'bin/WCCILpmon.exe' -proj $Pd_ProjName -port $Pd_PmonPort -stopWait
}

function Pd_Win_SubsLoad()
{
	Pd_SvnItemsExport "${Pd_MainSrcDest[*]}" $Pd_SvnLogin $Pd_SvnPass
	
	for i in ${!Pd_SubsSrcDest[*]}; do
		if (($i % 2 == 0)); then
			continue
		fi
		
		local dest=${Pd_SubsSrcDest[(($i))]}
		
		[ -d $dest ] && rm -r $dest
	done
	
	Pd_SvnItemsExport "${Pd_SubsSrcDest[*]}" $Pd_SvnLogin $Pd_SvnPass
}

function Pd_Win_CfgFilesSetup()
{
	Pd_ProjCfg_Setup $Pd_TemplateCfgDir $Pd_CfgDir $Pd_Version \
		$Pd_ProjDir "${Pd_SubsSrcDest[*]}" 'win'
	local winProjDir=`cygpath -w -a $Pd_ProjDir`'\'
	
	Pd_ProjUnregister $Pd_RegFile $Pd_RegFile $Pd_ProjName
	Pd_ProjRegister $Pd_RegFile $Pd_ProjName $winProjDir $Pd_Version 'time' 'user'
}




function Pd_Win_DirsSetup()
{
	[ -d $Pd_ProjDir ] && rm -r $Pd_ProjDir
	[ -d $Pd_ProjDir ] || mkdir $Pd_ProjDir
	
	[ -d $Pd_CfgDir ] || mkdir $Pd_CfgDir
	[ -d $Pd_DataDir ] || mkdir $Pd_DataDir
	[ -d $Pd_MainDplistDir ] || mkdir $Pd_MainDplistDir
}

function Pd_Win_ProjStop()
{
	$Pd_WccoaDir'bin/WCCILpmon.exe' -proj $Pd_ProjName -port $Pd_PmonPort -stopWait
}

function Pd_Win_VarsSetup()
{
	declare -g Pd_Version=$1
	declare -g Pd_ProjDir=`Pd_PathNormalize $2 'dir'`
	declare -g Pd_ProjName=$3
	declare -g Pd_PmonPort=$4
	declare -g Pd_ResourcesDir=`Pd_PathNormalize $5 'dir'`
	declare -g Pd_Utils=`Pd_PathNormalize $6 'file'`
	
	declare -g Pd_CfgDir=$Pd_ProjDir'config/'
	declare -g Pd_DataDir=$Pd_ProjDir'data/'
	declare -g Pd_MainDplistDir=$Pd_ProjDir'dplist/'
	declare -g Pd_TemplateCfgDir=$Pd_ResourcesDir'config.template/'
	declare -g Pd_SvnSrcDestFile=$Pd_ResourcesDir'svn.src.dest.txt'
	declare -g Pd_DbFillFile=$Pd_ResourcesDir'db.fill.txt'
	
	declare -g Pd_WccoaDir='C:/Siemens/Automation/WinCC_OA/'$Pd_Version'/'
	declare -g Pd_RegFile='C:/ProgramData/Siemens/WinCC_OA/pvssInst.conf'
	
	declare -g Pd_MainSrcDest=(`Pd_FileSectionRead $Pd_SvnSrcDestFile "#main"`)
	declare -g Pd_SubsSrcDest=(`Pd_FileSectionRead $Pd_SvnSrcDestFile "#sub"`)
	
	declare -g Pd_SvnLogin=`Pd_ParamGetFromFile $Pd_ResourcesDir'svn.auth.txt' login`
	declare -g 	Pd_SvnPass=`Pd_ParamGetFromFile $Pd_ResourcesDir'svn.auth.txt' pass`
}




function Pd_DbFill()
{
	local version=$1
	local dbFillFile=$2
	local dpListDir=$3
	local login=$4
	local pass=$5
	local impExpUtil=$6
	
	local i=0
	local itemsSrcDest
	
	while read line; do
		itemsSrcDest[$i]=$line
		itemsSrcDest[(($i + 1))]=$dpListDir
		((i += 2))
	done < $dbFillFile
	
	Pd_SvnItemsExport "${itemsSrcDest[*]}" $login $pass
	
	for file in $dpListDir*; do
		$impExpUtil $version 'json.import.dpts' $file
	done
}

function Pd_DbCreate()
{
	local projName=$1
	local projDir=$2
	local wccoaDir=$3
	
	mkdir $projDir'/db'
	mkdir $projDir'/db/wincc_oa'
	mkdir $projDir'/log'
	
	$wccoaDir'bin/WCCOAtoolcreateDB.exe' -proj $projName -yes &> /dev/null
}

function Pd_ProjUnregister()
{
	local baseFile=$1
	local resultFile=$2
	local projName=$3
	local regex="s|\[[^\n]*?$projName\].*?InstallationDir.*?\n||gms"
	
	[ $baseFile != $resultFile ] && cp $baseFile $resultFile
	perl -0777 -pi -e $regex $resultFile
}

function Pd_ProjRegister()
{
	local regFile=$1
	local projName=$2
	local projDir=$3
	local version=$4
	local time=$5
	local user=$6
	
	local lines
	lines[0]='[Software\ETM\PVSS II\Configs\'"$projName]"
	lines[1]="notRunnable = 0"
	lines[2]="InstallationDate = \"$time\""
	lines[3]="InstallationUser = \"$user\""
	lines[4]="InstallationVersion = \"$version\""
	lines[5]="PVSS_II = \"$projDir"'config\config"'
	lines[6]="InstallationDir = \"$projDir\""
	
	for i in ${!lines[*]}; do
    	echo ${lines[$i]} >> $regFile
	done
}

function Pd_ProjCfg_Setup()
{
	local src=$1
	local dest=$2
	local wccoaVersion=$3
	local projDir=$(echo $4 | sed 's;\\;/;g')
	local subprojDirs=$5
	local os=$6
	local cfgFile=$projDir'config/config'
	
	cp -r $src* $dest
	Pd_ProjCfg_SetupMainSection $cfgFile "$wccoaVersion" $projDir $os
	Pd_PrjCfg_SetupBaseSection $cfgFile "$wccoaVersion"
	Pd_ProjCfg_SetupSubSection $cfgFile "${subprojDirs[*]}" $os
}




function Pd_ProjCfg_SetupMainSection()
{
	local cfgFile=$1
	local wccoaVersion=$2
	local projDir=$3
	local os=$4
	
	local lineNum=`grep -n '#main*' ${cfgFile} | cut -d: -f1`
	projDir=`Pd_PathGet_ForOs $projDir 'dir' $os`
	
	sed -i "$lineNum,+1s;proj_path =.*;proj_path = \"$projDir\";" $cfgFile
	sed -i "s;proj_version =.*;proj_version = \"$wccoaVersion\";g" $cfgFile
}

function Pd_PrjCfg_SetupBaseSection()
{
	local cfgFile=$1
	local wccoaVersion=$2
	local wccoaPathStub='C:\/Siemens\/Automation\/WinCC_OA\/'
	
	sed -i "s;pvss_path =.*;pvss_path = \"$wccoaPathStub$wccoaVersion\";" $cfgFile
}

function Pd_ProjCfg_SetupSubSection()
{
	local cfgFile=$1
	local subprojDirs=($2)
	local os=$3
	
	for i in ${!subprojDirs[*]}; do
		if (($i % 2 == 0)); then
			continue
		fi
		
		local subprojPath=${subprojDirs[$i]}
		subprojPath=`Pd_PathGet_ForOs $subprojPath 'dir' $os`
		
		sed -i "s;#sub;#sub\nproj_path = \"$subprojPath\";" $cfgFile
	done
}




function Pd_PathGet_ForOs()
{
	local linuxPath=$1
	local type=$2
	local os=$3
	local result
	
	if [ $os = 'win' ]; then
		result=`cygpath -w -a -m $linuxPath`
	fi
	
	if [ $os = 'linux' ]; then
		result=$linuxPath
	fi
	
	if [ $type = 'dir' ]; then
		result=`Pd_PathNormalize $result 'dir'`
	fi
	
	echo $result
}




function Pd_SvnItemsExport()
{
	local itemsSrcDest=($1)
	local login=$2
	local pass=$3
	
	for i in ${!itemsSrcDest[*]}; do
		if (($i % 2 == 0)); then
			continue
		fi
		
		local src=${itemsSrcDest[(($i - 1))]}
		local dest=${itemsSrcDest[(($i))]}
		
		Pd_SvnItemExport $src $dest $login $pass
	done
}




function Pd_SvnItemExport()
{
	local src=$1
	local dest=$2
	local login=$3
	local pass=$4
	
	dest=`Pd_PathNormalize $dest 'dir'`
	
	if [[ "${src}" == http* ]]; then
		svn export ${src} ${dest} --username ${login} --password ${pass} --force -q --no-auth-cache
	fi
	
	chmod -R 777 ${dest}
}




function Pd_PathNormalize()
{
	local path=$1
	local type=$2
	
	path=`cygpath -m $path`
	[ $type = 'dir' ] && path=$(echo $path | sed 's;\(\w\)$;\1/;g')
	
	echo $path
}




function Pd_FileSectionRead()
{
	local file=$1
	local sectionName=$2
	local sectionFound=false
	
	while read line; do
		if [[ "$line" =~ .*$sectionName ]]; then
			sectionFound=true
			continue
		fi
		
		if [ -z "$line" ]; then
			sectionFound=false
			continue
		fi
		
		if [ $sectionFound == true ]; then
			echo $line
		fi
		
	done < $file
}

function Pd_ParamGetFromFile()
{
	local file=$1
	local paramName=$2
	
	echo `grep "$paramName" $file | sed 's; ;;g' | cut -d "=" -f2`
}



