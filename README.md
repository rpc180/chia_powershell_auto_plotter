# Chia Powershell Plotter Auto-Handler 
Since I have several computers of varying performance I wanted to write a script that could be deployed across them to kick off plot creation based on the system's hostname.  The script is then added to Task Scheduler to run every hour where it determines whether to kick off another instance based on pass criteria:
 - Number of detected Running instances vs Maximum instances for this computer
 - Progress of last generated instance log (will not start until "Computing Table 3" of Phase 1)
 - Remaining space in TEMP drive
 - Reamining space in FINAL drive

## Usage
Save the included file in a folder on the target Windows computer.  There are two sample computers defined in the script.  To personalize computer 1 changes happen between lines 2-14 (detailed below).  To personalize computer 2 changes are at lines 16-22.  To add a 3rd computer, copy one of the "blocks" and paste it right after the second sample computer.
```sh
$pkey_Farmer = "public farm key"
$pkey_Pool = "public pool key"

Switch ( $env:COMPUTERNAME ) {
    "Computer1" { 
        $Max_Instances = 3
        $Drive_Temp = "F:"
        $Drive_Final = "E:"
        $Path_Temp = "$Drive_Temp"
        $Path_Final = "$Drive_Final\Farm" 
        $Chia_AppPath = "C:\Users\USERNAME\AppData\local\chia-blockchain\app-1.1.3\resources\app.asar.unpacked\daemon"
        $Chia_PlotLogPath = "C:\Users\USERNAME\.chia\mainnet\plotter"
        }
```
- Line 2: Replace text inside quotes with your Public Farmer key 
- Line 2: Replace text inside quotes with your Public Pool key
- Line 6: Replace with your computer's returned "hostname"
- Line 7: Replace with your desired maximum instances to run at once, these will auto-stagger based on progress of last run log.
- Line 8: Replace with your temporary storage drive letter
- Line 9: Replace with your final storage drive letter
- Line 10: If you have a subfolder where you do plots, add it after the text as \subfoldername
- Line 11: If you have a subfolder where your final plots go, add it after the text as \subfoldername
- Line 12-13: Location of the chia installed files, I had different user names on different systems so different directories
-- Note that the Create_Plots.log file is placed in the plotter log directory.

## Automation
You can then add it as a Scheduled Task to run on an hourly schedule.
 - Create a new task
 - Set action "Run a Program" just type "powershell" in the box (without quotes)
 - Add additional flags "-noprofile -File C:\SaveLocation\Create_Plots.ps1" (without quotes)

This will also create a run log file called "Create_Plots.log" in the Chia plotting directory by default but can be configured in the computername block as desired.

#### Example Run:
```sh
Script running on DEN-PC at 2021-05-07.11-20
in C:\Support\Create_Plots.ps1 by someuser
Runlog File: C:\Users\someuser\.chia\mainnet\plotter\Create_Plots.log
Total Active Instances: 2


Creating new instance at F:\Plot-2021-05-07.11-20.
```
