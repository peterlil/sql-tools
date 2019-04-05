
class Win32_ComputerSystemWindowsProductActivationSetting : CIM_ElementSetting
{
  Win32_ComputerSystem           REF Element;
  Win32_WindowsProductActivation REF Setting;
};

class Win32_NetworkAdapterSetting : Win32_DeviceSettings
{
  Win32_NetworkAdapter              REF Element;
  Win32_NetworkAdapterConfiguration REF Setting;
};




class Win32_SystemBootConfiguration : Win32_SystemSetting
{
  Win32_ComputerSystem    REF Element;
  Win32_BootConfiguration REF Setting;
};

class Win32_SystemTimeZone : Win32_SystemSetting
{
  Win32_ComputerSystem REF Element;
  Win32_TimeZone       REF Setting;
};
