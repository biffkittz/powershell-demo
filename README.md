# PowerShell Demo Features
1. PowerShell runspaces for parallel ScriptBlock executions
2. Runspace progress report output during background execution
3. AWS CLI and AWS PowerShell module integration
4. Cloudflare API integration using Invoke-RestMethod for DNS record manipulation
5. Text to object creation, JSON serialization/deserialization
6. Bash script execution from PowerShell
7. Logging and error handling

#### Prerequisites
1. Configured AWS credentials that permit S3 and EC2 operations
2. Cloudflare credential and ZoneId for DNS management (optional)
3. AWS CLI and AWSPowerShell.NetCore module
4. fswebcam utlity for command-line webcam capturing (and a physical webcam from which to capture)

#### Example invocation
Tested using PowerShell 7.5.3 on Debian 12
```
PS> ./run-temp-monitoring-site.ps1 -CloudflareToken <token> -CloudflareZoneId <zone_id>
```

#### Live Site
<img src="https://github.com/biffkittz/powershell-demo/blob/main/monitor.png" width="300" height="500">

#### Example Script Output

```
PS /home/user/powershell> ./run-temp-monitoring-site.ps1 -CloudflareToken <token> -CloudflareZoneId <zoneId>
[2025-09-25 09:36:26.401] [Info] Imported module AWSPowerShell.NetCore
[2025-09-25 09:36:26.455] [Info] Waiting for runspaces to complete with timeout of 30 seconds
{
    "StackId": "arn:aws:cloudformation:us-east-2:670833622677:stack/temp-stack-19358a09/a54b8a20-9a14-11f0-aa1b-06d43d302d75"
}

**************************************************
[2025-09-25 09:37:22.267] [Info] WebsiteURL: http://3.14.249.194
**************************************************
[2025-09-25 09:37:22.267] [Info] Updating Cloudflare DNS record for monitoring site...
[2025-09-25 09:37:22.975] [Info] Updated Cloudflare DNS record for monitor.biffkittz.com to point to 3.14.249.194
[2025-09-25 09:37:22.975] [Info] Entering run loop for 5 minutes...
upload: ./backyard.jpg to s3://biffkittz-monitoring-data/backyard.jpg
upload: ./df-output.json to s3://biffkittz-monitoring-data/df-output.json
[2025-09-25 09:37:25.295] [Info] Waiting for runspaces to complete with timeout of 15 seconds
[2025-09-25 09:37:26.322] [Info] Running average CPU calculation...
[2025-09-25 09:37:27.351] [Info] Running average CPU calculation...
[2025-09-25 09:37:28.381] [Info] Running average CPU calculation...
[2025-09-25 09:37:29.410] [Info] Running average CPU calculation...
[2025-09-25 09:37:30.438] [Info] Running average CPU calculation...
[2025-09-25 09:37:31.471] [Info] Running average CPU calculation...
[2025-09-25 09:37:32.500] [Info] Average idle: 84.82%, Average usage: 15.18%
[2025-09-25 09:37:33.529] [Info] Average idle: 84.82%, Average usage: 15.18%
upload: ./cpu-statistics.txt to s3://biffkittz-monitoring-data/cpu-statistics.txt
upload: ./backyard.jpg to s3://biffkittz-monitoring-data/backyard.jpg
upload: ./df-output.json to s3://biffkittz-monitoring-data/df-output.json
[2025-09-25 09:37:52.247] [Info] Waiting for runspaces to complete with timeout of 15 seconds
[2025-09-25 09:37:53.274] [Info] Running average CPU calculation...
[2025-09-25 09:37:54.302] [Info] Running average CPU calculation...
[2025-09-25 09:37:55.331] [Info] Running average CPU calculation...
[2025-09-25 09:37:56.363] [Info] Running average CPU calculation...
[2025-09-25 09:37:57.394] [Info] Running average CPU calculation...
[2025-09-25 09:37:58.427] [Info] Running average CPU calculation...
[2025-09-25 09:37:59.458] [Info] Average idle: 90.24%, Average usage: 9.76%
[2025-09-25 09:38:00.490] [Info] Average idle: 90.24%, Average usage: 9.76%
upload: ./cpu-statistics.txt to s3://biffkittz-monitoring-data/cpu-statistics.txt
upload: ./backyard.jpg to s3://biffkittz-monitoring-data/backyard.jpg
upload: ./df-output.json to s3://biffkittz-monitoring-data/df-output.json
[2025-09-25 09:38:19.528] [Info] Waiting for runspaces to complete with timeout of 15 seconds
[2025-09-25 09:38:20.554] [Info] Running average CPU calculation...
^C[2025-09-25 09:38:20.795] [Warning] Tearing down infra after running site for 5 minutes
[2025-09-25 09:38:20.795] [Info] Deleting CloudFormation stack...
[2025-09-25 09:38:21.729] [Info] Destroying S3 buckets...
[2025-09-25 09:38:21.738] [Info] Waiting for runspaces to complete with timeout of 30 seconds
[2025-09-25 09:38:23.770] [Info] Deleting monitor.biffkittz.com record from Cloudflare...
[2025-09-25 09:38:24.149] [Info] Teardown complete.

```
