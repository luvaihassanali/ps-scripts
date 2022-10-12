# Setup Azure DevOps pipelines to work with Dynamics 365 on-prem and cloud solutions

## Notes:
- Call DEV pipeline to export solutions from Dynamics (.zip files), use SolutionPackager to extract and push to source control, and publish .zip files for use in release pipelines
- Release pipeline import solutions into target environment
- Org. settings prevent server from executing PS module through DevOps Agent however it works locally so workaround is to launch separate powershell window (module-helper.ps1) and pipe output back to agent so output is displayed on web interface
- Get past MFA on azure user accounts by adding client secret to app registration created indirectly by portal initialization
- Release pipelines use release-task.ps1 to import solution into environments
- Edit word Template/template in template-pipeline-config.yml for appropriate project name/branch name
- Currently setup to manual but can be scheduled using cron:
```
schedules:
- cron: "0 0 * * *"
  displayName: Daily midnight build
  branches:
    include:
    - main
  always: true

trigger: none
pr: none
```
