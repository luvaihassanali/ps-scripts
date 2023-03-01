Template files for Azure DevOps pipelines to export/import Dynamics 365 solutions on-premises and in the cloud (Power Apps). Pipeline can also migrate portal configuration for Power Apps Portals (Power Pages). These scripts were developed in a weird way because there was no access to Azure DevOps Power Apps extension and organizational policies on remote PowerShell execution prevented modules from loading.

Automatic trigger:
```
schedules:
- cron: "0 0 * * *"
  displayName: Daily midnight build
  branches:
    include:
    - main
  always: true
trigger: none
pr: none
```
