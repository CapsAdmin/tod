set WORKSHOP_ID=0

cd /d "%~dp0"
cd ../../../bin/

gmad create -folder "%~dp0\" -out "%~dp0\..\__TEMP.gma"
gmpublish update -addon "%~dp0\..\__TEMP.gma" -id "%WORKSHOP_ID%"
del %~dp0\..\__TEMP.gma

pause