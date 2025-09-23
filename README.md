# PowerShell Demo
1. PowerShell runspaces for parallel ScriptBlock executions
2. Integrated with AWS CLI and AWS PowerShell modules
3. API calls made to Cloudflare using Invoke-RestMethod
4. Text to object creation, JSON serialization/deserialization

#### Example Script Output:

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

StackName           CreationTime         LastUpdatedTime Capabilities StackStatus     DisableRollback
---------           ------------         --------------- ------------ -----------     ---------------
temp-stack-216248a1 9/23/2025 4:26:12 PM                              CREATE_COMPLETE False

result   : @{id=e7cf7c6caa4ac5395a72ea8a6e8b56e8}
success  : True
errors   : {}
messages : {}

```
