import-module failoverclusters
#Log Path , Chaning the path will Require update Log Analytics Custom Logs Configuration 
$LogPath = "C:\CSVToLAlogs"
if(!(Test-Path $LogPath)){  New-Item -Path "C:\CSVToLAlogs" -ItemType Directory}

#this to be used by log Analytics Custom Logs  
#Parse Stings ClName=HVCL2 CSVName=CSV1 Path=C:\ClusterStorage\Volume1 TotalSize=1099492749312 FreeSpaceGB=1099219038208 UsedSpaceGB=273711104 UsedPerct=99.97511
$objs = @()
$objs2 = @()
#$Date = Get-Date -Format "MM/dd/yyyy HH:mm:ss"

$clus =  (Get-Cluster).Name
$dom =  (Get-Cluster).domain 
$clusnodes = Get-ClusterNode -Cluster $clus

foreach ( $clusnode in $clusnodes)
    {

       $VMs = Get-vm -ComputerName $clusnode
       foreach ($VM in $vms)
        {
            $obj2 = New-Object PSObject -Property @{
                 VMNAME         = "Name=" + $VM.Name
                 State          = "State=" + $VM.State
                 CPU            = "CPU=" + $VM.CPUUsage
                 MemoryAssigned = "MemoryAssigned=" +$VM.MemoryAssigned
                 Version        = "Version=" + $vm.Version 
            }

            $objs2 += $obj2

        }

        
    }


 if(Get-Cluster -Name $clus)
     {
        $csvs = Get-ClusterSharedVolume -Cluster $clus
        foreach ( $csv in $csvs )
        {
           $csvinfos = $csv | select -Property Name -ExpandProperty SharedVolumeInfo
           foreach ( $csvinfo in $csvinfos )
           {
              $obj = New-Object PSObject -Property @{
                 CLUs        = "CN=" + $Clus
                 Name        = "CVN=" + $csv.Name
                 Path        = "P=" + $csvinfo.FriendlyVolumeName
                 Size        = "TS=" +$csvinfo.Partition.Size
                 FreeSpace   = "FS=" +$csvinfo.Partition.FreeSpace
                 UsedSpace   = "US=" +$csvinfo.Partition.UsedSpace
                 PercentFree = "UP=" +$csvinfo.Partition.PercentFree
              }

              $objs += $obj
           }
        }


        $objs | ft -HideTableHeaders  CLUs,Name,size,FreeSpace,UsedSpace,PercentFree  | Out-File "$LogPath\CluserCSVinfo_$clus.log" ascii 
        $objs2  | ft -HideTableHeaders VMNAME,State,CPU,MemoryAssigned,Version | Out-File "$LogPath\Clusterinfo__$clus.log" ascii 


    }

