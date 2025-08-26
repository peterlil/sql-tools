REM https://techcommunity.microsoft.com/blog/sqlserversupport/sql-server-2005---rdtsc-truths-and-myths-discussed/315421
REM RDTSC drift is not a major performance issue these days (2025) and should only be used in deep targeted performance troubleshooting .

@ECHO OFF

ECHO Processor Info for Machine: \\%COMPUTERNAME%
ECHO.
ECHO Collected %date% %time%
ECHO.

RDTSCTest\RDTSCTest.exe -md

REM :top
REM sleep 20
REM RDTSCTest.exe -mt
REM goto :top
