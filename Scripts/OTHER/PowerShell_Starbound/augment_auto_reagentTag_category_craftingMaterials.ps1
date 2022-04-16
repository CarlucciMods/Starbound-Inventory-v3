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
$mod_dir = "B:\Users\Richard\Desktop\rcarlucci1\starbound\mods"
#In case you want to specify it from the shell, use below command
#$mod_dir = Read-Host "Specify the mod directory"
$scan_obj_dir="B:\Users\Richard\Desktop\rcarlucci1\starbound\mods\"
$matched_content="category"

############################################################################
# Just Uncomment the below 2 lines if you want to generate 
# the scan_obj_dir variable at the run time using user-input

    #$tmp = [String](Read-Host "Please enter the mod name")
    #$scan_obj_dir = $mod_dir + "\" +$tmp
############################################################################

Get-ChildItem $scan_obj_dir -Recurse -Filter "*.augment" | ForEach-Object {
  $tmp = $_.FullName -split "items"
  $patch_file_name = $mod_dir + "\++carlucci_inventory++\items" + $tmp[1] +".patch"
  $patch_file_name

  $tmp = [System.IO.DirectoryInfo] $patch_file_name
  $patch_file_dir = $tmp.Parent.FullName
      
  Create the folder structure if not exisiting
  if(!(Test-Path  $patch_file_dir)){ New-Item -path $patch_file_dir -type directory }
       
  #Write the content into the file
       
  Write-Output '[[{"op":"test","path":"/itemTags","inverse":true},{"op":"add","path":"/itemTags","value":[]}],[{"op":"add","path":"/itemTags/-","value":"reagent"}],[{"op" : "replace","path" : "/category","value" :"craftingmaterial"}]]' | Out-File $patch_file_name -Encoding UTF8
  }