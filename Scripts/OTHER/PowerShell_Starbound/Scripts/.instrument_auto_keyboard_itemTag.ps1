#   Script Name : patch_script.ps1
#
#   Developed By : Vijay Saini
#    Scripting Language : PowerShell
#
#   Date : 05 July 2018
#
#   Purpose : custom requirement
#
#   Author  : Vijay Saini
#
#   
cls
$mod_dir = "B:\WORKING_STARBOUND\Starbound_Tools_&_Docs\PowerShell_Starbound\patching"
#In case you want to specify it from the shell, use below command
#$mod_dir = Read-Host "Specify the mod directory"
$scan_obj_dir= "B:\WORKING_STARBOUND\Starbound_Tools_&_Docs\PowerShell_Starbound\patching\"

############################################################################
# Just Uncomment the below 2 lines if you want to generate 
# the scan_obj_dir variable at the run time using user-input

    #$tmp = [String](Read-Host "Please enter the mod name")
    #$scan_obj_dir = $mod_dir + "\" +$tmp
############################################################################

Get-ChildItem $scan_obj_dir -Recurse -Filter "*.instrument" | ForEach-Object {
  $tmp = $_.FullName -split "patching"
  $patch_file_name = $mod_dir  + $tmp[1] +".patch"
  $patch_file_name

  $tmp = [System.IO.DirectoryInfo] $patch_file_name
  $patch_file_dir = $tmp.Parent.FullName
      
       
  #Write the content into the file
       
  Write-Output '[[{"op":"test","path":"/itemTags","inverse":true},{"op":"add","path":"/itemTags","value":[]}],[{"op":"add","path":"/itemTags/-","value":"keyboard"}]]' | Out-File $patch_file_name -Encoding UTF8
  }