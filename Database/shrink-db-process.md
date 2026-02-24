Shrinking a database file **without causing massive fragmentation** is absolutely possible — but only when following a disciplined process. Most fragmentation from shrinking happens because SQL Server must *move pages around* inside the file to free space at the end. The key is to **defragment first**, then **shrink only to the point where free space exists**, and **avoid repeated shrink/grow cycles**.

Below is the best‑practice procedure, based on Microsoft’s official guidance about shrink behavior and data movement operations. [\[sqlservercentral.com\]](https://www.sqlservercentral.com/articles/understanding-crud-operations-against-heaps-and-forwarding-pointers)

***

# ✅ **Best Procedure to Shrink a Single‑File Database Without Causing Fragmentation**

## **1. Rebuild or reorganize indexes first (eliminate existing internal/external fragmentation)**

Before shrinking, you want the file to be as tightly packed as possible to avoid SQL Server having to move lots of scattered pages:

```sql
ALTER INDEX ALL ON YourTableName REBUILD; 
-- or for the whole DB, run your index maintenance job
```

A rebuild compacts pages and removes fragmentation, preparing the file for a clean shrink. This aligns with Microsoft’s note that index rebuilds can reduce size without even shrinking. [\[sqlservercentral.com\]](https://www.sqlservercentral.com/articles/understanding-crud-operations-against-heaps-and-forwarding-pointers)

***

## **2. Identify how much free space is actually available**

Use:

```sql
DBCC SQLPERF(LOGSPACE);       -- For log
EXEC sp_spaceused;            -- For data file
```

Or more precisely:

```sql
SELECT
    name,
    size/128 AS SizeMB,
    FILEPROPERTY(name,'SpaceUsed')/128 AS SpaceUsedMB
FROM sys.database_files;
```

Shrink only if **significant real free space** exists.

***

## **3. Shrink **in one controlled operation**, NOT incrementally**

This is important: **Do not** run:

```sql
DBCC SHRINKFILE (file, 0)
```

or repeated small shrinks. This REPEATED movement of pages is exactly what causes extreme fragmentation.

Instead, shrink **once** to a target size that corresponds to actual free space:

```sql
DBCC SHRINKFILE (YourLogicalFileName, TargetSizeMB);
```

Pick `TargetSizeMB` a bit **above** `SpaceUsedMB`, so SQL Server does minimal page movement.

The shrink command removes unused space, and Microsoft confirms it works by *moving pages* and therefore can cause fragmentation if misused. [\[sqlservercentral.com\]](https://www.sqlservercentral.com/articles/understanding-crud-operations-against-heaps-and-forwarding-pointers)

***

## **4. Optional: Run a final index REBUILD after shrinking**

If you want **optimal** structure post‑shrink:

```sql
ALTER INDEX ALL ON YourTableName REBUILD;
```

A shrink can cause new fragmentation (because it moves pages), so rebuilding afterwards will eliminate the residual fragmentation. This is often recommended on performance‑critical OLTP systems.

# 🚫 **What NOT to do**

### **❌ Do not run shrink frequently**

Routine shrinking leads to “shrinking–growing–shrinking” churn and heavy fragmentation + IO pressure.

### **❌ Do not shrink to 0 MB or “as small as possible”**

SQL Server relocates huge amounts of data pages trying to compact the file completely.

### **❌ Do not shrink during heavy workload**

It causes blocking and massive data movement in tempdb (Microsoft docs confirm shrink operations use tempdb for sorts/copying when needed). [\[sqlservercentral.com\]](https://www.sqlservercentral.com/articles/understanding-crud-operations-against-heaps-and-forwarding-pointers)

***

# 📌 **Example: Safe Shrink Process**

Let's say your file is:

*   Current size = 300 GB
*   Space used = 210 GB
*   Free space = 90 GB

A safe shrink target might be:

```sql
DBCC SHRINKFILE (MyDb_Data, 220000); -- shrink to 220 GB
```

This removes 80 GB without destroying the data layout.

***

