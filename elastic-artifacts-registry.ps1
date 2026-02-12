$STACK_VERSION = "8.19.11"
$ARTIFACT_DOWNLOADS_BASE_URL = "https://artifacts.elastic.co/downloads"
$env:DOWNLOAD_BASE_DIR = Join-Path $PWD "elastic-artifacts"
if (-not $env:DOWNLOAD_BASE_DIR) {
    throw "Make sure to set DOWNLOAD_BASE_DIR when running this script"
}
$DOWNLOAD_BASE_DIR = $env:DOWNLOAD_BASE_DIR
$COMMON_PACKAGE_PREFIXES = @(
    "apm-server/apm-server"
    "beats/auditbeat/auditbeat"
    "beats/elastic-agent/elastic-agent"
    "beats/filebeat/filebeat"
    "beats/heartbeat/heartbeat"
    "beats/metricbeat/metricbeat"
    "beats/osquerybeat/osquerybeat"
    "beats/packetbeat/packetbeat"
    "cloudbeat/cloudbeat"
    "endpoint-dev/endpoint-security"
    "fleet-server/fleet-server"
)
$WIN_ONLY_PACKAGE_PREFIXES = @("beats/winlogbeat/winlogbeat")
$RPM_PACKAGES = @("beats/elastic-agent/elastic-agent")
$DEB_PACKAGES = @("beats/elastic-agent/elastic-agent")
function Download-Packages {
    param(
        [string]$UrlSuffix,
        [string[]]$PackagePrefixes
    )
    $urlSuffixes = @($UrlSuffix, "$UrlSuffix.sha512", "$UrlSuffix.asc")
    foreach ($downloadPrefix in $PackagePrefixes) {
        foreach ($pkgUrlSuffix in $urlSuffixes) {
            $pkgDir = Split-Path -Parent (Join-Path $DOWNLOAD_BASE_DIR $downloadPrefix)
            $dlUrl = "$ARTIFACT_DOWNLOADS_BASE_URL/$downloadPrefix-$pkgUrlSuffix"
            if (-not (Test-Path $pkgDir)) {
                New-Item -ItemType Directory -Path $pkgDir -Force | Out-Null
            }
            $fileName = Split-Path -Leaf $dlUrl
            $outputPath = Join-Path $pkgDir $fileName
            Write-Host "Downloading: $dlUrl"
            & curl.exe -sfL -o $outputPath $dlUrl
            if ($LASTEXITCODE -ne 0) {
                Write-Warning "Failed to download: $dlUrl"
            }
        }
    }
}
# and we download
foreach ($_os in @("linux", "windows")) {
    switch ($_os) {
        "linux" {
            $PKG_URL_SUFFIX = "$STACK_VERSION-$_os-x86_64.tar.gz"
        }
        "windows" {
            $PKG_URL_SUFFIX = "$STACK_VERSION-$_os-x86_64.zip"
        }
        default {
            Write-Error "[ERROR] Something happened"
            exit 1
        }
    }
    Download-Packages -UrlSuffix $PKG_URL_SUFFIX -PackagePrefixes $COMMON_PACKAGE_PREFIXES
    if ($_os -eq "windows") {
        Download-Packages -UrlSuffix $PKG_URL_SUFFIX -PackagePrefixes $WIN_ONLY_PACKAGE_PREFIXES
    }
    if ($_os -eq "linux") {
        Download-Packages -UrlSuffix "$STACK_VERSION-x86_64.rpm" -PackagePrefixes $RPM_PACKAGES
        Download-Packages -UrlSuffix "$STACK_VERSION-amd64.deb" -PackagePrefixes $DEB_PACKAGES
    }
}