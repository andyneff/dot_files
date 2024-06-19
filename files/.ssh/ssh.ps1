$ArgArray = [System.Collections.ArrayList]$Args
$ind = $ArgArray.IndexOf("-F")
if ($ind -ge 0) {
  $ArgArray.RemoveAt($ind)
  $ArgArray.RemoveAt($ind)
}
for($i=0; $i -lt $ArgArray.Count; $i++)
{
  if (([string]$ArgArray[$i]).StartsWith("vscode.plink."))
  {
    $ArgArray[$i] = $ArgArray[$i].SubString(13)
  }
}
Write-Host $ArgArray
& "$HOME\bin\hpc\plink.exe" $ArgArray