[CmdletBinding()]
param(
    [string]$Type = "all"
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$comDef = @'
using System;
using System.Runtime.InteropServices;

namespace NBXAudio {
    [Guid("A95664D2-9614-4F35-A746-DE8DB63617E6"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    public interface IMMDeviceEnumerator {
        int EnumAudioEndpoints(int dataFlow, int stateMask, out IntPtr devices);
        int GetDefaultAudioEndpoint(int dataFlow, int role, out IMMDevice endpoint);
    }

    [Guid("D666063F-1587-4E43-81F1-B948E807363F"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    public interface IMMDevice {
        int Activate(ref Guid id, int clsCtx, IntPtr activationParams, out IntPtr interfacePointer);
        int OpenPropertyStore(int stgmAccess, out IntPtr properties);
        int GetId([MarshalAs(UnmanagedType.LPWStr)] out string id);
        int GetState(out int state);
    }

    [ComImport, Guid("BCDE0395-E52F-467C-8E3D-C4579291692E")]
    public class MMDeviceEnumeratorComObject {}

    public class Endpoints {
        public static string GetDefaultId(int dataFlow, int role) {
            try {
                var enumerator = (IMMDeviceEnumerator)new MMDeviceEnumeratorComObject();
                IMMDevice dev;
                if (enumerator.GetDefaultAudioEndpoint(dataFlow, role, out dev) == 0 && dev != null) {
                    string id;
                    dev.GetId(out id);
                    return id != null ? id.ToLowerInvariant() : "";
                }
            } catch {}
            return "";
        }
    }
}
'@

Add-Type -TypeDefinition $comDef -ErrorAction SilentlyContinue

$defaultInput = [NBXAudio.Endpoints]::GetDefaultId(1, 2) # eCapture = 1, eCommunications = 2
if ([string]::IsNullOrEmpty($defaultInput)) {
    $defaultInput = [NBXAudio.Endpoints]::GetDefaultId(1, 0) # eConsole = 0
}

$defaultOutput = [NBXAudio.Endpoints]::GetDefaultId(0, 0) # eRender = 0, eConsole = 0

$rawDevices = Get-PnpDevice -Class AudioEndpoint -Status OK -ErrorAction SilentlyContinue | ForEach-Object {
    $friendly = $_.FriendlyName
    $inst = $_.InstanceId
    if ($inst -and $friendly) {
        if ($inst.StartsWith("SWD\MMDEVAPI\", [System.StringComparison]::OrdinalIgnoreCase)) {
            $inst = $inst.Substring(12)
        }
        $inst = $inst.TrimStart('\').ToLowerInvariant()
        [PSCustomObject]@{
            FriendlyName = $friendly
            InstanceId = $inst
        }
    }
}

$inputs = @()
$outputs = @()

foreach ($dev in $rawDevices) {
    if ($dev.InstanceId.Contains("{0.0.1.")) {
        $isDef = ($dev.InstanceId -eq $defaultInput)
        $inputs += [PSCustomObject]@{
            deviceId = $dev.InstanceId
            label = $dev.FriendlyName
            isDefault = $isDef
        }
    } elseif ($dev.InstanceId.Contains("{0.0.0.")) {
        $isDef = ($dev.InstanceId -eq $defaultOutput)
        $outputs += [PSCustomObject]@{
            deviceId = $dev.InstanceId
            label = $dev.FriendlyName
            isDefault = $isDef
        }
    }
}

# Ensure default device is first in the list if identified
if ($defaultInput) {
    $defItem = $inputs | Where-Object { $_.deviceId -eq $defaultInput } | Select-Object -First 1
    if ($defItem) {
        $inputs = @($defItem) + @($inputs | Where-Object { $_.deviceId -ne $defaultInput })
    }
}

if ($defaultOutput) {
    $defItem = $outputs | Where-Object { $_.deviceId -eq $defaultOutput } | Select-Object -First 1
    if ($defItem) {
        $outputs = @($defItem) + @($outputs | Where-Object { $_.deviceId -ne $defaultOutput })
    }
}

[PSCustomObject]@{
    defaultInput = $defaultInput
    defaultOutput = $defaultOutput
    inputs = $inputs
    outputs = $outputs
} | ConvertTo-Json -Compress -Depth 4
