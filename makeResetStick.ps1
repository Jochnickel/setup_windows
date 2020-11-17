#needs admin rights

$isoFile = $args[0]
$thumbDrive = $args[1]

$version = "Windows 10 Pro"

#  mount iso
$isoDriveLetter = (Mount-DiskImage $isoFile -PassThru | Get-Volume).DriveLetter

#TODO check letter automtaically
If ($isoDriveLetter -eq ""){echo couldnt mount image; exit}
If ($isoDriveLetter -eq $null){echo couldnt mount image; exit}

#  move to temp dir
New-TemporaryFile | %{ rm $_ ; mkdir $_ ; cd $_}



#copy iso to stick
$jobFileCopy = Start-Job -ScriptBlock {
  robocopy $args
} -ArgumentList $isoDriveLetter':\', $thumbDrive, /S,  /XF, install.esd

#export drivers
$jobExportDrivers = Start-Job -ScriptBlock {
  mkdir drivers
  Export-WindowsDriver -Online -Destination .\drivers
}

#iso/esd -> wim
$jobUnpackWim = Start-Job -ScriptBlock {
  mkdir wim
  Dism.exe $args
} -ArgumentList /Export-Image, /SourceImageFile:$isoDriveLetter":\sources\install.esd", /SourceName:$version, /DestinationImageFile:.\wim\install.wim, /Compress:Max, /CheckIntegrity

# wim mount
$jobMountImage = Start-Job -ScriptBlock {
  $args[0] | Wait-Job
  mkdir offline
  Mount-WindowsImage -Path .\offline\ -ImagePath .\wim\install.wim -Name $args[1]
} -ArgumentList $jobUnpackWim, $version


#import drivers
$jobAddDrivers = Start-Job -ScriptBlock {
  $args[0] | Wait-Job
  $args[1] | Wait-Job
  Add-WindowsDriver -Path .\offline -Driver .\drivers -Recurse
} -ArgumentList $jobExportDrivers, $jobMountImage


# remove YourPhone app from mounted
$jobCustomizeMount = Start-Job -ScriptBlock {
  $args[0] | Wait-Job
  
  Remove-AppxProvisionedPackage -PackageName Microsoft.YourPhone -Path .\offline
  Enable-WindowsOptionalFeature -Path .\offline -FeatureName "NetFx3" -All
  
  # set product key
  $productKey = (Get-WmiObject -query 'select * from SoftwareLicensingService').OA3xOriginalProductKey
  Set-WindowsProductKey -Path .\offline -ProductKey $productKey
  
} -ArgumentList $jobMountImage


$jobUnMountImage = Start-Job -ScriptBlock {
  $args[0] | Wait-Job
  $args[1] | Wait-Job
  Dismount-WindowsImage -Path .\offline -Save
  copy .\wim\install.wim $args[2]
} -ArgumentList $jobCustomizeMount, $jobAddDrivers, $thumbDrive'sources\install.wim'

echo waiting for tasks to finish
$jobUnMountImage | Wait-Job
echo done
pause
