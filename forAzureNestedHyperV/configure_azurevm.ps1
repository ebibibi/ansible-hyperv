$boxstarter_packageurl = "https://gist.githubusercontent.com/ebibibi/b5d6204297b634dbd0334274746b7c71/raw/boxstarter.txt"
$repo_path = "C:\ansible-hyperv"
$repo = "https://github.com/ebibibi/ansible-hyperv.git"
$pull_golden_image_path = "E:\golden_images"
$golden_images_containerUrl = "https://goldenimagesforebi.blob.core.windows.net/goldenimage"
$sasTokenFile = ".\sas.txt" # SASトークンが保存されているファイルへのパスを指定します

. { Invoke-WebRequest -useb https://boxstarter.org/bootstrapper.ps1 } | Invoke-Expression; Get-Boxstarter -Force
Install-BoxstarterPackage -PackageName $boxstarter_packageurl
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False


# repo
git clone $repo $repo_path

# pull golden images
if(!(Test-Path $pull_golden_image_path)) {
    New-Item -ItemType Directory -Path $pull_golden_image_path
}
$sasToken = Get-Content -Path $sasTokenFile

# Blobリストの取得
$response = Invoke-RestMethod -Method Get -Uri "${golden_images_containerUrl}?${sasToken}?restype=container&comp=list"

foreach ($blob in $response.EnumerationResults.Blobs.Blob) {
    $blobName = $blob.Name
    $blobUrl = "$golden_images_containerUrl/$blobName$sasToken"
    $localFilePath = Join-Path -Path $pull_golden_image_path -ChildPath $blobName

    # Blobのダウンロード
    Invoke-WebRequest -Uri $blobUrl -OutFile $localFilePath
}
