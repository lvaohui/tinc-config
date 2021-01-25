@echo off
cd /d %~dp0
set /p net_name="Net name [default: vpn]"
set /p host_name="Host name [default: node0]"

if "%net_name%"=="" (
    set net_name=vpn
)
if "%host_name%"=="" (
    set host_name=node0
)

set /p server_name="the server host name you will connect:"

set /p local_ipv4_addr="Local ipv4 address[default: 10.0.0.1]:"
set /p local_ipv6_addr="Local ipv6 address[default: fec0::1]:"

if "%local_ipv4_addr%"=="" (
    set local_ipv4_addr=10.0.0.1
)
if "%local_ipv6_addr%"=="" (
    set local_ipv6_addr=fec0::1
)

mkdir %net_name%
cd %net_name%

echo Name = %host_name% > tinc.conf
echo Interface = tinc >> tinc.conf
echo AddressFamily = any >> tinc.conf
echo ConnectTo = %server_name% >> tinc.conf
echo PrivateKeyFile = %cd%\rsa_key.priv >> tinc.conf

mkdir hosts
cd hosts
echo Subnet=%local_ipv4_addr%/32 > %host_name%
echo Subnet=%local_ipv6_addr%/128 >> %host_name%

cd ../../

::start.bat

echo @echo off > start.bat
echo ::open admin >> start.bat
echo ^>nul 2^>^&1 "%%SYSTEMROOT%%\system32\cacls.exe" "%%SYSTEMROOT%%\system32\config\system" >> start.bat
echo if '%%errorlevel%%' NEQ '0' ( >> start.bat
echo goto UACPrompt >> start.bat
echo ) else ( goto gotAdmin ) >> start.bat
echo :UACPrompt >> start.bat
echo echo Set UAC = CreateObject^^("Shell.Application"^^) ^> "%%temp%%\getadmin.vbs" >> start.bat
echo echo UAC.ShellExecute "%%~s0", "", "", "runas", 1 ^>^> "%%temp%%\getadmin.vbs" >> start.bat
echo "%%temp%%\getadmin.vbs" >> start.bat
echo exit /B >> start.bat
echo :gotAdmin >> start.bat
echo if exist "%%temp%%\getadmin.vbs" ( del "%%temp%%\getadmin.vbs" ) >> start.bat

echo cd /d %%~dp0 >> start.bat
echo tincd.exe -n %net_name% >> start.bat
echo pause >> start.bat


::stop.bat

echo @echo off > stop.bat
echo ::open admin >> stop.bat
echo ^>nul 2^>^&1 "%%SYSTEMROOT%%\system32\cacls.exe" "%%SYSTEMROOT%%\system32\config\system" >> stop.bat
echo if '%%errorlevel%%' NEQ '0' ( >> stop.bat
echo goto UACPrompt >> stop.bat
echo ) else ( goto gotAdmin ) >> stop.bat
echo :UACPrompt >> stop.bat
echo echo Set UAC = CreateObject^^("Shell.Application"^^) ^> "%%temp%%\getadmin.vbs" >> stop.bat
echo echo UAC.ShellExecute "%%~s0", "", "", "runas", 1 ^>^> "%%temp%%\getadmin.vbs" >> stop.bat
echo "%%temp%%\getadmin.vbs" >> stop.bat
echo exit /B >> stop.bat
echo :gotAdmin >> stop.bat
echo if exist "%%temp%%\getadmin.vbs" ( del "%%temp%%\getadmin.vbs" ) >> stop.bat

echo cd /d %%~dp0 >> stop.bat
echo tincd.exe -n %net_name% -k >> stop.bat
echo pause >> stop.bat


tincd.exe -n %net_name% -K 4096

pause