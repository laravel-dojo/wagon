 _   _           ___                  
| | | |         / _ \                 
| | | |_      _/ /_\ \_ __ ___  _ __  
| | | \ \ /\ / /  _  | '_ ` _ \| '_ \ 
| |_| |\ V  V /| | | | | | | | | |_) |
 \___/  \_/\_/ \_| |_/_| |_| |_| .__/ 
                               | |    
                               |_|    

01010101 01110111 01000001 01101101 01110000 
V 3.1.0		www.uwamp.com
--------------------------------------------


Apache config file : 
	UwAmp\bin\apache\conf\httpd_uwamp.conf

PHP config file : 
	UwAmp\bin\php\CURRENT PHP VERSION\php_uwamp.ini
		

MYSQL config file : 
	UwAmp\bin\database\mysql\my_uwamp.ini


MYSQL PASSWORD : 
	user : root
	password : root


Available Macro in setting: 

	{TEMPPATH}			= UwAmp\temp
	{APACHEPATH} 			= UwAmp\bin\apache
	{DOCUMENTPATH} 			= UwAmp\www
	{PHPAPPS}			= UwAMp\phpapps
	{PHPPATH} 			= UwAmp\bin\php\CURRENT PHP IN UWAMP CONTROL\
	{PHPAPACHE2FILE} 		= UwAmp\bin\php\CURRENT PHP IN UWAMP CONTROL\CURRENT apache2.dll
	{PHPEXTPATH} 			= UwAmp\bin\php\CURRENT PHP IN UWAMP CONTROL\ext
	{PHPZENDPATH} 			= UwAmp\bin\php\CURRENT PHP IN UWAMP CONTROL\zend_ext
	{PHPMODULENAME}			= Module name of current php version
	{LISTEN_VIRTUAL_HOST_PORT}	= Apache Listens ports

	{MYSQLPATH}			= UwAmp\bin\database\mysql\
	{MYSQLBINPATH}			= UwAmp\bin\database\mysql\bin
	{MYSQLDATAPATH}			= UwAmp\bin\database\mysql\data

	{ONLINE_MODE}			= Require all granted
			OR
					= Require local

	if ONLINE_MODE is set to Online the serveur is available for all IP
	if ONLINE_MODE is set to Offline the serveur is available just for 127.0.0.1

