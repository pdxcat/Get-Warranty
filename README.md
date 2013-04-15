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

I've finally published the API key that I'm using to query Dell's website
for this information. I was skeptical at first because I wasn't sure if it
was appropriate for me to do that. Recently, I've found a few different
places on the Internet which are easily findable with a little Googling
where API keys are posted publicly. I figure the cat is out of the bag now
and there's no need for me to hide it (at least until Dell says otherwise).