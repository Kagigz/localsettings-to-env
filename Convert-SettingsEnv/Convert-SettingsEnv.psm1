Param(
    [Parameter(Position=0, Mandatory=$False, HelpMessage="Set to 'no' (default) if you want to convert a local.settings.json file into a .env file, set to 'yes' if you want to do the opposite.")]
    [string]$FromEnv,
    [Parameter(Position=1, Mandatory=$False, HelpMessage="Path of the folder containing the file to convert (default: current folder)")]
    [string]$Path
    )

function Convert-SettingsEnv {

    <#
        .Synopsis
        Convert local.settings.json file to .env file and the other way around
        .Description
        This command will convert the local.settings.json file in the same folder to a .env file, and do the reverse action if specified.
        .Parameter FromEnv
        Set to yes if you want an .env file to be converted into a local.settings.json file.
        .Parameter Path
        The path of the folder containing the file to convert.
    #>
        
    Try {

        $reverse = "no"

        if($FromEnv -ne '') {
            $reverse = $FromEnv
        }

        $path_create = '.'
        $path_read = '.'
        if($Path -ne '') {
            $path_create = $Path
            $path_read = $Path
        }
        $path_create += '\'
        $path_read += '\'

        if($reverse -eq 'no') {
            Write-Host "Converting local.settings.json to .env..."
            $path_create += '.env'
            $path_read += 'local.settings.json'
        }
        else {
            Write-Host "Converting .env to local.settings.json..."
            $path_create += 'local.settings.json'
            $path_read += '.env'
        }

        $text = Get-Content -Path $path_read
        
        if($reverse -eq 'no') {

            $text = $text.Replace(' ','')
            $text = $text.Replace("`n",'')
            $text = $text.Replace("`t",'')
            $text = $text.Replace('{','')
            $text = $text.Replace('}','')
            $text = $text.Replace('"IsEncrypted":false,', '')
            $text = $text.Replace('"Values":', '')
            $text = $text.Replace('":','=')

            $lines = ''
            foreach($line in $text) {
                if($line -ne '') {
                    if($line[0] -eq '"') {
                        $line = $line.Substring(1,$line.length-1)
                    }
                    if($line[$line.length-1] -eq ',') {
                        $line = $line.Substring(0,$line.length-1)
                    }
                    $lines += $line
                    $lines += "`n"
                }
            }

        }
        else {

            $lines = "{`n`t`"IsEncrypted`": false,`n`t`"Values`": {`n"
            foreach($line in $text) {
                if($line -ne '') {
                    $stringarray = $line.Split('=')
                    $new_line = '"' + $stringarray[0] + '": '
                    foreach($substring in $stringarray[1..($stringarray.length)]) {
                        $new_line += $substring
                        $new_line += '='
                    }
                    $new_line = "`t`t" + $new_line.Substring(0,$new_line.length-1)
                    $new_line += ","
                    $lines += $new_line
                    $lines += "`n"
                }
            }
            $lines = $lines.Substring(0,$lines.length-2)
            $lines += "`n`t}`n}"

        }


        New-Item -Path $path_create -ItemType 'file' -Value $lines -Force
        Write-Host "Converted file."
    
    }
    Catch {
        Write-Warning "Could not convert file."
        Write-Warning $_.Exception.Message
    }

}

Export-ModuleMember -Function Convert-SettingsEnv