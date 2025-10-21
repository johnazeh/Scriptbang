USE msdb;
GO

-- Check Database Mail profile and account settings
SELECT 
    p.name AS ProfileName,
    a.name AS AccountName,
    a.email_address AS FromAddress,
    a.display_name AS DisplayName,
    a.replyto_address AS ReplyTo,
    s.servername AS SMTPServer,
    s.port AS SMTPPort,
    s.enable_ssl AS SSLEnabled
FROM dbo.sysmail_profile AS p
JOIN dbo.sysmail_profileaccount AS pa ON p.profile_id = pa.profile_id
JOIN dbo.sysmail_account AS a ON pa.account_id = a.account_id
JOIN dbo.sysmail_server AS s ON a.account_id = s.account_id;
