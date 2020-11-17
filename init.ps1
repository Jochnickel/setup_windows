Get-AppxPackage Microsoft.YourPhone -AllUsers | Remove-AppxPackage
net user Administrator /active:yes
net user Administrator *
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:Containers-DisposableClientVM /all /norestart
dism.exe /online /enable-feature /featurename:NetFx3 /all /norestart
wsl --set-default-version 2


echo enable incoming remote
netplwiz
