#needs admin rights

$isoFile = $args[0]

#  mount iso
$isoDriveLetter = (Mount-DiskImage $isoFile -PassThru | Get-Volume).DriveLetter

#TODO check letter automtaically

#  move to temp dir
New-TemporaryFile | %{ rm $_ ; mkdir $_ ; cd $_}

#TODO unpack wim
mkdir wim
dism /export-image /SourceImageFile:$isoDriveLetter":\sources\install.esd" /DestinationImageFile:.\wim\install.wim

#TODO mount image
mkdir offline
Mount-WindowsImage -ImagePath .\wim\install.wim -Path .\offline # -Index 2 

#TODO export drivers
mkdir drivers
Export-WindowsDriver -Online -Destination .\drivers

#TODO add drivers to image
Add-WindowsDriver -Path .\offline -Driver .\drivers -Recurse

# remove YourPhone app
Remove-AppxProvisionedPackage -PackageName Microsoft.YourPhone -Path .\offline

# set product key
$productKey = (Get-WmiObject -query 'select * from SoftwareLicensingService').OA3xOriginalProductKey
Set-WindowsProductKey -Path .\offline -ProductKey $productKey

#pack
Dismount-WindowsImage -Path "c:\offline" -Save
