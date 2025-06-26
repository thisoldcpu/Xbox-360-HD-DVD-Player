# The Xbox 360 HD DVD Player

## Xbox 360 HD DVD Player driver download & installation guide

### Modern Driver Support & Info

This repository is dedicated to preserving support and documentation for the Xbox 360 HD DVD Player on modern Windows systems.

The Xbox 360 HD DVD Player was a discontinued accessory (2006–2008) allowing playback of HD DVD movies. On modern Windows releases, the optical drive works out of the box, but the "Xbox 360 Memory Unit" device (a 256MB flash partition) shows up as `Xbox 360 HD DVD Interface 0` and `Xbox 360 HD DVD Interface 1`, requiring a driver.

---

## Official Microsoft "Null" Drivers

Microsoft still offers the original "null" drivers, which simply suppress the yellow exclamation mark and set a friendly name for the interfaces.

**Microsoft Update Catalog links:**

- [Xbox 360 HD DVD Interface 0](https://catalog.update.microsoft.com/ScopedViewInline.aspx?updateid=1d4d21a6-28da-492b-840f-1c67885161f3)
- [Xbox 360 HD DVD Interface 1](https://catalog.update.microsoft.com/ScopedViewInline.aspx?updateid=a7af3f49-d144-4786-af8f-301a8c7e8319)

**Direct CAB download:**  
[20021667_7b6ddf62cdeb07d7c3ba4a0d902124e7212a34c2.cab](https://catalog.s.download.windowsupdate.com/msdownload/update/driver/drvs/2012/12/20021667_7b6ddf62cdeb07d7c3ba4a0d902124e7212a34c2.cab)

These drivers are Microsoft-certified and safe.  
They do *not* add extra functionality—just assign a proper device name and remove the warning icon for the memory unit interfaces.

The cab file contains 2 files:
XBoxHDDVD.cat (8kb)
XBoxHDDVD.inf (2kb)

```
; Copyright 2006 Microsoft Corporation
;
; XBOXHD.INF
;
; Sets user friendly names for unsupported interfaces in the XBOX HD/DVD Drive.
; Installs a NULL driver service for the two memory unit interfaces
;

[Version]
Signature="$WINDOWS NT$"
Class=USB
ClassGUID={36FC9E60-C465-11CF-8056-444553540000}
Provider=%MSFT%
CatalogFile=XBoxHDDVD.cat
DriverVer=11/09/2006,1.0.0.0

; Add source disk to allow chkinf to work properly
[SourceDisksNames]
1=%XBoxHDDVD.DiskName%

[SourceDisksFiles]

[DestinationDirs]

[ControlFlags]
ExcludeFromSelect = *

[Manufacturer]
%MSFT%=MSFT,NTx86,NTia64,NTamd64

[MSFT]  ; Added to keep chkinf from complaining
%Interface0.DeviceDesc%=Nullx,USB\VID_045e&PID_029E&MI_00
%Interface1.DeviceDesc%=Nullx,USB\VID_045e&PID_029E&MI_01

[MSFT.NTx86]
%Interface0.DeviceDesc%=Nullx,USB\VID_045e&PID_029E&MI_00
%Interface1.DeviceDesc%=Nullx,USB\VID_045e&PID_029E&MI_01

[MSFT.NTia64]
%Interface0.DeviceDesc%=Nullx,USB\VID_045e&PID_029E&MI_00
%Interface1.DeviceDesc%=Nullx,USB\VID_045e&PID_029E&MI_01

[MSFT.NTamd64]
%Interface0.DeviceDesc%=Nullx,USB\VID_045e&PID_029E&MI_00
%Interface1.DeviceDesc%=Nullx,USB\VID_045e&PID_029E&MI_01

[NullX]
CopyFiles = NullX.CopyFiles
AddReg    = NullX.AddReg

[NullX.CopyFiles]

[NullX.AddReg]

[NullX.Services]
AddService= ,0x00000002 ; null service install

[Strings]
MSFT                  = "Microsoft"
XBoxHDDVD.DiskName    = "XBOX HD-DVD installation media"
Interface0.DeviceDesc = "Xbox 360 HD DVD Interface 0"
Interface1.DeviceDesc = "Xbox 360 HD DVD Interface 1"


; Copyright 2006 Microsoft Corporation
;
; XBOXHD.INF
;
; Sets user friendly names for unsupported interfaces in the XBOX HD/DVD Drive.
; Installs a NULL driver service for the two memory unit interfaces
;

[Version]
Signature="$WINDOWS NT$"
Class=USB
ClassGUID={36FC9E60-C465-11CF-8056-444553540000}
Provider=%MSFT%
CatalogFile=XBoxHDDVD.cat
DriverVer=11/09/2006,1.0.0.0

; Add source disk to allow chkinf to work properly
[SourceDisksNames]
1=%XBoxHDDVD.DiskName%

[SourceDisksFiles]

[DestinationDirs]

[ControlFlags]
ExcludeFromSelect = *

[Manufacturer]
%MSFT%=MSFT,NTx86,NTia64,NTamd64

[MSFT]  ; Added to keep chkinf from complaining
%Interface0.DeviceDesc%=Nullx,USB\VID_045e&PID_029E&MI_00
%Interface1.DeviceDesc%=Nullx,USB\VID_045e&PID_029E&MI_01

[MSFT.NTx86]
%Interface0.DeviceDesc%=Nullx,USB\VID_045e&PID_029E&MI_00
%Interface1.DeviceDesc%=Nullx,USB\VID_045e&PID_029E&MI_01

[MSFT.NTia64]
%Interface0.DeviceDesc%=Nullx,USB\VID_045e&PID_029E&MI_00
%Interface1.DeviceDesc%=Nullx,USB\VID_045e&PID_029E&MI_01

[MSFT.NTamd64]
%Interface0.DeviceDesc%=Nullx,USB\VID_045e&PID_029E&MI_00
%Interface1.DeviceDesc%=Nullx,USB\VID_045e&PID_029E&MI_01

[NullX]
CopyFiles = NullX.CopyFiles
AddReg    = NullX.AddReg

[NullX.CopyFiles]

[NullX.AddReg]

[NullX.Services]
AddService= ,0x00000002 ; null service install

[Strings]
MSFT                  = "Microsoft"
XBoxHDDVD.DiskName    = "XBOX HD-DVD installation media"
Interface0.DeviceDesc = "Xbox 360 HD DVD Interface 0"
Interface1.DeviceDesc = "Xbox 360 HD DVD Interface 1"
```

---

## UDF 2.5 Driver: Required for HD DVD Playback on Older Windows

### What is UDF 2.5?

**UDF 2.5** (Universal Disk Format 2.5) is the filesystem used on most HD DVD and Blu-ray movie discs.

Without UDF 2.5 support, Windows can't read the contents of these discs—you'll see a blank disc or a prompt to format.

### Is UDF 2.5 included with Windows?

| Windows Version    | UDF 2.5 Support | Notes                                           |
| ------------------ | --------------- | ----------------------------------------------- |
| Windows XP         | No              | Needs extra driver to read HD DVD/Blu-ray discs |
| Windows Vista+     | Yes             | Native support; no driver needed                |
| Linux, macOS       | Partial/Yes     | Most modern distros support UDF 2.5             |

---

### UDF 2.5 Driver for Windows XP

Microsoft released a UDF 2.5 driver update for Windows XP called “Windows Feature Pack for Storage 1.0,” which enables Windows XP to read UDF 2.5 discs (required for most HD DVD and Blu-ray media).

As of 2025, this update is **no longer available from Microsoft**, but is preserved on Internet Archive:

- [WindowsXP-KB932716-v2-x86-ENU.exe (Internet Archive)](https://archive.org/details/windows-xp-kb-932716-v-2-x-86-enu)

**SHA1 (original EXE):** `f1e0b16ff6d4a451ff54b6e76fbed4b491c81121`  
Uploaded for community preservation by [ThisOldCPU](https://archive.org/search?query=thisoldcpu)).

> **Note:**  
> There is **no official UDF 2.5 driver for Windows 2000 or earlier**.

---
