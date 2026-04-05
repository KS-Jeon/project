param(
    [Parameter(Mandatory = $true)]
    [string]$ManagementEndpoint,

    [Parameter(Mandatory = $true)]
    [string]$SvmName,

    [string]$SshUser = "fsxadmin",

    [string]$ShareName = "shared",

    [string]$SharePath = "/shared",

    [switch]$RequireSmbEncryption,

    [switch]$DryRun
)

# This helper assumes an ONTAP administrator account (for example fsxadmin)
# is already configured and reachable over SSH from the execution host.

$commands = @(
    "vserver cifs share create -vserver $SvmName -share-name $ShareName -path $SharePath"
)

if ($RequireSmbEncryption) {
    $commands += "vserver cifs share properties add -vserver $SvmName -share-name $ShareName -share-properties encrypt-data"
}

$remoteCommand = $commands -join "; "

if ($DryRun) {
    Write-Host "ssh $SshUser@$ManagementEndpoint $remoteCommand"
    exit 0
}

ssh "$SshUser@$ManagementEndpoint" $remoteCommand
