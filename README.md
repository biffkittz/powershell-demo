# PowerShell Demo
1. PowerShell runspaces for parallel ScriptBlock executions
2. Integrated with AWS CLI and AWS PowerShell modules
3. Various API calls made to Cloudflare using Invoke-RestMethod
4. Text to object creation, JSON serialization/deserialization
5. Logging and error handling

#### Prerequisites
1. Configured AWS credentials that permit S3 and EC2 operations
2. Cloudflare credential and ZoneId for DNS management (optional)
3. AWS CLI and AWSPowerShell.NetCore module
4. fswebcam utlity for command-line webcam capturing

#### Example invocation
Tested using PowerShell 7.5.3 on Debian 12
```
PS> ./run-temp-monitoring-site.ps1 -CloudflareToken <token> -CloudflareZoneId <zone_id>
```

#### Live Site
<img src="https://github.com/biffkittz/powershell-demo/blob/main/monitor.png" width="300" height="500">

#### Example Script Output

```
[2025-09-23 12:26:07.287] [Info] Imported module AWSPowerShell.NetCore
[2025-09-23 12:26:07.353] [Info] Waiting for runspaces to complete with timeout of 30 seconds

{
    "StackId": "arn:aws:cloudformation:us-east-2:670833622677:stack/temp-stack-216248a1/04c329d0-989a-11f0-b877-0a192f7eb5c5"
}

******************************************************************
[2025-09-23 12:26:54.586] [Info] WebsiteURL: http://3.145.34.169
******************************************************************

[2025-09-23 12:26:54.587] [Info] Updating Cloudflare DNS record for monitoring site...
[2025-09-23 12:26:55.353] [Info] Updated Cloudflare DNS record for monitor.biffkittz.com to point to 3.145.34.169
[2025-09-23 12:26:55.354] [Info] Entering run loop for 5 minutes...
upload: ./backyard.jpg to s3://biffkittz-monitoring-data/backyard.jpg
upload: ./df-output.json to s3://biffkittz-monitoring-data/df-output.json
upload: ./backyard.jpg to s3://biffkittz-monitoring-data/backyard.jpg
upload: ./df-output.json to s3://biffkittz-monitoring-data/df-output.json
upload: ./backyard.jpg to s3://biffkittz-monitoring-data/backyard.jpg
upload: ./df-output.json to s3://biffkittz-monitoring-data/df-output.json
upload: ./backyard.jpg to s3://biffkittz-monitoring-data/backyard.jpg
upload: ./df-output.json to s3://biffkittz-monitoring-data/df-output.json
upload: ./backyard.jpg to s3://biffkittz-monitoring-data/backyard.jpg
upload: ./df-output.json to s3://biffkittz-monitoring-data/df-output.json
upload: ./backyard.jpg to s3://biffkittz-monitoring-data/backyard.jpg
upload: ./df-output.json to s3://biffkittz-monitoring-data/df-output.json
upload: ./backyard.jpg to s3://biffkittz-monitoring-data/backyard.jpg
upload: ./df-output.json to s3://biffkittz-monitoring-data/df-output.json
[2025-09-23 12:31:14.761] [Warning] Tearing down infra after running site for 5 minutes
[2025-09-23 12:31:14.761] [Info] Deleting CloudFormation stack...
[2025-09-23 12:31:15.619] [Info] Destroying S3 buckets...
[2025-09-23 12:31:15.620] [Info] Waiting for runspaces to complete with timeout of 30 seconds
[2025-09-23 12:31:17.547] [Info] Deleting monitor.biffkittz.com record from Cloudflare...
[2025-09-23 12:31:18.259] [Info] Teardown complete.
```
