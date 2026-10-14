Add-Type -AssemblyName System.Drawing

$path = 'M:/Maxon-Project/Zephyr/design/app-icon/foreground.png'
$bmp = [System.Drawing.Image]::FromFile($path)
$w = $bmp.Width; $h = $bmp.Height
$rect = New-Object System.Drawing.Rectangle(0, 0, $w, $h)
$data = $bmp.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadWrite, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$stride = $data.Stride
$bytes = New-Object byte[] ($stride * $h)
[System.Runtime.InteropServices.Marshal]::Copy($data.Scan0, $bytes, 0, $bytes.Length)

$removedOrange = 0; $softened = 0
for ($y = 0; $y -lt $h; $y++) {
  for ($x = 0; $x -lt $w; $x++) {
    $i = $y * $stride + $x * 4
    $b = $bytes[$i]; $g = $bytes[$i+1]; $r = $bytes[$i+2]; $a = $bytes[$i+3]
    if ($a -eq 0) { continue }
    $max = [Math]::Max($r, [Math]::Max($g, $b)); $min = [Math]::Min($r, [Math]::Min($g, $b))
    $spread = $max - $min
    if ($spread -gt 45 -and $r -gt $g -and $r -gt $b) {
      $bytes[$i+3] = 0; $removedOrange++; continue
    }
    if ($a -le 140) {
      $bytes[$i+3] = [byte]([Math]::Floor($a * 0.35)); $softened++
    }
  }
}
[System.Runtime.InteropServices.Marshal]::Copy($bytes, 0, $data.Scan0, $bytes.Length)
$bmp.UnlockBits($data)

$out = 'M:/Maxon-Project/Zephyr/design/app-icon/foreground-clean.png'
$bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
Write-Output ("done: removedOrange={0} softened={1} size={2}x{3}" -f $removedOrange, $softened, $w, $h)
