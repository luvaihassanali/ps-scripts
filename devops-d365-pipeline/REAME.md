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
