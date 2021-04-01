#Requires -Modules Selenium

#Quick and Dirty script to notify on halfords restocking

# Also needs the matching webdriver matching the google chrome version 
# Download from https://chromedriver.storage.googleapis.com/index.html
# Place here: C:\Program Files\WindowsPowerShell\Modules\Selenium\3.0.1\assemblies
# More information on Selenium module can be found here
# https://adamtheautomator.com/selenium-powershell/#Importing_the_Selenium_to_PowerShell
if(-not (Get-Module Selenium)){
    Install-Module Selenium
}else{
    write-host "Selenium Module installed"
}

import-Module Selenium


#actual url
$url='https://www.halfords.com/bikes/electric-bikes/voodoo-bizango-e-shimano-electric-mountain-bike---17in-19in-21in-frames-180982.html'
#test url - testing in stock stuff
#$url='https://www.halfords.com/bikes/electric-bikes/carrera-vengeance-e-mens-electric-mountain-bike-2.0---18in-20in-frames-446110.html'
$interval_mins = 60

$prowl_apikey="xxxxxxx"
function Send-ProwlNotification {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,ValueFromPipeline)]
        [string[]]$ApiKeys,
        [string]$Subject,
        [string]$Message,
        [ValidateNotNullOrEmpty()]
        [string]$From='Posh-Prowl',
        [string]$ProviderKey,
        [ValidateRange(-2,2)]
        [int]$Priority=0,
        [string]$Url
    )

    Begin {
        $allKeys = @()
        $apiUrl = 'https://api.prowlapp.com/publicapi/add'

        # $Subject and/or $Message are/is required
        if (-not $Subject -and -not $Message) {
            throw "You must provide -Subject or -Message or both."
        }

        # validate the byte length of the various parameters
        if ($Subject) {
            if ([Text.Encoding]::UTF8.GetByteCount($Subject) -gt 1024) {
                throw "Subject must be no larger than 1024 bytes."
            }
        }
        if ($Message) {
            if ([Text.Encoding]::UTF8.GetByteCount($Message) -gt 10000) {
                throw "Message must be no larger than 10000 bytes."
            }
        }
        if ($From) {
            if ([Text.Encoding]::UTF8.GetByteCount($From) -gt 256) {
                throw "From must be no larger than 256 bytes."
            }
        }
        if ($ProviderKey) {
            if ([Text.Encoding]::UTF8.GetByteCount($ProviderKey) -gt 40) {
                throw "ProviderKey must be no larger than 40 bytes."
            }
        }
        if ($Url) {
            if ([Text.Encoding]::UTF8.GetByteCount($Url) -gt 512) {
                throw "Url must be no larger than 512 bytes."
            }
        }
    }

    Process {
        # add the keys from this pipeline item to
        # the set of all keys
        $allKeys += $ApiKeys
    }

    End {
        # remove duplicates
        $allKeys = $allKeys | Select-Object -Unique

        # prepare the keys for transmission
        $apikey = $allKeys -join ','

        # build the body
        $body = @{
            apikey = $apikey
            application = $From
            priority = $Priority
        }
        if ($Subject) { $body.event = $Subject }
        if ($Message) { $body.description = $Message }
        if ($ProviderKey) { $body.providerkey = $ProviderKey }
        if ($Url) { $body.url = $Url }

        Write-Verbose "Sending message to $($allKeys.Count) key(s)"
        $response = Invoke-RestMethod $apiUrl -Method Post -Body $body

        if ($response.prowl.success) {
            Write-Verbose "$($response.prowl.success.remaining) calls remaining. Resets at $([DateTimeOffset]::FromUnixTimeSeconds($response.prowl.success.resetdate))"
        }

    }


    <#
    .SYNOPSIS
        Send a Prowl notification.
    .DESCRIPTION
        Send a Prowl push notification to one or more API keys.
    .PARAMETER APIKeys
        One or more Prowl API keys to send to.
    .PARAMETER Subject
        The name of the event or subject of the notification. Required if Message is not specified. (1024 bytes max)
    .PARAMETER Message
        A description of the event, generally terse. Required if Subject is not specified. (10,000 bytes max)
    .PARAMETER From
        The name of your application or the sender of the event. (256 bytes max)
    .PARAMETER ProviderKey
        Your provider API key. Only necessary if you have been whitelisted.
    .PARAMETER Priority
        The priority of the notification ranging from -2 to 2 where -2 is Very Low and 2 is Emergency. Emergency priority messages may bypass quiet hours according to the user's settings.
    .PARAMETER Url
        The URL which should be attached to the notification. This will trigger a redirect when launched, and is viewable in the notification list. (512 bytes max)
    .EXAMPLE
        Send-ProwlNotification 'XXXXXXXXXXXX' -Subject 'The operation is complete.'
        Send a subject-only message to a single API key.
    .EXAMPLE
        $keys = 'XXXXXXXXXXXXXXXX','YYYYYYYYYYYYYYYY'
        PS C:\>$from = 'The Ticketing System'
        PS C:\>$subject = 'Ticket Requires Attention'
        PS C:\>$msg = 'Ticket #12345 requires authorization.'
        PS C:\>$url = 'https://example.com/tickets/12345'
        PS C:\>$keys | Send-ProwlNotification -Subject $subject -Message $msg -From $from -Url $url
        Send a message to multiple recipients with a custom app name and URL link
    .LINK
        Project: https://github.com/rmbolger/Posh-Prowl
    #>
}

do{
    # Create a new ChromeDriver Object instance.
    $ChromeDriver = New-Object OpenQA.Selenium.Chrome.ChromeDriver
    # Launch a browser and go to URL
    $ChromeDriver.Navigate().GoToURL($url)
    $ChromeDriver.FindElementByXPath("//*[@id=""productInfoBlock""]/div[6]/div[1]/div[1]/div/div[1]/ul/li[1]/a/span").Click()
    $ChromeDriver.ExecuteScript("window.scrollTo(0, 1380)")
    Start-Sleep -Seconds 1
    $location=$ChromeDriver.FindElementByXPath("/html/body/div[1]/section[2]/div[3]/div[1]/div/div[2]/div[6]/div[3]/div/div/div[1]/form/div[1]/div/div[1]/div/div/input")
    $location.SendKeys("SO41 0LH")
 


    $location.Submit()
    Start-Sleep -Seconds 2
    $inStock=$ChromeDriver.FindElementByXPath("/html/body/div[1]/section[2]/div[3]/div[1]/div/div[2]/div[6]/div[3]/div/div/div[3]/div/div/div[2]/div[2]/button") 
    $inStock
            if((Measure-Object -InputObject $inStock).count -eq 1){
             Write-Host "in stock sending push" -ForegroundColor Green
            Send-ProwlNotification -Subject "$NoOfSlots Halfords Bike Stock Found" -Message "Urgent Alert" -Priority 2 -ApiKeys $prowl_apikey
#send push
        }else{
            Write-Host "not in stock"  -ForegroundColor Red
            Send-ProwlNotification -Subject "$NoOfSlots Halfords Bike not Found" -Message "Urgent Alert" -Priority 2 -ApiKeys $prowl_apikey
    }

    $ChromeDriver.Close()
    $ChromeDriver.Quit()
    Start-Sleep -Seconds ($interval_mins * 60)

} while ($inStock -eq $null)
