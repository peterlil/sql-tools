wmic os get Caption, BuildNumber, CSDVersion, CSName, ForegroundApplicationBoost, FreePhysicalMemory, OSArchitecture, Version /format:textvaluelist.xsl

wmic bios get /format:textvaluelist.xsl

wmic logicaldisk get Caption, Description, FileSystem, Size, FreeSpace, VolumeName

wmic memphysical get

wmic memorychip get

wmic nic get

wmic nicconfig get

wmic partition get

wmic process get