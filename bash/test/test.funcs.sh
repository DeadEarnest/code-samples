



function Tf_Kill()
{
	local grepStr=$1
	
	ps -W | grep -i ${grepStr} | awk '{print $1}' | \
		while read pid; do taskkill /F /PID ${pid}; done;
}




function Tf_Sleep()
{
	local time=$1
	
	echo sleep $time started
	sleep $time
	echo sleep $time ended
}




function Tf_AssertElemsEqual()
{
	local expected=($1)
	local actual=($2)
	local expectedLen=${#expected[*]}
	local actualLen=${#actual[*]}
	
	$_ASSERT_EQUALS_ "'Elements have different length!'" $expectedLen $actualLen
	
	local equals=true	
	for i in ${!expected[*]}; do
		local exp="${expected[$i]}"
		local act="${actual[$i]}"
		
		test $exp = $act && equals=true || equals=false
		
		if [ $equals == false ]; then
			echo -=-=-=-=-=-=-=-=-=-=-
			echo "expected [charNum = ${#exp}]:"
			echo "$exp"
			echo "actual [charNum = ${#act}]:"
			echo "$act"
			echo -=-=-=-=-=-=-=-=-=-=-
			return 1
		fi
	done
}




declare Tf_SavedLinesNum=-1
declare Tf_SavedLines=('')

function Tf_FileReadLines()
{
	local file=$1
	local startLineNum=$2
	
	Tf_SavedLinesNum=0
	local readLinesNum=0
	
	while read -r line; do
		((readLinesNum++))
		if (( $readLinesNum < $startLineNum )); then
			continue
		fi
				
		Tf_SavedLines[$Tf_SavedLinesNum]="$line"
		((Tf_SavedLinesNum++))
	done < $file
}

function Tf_SavedLinesEcho()
{
	for i in ${!Tf_SavedLines[*]}; do
    	echo "${Tf_SavedLines[$i]}"
	done
}



