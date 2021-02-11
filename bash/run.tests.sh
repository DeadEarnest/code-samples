#! /bin/bash




function main()
{
	. source/proj.deploy.sh
	. test/proj.deploy.sh
	. test/test.funcs.sh
	
	Pd_Test_VarsSetup '3.14' './test/resources/' './test/temp/' \
		'../../tools/utils/utils.bat'
	
	local shUnitDir='./shunit2/'
	. $shUnitDir'shunit2'
}




main
