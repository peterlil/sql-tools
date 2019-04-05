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
