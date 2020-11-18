$isoFile = "D:\Downloads\Windows.iso"
$thumbDriveLetter = "E"

echo formatting drive $thumbDriveLetter ...
Format-Volume -DriveLetter $thumbDriveLetter -FileSystem FAT32 -NewFileSystemLabel "Windows10"

echo Mounting iso ...
$isoDriveLetter = (Mount-DiskImage $isoFile -PassThru | Get-Volume).DriveLetter

echo Copying Windows Key ...
$wkey=(Get-WmiObject -query 'select * from SoftwareLicensingService').OA3xOriginalProductKey
echo [PID] > $thumbDriveLetter':\sources\PID.txt'
echo Value=$wkey >> $thumbDriveLetter':\sources\PID.txt'
echo [EditionID] Education [Channel] Retail > $thumbDriveLetter':\sources\EI.cfg'
mkdir $thumbDriveLetter':\drivers'

echo Copying Drivers ...
Export-WindowsDriver -Online -Destination $thumbDriveLetter':\drivers'

echo Copying ISO ...
robocopy $isoDriveLetter':\' $thumbDriveLetter':\' /S

echo done
pause





##old

# #needs admin rights
# #error "The file install.wim is too big for the stick

# $isoFile = "D:\Downloads\Windows.iso"
# $thumbDriveLetter = "E"

# $version = "Windows 10 Pro"


# $thumbDrive = $thumbDriveLetter+':\'
# #  mount iso
# $isoDriveLetter = (Mount-DiskImage $isoFile -PassThru | Get-Volume).DriveLetter


# #TODO check letter automtaically
# If ($isoDriveLetter -eq ""){echo couldnt mount image; exit}
# If ($isoDriveLetter -eq $null){echo couldnt mount image; exit}

# #  move to temp dir
# $tmpdir = New-TemporaryFile | %{ rm $_ ; mkdir $_ }
# cd $tmpdir





# #copy iso to stick
# $jobFileCopy = Start-Job -ScriptBlock {
#   Format-Volume -DriveLetter $args[0] -FileSystem FAT32 -NewFileSystemLabel "Windows10"
#   robocopy $args[1] $args[2] /S /XF install.esd
# } -ArgumentList $thumbDriveLetter, $isoDriveLetter':\', $thumbDrive

# #export drivers
# $jobExportDrivers = Start-Job -ScriptBlock {
#   cd $args[0]
#   mkdir drivers
#   Export-WindowsDriver -Online -Destination .\drivers
# } -ArgumentList $pwd

# #iso/esd -> wim
# $jobUnpackEsd = Start-Job -ScriptBlock {
#   cd $args[0]
#   mkdir wim
#   Dism.exe /Export-Image $args[1], $args[2] /DestinationImageFile:.\wim\install.wim  /Compress:Max /CheckIntegrity
# } -ArgumentList $pwd, /SourceImageFile:$isoDriveLetter":\sources\install.esd", /SourceName:$version


# #TODO wim mount
# $jobMountImage = Start-Job -ScriptBlock {
#   cd $args[0]
#   $args[1] | Wait-Job 
#   mkdir offline
#   Mount-WindowsImage -Path .\offline\ -ImagePath .\wim\install.wim -Name $args[2]
# } -ArgumentList $pwd, $jobUnpackEsd, $version


# #import drivers
# $jobAddDrivers = Start-Job -ScriptBlock {
#   cd $args[0]
#   $args[1] | Wait-Job
#   $args[2] | Wait-Job
#   Add-WindowsDriver -Path .\offline -Driver .\drivers -Recurse
# } -ArgumentList $pwd, $jobExportDrivers, $jobMountImage


# # remove YourPhone app from mounted
# $jobCustomizeMount = Start-Job -ScriptBlock {
#   cd $args[0]
#   $args[1] | Wait-Job
  
#   Remove-AppxProvisionedPackage -PackageName Microsoft.YourPhone -Path .\offline
#   Enable-WindowsOptionalFeature -Path .\offline -FeatureName "NetFx3" -All
  
#   # set product key
#   $productKey = (Get-WmiObject -query 'select * from SoftwareLicensingService').OA3xOriginalProductKey
#   Set-WindowsProductKey -Path .\offline -ProductKey $productKey
  
# } -ArgumentList $pwd, $jobMountImage


# $jobUnMountImage = Start-Job -ScriptBlock {
#   cd $args[0]
#   $args[1] | Wait-Job
#   $args[2] | Wait-Job
#   Dismount-WindowsImage -Path .\offline -Save
#   copy .\wim\install.wim $args[3]
# } -ArgumentList $pwd, $jobCustomizeMount, $jobAddDrivers, $thumbDrive'sources\install.wim'

# echo waiting for tasks to finish
# $jobUnMountImage | Wait-Job
# echo done
# pause
