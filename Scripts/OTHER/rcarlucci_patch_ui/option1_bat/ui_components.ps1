#ERASE ALL THIS AND PUT XAML BELOW between the @" "@
$inputXML = @'
<Window x:Class="WpfApplication4.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        xmlns:local="clr-namespace:WpfApplication4"
        mc:Ignorable="d"
        Title="Starbound Patch Tool" Height="412" Width="571">

    <Window.Background>
        <LinearGradientBrush EndPoint="0.5,1" StartPoint="0.5,0">
            <GradientStop Color="#FFAAB992" Offset="0.292"/>
            <GradientStop Color="#FFC5CEF0" Offset="0.778"/>
        </LinearGradientBrush>
    </Window.Background>

    <Grid>
        <Grid HorizontalAlignment="Left" Height="319" VerticalAlignment="Top" Width="517">
            <Label x:Name="label" Content="Home Directory" HorizontalAlignment="Left" Margin="52,44,0,0" VerticalAlignment="Top" Background="#FFB7CBC7"/>
            <Label x:Name="label1" Content="Mod Name" HorizontalAlignment="Left" Margin="52,93,0,0" VerticalAlignment="Top" Background="#FFB7CBC7"/>
            <Label x:Name="label2" Content="Search Mask" HorizontalAlignment="Left" Margin="52,152,0,0" VerticalAlignment="Top" Background="#FFB7CBC7"/>
            <TextBox x:Name="textBox" HorizontalAlignment="Left" Height="23" Margin="194,44,0,0" TextWrapping="Wrap" Text="C:\" VerticalAlignment="Top" Width="254" Background="#FFE4D6D6"/>
            <TextBox x:Name="textBox_Copy" HorizontalAlignment="Left" Height="23" Margin="194,97,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="120" Background="#FFE8CBCB"/>
            <Button x:Name="button" Content="Generate Patch" HorizontalAlignment="Left" Margin="79,275,0,0" VerticalAlignment="Top" Width="235" Height="25" Background="#FFDABABA"/>

            <ComboBox x:Name="comboBox" HorizontalAlignment="Left" Margin="194,156,0,0" VerticalAlignment="Top" Width="120">
                <ComboBoxItem IsSelected="True">.Object</ComboBoxItem>
                <ComboBoxItem>.category</ComboBoxItem>
                <ComboBoxItem>.custom</ComboBoxItem>
            </ComboBox>

        </Grid>

    </Grid>
</Window>

'@       
 
$inputXML = $inputXML -replace 'mc:Ignorable="d"','' -replace "x:N",'N'  -replace '^<Win.*', '<Window'
 
[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
[xml]$XAML = $inputXML
#Read XAML
 
    $reader=(New-Object System.Xml.XmlNodeReader $xaml)
  try{$Form=[Windows.Markup.XamlReader]::Load( $reader )}
    catch{Write-Host "Unable to load Windows.Markup.XamlReader. Double-check syntax and ensure .net is installed."}
 
#===========================================================================
# Store Form Objects In PowerShell
#===========================================================================
 
#$xaml.SelectNodes("//*[@Name]") | %{Set-Variable -Name "var_$($_.Name)" -Value $Form.FindName($_.Name) -Scope Global  }
$xaml.SelectNodes("//*[@Name]") | %{Set-Variable -Name "var_$($_.Name)" -Value $Form.FindName($_.Name) }
 

#--------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------


Function Get-FormVariables{
if ($global:ReadmeDisplay -ne $true){Write-host "If you need to reference this display again, run Get-FormVariables" -ForegroundColor Yellow;$global:ReadmeDisplay=$true}
write-host "Found the following interactable elements from our form" -ForegroundColor Cyan
get-variable var_*
}



$Form.ShowDialog() | out-null

#--------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------
