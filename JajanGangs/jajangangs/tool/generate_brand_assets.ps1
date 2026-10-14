Add-Type -AssemblyName System.Drawing
$root = Split-Path $PSScriptRoot -Parent
$icon = [System.Drawing.Image]::FromFile((Join-Path $root 'assets/branding/app_icon_source.png'))
$mascot = [System.Drawing.Image]::FromFile((Join-Path $root 'assets/branding/mascot.png'))
function Export-Asset($source, [string]$relative, [int]$size, [double]$scale = 1, [bool]$opaque = $false) {
 $path = Join-Path $root $relative
 [System.IO.Directory]::CreateDirectory((Split-Path $path)) | Out-Null
 $format = if ($opaque) { [System.Drawing.Imaging.PixelFormat]::Format24bppRgb } else { [System.Drawing.Imaging.PixelFormat]::Format32bppArgb }
 $bmp = [System.Drawing.Bitmap]::new($size,$size,$format)
 $g = [System.Drawing.Graphics]::FromImage($bmp)
 $g.Clear($(if($opaque){[System.Drawing.Color]::FromArgb(16,44,66)}else{[System.Drawing.Color]::Transparent}))
 $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
 $side = [int]($size * $scale); $offset = [int](($size-$side)/2)
 $g.DrawImage($source,$offset,$offset,$side,$side)
 $bmp.Save($path,[System.Drawing.Imaging.ImageFormat]::Png)
 $g.Dispose();$bmp.Dispose()
}
$catalog = Get-Content (Join-Path $root 'ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json') -Raw | ConvertFrom-Json
foreach($entry in $catalog.images) {
 $size = [int]([double]($entry.size.Split('x')[0]) * [double]($entry.scale.TrimEnd('x')))
 Export-Asset $icon ('ios/Runner/Assets.xcassets/AppIcon.appiconset/'+$entry.filename) $size 1 $true
}
$densities = @{'mdpi'=1; 'hdpi'=1.5; 'xhdpi'=2; 'xxhdpi'=3; 'xxxhdpi'=4}
foreach($density in $densities.GetEnumerator()) {
 $d=$density.Key;$factor=$density.Value
 Export-Asset $icon "android/app/src/main/res/mipmap-$d/ic_launcher.png" ([int](48*$factor)) 1 $true
 Export-Asset $mascot "android/app/src/main/res/drawable-$d/jajan_foreground.png" ([int](108*$factor)) .65
 Export-Asset $mascot "android/app/src/main/res/drawable-$d/jajan_splash_icon.png" ([int](288*$factor)) .65
 Export-Asset $mascot "android/app/src/main/res/drawable-$d/jajan_splash.png" ([int](240*$factor)) 1
}
foreach($scale in 1,2,3) {
 $name = if($scale -eq 1){'LaunchImage.png'}else{"LaunchImage@${scale}x.png"}
 Export-Asset $mascot "ios/Runner/Assets.xcassets/LaunchImage.imageset/$name" (240*$scale) 1
}
$icon.Dispose();$mascot.Dispose()
