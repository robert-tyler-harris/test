  ########################### Configure Windows Servers ###########################

$NICs = gip
$ClientDNS = "168.63.129.16","10.100.1.10"
$DC_DNS= "127.0.0.1","168.63.129.16"

# Determine Number of NICs attached
if ((gip).ipv4address.ipaddress[1] -notlike $null)
{
    # Get/Set Interfaces as Variables
    $OutsideNIC = (gip | Where-Object {$_.IPv4Address.IPAddress -like "10.100.0*"})
    $InsideNIC = (gip | Where-Object {$_.IPv4Address.IPAddress -like "10.100.1*"})

    # Set the InsideNIC's Gateway to variable
    [int]$LastOctet = 1
    $Octets = $InsideNIC.IPv4Address.IPAddress -split "\."
    $Octets[3] = $LastOctet.ToString()
    $InsideGateway = $octets -join "."

    Disable-NetAdapterBinding -Name $OutsideNIC.InterfaceAlias -ComponentID ms_tcpip6
    Disable-NetAdapterBinding -Name $InsideNIC.InterfaceAlias -ComponentID ms_tcpip6

    #Set routes on outside Int
    ROUTE ADD 0.0.0.0 MASK 128.0.0.0 $OutsideNIC.IPv4DefaultGateway.nexthop IF $OutsideNIC.InterfaceIndex -p
    ROUTE ADD 128.0.0.0 MASK 128.0.0.0 $OutsideNIC.IPv4DefaultGateway.nexthop IF $OutsideNIC.InterfaceIndex -p

    if($env:COMPUTERNAME -like "vm-dc1")
    {
        Set-DnsClientServerAddress -InterfaceIndex $OutsideNIC.InterfaceIndex -ServerAddresses $DC_DNS
        Set-DnsClientServerAddress -InterfaceIndex $InsideNIC.InterfaceIndex -ServerAddresses $DC_DNS

    }
    else
    {
        Set-DnsClientServerAddress -InterfaceIndex $OutsideNIC.InterfaceIndex -ServerAddresses $ClientDNS
        Set-DnsClientServerAddress -InterfaceIndex $InsideNIC.InterfaceIndex -ServerAddresses $ClientDNS
    }
    # Configure both Interfaces
    netsh interface ip set address name=($OutsideNIC).InterfaceIndex static $OutsideNIC.IPv4Address.Ipaddress 255.255.255.0
    netsh interface ip set address name=($InsideNIC).InterfaceIndex static $InsideNIC.IPv4Address.Ipaddress 255.255.255.0 $InsideGateway

} 
else
{ 
    # Set Static IP
    netsh interface ip set address name=($NIC).InterfaceIndex static $NIC.IPv4Address.Ipaddress 255.255.255.0 ($NIC.IPv4DefaultGateway).NextHop
 
    # Set Client DNS
    Set-DnsClientServerAddress -InterfaceIndex $NIC.InterfaceIndex -ServerAddresses $ClientDNS
}
