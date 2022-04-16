#!/usr/bin/pwsh

#
#   Script Name : inv_patch_gen.ps1
#

#
#   Script by Lyrthras#7199, 09 July 21 13:20 UTC+8
#


### ###     Configuration     ### ###

# Whether to produce compact json
# `$False` - nicely-printed json; `$True` - compact one-line
# Set to `$True` to reduce total size by ~25%
$compact = $False

# If modDir below is empty or unspecified, would ask the user instead.
$modDir = ""

# Debug output (complain on unrecognized extension)
$debug = $False

# Don't show progress if $true, might be faster? (probably not)
$silent = $False

### ###     ---     ### ###




### ###     Mappings     ### ###

# Search in these directories within the mod for items.
# Don't add everything if they don't contain items, it might probably slow stuff down
$searchIn = @(
    "codex",
    "items",
    "objects"
	"liquid"
)

# List of file extensions that the script shouldn't complain about. (exists solely for debugging)
$ignored = @(
    ".png", ".jpg", ".gif", ".bmp", ".tif",         # Images
    ".ase", ".aseprite", ".gpl", ".psd", ".pdn"     # Sprite programs
    ".ogg", ".wav", ".aac", ".mp4", ".mp3",         # Sound
    ".frames", ".config", ".animation", ".bak",     # Starbound common
    ".lua", ".patch", ".weaponability",
    ".weaponcolors", ".combofinisher",
    ".objectdisabled", ".disabled",
    ".txt", ".db", ".ini", ".bat", ".cmd", ".sh"    # Other
)

# What bag should an item belong based on the extension.
# Value is either a bagType string, or a ScriptBlock accepting the file path and returning the bagType string.
#   ScriptBlocks here are useful for checking the contents of the file instead, to determine where they belong.
# NOTE: Cast JSON arrays first from -AsHashtable. Like [string[]]($yourJsonData)
$bags = @{
    ".chest" = "armorBag"
    ".legs" = "armorBag"
    ".back" = "armorBag"
    ".head" = "armorBag"

    ".flashlight" = "toolBag"
    ".miningtool" = "toolBag"          # drills and pickaxes
    ".harvestingtool" = "toolBag"
    ".inspectiontool" = "toolBag"
    ".painttool" = "toolBag"
    ".tillingtool" = "toolBag"
    ".wiretool" = "toolBag"
    ".beamaxe" = "toolBag"

    ".currency" = "moneyBag"
    ".codex" = "hobbyBag"
    ".instrument" = "hobbyBag"
    ".augment" = "augmentsBag"     # augments, collars, dyes

    ".unlock" = "vehicleBag"          # repairs and ship upgrades

    ".liquid" = "liquidBag"
    ".liqitem" = "liquidBag"
    ".liquid" = "liquidBag"
    ".matitem" = { param($f);
        $json = Get-Content -Raw -Path $f | ConvertFrom-Json -AsHashtable
        # platforms, rails, blocks

        switch -Wildcard ($json.category) {
            "platform"  { return "objectBag" }
            "rail"      { return "transportBag" }
        }
        return "materialBag"
    }

    ".consumable" = { param($f);
        $json = Get-Content -Raw -Path $f | ConvertFrom-Json -AsHashtable
        # food, stim, medicine

        switch -Wildcard ($json.category) {
            "preparedFood"  { return "foodBag" }
            "food"          { return "foodBag" }
            "drink"         { return "foodBag" }
            "medicine"      { return "medsBag" }
        }

        # for modded stuff that messes with categories
        switch -Wildcard ([string[]]($json.blockingEffects)) {
            "*heal"     { return "medsBag" }
            "antidote"  { return "medsBag" }
        }
    }

    ".thrownitem" = { param($f);
        $json = Get-Content -Raw -Path $f | ConvertFrom-Json -AsHashtable
        # throwables, also pet pods (empty)

        if ((([string[]]($json.radioMessagesOnPickup)).count -gt 0) -and ([string[]]($json.radioMessagesOnPickup)).Contains("pickupcapturepod")) {
            return "farmBag"        # ???, 'farmBag' says it's for pets
        } elseif ($json.itemName -match "capturepod") {
            return "farmBag"
        } else {
            return "throwBag"
        }
    }

    ".item" = { param($f);
        $json = Get-Content -Raw -Path $f | ConvertFrom-Json -AsHashtable
        # crafting material, mech parts, ore, foodstuff (inedible),
        #   dubloon, voxels, fossils, licenses, trading card

        switch -Wildcard ($json.category) {
            "craftingMaterial"  { return "reagentBag" }
            "salvageComponent"  { return "vehicleBag" }
            "shipLicense"       { return "vehicleBag" }
            "mechPart"          { return "vehicleBag" }
            "fuel"              { return "vehicleBag" }
            "*Fossil"           { return "objectBag2" }
            "currency"          { return "moneyBag"   }
            "cookingIngredient" { return "foodBag"    }
            "foodJunk"          { return "foodBag"    }     # Same bag? (rotten food)
            "upgradeComponent"  { return "mainBag"    }     # ??? (upgrades)
            "tradingCard"       { return "mainBag"    }
            "tradeGoods"        { return "mainBag"    }
            "trophy"            { return "mainBag"    }     # ??? (monsterclaw) (and doubt they're placeable)
            "quest"             { return "mainBag"    }
            "junk"              {
                if ($json.itemName -match "platinum|plutonium") {
                    return "reagentBag"
                } else {
                    return "mainBag"
                }
            }
        }

        # fallback, check if itemTags contains X (switch on array)
        # order matters, top to bottom priority
        switch ([string[]]($json.itemTags)) {
            "salvage"   { return "vehicleBag" }
            "fossil"    { return "objectBag2" }
            "reagent"   { return "reagentBag" }
        }
    }

    ".activeitem" = {
        param($f);
        $json = Get-Content -Raw -Path $f | ConvertFrom-Json -AsHashtable
        # !!! weapons, shields, tools (fossil brush, net, tools,
        #       vehic controllers, pods, mech blueprints?

        if ($json.itemName -match "capturepod") { return "farmBag" }
        if ($json.itemName -match "stationtransponder") { return "deviceBag" }
        if ($json.itemName -match "mechblueprint") { return "vehicleBag" }

        switch -Wildcard ($json.category) {
            "railPlatform"      { return "transportBag" }
            "vehicleController" { return "vehicleBag"   }
            "throwableItem"     { return "throwBag"     }
            "fishingRod"        { return "toolBag"      }
            "tool"              { return "toolBag"      }   # watering cans, rail hooks still go in here
            "mysteriousReward"  { return "mainBag"      }   # ??? (reward bags)
            "drone"             { return "mainBag"      }
            "quest"             { return "mainBag"      }

            "shield"            { return "armoryBag"    }   # ??? armory and not armor?

            "grenadeLauncher"   { return "armoryBag"    }
            "rocketLauncher"    { return "armoryBag"    }
            "machinePistol"     { return "armoryBag"    }
            "assaultRifle"      { return "armoryBag"    }
            "uniqueWeapon"      { return "armoryBag"    }
            "sniperRifle"       { return "armoryBag"    }
            "broadsword"        { return "armoryBag"    }
            "fistWeapon"        { return "armoryBag"    }
            "shortsword"        { return "armoryBag"    }
            "boomerang"         { return "armoryBag"    }
            "chakram"           { return "armoryBag"    }
            "shotgun"           { return "armoryBag"    }
            "dagger"            { return "armoryBag"    }
            "hammer"            { return "armoryBag"    }
            "pistol"            { return "armoryBag"    }
            "spear"             { return "armoryBag"    }
            "staff"             { return "armoryBag"    }
            "wand"              { return "armoryBag"    }
            "whip"              { return "armoryBag"    }
            "axe"               { return "armoryBag"    }
            "bow"               { return "armoryBag"    }
            "toy"               { return "armoryBag"    }
        }

        # fallback
        switch ([string[]]($json.itemTags)) {
            "shield"            { return "armoryBag"    }   # ??? armory and not armor?
            "weapon"            { return "armoryBag"    }
            "vehicleController" { return "vehicleBag"   }

        }
    }

    ".object" = { param($f);
        $json = Get-Content -Raw -Path $f | ConvertFrom-Json -AsHashtable
        # !!! all sorts of stuff

        ## objectBag2 - decorative, non-functional stuff
        ## objectBag  - functional, crafting, interactable etc

        switch -Wildcard ($json.category)
        {
            "teleportMarker"{ return "transportBag" }
            "teleporter"    { return "transportBag" }
            "railPoint"     { return "transportBag" }
            "light"         { return "lightingBag"  }
            "wire"          { return "lightingBag"  }       # !!! Wire one with lighting, or power? (power is unused for anything)
            "fridgeStorage" { return "storageBag"   }
            "storage"       { return "storageBag"   }
            "actionFigure"  { return "objectBag2"   }
            "decorative"    { return "objectBag2"   }
            "breakable"     { return "objectBag2"   }
            "artifact"      { return "objectBag2"   }
            "generic"       { return "objectBag2"   }
            "bug"           { return "objectBag2"   }
            "shippingContainer" { return "objectBag"    }
            "techManagement"{ return "objectBag"    }
            "playerstation" { return "objectBag"    }
            "terraformer"   { return "objectBag"    }
            "furniture"     { return "objectBag"    }
            "crafting"      { return "objectBag"    }
            "spawner"       { return "objectBag"    }
            "genboss"       { return "objectBag"    }       # also traps too
            "other"         { return "objectBag"    }       # Mostly shops. Do they belong here?
            "door"          { return "objectBag"    }
            "trap"          { return "objectBag"    }
            "farmBeastEgg"  { return "farmBag"      }
            "sapling"       { return "farmBag"      }
            "seed"          { return "farmBag"      }

        }

        switch ([string[]]($json.itemTags)) {
            "newfuelhatch"  { return "storageBag"   }
        }

        # Determine functionality whether it has a script or not TODO also check ui presence
        if (([string[]]$n).count -eq 0) {   # check if doesn't exist or empty
            # No script
            return "objectBag2"
        } else {
            # Has script
            return "objectBag"
        }
    }
}

### ###     ---     ### ###




### ###     Internal     ### ###

# progress color
$host.privatedata.ProgressBackgroundColor = "darkgray";

# Check JSON+comments support
#   I made this thingy myself (Lyrthras#7199) lol, for compatibility with old powershell versions
try {
    ## PS >= 6.0 ## Powershell Core ##
    ConvertFrom-Json -AsHashtable '{"A":"bb//bb"/*comment*/,"123":["a","#b","dd/*ee*//\"//e/*g*/"],"e":1}//y"e"s' | Out-Null
} catch {
    # try running pwsh instead if it exists
    if (Get-Command "pwsh" -ErrorAction SilentlyContinue) {
        pwsh $PSCommandPath
        exit
    } else {
        ## PS < 6.0 ## Windows Powershell ##
        Write-Host "> Powershell Core ( >= 6.0 ) not found."
        Write-Host "  Will fall back to using JSON workarounds (slower and more prone to break)"

        if (Get-Command "ConvertFrom-Json" -errorAction SilentlyContinue) {
            ## PS [3.0, 5.1] ## Windows Powershell 3.0+ ##
            New-Alias -Name 'ConvertFrom-Json' -Value 'ConvertFrom-Json3' -Scope Global
            Write-Host "  (Using comment-removal method)"
        } else {
            ## PS < 3.0 ## Windows Powershell 2- ##
            New-Alias -Name 'ConvertFrom-Json' -Value 'ConvertFrom-Json2' -Scope Global
            Write-Host "  (Using JSSerializer (from .NET 3.5+, expect failure if that doesn't exist))"
        }
    }
}

function ConvertFrom-JsonFor3 {
    param(
        [Parameter(ValueFromPipeline=$true)]$InputObject,
        [Switch]$AsHashtable
    )

    # regex for stripping comments away from SB's json
    #   ( https://stackoverflow.com/a/65740485 )
    # full path : since we need the original cmdlet
    $json = ($InputObject -replace '("(\\.|[^\\"])*")|/\*[\S\s]*?\*/|//.*', '$1') | Microsoft.PowerShell.Utility\ConvertFrom-Json
    return $json
}

function ConvertFrom-JsonFor2 {
    param(
        [Parameter(ValueFromPipeline=$true)]$InputObject,
        [Switch]$AsHashtable
    )

    # use .net 3.5+ library
    #   ( https://stackoverflow.com/a/17602226 )
    [System.Reflection.Assembly]::LoadWithPartialName("System.Web.Extensions")
    $str = $InputObject -replace '("(\\.|[^\\"])*")|/\*[\S\s]*?\*/|//.*', '$1'
    $ser = New-Object System.Web.Script.Serialization.JavaScriptSerializer

    return $ser.DeserializeObject($str)
}

### ###     ---     ### ###




### ###     Functions     ### ###

function New-Patch($bagType) {
    return @"
[
  [
    { "op": "test", "path": "/itemTags", "inverse": true },
    { "op": "add", "path": "/itemTags", "value": [] }
  ],
  [
    { "op": "add", "path": "/itemTags/-", "value": "$bagType" }
  ]
]
"@
}

function New-CompactPatch($bagType) {
    return @"
[[{"op":"test","path":"/itemTags","inverse":true},{"op":"add","path":"/itemTags","value":[]}],[{"op":"add","path":"/itemTags/-","value":"$bagType"}]]
"@
}

# modDir - path to mod folder to do patches on
# itemsDir - folder name within the mod, e.g. "codex", "objects", "items/active"
# outDir - place to put the patched stuff, root
function Write-Patches($modDir, $itemsDir, $outDir) {
    Write-Host "> Listing files for '$itemsDir'."
    if (! (Test-Path (Join-Path $modDir $itemsDir))) {
        Write-Host "> No $itemsDir directory, skipping."
        return
    }

    $files = (Get-ChildItem (Join-Path $modDir $itemsDir) -Recurse -File)

    Push-Location $modDir

    # Progress stuff
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $filecount = $files.Length
    $progress = 0
    $patches = 0

    $files | ForEach-Object {
        $progress++

        if (! $bags.ContainsKey($_.Extension)) {
            if ((! $ignored.Contains($_.Extension)) -and $debug) {
                Write-Warning ("Unrecognized extension " + $_.Extension + " from $_")
            }
            return      # Not 'continue', this is a ForEach-Object, not a foreach
        }

        # Translate mod directory path to output dir path
        $srcRelative = (Resolve-Path -Relative $_)
        $dest = [System.IO.DirectoryInfo](Join-Path $outDir $srcRelative)
        $patchName = [System.IO.DirectoryInfo]($dest.FullName + ".patch")
        $patchDir = $dest.Parent.FullName

        #Create destination folder structure if not existing
        if (! (Test-Path $patchDir)) { New-Item -path $patchDir -type directory | Out-Null }

        $bagType = $bags[$_.Extension]

        if ($bagType -is [String]) {}   # we're good
        elseif ($bagType -is [ScriptBlock]) {
            # run the ScriptBlock to get the actual bagType string
            $bagType = (&$bagType $_)
            if (! $bagType) {
                Write-Warning "!> Unhandled case for file $srcRelative"
            }
        } else {
            Write-Error ("!> (Script) Invalid value type for " + $_.Extension)
            return
        }


        if ($compact) {
            New-CompactPatch $bagType | Out-File $patchName
        } else {
            New-Patch $bagType | Out-File $patchName
        }

        $patches++

        if ((! $silent) -and ($sw.Elapsed.TotalMilliseconds -ge 330)) {
            Write-Progress -Activity "File: $srcRelative" -Status "File ($progress/$filecount)" -CurrentOperation $patchName.Name -PercentComplete (($progress/$filecount)*100)
            $sw.Reset(); $sw.Start()
        }
    }
    Write-Progress -Activity "Done." -Completed
    Write-Host ">>> Processed $patches patches for directory '$itemsDir'."

    Pop-Location
}

### ###     ---     ### ###




Clear-Host

# Ask
if (! $modDir) {
    $modDir = (Read-Host "Specify the mod directory")
}

$searchIn | ForEach-Object { Write-Patches $modDir $_ ($modDir+"_patches") }


Read-Host "Done. Press enter to exit." | Out-Null 
