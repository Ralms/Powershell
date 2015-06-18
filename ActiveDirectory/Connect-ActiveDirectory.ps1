function Connect-ActiveDirectory {
    [CmdletBinding()]
    param (
        [Parameter(ParameterSetName='Credential')]
        [Parameter(ParameterSetName='CredentialObject')]
        [Parameter(ParameterSetName='Default')]
        [string]$ComputerName,
        [Parameter(ParameterSetName='Credential')]
        [string]$DomainName,
        [Parameter(ParameterSetName='Credential', Mandatory=$true)]
        [string]$UserName,
        [Parameter(ParameterSetName='Credential', HelpMessage='Password for Username in remote domain.', Mandatory=$true)]
        [string]$Password,
        [parameter(ParameterSetName='CredentialObject',HelpMessage='Full credential object',Mandatory=$True)]
        [System.Management.Automation.PSCredential]$Creds,
        [Parameter(HelpMessage='Context to return, forest, domain, or DirectoryEntry.')]
        [ValidateSet('Domain','Forest','DirectoryEntry','ADContext')]
        [string]$ADContextType = 'ADContext'
    )
    
    $UsingAltCred = $false
    
    # If the username was passed in domain\<username> or username@domain then gank the domain name for later use
    if (($UserName -split "\\").Count -gt 1) {
        $DomainName = ($UserName -split "\\")[0]
        $UserName = ($UserName -split "\\")[1]
    }
    if (($UserName -split "\@").Count -gt 1) {
        $DomainName = ($UserName -split "\@")[1]
        $UserName = ($UserName -split "\@")[0]
    }
    
    switch ($PSCmdlet.ParameterSetName) {
        'CredentialObject' {
            if ($Creds.GetNetworkCredential().Domain -ne '')  {
                $UserName= $Creds.GetNetworkCredential().UserName
                $Password = $Creds.GetNetworkCredential().Password
                $DomainName = $Creds.GetNetworkCredential().Domain
                $UsingAltCred = $true
            }
            else {
                throw 'The credential object must include a defined domain.'
            }
        }
        'Credential' {
            if (-not $DomainName) {
                Write-Error 'Username must be in @domainname.com or <domainname>\<username> format or the domain name must be manually passed in the DomainName parameter'
                return $null
            }
            else {
                $UserName = $DomainName + '\' + $UserName
                $UsingAltCred = $true
            }
        }
    }

    $ADServer = ''
    
    # If a computer name was specified then we will attempt to perform a remote connection
    if ($ComputerName) {
        # If a computername was specified then we are connecting remotely
        $ADServer = "LDAP://$($ComputerName)"
        $ContextType = [System.DirectoryServices.ActiveDirectory.DirectoryContextType]::DirectoryServer

        if ($UsingAltCred) {
            $ADContext = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext $ContextType, $ComputerName, $UserName, $Password
        }
        else {
            if ($ComputerName) {
                $ADContext = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext $ContextType, $ComputerName
            }
            else {
                $ADContext = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext $ContextType
            }
        }
        
        try {
            switch ($ADContextType) {
                'ADContext' {
                    return $ADContext
                }
                'DirectoryEntry' {
                    if ($UsingAltCred) {
                        return New-Object System.DirectoryServices.DirectoryEntry($ADServer ,$UserName, $Password)
                    }
                    else {
                        return New-Object -TypeName System.DirectoryServices.DirectoryEntry $ADServer
                    }
                }
                'Forest' {
                    return [System.DirectoryServices.ActiveDirectory.Forest]::GetForest($ADContext)
                }
                'Domain' {
                    return [System.DirectoryServices.ActiveDirectory.Domain]::GetDomain($ADContext)
                }
            }
        }
        catch {
            throw
        }
    }
    
    # If using just an alternate credential without specifying a remote computer (dc) to connect they
    # try connecting to the locally joined domain with the credentials.
    if ($UsingAltCred) {
        # *** FINISH ME ***
    }
    # We have not specified another computer or credential so connect to the local domain if possible.
    try {
        $ContextType = [System.DirectoryServices.ActiveDirectory.DirectoryContextType]::Domain
    }
    catch {
        throw 'Unable to connect to a default domain. Is this a domain joined account?'
    }
    try {
        switch ($ADContextType) {
            'ADContext' {
                return New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext $ContextType
            }
            'DirectoryEntry' {
                return [System.DirectoryServices.DirectoryEntry]''
            }
            'Forest' {
                return [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()
            }
            'Domain' {
                return [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
            }
        }
    }
    catch {
        throw
    }
}
