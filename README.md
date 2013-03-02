Get-Warranty
============
By: Craig Meinschein (pfaffle)
With contributions from: Zaynab Alattar (zaalatta)

PowerShell script that retrieves Dell warranty information about a box.

Usage: .\Get-Warranty.ps1 [computername]

This script retrieves the Service Tag from the target computer and then
queries api.dell.com for warranty information. It outputs it as a custom
PowerShell object.

The target computer must of course be manufactured by Dell.

The script requires an API Key (string), which you may be able to find
on the internet, or by talking to your Dell representative.