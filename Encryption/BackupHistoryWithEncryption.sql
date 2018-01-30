:connect HiramPC01
go
SELECT TOP 10 bmf.media_set_id, family_sequence_number, media_family_id, physical_device_name, name, database_name, server_name, key_algorithm, encryptor_thumbprint, encryptor_type
FROM   msdb.dbo.backupmediafamily as bmf
INNER JOIN msdb.dbo.backupset as bs ON bmf.media_set_id = bs.media_set_id  
WHERE  bs.type = 'D' and bs.database_name IN ('master')
ORDER BY backup_start_date desc

go

:connect HiramPC02
SELECT TOP 10 bmf.media_set_id, family_sequence_number, media_family_id, physical_device_name, name, database_name, server_name, key_algorithm, encryptor_thumbprint, encryptor_type
FROM   msdb.dbo.backupmediafamily as bmf
INNER JOIN msdb.dbo.backupset as bs ON bmf.media_set_id = bs.media_set_id  
WHERE  bs.type = 'D' and bs.database_name IN ('master')
ORDER BY backup_start_date desc

go