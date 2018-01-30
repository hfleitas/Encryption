/********************************************************************************/
-- AUTHOR: 	Hiram Fleitas, hiramfleitas@hotmail.com, http://dba2o.wordpress.com
-- DATE: 2017/09/18
-- VERSION: SQL 2014 - 2016 Dev and Enterprise Editions.
-- PURPOSE: Setup Keys and Certs for Backup encryption.
-- USAGE: Run script on Primary replica or standalone instance. 
-- 		@Go = 0 will print only. Run printed output if desired.
/********************************************************************************/
--:connect HiramPC01
use master
go
declare  @Go			bit = 0 --0 print only, 1 run exec !

		,@smkpass		nvarchar(128) = 'w@k3b0ard_!_Master' --password here.
		,@smkBakpass	nvarchar(128) = 'w@k3b0ard_!_Master17' --password here.
		,@createsmk		nvarchar(max) 
		,@smkbak		nvarchar(max)
		,@smkBakFile	nvarchar(max) 
		
		--Store keys in 3 places or in a safe or cloud key vault. Create folders if not exist.
		,@path1			nvarchar(max) = '\\NetworkShare\SqlShared\HiramPC01\Deployments\'
		,@path2			nvarchar(max) = 'C:\Deployments\'
		,@path3			nvarchar(max) = 'C:\Windows\'
		;

declare	 @dmkbak		nvarchar(max) 
		,@dmkBakFile	nvarchar(max) 
		,@dmkpass		nvarchar(128) = @smkpass
		,@dmkBakpass	nvarchar(128) = @smkBakpass

		,@CrtWithEnc	sysname = 'BackupCertWithEnc'
		,@CrtWithPK		sysname = 'BackupCertWithPK' 
		,@CrtEncPass	nvarchar(128) = 'w@k3b0ard=!Master17' --password here.
		,@CrtPkPass		nvarchar(128) = 'w@k3b0ard=Master17' --password here.
		,@CreateCrt		nvarchar(max) 
		,@Sub1			nvarchar(max) = 'Certificate for SQL backups with Encryption'
		,@Sub2			nvarchar(max) = 'Certificate for SQL backups with Private Key'
		,@CrtBak		nvarchar(max)
		,@CrtPKFile		nvarchar(max) 
		,@CrtBakFile	nvarchar(max) 
		;
		
/*** KEYs ***/
select @createsmk = 'CREATE MASTER KEY ENCRYPTION BY PASSWORD = '''+@smkpass+''';'
print @createsmk; 
if @Go = 1 exec sp_executesql @createsmk;

--Backup SERVICE master key - SUPER IMPORTANT!!!!
select @smkBakFile = 'Donot_delete_'+@@SERVERNAME+'-SMK.bak'
select @smkbak = 
		N'OPEN MASTER KEY DECRYPTION BY PASSWORD = '''+@smkpass+''';
		BACKUP SERVICE MASTER KEY TO FILE = '''+@path1+@smkBakFile+''' ENCRYPTION BY PASSWORD = '''+@smkBakpass+''' ;  
		BACKUP SERVICE MASTER KEY TO FILE = '''+@path2+@smkBakFile+''' ENCRYPTION BY PASSWORD = '''+@smkBakpass+''' ; 
		BACKUP SERVICE MASTER KEY TO FILE = '''+@path3+@smkBakFile+''' ENCRYPTION BY PASSWORD = '''+@smkBakpass+''' ; 
		CLOSE MASTER KEY ;';
print @smkbak; 
if @Go = 1 exec sp_executesql @smkbak;

--Backup DMKeys - SUPER IMPORTANT!!!!
select @dmkBakFile = 'Donot_delete_'+@@SERVERNAME+'-DMK-ExportedMasterKey.bak';
select @dmkbak = 
		N'OPEN MASTER KEY DECRYPTION BY PASSWORD = '''+@dmkpass+''';
		BACKUP MASTER KEY TO FILE = '''+@path1+@dmkBakFile+''' ENCRYPTION BY PASSWORD = '''+@dmkBakpass+''' ;  
		BACKUP MASTER KEY TO FILE = '''+@path2+@dmkBakFile+''' ENCRYPTION BY PASSWORD = '''+@dmkBakpass+''' ; 
		BACKUP MASTER KEY TO FILE = '''+@path3+@dmkBakFile+''' ENCRYPTION BY PASSWORD = '''+@dmkBakpass+''' ; 
		CLOSE MASTER KEY ;';
print @dmkbak; 
if @Go = 1 exec sp_executesql @dmkbak;

/*** CERTs ***/
select @CreateCrt = 
		N'CREATE CERTIFICATE ['+@CrtWithEnc+'] ENCRYPTION BY PASSWORD = '''+@CrtEncPass+''' WITH SUBJECT = '''+@Sub1+''' ;
		CREATE CERTIFICATE ['+@CrtWithPK+'] WITH SUBJECT = '''+@Sub2+''' ;';
print @CreateCrt; 
if @Go = 1 exec sp_executesql @CreateCrt;

--Backup Cert - SUPER IMPORTANT!!!!
select @CrtBakFile = 'Donot_delete_'+@@SERVERNAME+'_'+@CrtWithEnc+'.cer'
select @CrtPKFile = 'Donot_delete_'+@@SERVERNAME+'_'+@CrtWithEnc+'.key'
select @CrtBak = 
		N'BACKUP CERTIFICATE ['+@CrtWithEnc+'] TO FILE = '''+@path1+@CrtBakFile+''' WITH PRIVATE KEY (FILE = '''+@path1+@CrtPKFile+''', DECRYPTION BY PASSWORD = '''+@CrtEncPass+''', ENCRYPTION BY PASSWORD = '''+@CrtPkPass+''') ;
		BACKUP CERTIFICATE ['+@CrtWithEnc+'] TO FILE = '''+@path2+@CrtBakFile+''' WITH PRIVATE KEY (FILE = '''+@path2+@CrtPKFile+''', DECRYPTION BY PASSWORD = '''+@CrtEncPass+''', ENCRYPTION BY PASSWORD = '''+@CrtPkPass+''') ;
		BACKUP CERTIFICATE ['+@CrtWithEnc+'] TO FILE = '''+@path3+@CrtBakFile+''' WITH PRIVATE KEY (FILE = '''+@path3+@CrtPKFile+''', DECRYPTION BY PASSWORD = '''+@CrtEncPass+''', ENCRYPTION BY PASSWORD = '''+@CrtPkPass+''') ;
		;';
print @CrtBak; 
if @Go = 1 exec sp_executesql @CrtBak;

select @CrtBakFile = 'Donot_delete_'+@@SERVERNAME+'_'+@CrtWithPK+'.cer'
select @CrtPKFile = 'Donot_delete_'+@@SERVERNAME+'_'+@CrtWithPK+'.key'
select @CrtBak = 
		N'BACKUP CERTIFICATE ['+@CrtWithPK+'] TO FILE = '''+@path1+@CrtBakFile+''' WITH PRIVATE KEY (FILE = '''+@path1+@CrtPKFile+''', ENCRYPTION BY PASSWORD = '''+@CrtPkPass+''') ;
		BACKUP CERTIFICATE ['+@CrtWithPK+'] TO FILE = '''+@path2+@CrtBakFile+''' WITH PRIVATE KEY (FILE = '''+@path2+@CrtPKFile+''', ENCRYPTION BY PASSWORD = '''+@CrtPkPass+''') ;
		BACKUP CERTIFICATE ['+@CrtWithPK+'] TO FILE = '''+@path3+@CrtBakFile+''' WITH PRIVATE KEY (FILE = '''+@path3+@CrtPKFile+''', ENCRYPTION BY PASSWORD = '''+@CrtPkPass+''') ;
		;';
print @CrtBak; 
if @Go = 1 exec sp_executesql @CrtBak;

PRINT '--Set all Backup maintenance plans (SystemDBs/UserDBs/Full/Diff/Tlog) to use Algorithm AES 256 (or greater) and Cert '+@CrtWithPK+'. '

/*ROLLBACK UNDO/CLEANUP */
PRINT '/*** 
--ROLLBACK if required.
drop CERTIFICATE '+@CrtWithEnc+'
drop CERTIFICATE '+@CrtWithPK+'
drop master key
--With sqlcmd mode:
:!!if exist '+@path1+@CrtBakFile+' del '+@path1+@CrtBakFile+'
:!!if exist '+@path2+@CrtBakFile+' del /f '+@path2+@CrtBakFile+'
:!!if exist '+@path3+@CrtBakFile+' del /f '+@path3+@CrtBakFile+'

:!!if exist '+@path1+@CrtPKFile+' del '+@path1+@CrtPKFile+'
:!!if exist '+@path2+@CrtPKFile+' del /f '+@path2+@CrtPKFile+'
:!!if exist '+@path3+@CrtPKFile+' del /f '+@path3+@CrtPKFile+'

:!!if exist '+@path1+@dmkBakFile+' del '+@path1+@dmkBakFile+'
:!!if exist '+@path2+@dmkBakFile+' del /f '+@path2+@dmkBakFile+'
:!!if exist '+@path3+@dmkBakFile+' del /f '+@path3+@dmkBakFile+'

:!!if exist '+@path1+@smkBakFile+' del '+@path1+@smkBakFile+'
:!!if exist '+@path2+@smkBakFile+' del /f '+@path2+@smkBakFile+'
:!!if exist '+@path3+@smkBakFile+' del /f '+@path3+@smkBakFile+'

:!!if exist '+@path1+'Donot_delete_'+@@SERVERNAME+'_'+@CrtWithEnc+'.cer'+' del '+@path1+'Donot_delete_'+@@SERVERNAME+'_'+@CrtWithEnc+'.cer'+'
:!!if exist '+@path2+'Donot_delete_'+@@SERVERNAME+'_'+@CrtWithEnc+'.cer'+' del /f '+@path2+'Donot_delete_'+@@SERVERNAME+'_'+@CrtWithEnc+'.cer'+'
:!!if exist '+@path3+'Donot_delete_'+@@SERVERNAME+'_'+@CrtWithEnc+'.cer'+' del /f '+@path3+'Donot_delete_'+@@SERVERNAME+'_'+@CrtWithEnc+'.cer'+'
:!!if exist '+@path1+'Donot_delete_'+@@SERVERNAME+'_'+@CrtWithEnc+'.key'+' del '+@path1+'Donot_delete_'+@@SERVERNAME+'_'+@CrtWithEnc+'.key'+'
:!!if exist '+@path2+'Donot_delete_'+@@SERVERNAME+'_'+@CrtWithEnc+'.key'+' del /f '+@path2+'Donot_delete_'+@@SERVERNAME+'_'+@CrtWithEnc+'.key'+'
:!!if exist '+@path3+'Donot_delete_'+@@SERVERNAME+'_'+@CrtWithEnc+'.key'+' del /f '+@path3+'Donot_delete_'+@@SERVERNAME+'_'+@CrtWithEnc+'.key'+'
***/'
go