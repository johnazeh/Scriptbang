SELECT 
   t.NAME AS table_name,
   SUM(p.rows) AS row_count,
   CAST(SUM(a.total_pages) * 8 / 1024.0 / 1024.0 AS DECIMAL(10, 2)) AS size_gb
FROM 
   sys.tables t
INNER JOIN 
   sys.indexes i ON t.OBJECT_ID = i.object_id
INNER JOIN 
   sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
INNER JOIN 
   sys.allocation_units a ON p.partition_id = a.container_id
WHERE 
   t.is_ms_shipped = 0
GROUP BY 
   t.NAME
ORDER BY 
   size_gb DESC;

 Select top (111) * from [dbo].[BatchRecord]