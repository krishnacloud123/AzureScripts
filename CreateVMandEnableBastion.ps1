# This script will create RG , create VNET , Create Bastion Host followed by Virtual Machine 

New-AzResourceGroup -Name Test-Bastion-RG -Location "East US"

#Setup Bastion and VNET coniguration
$Bastionsub = New-AzVirtualNetworkSubnetConfig -Name AzureBastionSubnet -AddressPrefix 10.0.0.0/27
$FWsub = New-AzVirtualNetworkSubnetConfig -Name AzureFirewallSubnet -AddressPrefix 10.0.1.0/26
$Worksub = New-AzVirtualNetworkSubnetConfig -Name Workload-SN -AddressPrefix 10.0.2.0/24


#create the virtual network:
$testVnet = New-AzVirtualNetwork -Name Test-Bastion-VN -ResourceGroupName Test-Bastion-RG `
-Location "East US" -AddressPrefix 10.0.0.0/16 -Subnet $Bastionsub, $FWsub, $Worksub

#Create Bastion Host
$publicip = New-AzPublicIpAddress -ResourceGroupName Test-Bastion-RG -Location "East US" `
   -Name Bastion-pip -AllocationMethod static -Sku standard

New-AzBastion -ResourceGroupName Test-Bastion-RG -Name Bastion-01 -PublicIpAddress $publicip -VirtualNetwork $testVnet

#Create a Virtual Machine and Create the NIC
$wsn = Get-AzVirtualNetworkSubnetConfig -Name  Workload-SN -VirtualNetwork $testvnet
$NIC01 = New-AzNetworkInterface -Name Srv-Work -ResourceGroupName Test-Bastion-RG -Location "East us" -Subnet $wsn

#Define the virtual machine
$VirtualMachine = New-AzVMConfig -VMName Srv-Work -VMSize "Standard_DS2"
$VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName Srv-Work -ProvisionVMAgent -EnableAutoUpdate
$VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $NIC01.Id
$VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName 'MicrosoftWindowsServer' -Offer 'WindowsServer' -Skus '2019-Datacenter' -Version latest

#Create the virtual machine
New-AzVM -ResourceGroupName Test-Bastion-RG -Location "East US" -VM $VirtualMachine -Verbose

#Delete the Resoruce Group after the test to stop the charges
