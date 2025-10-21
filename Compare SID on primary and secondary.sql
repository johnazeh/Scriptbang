------select name and sid into a temp table that will be deleted
select name, sid 
INTO #PrimaryLogin
from sys.server_principals
where type IN ('S','U','G')


---Import name and sid into a permanent table

select * into PrimaryLogin
From #PrimaryLogin

drop table  #PrimaryLogin



--------on secondary instance

---Import data from Primary instance (PrimaryLogin)  to seconadry instance table (PrimaryLogin)

------select name and sid into a temp table that will be deleted
select name, sid 
INTO #SecondaryLogin
from sys.server_principals
where type IN ('S','U','G')


---Import name and sid into a permanent table

select * into SecondaryLogin
From #SecondaryLogin

----drop table  #SecondaryLogin


------Compare sids between Primary and secondary

SELECT 
    s.name AS SecondaryLogin,
    p.sid AS PrimarySID,
    s.sid AS SecondarySID,
    CASE 
        WHEN p.sid IS NULL THEN 'Missing on Primary'
        WHEN s.sid IS NULL THEN 'Missing on Secondary'
        WHEN p.sid <> s.sid THEN 'SID Mismatch'
        ELSE 'Match'
    END AS Status
FROM sys.server_principals s
LEFT JOIN PrimaryLogin p ON s.name = p.name
WHERE s.type IN ('S', 'U','G')
ORDER BY s.name;

