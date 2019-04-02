Get-Counter -ListSet "SQLServer:Access Methods" | Select-Object -ExpandProperty Counter | Sort-Object
Get-Counter -ListSet "SQLServer:Buffer Manager" | Select-Object -ExpandProperty Counter | Sort-Object
Get-Counter -ListSet "SQLServer:Cursor Manager by Type" | Select-Object -ExpandProperty Counter | Sort-Object
Get-Counter -ListSet "SQLServer:Database Replica" | Select-Object -ExpandProperty Counter | Sort-Object
Get-Counter -ListSet "SQLServer:Databases" | Select-Object -ExpandProperty Counter | Sort-Object
Get-Counter -ListSet "SQLServer:General Statistics" | Select-Object -ExpandProperty Counter | Sort-Object
Get-Counter -ListSet "SQLServer:Latches" | Select-Object -ExpandProperty Counter | Sort-Object
Get-Counter -ListSet "SQLServer:Locks" | Select-Object -ExpandProperty Counter | Sort-Object
Get-Counter -ListSet "SQLServer:Memory Manager" | Select-Object -ExpandProperty Counter | Sort-Object
Get-Counter -ListSet "SQLServer:Plan Cache" | Select-Object -ExpandProperty Counter | Sort-Object
Get-Counter -ListSet "SQLServer:SQL Statistics" | Select-Object -ExpandProperty Counter | Sort-Object
Get-Counter -ListSet "SQLServer:Transactions" | Select-Object -ExpandProperty Counter | Sort-Object
Get-Counter -ListSet "SQLServer:Database Mirroring" | Select-Object -ExpandProperty Counter | Sort-Object
Get-Counter -ListSet "" | Select-Object -ExpandProperty Counter | Sort-Object
Get-Counter -ListSet "" | Select-Object -ExpandProperty Counter | Sort-Object
Get-Counter -ListSet "" | Select-Object -ExpandProperty Counter | Sort-Object
Get-Counter -ListSet "" | Select-Object -ExpandProperty Counter | Sort-Object
Get-Counter -ListSet "" | Select-Object -ExpandProperty Counter | Sort-Object



