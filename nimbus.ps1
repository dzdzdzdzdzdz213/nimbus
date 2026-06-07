#$OutputEncoding = [System.Text.UTF8Encoding]::new()
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
# nimbus - System Weather Engine
# Maps live system metrics onto a living weather visualization.
# Your machine has its own climate. Watch it change.

$ESC = "$([char]27)"
$RESET = "${ESC}[0m"
$CLS = "${ESC}[2J${ESC}[H"
$HIDE = "${ESC}[?25l"
$SHOW = "${ESC}[?25h"

$weatherTypes = @{
    Clear      = @{icon='☀'; temp='Warm';   wind='Calm';     color=@(255,220,80)}
    PartlyCloudy = @{icon='⛅'; temp='Mild';  wind='Light';   color=@(200,200,180)}
    Overcast   = @{icon='☁';  temp='Cool';   wind='Moderate'; color=@(150,150,160)}
    Fog        = @{icon='🌫'; temp='Chill';  wind='Still';   color=@(160,160,170)}
    Rain       = @{icon='🌧'; temp='Cold';   wind='Gusty';    color=@(80,130,200)}
    Storm      = @{icon='⛈'; temp='Volatile'; wind='High';    color=@(180,80,80)}
    Heatwave   = @{icon='🔥'; temp='Hot';    wind='Dry';      color=@(255,100,50)}
    Aurora     = @{icon='🌌'; temp='Ethereal'; wind='Cosmic'; color=@(100,200,255)}
}

function Get-FG($r, $g, $b) { "${ESC}[38;2;$r;$g;${b}m" }

function Get-SystemClimate {
    $cpu = (Get-CimInstance Win32_Processor).LoadPercentage
    $os = Get-CimInstance Win32_OperatingSystem
    $ramTotal = $os.TotalVisibleMemorySize / 1MB
    $ramFree = $os.FreePhysicalMemory / 1MB
    $ramPct = [Math]::Round((1 - $ramFree / $ramTotal) * 100, 1)
    $procCount = (Get-Process).Count
    $disk = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | Select-Object -First 1
    $diskPct = if ($disk) { [Math]::Round((($disk.Size - $disk.FreeSpace) / $disk.Size) * 100, 1) } else { 0 }
    $uptimeDays = ((Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime).TotalDays

    return @{
        cpu = $cpu
        ram = $ramPct
        proc = $procCount
        disk = $diskPct
        uptime = $uptimeDays
    }
}

function Get-Weather($climate) {
    # Weather = weighted combination of system metrics
    $cpuScore = $climate.cpu / 100
    $ramScore = $climate.ram / 100
    $diskScore = $climate.disk / 100
    $stress = ($cpuScore * 0.5 + $ramScore * 0.3 + $diskScore * 0.2)

    if ($stress -lt 0.15) {
        if ($climate.uptime -gt 5) { return $weatherTypes['Clear'] }
        return $weatherTypes['PartlyCloudy']
    }
    elseif ($stress -lt 0.3) {
        if ($climate.uptime -gt 10) { return $weatherTypes['Aurora'] }
        return $weatherTypes['PartlyCloudy']
    }
    elseif ($stress -lt 0.45) { return $weatherTypes['Overcast'] }
    elseif ($stress -lt 0.55) {
        if ($climate.cpu -gt 60) { return $weatherTypes['Fog'] }
        return $weatherTypes['Overcast']
    }
    elseif ($stress -lt 0.65) { return $weatherTypes['Rain'] }
    elseif ($stress -lt 0.8) {
        if ($cpuScore -gt $ramScore) { return $weatherTypes['Storm'] }
        return $weatherTypes['Rain']
    }
    else { return $weatherTypes['Heatwave'] }
}

function Draw-WeatherMap($climate, $weather, $frame) {
    $r, $g, $b = $weather.color
    $fg = Get-FG $r $g $b
    $lf = Get-FG 100 100 120

    $pressure = [Math]::Round(1013 - ($climate.cpu * 0.3) + ($climate.ram * 0.1), 1)
    $humidity = [Math]::Round(30 + ($climate.ram * 0.6), 1)
    $windSpeed = [Math]::Round(5 + ($climate.proc * 0.05), 1)

    # Live particle system
    $particles = @()
    $numP = 40
    for ($i = 0; $i -lt $numP; $i++) {
        $px = [Math]::Sin($frame * 0.02 + $i * 1.7) * 15 + 30
        $py = [Math]::Cos($frame * 0.03 + $i * 2.3) * 10 + 12
        $particles += @{x=$px; y=$py; phase=$i}
    }

    $lines = @()
    $lines += "${fg}   ╔══════════════════════════════════════╗"
    $lines += "${fg}   ║          SYSTEM WEATHER MAP          ║"
    $lines += "${fg}   ╚══════════════════════════════════════╝"
    $lines += ""
    $lines += "${fg}   $($weather.icon)  $($weather.temp) · $($weather.wind) Winds${RESET}"
    $lines += "${lf}   Pressure: ${pressure} hPa  |  Humidity: ${humidity}%  |  Wind: ${windSpeed} m/s${RESET}"
    $lines += ""

    # ASCII weather landscape
    $sky = @()
    for ($y = 0; $y -lt 20; $y++) {
        $row = "   "
        for ($x = 0; $x -lt 60; $x++) {
            $isParticle = $false
            foreach ($p in $particles) {
                $dx = $x - [Math]::Round($p.x)
                $dy = $y - [Math]::Round($p.y)
                if ([Math]::Abs($dx) -le 1 -and [Math]::Abs($dy) -le 1) { $isParticle = $true; break }
            }

            if ($isParticle) {
                $row += "${fg}$($weather.icon[0])${RESET}"
            } elseif ($y -ge 17 -and $y -le 18) {
                # Ground
                $gShade = 60 + [Math]::Round($climate.disk * 0.5)
                $row += "${ESC}[38;2;$gShade;$([Math]::Round($gShade*1.5));${gShade}m▄${RESET}"
            } elseif ($y -ge 15 -and $y -le 16 -and $x % 8 -gt 3) {
                # City silhouette
                $bHeight = ($y - 15) * 2
                $row += "${lf}▓${RESET}"
            } else {
                # Sky gradient by CPU
                $skyB = [Math]::Round(200 - $climate.cpu * 1.5)
                $skyG = [Math]::Round(180 - $climate.cpu * 1.2)
                $skyR = [Math]::Round(160 - $climate.cpu * 0.8)
                if ($skyR -lt 30) { $skyR = 30 }
                if ($skyG -lt 30) { $skyG = 30 }
                if ($skyB -lt 50) { $skyB = 50 }
                $row += "${ESC}[48;2;$skyR;$skyG;${skyB}m ${RESET}"
            }
        }
        $sky += $row
    }
    $lines += $sky -join "`n"

    # Climate dashboard
    $cpuBar = [Math]::Round($climate.cpu / 2.5)
    $ramBar = [Math]::Round($climate.ram / 2.5)
    $diskBar = [Math]::Round($climate.disk / 2.5)
    $lines += ""
    $lines += "${fg}   CPU Load     $(('█' * $cpuBar) + ('░' * (40 - $cpuBar)))  $($climate.cpu)%${RESET}"
    $lines += "${fg}   Memory       $(('█' * $ramBar) + ('░' * (40 - $ramBar)))  $($climate.ram)%${RESET}"
    $lines += "${fg}   Disk         $(('█' * $diskBar) + ('░' * (40 - $diskBar)))  $($climate.disk)%${RESET}"
    $lines += ""
    $lines += "${lf}   Processes: $($climate.proc)  |  Uptime: $([Math]::Round($climate.uptime, 1)) days${RESET}"

    return $lines -join "`n"
}

# Main loop
Write-Host $HIDE -NoNewline
try {
    for ($frame = 0; $frame -lt 180; $frame++) {
        $climate = Get-SystemClimate
        $weather = Get-Weather $climate
        $map = Draw-WeatherMap $climate $weather $frame

        Write-Host $CLS -NoNewline
        Write-Host $map

        # Forecast
        $r, $g, $b = $weather.color
        $fg = Get-FG $r $g $b
        $trend = if ($climate.cpu -gt 70) { "Deteriorating — storm front approaching" } `
            elseif ($climate.cpu -gt 50) { "Unsettled — chance of system storms" } `
            elseif ($climate.cpu -gt 30) { "Mild — partly cloudy with calm periods" } `
            else { "Fair — clear skies ahead" }
        Write-Host ""
        Write-Host "${fg}   Forecast: ${trend}${RESET}"

        Start-Sleep -Milliseconds 250
    }
} finally {
    Write-Host $SHOW -NoNewline
    Write-Host $RESET
    Write-Host ""
    Write-Host "  nimbus has passed. The weather shifts on."
    Write-Host ""
}
