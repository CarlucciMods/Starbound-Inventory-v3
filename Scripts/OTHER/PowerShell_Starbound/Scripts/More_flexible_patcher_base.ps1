#   Script Name : patch_script.ps1
#
#   Developed By : Vijay Saini
#      Scripting Language : PowerShell
#
#   Date : 05 July 2018
#
#   Purpose : custom requirement
#
#   Author  : Vijay Saini
#
#
cls
##makes a new folder.
##Starbound won't read this - intentionally.
##You'll need to copy them over to your mod folder.

$mod_dir = "C:\Users\1019080\Desktop\rcarlucci1\starbound\mods"
#$mod_dir = "C:\Games\Steam\steamapps\common\Starbound - Copy\mods"
$output_dir = $mod_dir + "\_script_output"
$fileFilter = "*.object"
#$scan_obj_dir= $mod_dir + "\betterblocks"

$targetType = 'category'
##What is getting replaced
$target_value = 'door'
$patched_value = 'Test_Value'
#$pattern = $targetType + ':' + $target_value ;

##Compact patch - loads faster
#$output_patch = '[{"op":"replace","path":"\' + $targetType + '","value":"' + $patched_value + '"}]'
##More readable patch - proper whitespace useage
$T = "    "
$output_patch = "[`n  {`n$T`"op`": `"replace`",`n$T`"path`": `"\$targetType`",`n$T`"value`": `"$patched_value`"`n  }`n]"


Get-ChildItem $mod_dir -Recurse -Filter $fileFilter | ForEach-Object{
  $fullName = $_.FullName
  #Pull the line containing "category" if it exists
  $contents = Get-Content -Path $fullName | Where-Object { $_.Contains('"category"') }
  ##relative path within mods
  $relative = $fullName.Replace("$mod_dir", '')
  ##get mod name after \mods\
    ##so it can be removed
    ##It could be added as a JSON comment if desired
  $mod_name = $relative.Split("\")[1]
  $output_relative = $relative.Replace("$mod_name\", '')
  $output_file_full = $output_dir + $output_relative + '.patch'
  $file_name = $output_file_full.Split("\")[-1]
  $destDir = $output_file_full.Replace("\$file_name", '')

  if($contents.Length -ge 1){  ##It must contain $targetType
    if(!($contents.Contains("$target_value"))){
      ##we will test the length, and if 0 then don't patch.
      $output_patch = ""
    }
  }
  else{  ##Did tnot contain $targetType so we'll add it
    $output_patch = $output_patch.Replace('"replace"', '"add"')
  }
  
  if($output_patch.Length -ge 1){
    if(!(Test-Path $destDir )){ New-Item -path $destDir -type directory }

    ##Write the content into the file
    $output_patch | Out-File $output_file_full -Encoding UTF8
    
    ##Converting the file to UTF8 NoBom
    #$MyText = Get-Content $patch_file_name ;
    #$Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False;
    #[System.IO.File]::WriteAllLines($patch_file_name,  $MyText, $Utf8NoBomEncoding);
  }
}