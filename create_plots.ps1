# Get your keys from .\chia.exe keys show
$pkey_Farmer = "public farm key"
$pkey_Pool = "public pool key"

Switch ( $env:COMPUTERNAME ) { # Specifics for each computer running plots, I had different usernames for each and different drive letters for each
    "Computer1" { 
        $Max_Instances = 3
        $Drive_Temp = "F:"
        $Drive_Final = "E:"
        $Path_Temp = "$Drive_Temp"
        $Path_Final = "$Drive_Final\Farm" 
        $Chia_AppPath = "C:\Users\USERNAME\AppData\local\chia-blockchain\app-1.1.3\resources\app.asar.unpacked\daemon"
        $Chia_PlotLogPath = "C:\Users\USERNAME\.chia\mainnet\plotter"
        }
    "Computer2" { 
        $Max_Instances = 6
        $Drive_Temp = "E:"
        $Drive_Final = "D:"
        $Path_Temp = "$Drive_Temp"
        $Path_Final = "$Drive_Final\Farm" 
        $Chia_AppPath = "C:\Users\USERNAME\AppData\local\chia-blockchain\app-1.1.3\resources\app.asar.unpacked\daemon"
        $Chia_PlotLogPath = "C:\Users\USERNAME\.chia\mainnet\plotter"
        }
}

# Log Info / Header - Outputs a Create_Plots.log file to the above defined chia plotter directory
$TimeStamp = (Get-Date).ToString('yyyy-MM-dd.HH-mm')
$RunLog = "$Chia_PlotLogPath\Create_Plots.log"
$RunPath = $MyInvocation.MyCommand.Path
write-output `n "Script running on $env:COMPUTERNAME at $TimeStamp" | tee-object -filepath $runlog
write-output "in $RunPath by $($env:username)" | tee-object -filepath $runlog -append
write-output "Runlog File: $runlog" | tee-object -filepath $runlog -append

# Calculate freespace in Final and Temp
$FreeBytes_Final = (Get-CimInstance Win32_LogicalDisk -filter "Mediatype=12" | where-object { $_.DeviceID -match $Drive_Final }).FreeSpace
$FreeBytes_Temp = (Get-CimInstance Win32_LogicalDisk -filter "Mediatype=12" | where-object { $_.DeviceID -match $Drive_Temp }).FreeSpace

# Count Active Instances also Clear Out Empty Temp Folders
$Count_ActiveInstances = 0
foreach ( $dir in (get-childitem $Path_Temp) ) {
    if ( (gci $dir.FullName | measure-object).count -gt 1 ) { # Folders in temp with files are active instances
        write-output "$dir.name is an active folder"
        $Count_ActiveInstances = $Count_ActiveInstances+1
        }
    else {
        write-output "I should delete this folder $dir"
        # Delete folder steps - To be added remove-item $dir.name -force
        }
    }
Write-Output "Total Active Instances: $Count_ActiveInstances" `n | tee-object -filepath $runlog -append

# Are we at the maximum number of active instances?
if ( $Count_ActiveInstances -ge $Max_Instances ) { 
    Write-Output "TERM: Maximum active instances reached." `n | tee-object -filepath $runlog -append
    Exit
    }

# How far has the latest instance gotten into its work?
if ( ((Get-Content (Get-ChildItem $Chia_PlotLogPath\plot* | Sort-Object CreationTime | Select-Object -Last 1).Fullname) | Select-String -Pattern "Computing table 3") -eq $null ) {
    Write-Output "TERM: Current active instance not far enough into Phase 1 to begin new instance." `n | tee-object -filepath $runlog -append
    Exit
}

# Is there enough space in the temp location for another instance?
if ( $FreeBytes_Temp -lt 375809638400 ) { 
    Write-Output "TERM: Temporary drive location space is at reservation limit." `n | tee-object -filepath $runlog -append
    Exit
    }

# Is there enough space in the final location for another plot?
if ( $FreeBytes_Final -lt 214748254849 ) { 
    Write-Output "TERM: Final drive location space is at reservation limit." `n | tee-object -filepath $runlog -append
    Exit
    }

# All checks passed, start a new instance
$Path_NewInstance = "$Path_Temp\Plot-$TimeStamp"
Write-Output "Creating new instance at $Path_NewInstance." `n | tee-object -filepath $runlog -append
New-Item $Path_NewInstance -ItemType Directory
Push-Location $Chia_AppPath
$arglist = "plots create -f $pkey_Farmer -p $pkey_Pool -t $Path_NewInstance -d $Path_Final"
Start-Process ./chia.exe -argumentlist $arglist -RedirectStandardOutput "$Chia_PlotLogPath\Plot-$TimeStamp.log"

Pop-Location
