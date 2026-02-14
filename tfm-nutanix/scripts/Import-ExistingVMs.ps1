<#
.SYNOPSIS
    Import existing Nutanix VMs into Terraform state via Terragrunt.

.DESCRIPTION
    Reads the virtual_machines.yaml in the specified deployment directory,
    finds all entries with import_uuid set, and runs `terragrunt import`
    for each one.

    This is a FALLBACK method. The preferred approach is declarative import
    blocks in imports.tf which run automatically during `terragrunt apply`.
    Use this script only if the declarative approach encounters issues.

.PARAMETER DeploymentDir
    Path to the deployment directory (e.g., Deployments/cluster-01/virtual_machines)

.PARAMETER DryRun
    If set, only prints the import commands without executing them.

.EXAMPLE
    .\Import-ExistingVMs.ps1 -DeploymentDir ".\Deployments\cluster-01\virtual_machines"
    .\Import-ExistingVMs.ps1 -DeploymentDir ".\Deployments\cluster-01\virtual_machines" -DryRun
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$DeploymentDir,

    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------------
# Locate the virtual_machines.yaml
# ---------------------------------------------------------------------------
$yamlFile = Join-Path (Split-Path $DeploymentDir -Parent) "virtual_machines.yaml"
if (-not (Test-Path $yamlFile)) {
    Write-Error "Cannot find virtual_machines.yaml at: $yamlFile"
    exit 1
}

Write-Host "`n=== Nutanix VM Import Helper ===" -ForegroundColor Cyan
Write-Host "YAML source : $yamlFile"
Write-Host "Deployment  : $DeploymentDir"
Write-Host ""

# ---------------------------------------------------------------------------
# Parse YAML (requires powershell-yaml module or manual parsing)
# Fallback: use a simple regex-based parser for the specific structure
# ---------------------------------------------------------------------------
$content = Get-Content $yamlFile -Raw

# Extract VM blocks with import_uuid
$vmPattern = '(?s)-\s+name:\s*"([^"]+)".*?import_uuid:\s*"([^"]+)"'
$matches = [regex]::Matches($content, $vmPattern)

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

    $cmd = "terragrunt import '$resource' '$vmUuid'"

    if ($DryRun) {
        Write-Host "  [DRY RUN] $cmd" -ForegroundColor Yellow
    }
    else {
        Write-Host "  Running: $cmd" -ForegroundColor Cyan
        Push-Location $DeploymentDir
        try {
            & terragrunt import $resource $vmUuid
            if ($LASTEXITCODE -ne 0) {
                Write-Warning "Import failed for $vmName (exit code: $LASTEXITCODE)"
            }
            else {
                Write-Host "  SUCCESS: $vmName imported." -ForegroundColor Green
            }
        }
        finally {
            Pop-Location
        }
    }
}

Write-Host "`n=== Import complete ===" -ForegroundColor Cyan
Write-Host "Next steps:"
Write-Host "  1. Run 'terragrunt plan' to verify no drift"
Write-Host "  2. Adjust YAML values to match actual VM state if drift is detected"
Write-Host "  3. Once plan is clean, remove import_uuid values from YAML"
Write-Host ""
