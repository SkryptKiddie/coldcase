# ColdCase
Artefact collector designed for legacy versions of Windows. 

![Demo of ColdCase running in Windows Server 2003](demo.gif)

## Help
```
 ColdCase Logical Collector

 Collects artefacts from legacy Windows systems to conduct incident response.
 Tested and designed for Windows XP and Windows Server 2003.
 The tool will automatically target "C:" drive if no /target argument is provided.

 Usage:
   coldcase.bat
   coldcase.bat /dryrun
   coldcase.bat /target C:
   coldcase.bat /dryrun /target C:

 Notes:
   - Run using an Administrator command prompt.
   - ZIP creation uses cscript.exe and Explorer's ZIP support.
   - This tool does not make efforts to respect Locard's Principle. You have been warned.
```

## Example output
Results are not saved in a typical Windows file system layout, rather they are sorted by the type of artefact. This may change in the future, but does not affect how these should be interpreted.

The generated bodyfile is compatible with [SluethKit's mactime](https://github.com/sleuthkit/sleuthkit/wiki/mactime) tool to create a file system timeline.
```
C:\COLLECTION-TEST-A6280F1FB9-MON009-07-2026_17-45-01-59
│   collection.log
│
├───Bodyfile
│       bodyfile.txt
│
├───EventLogs
│       AppEvent.Evt
│       SecEvent.Evt
│       SysEvent.Evt
│
├───Filesystem
│       dir_accessed_time.txt
│       dir_created_time.txt
│       dir_modified_time.txt
│       file_acls.txt
│       file_attributes.txt
│       fsutil_dirty_query.txt
│       fsutil_drives.txt
│       fsutil_ntfsinfo.txt
│       fsutil_usn_enumdata.txt
│       fsutil_usn_queryjournal.txt
│       fsutil_usn_readjournal.txt
│       fsutil_volumeinfo.txt
│       volume_label.txt
│
├───LiveResponse
│       arp.txt
│       codepage.txt
│       hostname.txt
│       ipconfig_all.txt
│       localgroups.txt
│       netstat_ano.txt
│       routes.txt
│       schtasks.txt
│       services.txt
│       sessions.txt
│       shares.txt
│       systeminfo.txt
│       tasklist.txt
│       tree.txt
│       users.txt
│
├───Profiles
│   ├───Administrator
│   │   │
│   │   ├───Application Data
│   │   │   │   desktop.ini
│   │   │   │
│   │   │   ├───Identities
│   │   │   │   └───{2DC19436-1FCF-47B5-9F1E-346E3B71FDD1}
│   │   │   └───Microsoft
│   │   │       ├───Credentials
│   │   │       │   └───S-1-5-21-926789311-2475876919-4159152486-500
│   │   │       ├───CryptnetUrlCache
│   │   │       │   ├───Content
│   │   │       │   │       E6024EAC88E6B6165D49FE3C95ADD735
│   │   │       │   │
│   │   │       │   └───MetaData
│   │   │       │           E6024EAC88E6B6165D49FE3C95ADD735
│   │   │       │
│   │   │       ├───HTML Help
│   │   │       │       hh.dat
│   │   │       │
│   │   │       ├───Internet Explorer
│   │   │       │   │   Desktop.htt
│   │   │       │   │
│   │   │       │   └───Quick Launch
│   │   │       │           desktop.ini
│   │   │       │           Launch Internet Explorer Browser.lnk
│   │   │       │           Show Desktop.scf
│   │   │       │
│   │   │       ├───Media Player
│   │   │       ├───MMC
│   │   │       ├───SystemCertificates
│   │   │       │   └───My
│   │   │       │       ├───Certificates
│   │   │       │       ├───CRLs
│   │   │       │       └───CTLs
│   │   │       └───Windows
│   │   │           └───Themes
│   │   │                   Custom.theme
│   │   │
│   │   └───Local Settings
│   │
│   └───All Users
│       │   dir_listing.txt
│       │
│       └───Application Data
│           │
│           └───Microsoft
│               ├───Crypto
│               │   ├───DSS
│               │   │   └───MachineKeys
│               │   └───RSA
│               │       ├───MachineKeys
│               │       └───S-1-5-18
│               │
│               ├───HTML Help
│               │
│               ├───Media Index
│               ├───Media Player
│               │
│               └───Network
│                   └───Connections
│                       └───Cm
│
├───RecycleBin
│   └───RECYCLER
│       └───S-1-5-21-926789311-2475876919-4159152486-500
│               Dc1.txt
│               Dc10.txt
│               Dc11.txt
│               Dc2.txt
│               Dc3.txt
│               Dc4.txt
│               Dc5.txt
│               Dc6.txt
│               Dc7.txt
│               Dc8.txt
│               Dc9.txt
│               desktop.ini
│               INFO2
│
├───Registry
│   │   DEFAULT.hiv
│   │   HKU_S-1-5-18.hiv
│   │   HKU_S-1-5-19.hiv
│   │   HKU_S-1-5-20.hiv
│   │   HKU_S-1-5-21-926789311-2475876919-4159152486-500.hiv
│   │   SAM.hiv
│   │   SECURITY.hiv
│   │   SOFTWARE.hiv
│   │   SYSTEM.hiv
│   │
│   └───repair
│           sam
│           security
│           software
│           system
│
└───WindowsArtifacts
    ├───Debug
    │   │   NetSetup.LOG
    │   │   PASSWD.LOG
    │   │   SecOOBE.log
    │   │
    │   ├───UserMode
    │   │       ChkAcc.bak
    │   │       ChkAcc.log
    │   │       gpdas.log
    │   │
    │   └───WPD
    │           wpdtrace.log
    │
    ├───INF
    ├───LOG
    │   │   0.log
    │   │   aspnetocm.log
    │   │   certocm.log
    │   │   cmsetacl.log
    │   │   comsetup.log
    │   │   DtcInstall.log
    │   │   FaxSetup.log
    │   │   iis6.log
    │   │   imsins.log
    │   │   LicenOc.log
    │   │   msmqinst.log
    │   │   netfxocm.log
    │   │   ntdtcsetup.log
    │   │   ocgen.log
    │   │   PFRO.log
    │   │   pop3oc.log
    │   │   regopt.log
    │   │   sessmgr.setup.log
    │   │   setupact.log
    │   │   setupapi.log
    │   │   setuperr.log
    │   │   tsoc.log
    │   │   uddisetup.log
    │   │   WindowsUpdate.log
    │   │   wmsetup.log
    │   │
    │   ├───Debug
    │   │   │   NetSetup.LOG
    │   │   │   PASSWD.LOG
    │   │   │   SecOOBE.log
    │   │   │
    │   │   ├───UserMode
    │   │   │       ChkAcc.log
    │   │   │       gpdas.log
    │   │   │
    │   │   └───WPD
    │   │           wpdtrace.log
    │   │
    │   ├───PCHealth
    │   │   └───HelpCtr
    │   │       └───Logs
    │   │               hcupdate.log
    │   │
    │   ├───repair
    │   │       setup.log
    │   │
    │   ├───security
    │   │   └───logs
    │   │           backup.log
    │   │           SceRoot.log
    │   │           scesetup.log
    │   │
    │   ├───SoftwareDistribution
    │   │   │   ReportingEvents.log
    │   │   │
    │   │   └───DataStore
    │   │       └───Logs
    │   │               edb.log
    │   │               res1.log
    │   │               res2.log
    │   │
    │   └───system32
    │       ├───CatRoot2
    │       │       edb.log
    │       │       edb00003.log
    │       │       edb00004.log
    │       │       edb00005.log
    │       │       edb00006.log
    │       │       edb00007.log
    │       │       edb00008.log
    │       │       edb00009.log
    │       │       edb0000A.log
    │       │       edb0000B.log
    │       │       edb0000C.log
    │       │       edb0000D.log
    │       │       edb0000E.log
    │       │       edb0000F.log
    │       │       edb00010.log
    │       │       edb00011.log
    │       │       edb00012.log
    │       │       edb00013.log
    │       │       edb00014.log
    │       │       edb00015.log
    │       │       res1.log
    │       │       res2.log
    │       │
    │       ├───config
    │       │   │   TempKey.LOG
    │       │   │   userdiff.LOG
    │       │   │
    │       │   └───systemprofile
    │       │           Sti_Trace.log
    │       │
    │       ├───LogFiles
    │       │   └───Cluster
    │       │           clusocm.log
    │       │
    │       ├───MsDtc
    │       │   │   MSDTC.LOG
    │       │   │
    │       │   └───Trace
    │       │           dtctrace.log
    │       │
    │       └───wbem
    │           └───Logs
    │                   FrameWork.log
    │                   mofcomp.log
    │                   replog.log
    │                   setup.log
    │                   wbemcore.log
    │                   wbemprox.log
    │                   wmiadap.log
    │                   wmiprov.log
    │
    └───Prefetch
            NTOSBOOT-B00DFAAD.pf
```

## Disclaimer
As explained in *Help*, This tool does not make extensive efforts to reduce interactions with a system. This is designed to act as a live incident response evidence collector, similar to [UNIX-like Artifacts Collector](https://github.com/tclahr/uac) running on a live system. **_It is purely up to the analyst to decide if this tool is fit for purpose for your investigation._** If in doubt, you should probably take a disk image.