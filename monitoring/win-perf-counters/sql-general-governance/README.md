# Setup performance monitoring on a Windows OS

## Set up basic performance monitoring for Windows 10

With basic performance monitoring I mean processes, CPU, disk, memory and network.

### 1. Extract all files 

Extract all files in the zip archive(Monitoring.v3.zip) to a folder, for example `C:\temp`.

### 2. _Optional_ Change sampling interval

If you need to change counter sampling interval -> open the file `perfmon-template-w10-basic.xml` in a text editor and find `<SampleInterval>5</SampleInterval>` and adjust it accordingly. The value is in seconds.

### 3. _Optional_ Change trace file destination

If you need to change destination of the trace files, the following paths need to and can be changed (it defaults to `C:\PerfLogs\*`). Otherwise, skip this step.:

1. copy-scripts.ps1, line 1 and 4.
2. perfmon-template-w10-basic.xml, line 14, 16-17 (_LatestOutputLocation_, _OutputLocation_, _RootPath_)
3. Remove old logs - Scheduled Task.xml, line 44 (_Arguments_)
4. Zip Perfmon Logs - Scheduled Task.xml, line 44 (_Arguments_)

### 4. Prepare the perfmon template

1. Start PowerShell as Administrator.
2. Type `cd C:\temp` (or wherever you unzipped the file) and press Enter.
3. Check if your execution policy is RemoteSigned (default for Windows Server, not default for Windows client) with `Get-ExecutionPolicy`.
4. If the execution policy is anything but _Unrestricted_ or _RemoteSigned_ you need to run this command: `Set-ExecutionPolicy RemoteSigned -Force`.
5. Then you also probably need to run the following as the files are downloaded from the Internet: 
```powershell
Unblock-File .\Make-PerfmonTemplate.ps1
```
6. Type `.\Make-PerfmonTemplate.ps1 -Template perfmon-template-w10-basic.xml` and press _Enter_.
7. Start _Performance Monitor_.
8. Right click _Performance->Data Collector Sets->User Defined_ and select _New->Data Collector Set_.
9. Type _Windows 10 basic trace_ as Name and select _Create from a template_ and click _Next_.
10. Click _Browse…_.
11. Browse for _[computer name]-PerfmonTemplate.xml_ and click Open.
12. Click _Finish_.

Now you have a trace definition under _User Defined_, which you can manually start and stop when needed.

### 5. _Optional_ If you want to have the trace to run continuously, then perform this additional step

1. You probably also need to unblock these scripts
```powershell
Unblock-File .\copy-scripts.ps1
Unblock-File .\remove-old-logs.ps1
Unblock-File .\schedule-the-tasks.ps1
Unblock-File .\zip-logs.ps1
```
2. Type “.\copy-scripts.ps1” and press Enter.
3. Type “.\schedule-the-tasks.ps1” in the PowerShell window and press Enter.
