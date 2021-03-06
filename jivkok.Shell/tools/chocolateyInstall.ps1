$package = 'jivkok.Shell'

function Get-CurrentDirectory
{
  $thisName = $MyInvocation.MyCommand.Name
  [IO.Path]::GetDirectoryName((Get-Content function:$thisName).File)
}

function New-Shortcut($ShortcutPath, $TargetPath, $Arguments, $IconLocation)
{
    $WshShell = New-Object -comObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($ShortcutPath)
    $Shortcut.TargetPath = $TargetPath
    $Shortcut.Arguments = $Arguments
    $Shortcut.IconLocation = $IconLocation
    $Shortcut.Save()
}

try {
  $currentPath = Get-CurrentDirectory

  $destPath = "$Home\.shell"
  if (!(Test-Path $destPath))
  {
    New-Item $destPath -Type Directory | Out-Null
  }

  # Copy files
  'Console.xml',
  'SetEnv.cmd',
  'SetPosh.ps1' |
    % {
      $params = @{
        Path = Join-Path $currentPath $_;
        Destination = Join-Path $destPath $_;
        Force = $true
      }
      Copy-Item @params
    }

  New-Shortcut "$Home\Desktop\JConsole.lnk" "$Env:ChocolateyInstall\bin\Console.exe" "-c $Home\.shell\console.xml" "cmd.exe,0"

  # BoxStarter
  Import-Module (Join-Path $currentPath BoxStarter.psm1)
  Disable-ShutdownTracker
  Disable-InternetExplorerESC
  Set-ExplorerOptions -showHidenFilesFoldersDrives $true -showProtectedOSFiles $true -showFileExtensions $true
  Enable-RemoteDesktop
  # Set-TaskbarSmall
  # Restart-Explorer

  [Environment]::SetEnvironmentVariable("_NT_SYMBOL_PATH", "srv*C:\Symbols*http://referencesource.microsoft.com/symbols*http://srv.symbolsource.org/pdb/Public*http://msdl.microsoft.com/download/symbols", "User")

  Write-ChocolateySuccess $package
} catch {
  Write-ChocolateyFailure $package "$($_.Exception.Message)"
  throw
}
