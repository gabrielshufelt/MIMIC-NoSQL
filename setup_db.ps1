# MIMIC-III Database Setup Script (Windows PowerShell)
# This script automates Phase 1 of the database setup

$ErrorActionPreference = "Stop"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "MIMIC-III Database Setup Script" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Download MIMIC-III dataset
Write-Host "Step 1: Checking for MIMIC-III dataset..." -ForegroundColor Yellow
$MimicPath = "$env:USERPROFILE\Downloads\mimic-iii"

if (Test-Path $MimicPath) {
    Write-Host "✓ MIMIC-III dataset already exists at $MimicPath" -ForegroundColor Green
} else {
    Write-Host "MIMIC-III dataset not found. Please download it manually from:" -ForegroundColor Red
    Write-Host "https://www.kaggle.com/datasets/bilal1907/mimic-iii-10k" -ForegroundColor White
    Write-Host ""
    Write-Host "Extract the zip file to: $MimicPath" -ForegroundColor White
    Write-Host "Make sure the root folder is named 'mimic-iii'" -ForegroundColor White
    Write-Host ""
    $continue = Read-Host "Press Enter once you've completed the download and extraction"

    if (-not (Test-Path $MimicPath)) {
        Write-Host "Error: Dataset not found at $MimicPath" -ForegroundColor Red
        exit 1
    }
}
Write-Host ""

# Step 2: Check for PostgreSQL
Write-Host "Step 2: Checking for PostgreSQL..." -ForegroundColor Yellow
$psqlPath = Get-Command psql -ErrorAction SilentlyContinue

if ($psqlPath) {
    Write-Host "✓ PostgreSQL is already installed" -ForegroundColor Green
    & psql --version
} else {
    Write-Host "PostgreSQL not found. Please install it manually from:" -ForegroundColor Red
    Write-Host "https://www.postgresql.org/download/windows/" -ForegroundColor White
    Write-Host ""
    Write-Host "During installation:" -ForegroundColor Yellow
    Write-Host "  - Set password for 'postgres' user to 'postgres'" -ForegroundColor White
    Write-Host "  - Make sure to add PostgreSQL bin directory to PATH" -ForegroundColor White
    Write-Host ""
    $continue = Read-Host "Press Enter once PostgreSQL is installed"

    # Refresh PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

    $psqlPath = Get-Command psql -ErrorAction SilentlyContinue
    if (-not $psqlPath) {
        Write-Host "Error: psql command not found. Make sure PostgreSQL bin directory is in PATH" -ForegroundColor Red
        exit 1
    }
}
Write-Host ""

# Step 3: Check for Python
Write-Host "Step 3: Checking for Python..." -ForegroundColor Yellow
$pythonPath = Get-Command python -ErrorAction SilentlyContinue

if ($pythonPath) {
    Write-Host "✓ Python is already installed" -ForegroundColor Green
    & python --version
} else {
    Write-Host "Python not found. Please install it manually from:" -ForegroundColor Red
    Write-Host "https://www.python.org/downloads/" -ForegroundColor White
    Write-Host ""
    Write-Host "During installation, make sure to check 'Add Python to PATH'" -ForegroundColor Yellow
    Write-Host ""
    $continue = Read-Host "Press Enter once Python is installed"

    # Refresh PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

    $pythonPath = Get-Command python -ErrorAction SilentlyContinue
    if (-not $pythonPath) {
        Write-Host "Error: python command not found. Make sure Python is in PATH" -ForegroundColor Red
        exit 1
    }
}
Write-Host ""

# Step 4: Install Python dependencies
Write-Host "Step 4: Installing Python dependencies..." -ForegroundColor Yellow
& python -m pip install --upgrade pip
& python -m pip install pandas sqlalchemy psycopg2-binary pymongo
Write-Host "✓ Python dependencies installed" -ForegroundColor Green
Write-Host ""

# Step 5: Create database
Write-Host "Step 5: Creating 'mimic' database..." -ForegroundColor Yellow
$env:PGPASSWORD = "postgres"

# Check if database exists
$dbExists = & psql -U postgres -lqt | Select-String -Pattern "\bmimic\b" -Quiet

if ($dbExists) {
    Write-Host "Database 'mimic' already exists." -ForegroundColor Yellow
    $recreate = Read-Host "Do you want to drop and recreate it? (y/n)"

    if ($recreate -eq "y" -or $recreate -eq "Y") {
        & dropdb -U postgres mimic
        & createdb -U postgres mimic
        Write-Host "✓ Database recreated" -ForegroundColor Green
    } else {
        Write-Host "Using existing database" -ForegroundColor Green
    }
} else {
    & createdb -U postgres mimic
    Write-Host "✓ Database created" -ForegroundColor Green
}
Write-Host ""

# Step 6: Apply schema
Write-Host "Step 6: Applying schema to database..." -ForegroundColor Yellow
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SchemaPath = Join-Path $ScriptDir "schema.sql"

if (-not (Test-Path $SchemaPath)) {
    Write-Host "Error: schema.sql not found at $SchemaPath" -ForegroundColor Red
    exit 1
}

Get-Content $SchemaPath | & psql -U postgres mimic
Write-Host "✓ Schema applied successfully" -ForegroundColor Green
Write-Host ""

# Step 7: Populate database
Write-Host "Step 7: Populating database..." -ForegroundColor Yellow
$populate = Read-Host "Do you want to populate the database now? This may take several minutes. (y/n)"

if ($populate -eq "y" -or $populate -eq "Y") {
    $PopulateScript = Join-Path $ScriptDir "populate_db.py"

    if (-not (Test-Path $PopulateScript)) {
        Write-Host "Error: populate_db.py not found at $PopulateScript" -ForegroundColor Red
        exit 1
    }

    & python $PopulateScript
    Write-Host "✓ Database populated successfully" -ForegroundColor Green
} else {
    Write-Host "Skipping database population. You can run it later with:" -ForegroundColor Yellow
    Write-Host "  python populate_db.py" -ForegroundColor White
}
Write-Host ""

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "✓ Database setup complete!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "To verify the installation, run:" -ForegroundColor Yellow
Write-Host "  psql -U postgres mimic -c '\dt'" -ForegroundColor White
Write-Host ""

# Clean up environment variable
Remove-Item Env:\PGPASSWORD
