#   Script Name : patch_script.ps1
#
#   Developed By : Vijay Saini
#  	Scripting Language : PowerShell
#
#   Date : 05 July 2018
#
#   Purpose : custom requirement
#
#   Author  : Vijay Saini

#+ "\betterblocks"
#   
cls
$mod_dir = "B:\Users\Richard\Desktop\patch_script_starbound\starbound\mods"
$scan_obj_dir= $mod_dir 

$target_category = "STORAGE"  #This is getting replaced with patched category
$patched_category = "PATCHED_CAT" 


$pattern = '"Category"' + ":" + '"' + $target_category +'"';

Get-ChildItem $scan_obj_dir -Recurse -File | Where-Object {Select-String -Path $_ -Pattern $pattern } | ForEach-Object{
      $tmp = $_.FullName -split "objects"
      $patch_file_name = $mod_dir + "\++carlucci_inventory++\objects" + $tmp[1] +".patch"
      
      $tmp = [System.IO.DirectoryInfo] $patch_file_name
      $patch_file_dir = $tmp.Parent.FullName
      
      #Create the folder structure if not exisiting
      if(!(Test-Path  $patch_file_dir)){ New-Item -path $patch_file_dir -type directory }
       
       #Write the content into the file
       Write-Output "[" | Out-File $patch_file_name 
         Write-Output " " | Out-File $patch_file_name -Append 
         Write-Output "  {" | Out-File $patch_file_name -Append 
         
         $matched_content = Get-Content $_.FullName | Where-Object {$_ -like "*category*"} 

                if($matched_content.Length -ge 1){  Write-Output '    "op": "replace",' | Out-File $patch_file_name -Append  } 
                else {  Write-Output '    "op": "add",' | Out-File $patch_file_name -Append   }
            Write-Output '    "path": "/category",' | Out-File $patch_file_name -Append 
                $str = '    "value"' + ': [ "' +$patched_category +'" ]'
            Write-Output $str | Out-File $patch_file_name -Append
         Write-Output "  }" | Out-File $patch_file_name -Append 
         Write-Output " " | Out-File $patch_file_name -Append 
         Write-Output "]" | Out-File $patch_file_name  -Append 
         
         
             
 #Converting the file to UTF8 NoBom   
 $MyText = Get-Content $patch_file_name ;
	$Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False;
	[System.IO.File]::WriteAllLines($patch_file_name ,	$MyText,	$Utf8NoBomEncoding);
   } 