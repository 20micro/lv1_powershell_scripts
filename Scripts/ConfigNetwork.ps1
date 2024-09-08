$ErrorActionPreference = "Stop"

$printAdapterName            = 'Adapter-Name'
$printEnableAdapter          = 'Der Adapter ist nicht aktiviert. Soll der Adapter aktiviert werden? [j/N]'
$printDisableAdapter         = 'Der Adapter ist aktiviert. Soll der Adapter deaktiviert werden? [j/N]'
$printConfigMode             = 'Dynamische oder statische Konfiguration? [d/s]'
$printRenewIpAddr            = 'DHCP bereits aktiviert. Neue IP-Adresse beziehen? [j/N]'
$printStaticIpAddress        = 'Statische IP-Adresse setzen'
$printErrorAdministratorRole = 'Fehler: Das Script muss als Administrator ausgeführt werden!'
$printErrorSettingIpSettings = 'Fehler: Beim Setzen der IP-Einstellungen ist ein Fehler aufgetreten!'
$printErrorWrongKeyInput     = 'Fehler: Falsche Eingabe!'

$defaultAdapterName = 'LAN'
$defaultIpAddr      = '10.0.0.20'
$defaultGateway     = '10.0.0.1'
$defaultDnsAddr     = '10.0.0.1'
$defaultPrefixLen   = 24

$protocol = 'IPv4'

function ShowConfig($netIpInterface) {
	$printIpAddr          = 'IP-Address:   '
	$printSubnet          = 'Subnet-Mask:  '
	$printGateway         = 'Gateway:      '
	$printDnsAddr         = 'DNS-Server:   '
	$printDnsDomain       = 'DNS-Domain:   '
	$printConnectionState = 'Connection:   '
	$printDhcpState       = 'DHCP:         '

	$netIpAddr = $netIpInterface | Get-NetIPAddress
	$ipAddr = $netIpAddr.IPAddress
	$prefixLen = $netIpAddr.PrefixLength

	$gateway = ($netIpInterface | Get-NetIPConfiguration).IPv4DefaultGateway.NextHop
	$networkAdapterConfig = Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object IPAddress -eq $ipAddr
	$subnet = $networkAdapterConfig | Select-Object -ExpandProperty IPSubnet
	$dnsDomain = $networkAdapterConfig.DNSDomain
	$dnsServerAddresses = ($netIpInterface | Get-DnsClientServerAddress) | Select-Object -ExpandProperty ServerAddresses

	$connectionState = $netIpInterface.ConnectionState
	$dhcpState = $netIpInterface.Dhcp

	Write-Output $printIpAddr$ipAddr'/'$prefixLen
	Write-Output $printSubnet$subnet
	Write-Output $printGateway$gateway
	Write-Output $printDnsAddr$dnsServerAddresses
	Write-Output $printDnsDomain$dnsDomain
	Write-Output $printConnectionState$connectionState
	Write-Output $printDhcpState$dhcpState
}

function validateAdministratorRole() {
	$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
	$isAdministrator = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

	if (!($isAdministrator)) {
		Write-Output $printErrorAdministratorRole

		exit 1
	}
}

function configAdapter() {
	if (!($adapterName = Read-Host "$printAdapterName [$defaultAdapterName]")) { $adapterName = $defaultAdapterName }

	try {
		$netAdapter = Get-NetAdapter -Name $adapterName | Where-Object {($_.Status -eq 'up' -or $_.Status -eq 'disabled')}
	} catch {
		Write-Output "Fehler: Der Adapter '$adapterName' existiert nicht!"
		Write-Output ''

		Exit 1
	}

	If ($null -eq $netAdapter) {
		if (!($disableAdapter = Read-Host "Fehler: Der Adapter '$adapterName' ist nicht verbunden! Soll der Adapter deaktiviert werden? [j/N]")) { $disableAdapter = 'N' }
		if ($disableAdapter -eq 'j') {
			Disable-NetAdapter -Name $adapterName -Confirm:$false
		}

		exit 0
	}

	if ($netAdapter.Status -eq 'up') {
		if (!($disableAdapter = Read-Host "$printDisableAdapter")) { $disableAdapter = 'N' }
		if ($disableAdapter -eq 'j') {
			Disable-NetAdapter -Name $adapterName -Confirm:$false
			
			exit 0
		}
	}

	if ($netAdapter.Status -eq 'disabled') {
		if (!($enableAdapter = Read-Host "$printEnableAdapter")) { $enableAdapter = 'N' }
		if ($enableAdapter -eq 'j') {
			Enable-NetAdapter -Name $adapterName -Confirm:$false
		}

		exit 0
	}

	return $netAdapter
}

function InputIpSettings() {
	$ipSettings = [PSCustomObject]@{
		ipAddr = ""
		prefix = 0
		gateway = ""
		dnsAddr = ""
	}

	$inputIpAddr    = 'IP-Address'
	$inputPrefixLen = 'Prefix-Length'
	$inputGateway   = 'Gateway'
	$inputDnsAddr   = 'DNS-Server'

	Write-Output $printStaticIpAddress
	if (!($ipSettings.ipAddr = Read-Host "$inputIpAddr [$defaultIpAddr]")) { $ipSettings.ipAddr = $defaultIpAddr }
	if (!($ipSettings.prefix = Read-Host "$inputPrefixLen [$defaultPrefixLen]")) { $ipSettings.prefix = $defaultPrefixLen }
	if (!($ipSettings.gateway = Read-Host "$inputGateway [$defaultGateway]")) { $ipSettings.gateway = $defaultGateway }
	if (!($ipSettings.dnsAddr = Read-Host "$inputDnsAddr [$defaultDnsAddr]")) { $ipSettings.dnsAddr = $defaultDnsAddr }

	return $ipSettings
}

function configDhcp($netAdapter) {
	$netIpInterface = $netAdapter | Get-NetIPInterface -InterfaceAlias $netAdapter.Name -AddressFamily $protocol

	If ($netIpInterface.DHCP -eq 'Enabled') {
		ShowConfig($netIpInterface)
		Write-Output ''
		$renewIp = Read-Host "$printRenewIpAddr"
		If ($renewIp -eq 'j') {
			$null = ipconfig /release $netAdapter.Name
			$null = ipconfig /renew $netAdapter.Name

			ShowConfig($netIpInterface)
		}

		Exit 0
	}

	If (($netIpInterface | Get-NetIPConfiguration).IPv4DefaultGateway) {
		$netIpInterface | Remove-NetRoute -Confirm:$false
	}

	$netIpInterface | Set-NetIPInterface -DHCP 'Enabled'
	$netIpInterface | Set-DnsClientServerAddress -ResetServerAddresses

	$null = ipconfig /release $netAdapter.Name
	$null = ipconfig /renew $netAdapter.Name

	ShowConfig($netIpInterface)
}

function configStatic($netAdapter) {
	$ipSettings = InputIpSettings

	try {
		$netIpInterface = $netAdapter | Get-NetIPInterface -InterfaceAlias $netAdapter.Name -AddressFamily $protocol

		If (($netIpInterface | Get-NetIPConfiguration).Ipv4Address.IPAddress) {
			$netIpInterface | Remove-NetIPAddress -AddressFamily $protocol -Confirm:$false
		}

		If (($netIpInterface | Get-NetIPConfiguration).Ipv4DefaultGateway) {
			$netIpInterface | Remove-NetRoute -AddressFamily $protocol -Confirm:$false
		}

		$netIpInterface | New-NetIPAddress -AddressFamily $protocol -IPAddress $ipSettings.ipAddr -PrefixLength $ipSettings.prefix -DefaultGateway $ipSettings.gateway
		$netIpInterface | Set-DnsClientServerAddress -ServerAddresses $ipSettings.dnsAddr

		ShowConfig($netIpInterface)
	} catch {
		Write-Output $printErrorSettingIpSettings

		exit 1
	}
}

# Script-Start
validateAdministratorRole

$netAdapter = configAdapter

$configMode = Read-Host "$printConfigMode"

if ($configMode -eq 'd') {
	configDhcp($netAdapter)
} elseif ($configMode -eq 's') {
	configStatic($netAdapter)
} else {
	Write-Output $printErrorWrongKeyInput

	exit 1
}

exit 0
