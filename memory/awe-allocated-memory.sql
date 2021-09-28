select  
    sum(awe_allocated_kb) / 1024 as [AWE allocated, Mb]  
from  
    sys.dm_os_memory_clerks
