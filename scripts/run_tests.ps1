Write-Host "Running Flutter analyze and tests (PowerShell)"
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  Write-Host "Flutter not found in PATH. Please install Flutter and ensure 'flutter' is available."; exit 1
}
Write-Host "Cleaning flutter_tools temp folders to avoid test finalizer issues..."
$temp = $env:TEMP
try {
  Get-ChildItem -Path $temp -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -like 'flutter_tools.*' } | ForEach-Object {
    Write-Host "Removing: $($_.FullName)"
    Remove-Item -LiteralPath $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
  }
} catch {
  Write-Host "Warning: could not fully clean temp folders: $_"
}

flutter pub get
flutter analyze
flutter test
if ($LASTEXITCODE -ne 0) { Write-Host "Tests failed"; exit $LASTEXITCODE }
Write-Host "All tests passed"
