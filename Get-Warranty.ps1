[CmdletBinding()]
param(
    [Parameter(Mandatory=$true,
               ValueFromPipeline=$True,
               ValueFromPipelineByPropertyName=$True)]
    [Alias('Name')]
    [String[]]$ComputerName,
    [Parameter(Mandatory=$false)]
    [Switch]$Latest
)
$apiKey = '1adecee8a60444738f280aad1cd87d0e'

foreach($Computer in $ComputerName) {
    $computerIsUp = Test-Connection $Computer -Count 1 -Quiet
    if (!$computerIsUp) {
        Write-Error "$Computer is down."
    } else {
        # Get Service Tag and Model of target computer.
        $bios       = Get-WMIobject -Class Win32_BIOS -ComputerName $Computer
        $system     = Get-WMIobject -Class Win32_ComputerSystem -ComputerName $Computer
        $serviceTag = $bios.SerialNumber
        $compName   = $bios.__SERVER
        $model      = $system.Model
        $manuf      = $system.Manufacturer

        if (!($manuf -match 'Dell')) {
            Write-Error "Computer not manufactured by Dell. Can't get warranty information."
        } else {
            # Get warranty information from Dell's website.
            $wc           = New-Object System.Net.WebClient
            $url          = "https://api.dell.com/support/v2/assetinfo/warranty/tags?svctags=${serviceTag}&apikey=${apiKey}"
            [xml]$webData = $wc.DownloadString($url)
            $warranties   = $webData.getassetwarrantyresponse.getassetwarrantyresult.response.dellasset.warranties.warranty

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
                $output = New-Object -Type PSCustomObject
                Add-Member -MemberType NoteProperty -Name 'ComputerName' -Value $compName -InputObject $output
                Add-Member -MemberType NoteProperty -Name 'Model' -Value $model -InputObject $output
                Add-Member -MemberType NoteProperty -Name 'ServiceTag' -Value $serviceTag -InputObject $output
                # Copy properties from the XML data gotten from Dell.
                foreach($property in ($warranty | Get-Member -Type Property)) {
                    Add-Member -MemberType NoteProperty -Name $property.name `
                        -Value $warranty.$($property.name) `
                        -InputObject $output
                }
                Write-Output $output
            }
        }
    }
}