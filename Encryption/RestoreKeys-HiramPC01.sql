/********************************************************************************/
-- AUTHOR: 	Hiram Fleitas, hiramfleitas@hotmail.com, http://dba2o.wordpress.com
-- DATE: 2017/09/18
-- VERSION: SQL 2014 - 2016 Dev and Enterprise Editions.
-- PURPOSE: Restore Keys and Certs for automatic Backup decryption/encryption.
-- USAGE: Run script on other servers than the @source, unless its a rebuild.
--		For example, run on secondary replicas or other standalone instances that 
---		need to decrypt backups from @source server.
-- 	@Go = 0 will print only. Run printed output if desired.
/********************************************************************************/
--:connect HiramPC02
use master
go
declare	 @source		sysname = 'HiramPC01'
		;

declare  @Go			bit = 0 --0 print only, 1 run exec !

		,@smkpass		nvarchar(128) = 'w@k3b0ard_!_Master' --password here.
		,@smkBakpass	nvarchar(128) = 'w@k3b0ard_!_Master17' --password here.
		,@smkBakFile	nvarchar(max) = 'Donot_delete_'+@source+'-SMK.bak'
		,@path1			nvarchar(max) = '\\NetworkShare\SqlShared\HiramPC01\Deployments\'
		,@ResVerify		nvarchar(max) = '\\NetworkShare\SqlShared\HiramPC01\System\msdb_backup_2017_09_19_153632_2641505.bak'
		,@smkRES		nvarchar(max)
		;

declare	 @dmkRES		nvarchar(max) 
		,@dmkBakFile	nvarchar(max) = 'Donot_delete_'+@source+'-DMK-ExportedMasterKey.bak'
		,@dmkpass		nvarchar(128) = @smkpass
		,@dmkBakpass	nvarchar(128) = @smkBakpass
		,@verifyMK		nvarchar(max)

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

select @smkRES = N'RESTORE SERVICE MASTER KEY FROM FILE = '''+@path1+@smkBakFile+''' DECRYPTION BY PASSWORD = '''+@smkBakpass+''' ; ';
print @smkRES; 
if @Go = 1 exec sp_executesql @smkRES; 
select @dmkRES = N'CREATE MASTER KEY ENCRYPTION BY PASSWORD = '''+@smkpass+''' ; ';
print @dmkRES; 
if @Go = 1 exec sp_executesql @dmkRES;

--Verify Master Key works.
select @verifyMK = 
		N'OPEN MASTER KEY DECRYPTION BY PASSWORD = '''+@smkpass+''';
		CLOSE MASTER KEY ;';
print @verifyMK; 
if @Go = 1 exec sp_executesql @verifyMK;

--restore certwithenc
select @CrtBakFile = 'Donot_delete_'+@source+'_'+@CrtWithEnc+'.cer'
select @CrtPKFile = 'Donot_delete_'+@source+'_'+@CrtWithEnc+'.key'
select @CrtBak = N'CREATE CERTIFICATE ['+@CrtWithEnc+'] FROM FILE = '''+@path1+@CrtBakFile+''' WITH PRIVATE KEY (DECRYPTION BY PASSWORD = '''+@CrtPkPass+''', FILE = '''+@path1+@CrtPKFile+''', ENCRYPTION BY PASSWORD = '''+@CrtEncPass+''') ; '
print @CrtBak; 
if @Go = 1 exec sp_executesql @CrtBak;

--restore certwithpk
select @CrtBakFile = 'Donot_delete_'+@source+'_'+@CrtWithPK+'.cer'
select @CrtPKFile = 'Donot_delete_'+@source+'_'+@CrtWithPK+'.key'
select @CrtBak = N'CREATE CERTIFICATE ['+@CrtWithPK+'] FROM FILE = '''+@path1+@CrtBakFile+''' WITH PRIVATE KEY (FILE = '''+@path1+@CrtPKFile+''', DECRYPTION BY PASSWORD = '''+@CrtPkPass+''') ; '
print @CrtBak; 
if @Go = 1 exec sp_executesql @CrtBak;

Print '--TEST RESTORE VERIFY:
	RESTORE VERIFYONLY FROM DISK = '''+@ResVerify+''' WITH FILE = 1, NOUNLOAD, NOREWIND;'


--FINISHED, BELOW THIS IS TESTING STUFF.
goto skipped

	--troubleshooting.
	select name from sys.databases where is_master_key_encrypted_by_server=1
	drop certificate backupcertwithpk
	drop master key
	
skipped:
go