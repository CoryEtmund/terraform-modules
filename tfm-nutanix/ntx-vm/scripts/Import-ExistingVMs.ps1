<#
.SYNOPSIS
    Import existing Nutanix VMs into Terraform state.

.DESCRIPTION
    Reads terraform.tfvars, finds entries with import_uuid, and runs
    `terraform import` for each.  This is a FALLBACK method — the preferred
    approach is declarative import blocks (just run `terraform apply`).

.PARAMETER DryRun
    If set, prints the import commands without executing them.

.EXAMPLE
    .\scripts\Import-ExistingVMs.ps1
    .\scripts\Import-ExistingVMs.ps1 -DryRun
#>

param(
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$tfvarsFile = "terraform.tfvars"
if (-not (Test-Path $tfvarsFile)) {
    Write-Error "Cannot find $tfvarsFile in current directory. Run from tfm-nutanix/ root."
    exit 1
}

Write-Host "`n=== Nutanix VM Import Helper ===" -ForegroundColor Cyan
Write-Host "Config: $tfvarsFile`n"

$content  = Get-Content $tfvarsFile -Raw
$vmPattern = '(?s)name\s*=\s*"([^"]+)".*?import_uuid\s*=\s*"([^"]+)"'
$matches  = [regex]::Matches($content, $vmPattern)

if ($matches.Count -eq 0) {
    Write-Host "No VMs with import_uuid found. Nothing to import." -ForegroundColor Yellow
    exit 0
}

Write-Host "Found $($matches.Count) VM(s) to import:" -ForegroundColor Green

foreach ($match in $matches) {
    $vmName   = $match.Groups[1].Value
    $vmUuid   = $match.Groups[2].Value
    $resource = "nutanix_virtual_machine_v2.vm[`"$vmName`"]"

    Write-Host "`n  VM Name : $vmName" -ForegroundColor White
    Write-Host "  UUID    : $vmUuid" -ForegroundColor White
    Write-Host "  Address : $resource" -ForegroundColor White

    if ($DryRun) {
        Write-Host "  [DRY RUN] terraform import '$resource' '$vmUuid'" -ForegroundColor Yellow
    }
    else {
        Write-Host "  Running import..." -ForegroundColor Cyan
        try {
            & terraform import $resource $vmUuid
            if ($LASTEXITCODE -ne 0) {
                Write-Warning "Import failed for $vmName (exit code: $LASTEXITCODE)"
            }
            else {
                Write-Host "  SUCCESS" -ForegroundColor Green
            }
        }
        catch {
            Write-Warning "Import failed for $vmName : $_"
        }
    }
}

Write-Host "`n=== Import complete ($($matches.Count) VMs) ===" -ForegroundColor Cyan
Write-Host "`nNext steps:"
Write-Host "  1. terraform plan        - verify no drift"
Write-Host "  2. Adjust tfvars values if drift is detected"
Write-Host "  3. Remove import_uuid from tfvars once plan is clean`n"
