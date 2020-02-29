# Converting local.settings.json to .env or the other way around

This repo contains a powershell script (.ps1) and module (.psm1) to convert Azure functions local.settings.json files to .env files, or the other way around.

You can either run the powershell script or use it as a module.

## Parameters

- `-FromEnv`: Set this to "yes" if you want to convert a .env file to a local.settings.json file. By default, it is set to "no"
- `-Path`: Set the path to the folder containing the file to convert. By default, it is the current directory

## Use as a module

1. In `C:\Program Files\WindowsPowerShell\Modules`, paste in the folder contained in this repo, with the .psm1 file inside
2. In a powershell window, run `Import-Module Convert-SettingsEnv` (you don't need to run it several times, just once per session)
3. Run the command `Convert-SettingsEnv`. You can pass in parameters if you'd like

## Run the script

1. Set the Execution Policy on your machine to RemoteSigned if you've never done it before: `Set-ExecutionPolicy RemoteSigned`
2. In the folder that contains the script, run `. .\convert-settings-env.ps1`. You can pass in parameters if you'd like




