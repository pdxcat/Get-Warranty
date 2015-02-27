function Get-DellWarranty { 
    <#
        .SYNOPSIS
        Retrieves warranty information from Dell computers.
        .SYNTAX
        Get-Warranty [-Computer] <String> [-Latest]
        .DESCRIPTION
        This script retrieves the Service Tag and other basic hardware information from the target computer and then queries api.dell.com to obtain warranty information. It outputs this information as a PowerShell object.
        .PARAMETER Computer
        Specifies the name of the computer for which to retrieve warranty information. You can specify the computer name in one of the following 
        formats:
        
        -- Full computer name (FQDN computer name); for example, computer-01.sales.contoso.com.
        
        -- Fully qualified domain name (FQDN)\computer name; for example, sales.contoso.com\computer-01.
        
        -- NetBIOS domain name\computer name; for example, sales\computer-01.
        
        -- Computer name (host name): for example, computer-01.
        
        If the computer name is not specified, the Get-Warranty cmdlet will retrieve warranty information for the computer on which it was run.
        .PARAMETER Latest
        Filter out all but the most recent warranty.
        .EXAMPLE
        Get-warranty -Computer test-machine-01
    #>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$false,
               ValueFromPipeline=$True,
               ValueFromPipelineByPropertyName=$True)]
    [Alias('Name')]
    [String]$Computer=$env:COMPUTERNAME,
    [Parameter(Mandatory=$false)]
    [Switch]$Latest
)
$apiKey = '1adecee8a60444738f280aad1cd87d0e'

foreach($Comp in $Computer) {
    $computerIsUp = Test-Connection $Comp -Count 1 -Quiet
    if (!$computerIsUp) {
        Write-Error "$Comp is down."
    } else {
        # Get Service Tag and Model of target computer.
        $bios       = gwmi Win32_SystemEnclosure -ComputerName $Comp
        $system     = gwmi Win32_ComputerSystem -ComputerName $Comp
        $serviceTag = $bios.SerialNumber
        $compName   = $bios.__SERVER
        $model      = $system.Model
        $manuf      = $system.Manufacturer

        if (!($manuf -match 'Dell')) {
            Write-Error "Computer not manufactured by Dell. Can't get warranty information."
        } else {
            # Get warranty information from Dell's website.
            $url        = "https://api.dell.com/support/v2/assetinfo/warranty/tags?svctags=${serviceTag}&apikey=${apiKey}"
            $req        = Invoke-RestMethod -URI $url -Method GET
            $warranties = $req.getassetwarrantyresponse.getassetwarrantyresult.response.dellasset.warranties.warranty
            $dellasset  = $req.getassetwarrantyresponse.getassetwarrantyresult.response.dellasset

            # If the $Latest paramater is given, filter out all but the most recent warranty.
            if ($Latest) {
                $latestWarranty = $warranties[0]
                foreach ($warranty in $warranties) {	
                    if ((Get-Date $warranty.enddate) -gt (Get-Date $latestWarranty.enddate)) {
                        $latestWarranty = $warranty
                    }
                }
                $warranties = $latestWarranty
            }

            # Construct and write output object.
            foreach($warranty in $warranties) {
                $age = [datetime]::ParseExact($dellasset.shipdate,"yyyy-MM-ddTHH:mm:ss",$null)
                $age = "{0:N2}" -f (([datetime]::now - $age).days / 365)
                
                $output = New-Object -Type PSCustomObject
                Add-Member -MemberType NoteProperty -Name 'ComputerName' -Value $compName -InputObject $output
                Add-Member -MemberType NoteProperty -Name 'Model' -Value $model -InputObject $output
                Add-Member -MemberType NoteProperty -Name 'ServiceTag' -Value $serviceTag -InputObject $output
                Add-Member -MemberType NoteProperty -Name 'Age' -Value $age -InputObject $output
                # Copy properties from the XML data gotten from Dell.
                foreach($property in ($warranty | Get-Member -Type Property)) {
                    Add-Member -MemberType NoteProperty -Name $property.name `
                        -Value $warranty.$($property.name) `
                        -InputObject $output
                }
                $output.StartDate = [datetime]::ParseExact($output.StartDate,"yyyy-MM-ddTHH:mm:ss",$null)
                $output.EndDate   = [datetime]::ParseExact($output.EndDate,"yyyy-MM-ddTHH:mm:ss",$null) 
                Write-Output $output
            }
        }
    }
}
}
