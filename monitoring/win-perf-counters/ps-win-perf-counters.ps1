Get-Counter -ListSet "SQLServer:Access Methods" | Select-Object -ExpandProperty Counter | Sort-Object
Get-Counter -ListSet "SQLServer:Buffer Manager" | Select-Object -ExpandProperty Counter | Sort-Object
Get-Counter -ListSet "SQLServer:Cursor Manager by Type" | Select-Object -ExpandProperty Counter | Sort-Object

