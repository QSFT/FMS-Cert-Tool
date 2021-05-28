@Echo off

REM Tool to replace Foglight Certificate
REM Create by Lee Ai
REM This is community based utility as @ 2017

cls

echo FMS certificate replacement tool v0.2
echo *************************************
echo This is simple tool to repalec Foglight Management Server certificate
echo Please copy this batch file to FMS Server $FGLHOME\bin and run from there
echo This tool will also backup exisitng tomecat.keystore file 
echo into $FGLHOME\config\CertBackup directory
echo *************************************

set /P _cert_ready=Are you read to continue? (Y/N) : 

if /I %_cert_ready% == n ( 

		goto quit
	)


set /P _cert_fmsname=Please enter FMS fully qualified domain name : 
set /P _cert_fmsip=Please enter FMS IP address : 
set /P _cert_validity=Please enter FMS certificate validity in days : 
set /P _cert_ou=Please enter your department name : 
set /p _cert_compnay= Please enter your company name : 
set /p _cert_city=Please enter your city name : 
set /p _cert_state=Please enter your state or province name : 
set /p _cert_country=Please enter your two letter country code : 


echo Backing up existing tomcat.keystore
echo *************************************

If  exist ..\config\CertBackup Goto BackupFolderExit
	md ..\config\CertBackup
:BackupFolderExit

copy ..\config\tomcat.keystore ..\config\Certbackup\tomcat.keystore.%date:~-4,4%%date:~-7,2%%date:~-10,2%

echo Deleting default out of box key
..\jre\bin\keytool -keystore ..\config\tomcat.keystore -storepass nitrogen -alias tomcat -delete


echo Creating new keypair
..\jre\bin\keytool -keystore ..\config\tomcat.keystore -storepass nitrogen -alias tomcat -keypass nitrogen -genkeypair -validity %_cert_validity% -keyalg RSA -keysize 2048 -dname "CN=%_cert_fmsname%, OU=%_cert_ou%, O=%_cert_compnay%, L=%_cert_city%, ST=%_cert_state%, C=%_cert_country%"  -ext san=dns:%_cert_fmsname%,ip:%_cert_fmsip%

echo Create CSR
..\jre\bin\keytool -keystore ..\config\tomcat.keystore -storepass nitrogen -alias tomcat -certreq -ext san=dns:%_cert_fmsname%,ip:%_cert_fmsip% -file %COMPUTERNAME%.csr

echo Backing up tomcat.keystore after generate CSR
copy ..\config\tomcat.keystore ..\config\Certbackup\tomcat.keystore.aftercsr.%date:~-4,4%%date:~-7,2%%date:~-10,2%
start notepad %COMPUTERNAME%.csr

echo *************************************
echo  pleae send %COMPUTERNAME%.csr (opened in notepad) to your certificate authority to get signed
echo  and copy singed certificate to current location/folder once you received
echo  then press space bar to continue 
echo *************************************

pause

rem setlocal EnableDelayedExpansion
set /P _cert_p7b_format=Is signed certifcate in p7b format? (Y/N) : 
(
		if /I %_cert_p7b_format% == n (
rem		set /P _cert_p7b_file=please enter full name on the signed certificate you received :
rem		..\jre\bin\keytool -keystore ..\config\tomcat.keystore -storepass nitrogen -keypass nitrogen -alias tomcat -import -trustcacerts -noprompt -file %_cert_p7b_file%
		goto NotP7b
	)
)

set /P _cert_p7b_file=please enter full name on the signed certificate you received :
..\jre\bin\keytool -keystore ..\config\tomcat.keystore -storepass nitrogen -keypass nitrogen -alias tomcat -import -trustcacerts -noprompt -file %_cert_p7b_file%
goto end

:NotP7b


echo *************************************
echo Please extract all individual and CA certificate to current location/folder and press space bar to continue
echo *************************************

pause

echo importing root CA
set /P _cert_Rootca_name=Please enter root CA certificate file name : 
..\jre\bin\keytool -keystore ..\config\tomcat.keystore -storepass nitrogen -alias FMSRootCA  -trustcacerts -noprompt -import -file %_cert_Rootca_name%

set /A _cert_intermediaCA_count=0

:ImportintermediaCACertiticate
set /P _cert_more_CA=Do you have any more intermedia CA? (Y/N) : 
set /A _cert_intermediaCA_count=_cert_intermediaCA_count+1

if /I %_cert_more_CA% == n ( 

		goto ImportFMSCertiticate
	)

set /P _cert_intermediaCA_count_name=Please enter your %_cert_intermediaCA_count% intermedia CA certificate file name : 
echo import %_cert_intermediaCA_count% intermedia CA certificate
..\jre\bin\keytool -keystore ..\config\tomcat.keystore -storepass nitrogen -alias %_cert_intermediaCA_count%  -trustcacerts  -import -file %_cert_intermediaCA_count_name% -noprompt

goto ImportintermediaCACertiticate

:ImportFMSCertiticate
echo Importing FMS certificate
set /P _cert_fms_certificate_name=Please enter your FMS certificate file name : 
..\jre\bin\keytool -keystore ..\config\tomcat.keystore -storepass nitrogen -alias tomcat  -trustcacerts -noprompt -import -file %_cert_fms_certificate_name%

:end

echo *************************************
echo Certificate import successful and please restart your FMS server
echo Please also update your FGLAM configruation to use new certificate
echo press space bar to exit the program
echo *************************************
pause

:quit
