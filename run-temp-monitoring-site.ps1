
<#
.SYNOPSIS
    Script to set up monitoring website infrastructure in AWS and Cloudflare, run it for a specified duration,
        then tear down the infrastructure

.DESCRIPTION
    This script creates S3 buckets for storing monitoring data and photos,
        deploys EC2 infrastructure using CloudFormation to host a static monitoring site,
        updates DNS records in Cloudflare (if token provided),
        and uploads monitoring data and images at regular intervals, to be displayed on the site.

    After the specified duration, it cleans up by deleting the CloudFormation stack, S3 buckets,
        and Cloudflare DNS record

    Script demonstrates the following:
        - Use of PowerShell runspaces for parallel execution of bucket creation and deletion
        - Interacting with an HTTP API (Cloudflare) using Invoke-RestMethod
        - JSON serialization and deserialization
        - Logging with timestamps and message types
        - Parameter validation
        - Error handling with try/catch/finally blocks
        - Interaction with AWS services using the AWS CLI and the AWSPowerShell.NetCore module
        - Use of external tools (fswebcam) to capture images from a webcam

.PARAMETER SiteRunDurationMinutes
    Duration in minutes for which the monitoring site should run before cleanup

.PARAMETER RunspacesMaxCount
    Maximum number of runspaces to use for parallel operations

.PARAMETER S3Region
    AWS region where S3 infra will be created

.PARAMETER CloudflareToken
    Cloudflare API token for DNS records manipulation. If not provided, DNS updates are skipped, but site will still be accessible at the IP address.

.PARAMETER CloudflareZoneId
    Cloudflare Zone ID for the domain where DNS records will be updated

.NOTES
    Requires AWS CLI and AWSPowerShell.NetCore module
    Requires fswebcam to capture images from a connected webcam
    Requires CloudFlare API token that has permissions to manage DNS records for the specified zone
    AWS credentials must be configured in the environment where this script runs
#>

param (
    [int]    $SiteRunDurationMinutes = 5,
    [int]    $RunspacesMaxCount = 5,
    [string] $S3Region = "us-east-2",
    [string] $CloudflareToken,
    [string] $CloudflareZoneId
)

$ScriptStartTime = Get-Date

$BucketNames = @(
    "biffkittz-monitoring-data",
    "biffkittz-photos"
)

function Write-Message {
    param (
        [ValidateSet("Info", "Warning", "Error")]
        [string]$MessageType = "Info",
        [string]$Message
    )

    $TimeStamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss.fff")

    if ($MessageType -eq "Error") {
        Write-Host "[$TimeStamp] [$MessageType] $Message" -ForegroundColor Red
        return
    }

    if ($MessageType -eq "Warning") {
        Write-Host "[$TimeStamp] [$MessageType] $Message" -ForegroundColor Yellow
        return
    }

    if ($MessageType -eq "Info") {
        Write-Host "[$TimeStamp] [$MessageType] $Message" -ForegroundColor Green
        return
    }
}

#region Checks and validations

if ((-not $RunspacesMaxCount) -or $RunspacesMaxCount -le 0) {
    Write-Message -MessageType Error -Message "RunspacesMaxCount must be a positive integer."
    exit 1
}

if ($S3Region -notin @("us-east-1", "us-east-2", "us-west-1", "us-west-2")) {
    Write-Message -MessageType Error -Message "Invalid S3Region specified. Please provide a valid AWS region."
    exit 1
}

if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
    Write-Message -MessageType Error -Message "AWS CLI not found. Please install AWS CLI and configure credentials."
    exit 1
}

try {
    Import-Module -Name AWSPowerShell.NetCore -ErrorAction Stop
    Write-Message -MessageType Info -Message "Imported module AWSPowerShell.NetCore"
}
catch {
    Write-Message -MessageType Error -Message "Module AWSPowerShell.NetCore not found. Install and try again."
}

if (-not (Get-Command Wait-CFNStack -ErrorAction SilentlyContinue)) {
    Write-Message -MessageType Error -Message  "Command Wait-CFNStack not found. Please install AWSPowerShell.NetCore."
    exit 1
}

#endregion

# Initialize runspace pool for parallel S3 bucket operations
$RunspacesMinCount = 1

$global:RunspacePool = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspacePool(
    $RunspacesMinCount,
    $RunspacesMaxCount
)

$global:RunspacePool.Open()

#region Helper Functions

function Wait-ForRunspacesCompletionAndThrowOnTimeout {
    param (
        [array]  $Runspaces,
        [int]    $TimeoutSeconds,
        [string] $ErrorMessage = "Timeout waiting for runspaces to complete"
    )

    $StartTime = Get-Date

    Write-Message `
        -MessageType "Info" `
        -Message "Waiting for runspaces to complete with timeout of $TimeoutSeconds seconds"

    while ( $Runspaces.State.IsCompleted -contains $False) {
        if ( (Get-Date) - $StartTime -gt (New-TimeSpan -Seconds $TimeoutSeconds) ) {
            Write-Message -MessageType "Error" -Message "Timeout waiting for runspaces to complete"
            throw $ErrorMessage ?? "Timeout waiting for runspaces to complete"
        }

        Start-Sleep -Milliseconds 10
    }
}

function Get-RunspacesResults {
    param (
        [array] $Runspaces
    )

    Write-Message `
        -MessageType "Info" `
        -Message "Collecting runspaces results"

    $Results = @()
    $Runspaces | ForEach-Object {
        $Results += $_.Runspace.EndInvoke($_.State)
    }

    Write-Host $Results
}

function Invoke-ScriptBlockPerBucketInRunspace {
    param (
        [ScriptBlock] $ScriptBlock,
        [array]       $BucketNames,
        [string]      $S3Region
    )

    $Runspaces = @()

    foreach ($BucketName in $BucketNames)
    {
        $Runspace = [powershell]::Create().AddScript($ScriptBlock)
        $null = $Runspace.AddArgument($BucketName)
        $null = $Runspace.AddArgument($S3Region)

        $Runspace.RunspacePool = $global:RunspacePool
        $Runspaces += New-Object PSObject -Property @{
            Runspace = $Runspace
            State = $Runspace.BeginInvoke()
        }
    }

    return $Runspaces
}
#endregion

#region Create S3 buckets in parallel using runspaces
$BucketCreationScriptBlock = {
    param (
        [string] $BucketName,
        [string] $S3Region
    )

    aws s3api create-bucket `
        --bucket $BucketName `
        --region $S3Region `
        --create-bucket-configuration LocationConstraint=$S3Region *> Out-Null

    Write-Message -MessageType Info "Attempted to create bucket $BucketName"
}

$BucketDestructionScriptBlock = {
    param (
        [string] $BucketName,
        [string] $S3Region
    )

    aws s3 rm s3://$BucketName --recursive *> Out-Null
    aws s3api delete-bucket `
        --bucket $BucketName `
        --region $S3Region *> Out-Null

    Write-Message Info "Attempted to destroy bucket $BucketName"
}

$BucketCreationRunspaces = Invoke-ScriptBlockPerBucketInRunspace `
    -ScriptBlock $BucketCreationScriptBlock `
    -BucketName $BucketNames `
    -S3Region $S3Region

Wait-ForRunspacesCompletionAndThrowOnTimeout `
    -Runspaces $BucketCreationRunspaces `
    -TimeoutSeconds 30 `
    -ErrorMessage "Timeout waiting for BucketCreationRunspaces to complete"
#endregion


#region Configure S3 bucket policies and CORS

# Allow public access to monitoring data bucket
aws s3api put-public-access-block `
    --bucket biffkittz-monitoring-data `
    --public-access-block-configuration BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false `
    --region $S3Region

# Add bucket policy to allow public read access to objects in monitoring data bucket
$bucketPolicyJson = @'
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowPublicRead",
            "Effect": "Allow",
            "Principal": "*",
            "Action": [
                "s3:GetObject"
            ],
            "Resource": [
                "arn:aws:s3:::biffkittz-monitoring-data/*"
            ]
        }
    ]
}
'@

Write-S3BucketPolicy `
    -BucketName "biffkittz-monitoring-data" `
    -Policy $bucketPolicyJson `
    -Region $S3Region

# Configure CORS for monitoring data bucket
aws s3api put-bucket-cors `
    --bucket biffkittz-monitoring-data `
    --cors-configuration file://cors.json `
    --region $S3Region

#endregion

#region Create EC2 infra using CloudFormation

# Create EC2 infra to host the monitoring site using CloudFormation
$cfnStackName = "temp-stack-$(([Guid]::NewGuid().ToString().Substring(0, 8)))"
$(aws cloudformation create-stack --stack-name $cfnStackName --template-body file://temp-infra.yaml)

Wait-CFNStack -StackName $cfnStackName -Status "CREATE_COMPLETE" -Timeout 300

$stackOutputs = (aws cloudformation describe-stacks --stack-name $cfnStackName --query "Stacks[0].Outputs" | ConvertFrom-Json)
$stackOutputMap = @{}
foreach ($output in $stackOutputs) {
    $stackOutputMap[$output.OutputKey] = $output.OutputValue
}

Write-Host "**************************************************"
Write-Message -MessageType Info "WebsiteURL: $($stackOutputMap["WebsiteURL"])"
Write-Host "**************************************************"
#endregion

#region Cloudflare DNS Record Update
$CloudflareDnsRecordId = $null

# Only attempt DNS update if CloudflareToken and CloudflareZoneId are provided
if ($CloudflareToken -and $CloudflareZoneId) {
    Write-Message -MessageType Info "Updating Cloudflare DNS record for monitoring site..."

    $CloudflareRecordName = "monitor.biffkittz.com"

    # Parse IP address of EC2 instance from WebsiteURL output returned by CloudFormation
    $IPAddress = $stackOutputMap["WebsiteURL"].Replace("http://", "").Replace("/", "")

    # Prepare DNS record payload
    $dnsRecordPayload = @{
        name = $CloudflareRecordName
        type = "A"
        content = $IPAddress
        ttl = 120
        proxied = $false
    } | ConvertTo-Json

    # Either update or create the DNS record, storing the record ID for later deletion
    $existingRecordResponse = Invoke-RestMethod -Method Get `
        -Uri "https://api.cloudflare.com/client/v4/zones/$CloudflareZoneId/dns_records?name=$CloudflareRecordName" `
        -Headers @{ "Authorization" = "Bearer $CloudflareToken"; "Content-Type" = "application/json" }

    if ($existingRecordResponse.result.Count -gt 0) {
        $CloudflareDnsRecordId = $existingRecordResponse.result[0].id

        Invoke-RestMethod -Method Put `
            -Uri "https://api.cloudflare.com/client/v4/zones/$CloudflareZoneId/dns_records/$recordId" `
            -Headers @{ "Authorization" = "Bearer $CloudflareToken"; "Content-Type" = "application/json" } `
            -Body $dnsRecordPayload
    }
    else {
        $newRecordResponse = Invoke-RestMethod -Method Post `
            -Uri "https://api.cloudflare.com/client/v4/zones/$CloudflareZoneId/dns_records" `
            -Headers @{ "Authorization" = "Bearer $CloudflareToken"; "Content-Type" = "application/json" } `
            -Body $dnsRecordPayload

        $CloudflareDnsRecordId = $newRecordResponse.result[0].id
    }

    Write-Message -MessageType Info "Updated Cloudflare DNS record for monitor.biffkittz.com to point to $IPAddress"
}
#endregion

#region Main run loop
try {
    Write-Message -MessageType Info "Entering run loop for $SiteRunDurationMinutes minutes..."
    while ((Get-Date) - $ScriptStartTime -lt (New-TimeSpan -Minutes $SiteRunDurationMinutes)) {

        # Capture a new backyard photo using fswebcam and upload to S3
        fswebcam -r 640x480 --jpeg -D 3 -S 13 backyard.jpg *> Out-Null
        aws s3 cp /home/biffkittz/powershell/backyard.jpg "s3://biffkittz-monitoring-data/backyard.jpg" --region $S3Region

        # Query some "monitoring" data, parse lines into object, write to json file, and upload to S3
        df -h > df-output.txt
        $data = @()
        $dfOutput = Get-Content -Path df-output.txt

        # Create objects from df-output.txt lines and add them to data array
        $dfOutput | ForEach-Object {
            $line = $_
            $escapedLine = $line -replace '"', '\"'

            $lineData = $escapedLine -split '\s+'

            $dataItem = @{
                Filesystem = $lineData[0]
                Size = $lineData[1]
                Used = $lineData[2]
                Avail = $lineData[3]
            }

            $data += $dataItem
        }

        # Write data array to JSON file
        "$($data | ConvertTo-Json -Depth 3)" > df-output.json

        # upload json to S3
        aws s3 cp /home/biffkittz/powershell/df-output.json "s3://biffkittz-monitoring-data/df-output.json" --region $S3Region

        Start-Sleep -Seconds 15
    }
}
finally {
    Write-Message -MessageType Warning "Tearing down infra after running site for $SiteRunDurationMinutes minutes"

    Write-Message -MessageType Info "Deleting CloudFormation stack..."
    aws cloudformation delete-stack --stack-name $cfnStackName

    Write-Message -MessageType Info "Destroying S3 buckets..."
    $BucketDestructionRunspaces = Invoke-ScriptBlockPerBucketInRunspace `
        -ScriptBlock $BucketDestructionScriptBlock `
        -BucketNames $BucketNames `
        -S3Region $S3Region

    Wait-ForRunspacesCompletionAndThrowOnTimeout `
        -Runspaces $BucketDestructionRunspaces `
        -TimeoutSeconds 30 `
        -ErrorMessage "Timeout waiting for BucketDestructionRunspaces to complete"

    if ($CloudflareDnsRecordId) {
        Write-Message -MessageType Info "Deleting monitor.biffkittz.com record from Cloudflare..."
        Invoke-RestMethod -Method Delete `
            -Uri "https://api.cloudflare.com/client/v4/zones/$CloudflareZoneId/dns_records/$CloudflareDnsRecordId" `
            -Headers @{ "Authorization" = "Bearer $CloudflareToken"; "Content-Type" = "application/json" }
    }

    Write-Message -MessageType Info "Teardown complete."
}
#endregion
