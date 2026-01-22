# Setting up Performance Monitor traces of SQL Server instances

## SQL Server 2019 (v15) - using the monitoring defaults

1. Extract all files in the zip archive to a folder, for example `C:\temp`.
2. Start *PowerShell* as an administrator.
3. Type `cd C:\temp` and press *Enter*.
4. Type `Set-ExecutionPolicy RemoteSigned -Force` and press *Enter*.
5. If you are setting this up for the default instance, execute the script in this step. If you are setting up monitoring for a named instance, skip to steg 6.
    ```powershell
    .\Setup-Monitoring.ps1 -LogRoot <PathToLogRoot>
    ```
    Note: LogRoot is the root folder where you want the logs, ex: C:\PerfLogs
6. Run this script if you are setting up moonitoring for a named instance.
    ```powershell
    .\Setup-Monitoring.ps1 -InstanceName <MyInstance> -LogRoot <PathToLogRoot>
    ```
    Note: LogRoot is the root folder where you want the logs, ex: C:\PerfLogs
    
Done.
