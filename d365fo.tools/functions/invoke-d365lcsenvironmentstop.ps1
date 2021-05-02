﻿
<#
    .SYNOPSIS
        Stop a specified environment through LCS.
        
    .DESCRIPTION
        Stop a specified IAAS environment that is Customer Managed through the LCS API.
        
    .PARAMETER ProjectId
        The project id for the Dynamics 365 for Finance & Operations project inside LCS
        
        Default value can be configured using Set-D365LcsApiConfig
        
    .PARAMETER BearerToken
        The token you want to use when working against the LCS api
        
        Default value can be configured using Set-D365LcsApiConfig
        
    .PARAMETER EnvironmentId
        The unique id of the environment that you want to take action upon
        
        The Id can be located inside the LCS portal
        
    .PARAMETER LcsApiUri
        URI / URL to the LCS API you want to use
        
        Depending where your LCS project is located, there are several valid URI's / URL's
        
        Valid options:
        "https://lcsapi.lcs.dynamics.com"
        "https://lcsapi.eu.lcs.dynamics.com"
        "https://lcsapi.fr.lcs.dynamics.com"
        "https://lcsapi.sa.lcs.dynamics.com"
        "https://lcsapi.uae.lcs.dynamics.com"
        "https://lcsapi.ch.lcs.dynamics.com"
        "https://lcsapi.lcs.dynamics.cn"
        "https://lcsapi.gov.lcs.microsoftdynamics.us"
        
        Default value can be configured using Set-D365LcsApiConfig
        
    .PARAMETER FailOnErrorMessage
        Instruct the cmdlet to write logging information to the console, if there is an error message in the response from the LCS endpoint
        
        Used in combination with either Enable-D365Exception cmdlet, or the -EnableException directly on this cmdlet, it will throw an exception and break/stop execution of the script
        This allows you to implement custom retry / error handling logic
        
    .PARAMETER EnableException
        This parameters disables user-friendly warnings and enables the throwing of exceptions
        This is less user friendly, but allows catching exceptions in calling scripts
        
    .EXAMPLE
        PS C:\> Invoke-D365LcsEnvironmentStop -ProjectId 123456789 -EnvironmentId "958ae597-f089-4811-abbd-c1190917eaae" -BearerToken "JldjfafLJdfjlfsalfd..." -LcsApiUri "https://lcsapi.lcs.dynamics.com"
        
        This will trigger the environment stop operation upon the given environment through the LCS API.
        The LCS project is identified by the ProjectId 123456789, which can be obtained in the LCS portal.
        The environment is identified by the EnvironmentId "958ae597-f089-4811-abbd-c1190917eaae", which can be obtained in the LCS portal.
        The request will authenticate with the BearerToken "JldjfafLJdfjlfsalfd...".
        The http request will be going to the LcsApiUri "https://lcsapi.lcs.dynamics.com"
        
    .EXAMPLE
        PS C:\> Invoke-D365LcsEnvironmentStop -EnvironmentId "958ae597-f089-4811-abbd-c1190917eaae"
        
        This will trigger the environment stop operation upon the given environment through the LCS API.
        The LCS project is identified by the ProjectId 123456789, which can be obtained in the LCS portal.
        The environment is identified by the EnvironmentId "958ae597-f089-4811-abbd-c1190917eaae", which can be obtained in the LCS portal.
        The request will authenticate with the BearerToken "JldjfafLJdfjlfsalfd...".
        The http request will be going to the LcsApiUri "https://lcsapi.lcs.dynamics.com"
        
    .LINK
        Get-D365LcsApiConfig
        
    .LINK
        Get-D365LcsApiToken
        
    .LINK
        Invoke-D365LcsApiRefreshToken
        
    .LINK
        Set-D365LcsApiConfig
        
    .LINK
        Invoke-D365LcsEnvironmentStart
        
    .NOTES
        Only Customer Managed IAAS environments are supported with this API.
        Microsoft Managed IAAS environments need to remain online to allow for Microsoft update operations and are not supported with this API.
        Self-service environments do not have a stop functionality and will not work with this API.
        
        Tags: Environment, Stop, StartStop, Start, LCS, Api
        
        Author: Mötz Jensen (@Splaxi), Billy Richardson (@richardsondev)
        
#>

function Invoke-D365LcsEnvironmentStop {
    [CmdletBinding()]
    [OutputType()]
    param(
        [int] $ProjectId = $Script:LcsApiProjectId,
        
        [Alias('Token')]
        [string] $BearerToken = $Script:LcsApiBearerToken,

        [Parameter(Mandatory = $true)]
        [string] $EnvironmentId,
        
        [string] $LcsApiUri = $Script:LcsApiLcsApiUri,

        [switch] $FailOnErrorMessage,

        [switch] $EnableException
    )

    Invoke-TimeSignal -Start

    if (-not ($BearerToken.StartsWith("Bearer "))) {
        $BearerToken = "Bearer $BearerToken"
    }

    $environmentAction = Start-LcsEnvironmentStartStopV2 -ProjectId $ProjectId -BearerToken $BearerToken -EnvironmentId $EnvironmentId -IsStop $True -LcsApiUri $LcsApiUri

    if (Test-PSFFunctionInterrupt) { return }

    if ($FailOnErrorMessage -and $environmentAction.ErrorMessage) {
        $messageString = "The request against LCS succeeded, but the response was an error message for the operation: <c='em'>$($environmentAction.ErrorMessage)</c>."
        $errorMessagePayload = "`r`n$($environmentAction | ConvertTo-Json)"
        Write-PSFMessage -Level Host -Message $messageString -Exception $([System.Exception]::new($($errorMessagePayload))) -Target $environmentAction
        Stop-PSFFunction -Message "Stopping because of errors." -Exception $([System.Exception]::new($($errorMessagePayload))) -Target $environmentAction
    }

    $temp = [PSCustomObject]@{ EnvironmentId = "$EnvironmentId"; ProjectId = $ProjectId }
    #Hack to silence the PSScriptAnalyzer
    $temp | Out-Null

    $environmentAction | Select-PSFObject *, "OperationActivityId as ActivityId", "EnvironmentId from temp as EnvironmentId", "ProjectId from temp as ProjectId" -TypeName "D365FO.TOOLS.LCS.Environment.Operation.Status"

    Invoke-TimeSignal -End
}