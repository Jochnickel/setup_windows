#needs admin rights

$isoFile = $args[0]
$thumbDrive = $args[1]

$version = "Windows 10 Pro"

#  mount iso
$isoDriveLetter = (Mount-DiskImage $isoFile -PassThru | Get-Volume).DriveLetter

#TODO check letter automtaically
If ($isoDriveLetter -eq ""){echo couldnt mount image; exit}
If ($isoDriveLetter -eq $null){echo couldnt mount image; exit}

#copy to stick
Start-Job -ScriptBlock {robocopy $args} -ArgumentList $isoDriveLetter':\', $thumbDrive, /S,  /XF, install.esd

Get-Job
#  move to temp dir
New-TemporaryFile | %{ rm $_ ; mkdir $_ ; cd $_}

Get-Job
# unpack wim
mkdir wim
Dism.exe /Export-Image /SourceImageFile:$isoDriveLetter":\sources\install.esd" /SourceName:$version /DestinationImageFile:.\wim\install.wim /Compress:Max /CheckIntegrity

Get-Job
#TODO mount image
mkdir offline
Mount-WindowsImage -Path .\offline\ -ImagePath .\wim\install.wim -Name $version

Get-Job
#TODO export drivers
mkdir drivers
Export-WindowsDriver -Online -Destination .\drivers

Get-Job
#TODO add drivers to image
Add-WindowsDriver -Path .\offline -Driver .\drivers -Recurse

Get-Job
# remove YourPhone app
Remove-AppxProvisionedPackage -PackageName Microsoft.YourPhone -Path .\offline
Enable-WindowsOptionalFeature -Path .\offline -FeatureName "NetFx3" -All

Get-Job
# set product key
$productKey = (Get-WmiObject -query 'select * from SoftwareLicensingService').OA3xOriginalProductKey
Set-WindowsProductKey -Path .\offline -ProductKey $productKey

Get-Job
#pack
Dismount-WindowsImage -Path .\offline -Save


