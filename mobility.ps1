########################### Mobility Servers ###########################
 
# Get/Set Interfaces as Variables
$OutsideNIC = (gip | Where-Object {$_.IPv4DefaultGateway -ne $null})
$InsideNIC = (gip | Where-Object {$_.IPv4DefaultGateway -eq $null})
$InsideGateway = ([ipaddress]$InsideNIC.IPv4Address.Ipaddress) -replace ([ipaddress]$InsideNIC.IPv4Address.Ipaddress).GetAddressBytes()[3],"1"
 
# Disable IPv6
Disable-NetAdapterBinding -Name $OutsideNIC.InterfaceAlias -ComponentID ms_tcpip6
Disable-NetAdapterBinding -Name $InsideNIC.InterfaceAlias -ComponentID ms_tcpip6
 
#Set routes on outside Int
ROUTE ADD 0.0.0.0 MASK 128.0.0.0 $OutsideNIC.IPv4DefaultGateway.nexthop IF $OutsideNIC.InterfaceIndex -p
ROUTE ADD 128.0.0.0 MASK 128.0.0.0 $OutsideNIC.IPv4DefaultGateway.nexthop IF $OutsideNIC.InterfaceIndex -p
 
# Get Routes
#Route Print
 
# Set Client DNS
Set-DnsClientServerAddress -InterfaceIndex $OutsideNIC.InterfaceIndex -ServerAddresses "168.63.129.16","8.8.8.8"
Set-DnsClientServerAddress -InterfaceIndex $InsideNIC.InterfaceIndex -ServerAddresses "168.63.129.16","8.8.8.8"
 
# Configure both Interfaces
netsh interface ip set address name=($OutsideNIC).InterfaceIndex static $OutsideNIC.IPv4Address.Ipaddress 255.255.255.0
netsh interface ip set address name=($InsideNIC).InterfaceIndex static $InsideNIC.IPv4Address.Ipaddress 255.255.255.0 $InsideGateway
 
# Set Time Zone
#Get-TimeZone -ListAvailable | where {$_.id -like "*pacific*"}
Set-TimeZone -Id "Pacific Standard Time"
