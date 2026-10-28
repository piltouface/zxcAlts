param([string]$zxc = (Join-Path ([Environment]::GetFolderPath('Desktop')) 'papa\alts.txt'))

$ErrorActionPreference = 'SilentlyContinue'
$zxci = [Diagnostics.Stopwatch]::StartNew()

try { [Console]::OutputEncoding = New-Object Text.UTF8Encoding $false } catch { }
try {
    Add-Type -Language CSharp -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public static class YAcon {
    [DllImport("kernel32.dll")] static extern IntPtr GetStdHandle(int n);
    [DllImport("kernel32.dll")] static extern bool GetConsoleMode(IntPtr h, out uint m);
    [DllImport("kernel32.dll")] static extern bool SetConsoleMode(IntPtr h, uint m);
    public static void EnableVt() { IntPtr h = GetStdHandle(-11); uint m; if (GetConsoleMode(h, out m)) SetConsoleMode(h, m | 4); }
}
"@
    [YAcon]::EnableVt()
} catch { }

function Show-Banner {
    $zxcb = [char]27
    $zxcc = "$zxcb[1;38;2;255;182;193m"; $dota1 = "$zxcb[38;2;150;110;125m"; $dota2 = "$zxcb[0m"
    $dota3 = @{
        'Y' = @('██╗   ██╗', '╚██╗ ██╔╝', ' ╚████╔╝ ', '  ╚██╔╝  ', '   ██║   ', '   ╚═╝   ')
        '-' = @('        ', '        ', '█████╗  ', '╚════╝  ', '        ', '        ')
        'A' = @(' █████╗ ', '██╔══██╗', '███████║', '██╔══██║', '██║  ██║', '╚═╝  ╚═╝')
        'L' = @('██╗     ', '██║     ', '██║     ', '██║     ', '███████╗', '╚══════╝')
        'T' = @('████████╗', '╚══██╔══╝', '   ██║   ', '   ██║   ', '   ██║   ', '   ╚═╝   ')
        'S' = @('███████╗', '██╔════╝', '███████╗', '╚════██║', '███████║', '╚══════╝')
    }
    Write-Host ''
    for ($yiupi = 0; $yiupi -lt 6; $yiupi++) {
        $pudge = '  '
        foreach ($sven in 'Y', '-', 'A', 'L', 'T', 'S') { $pudge += $dota3[$sven][$yiupi] }
        Write-Host "$zxcc$pudge$dota2"
    }
    Write-Host "$dota1  alt accounts checker  -  Minecraft / Discord / Steam$dota2"
    Write-Host ''
}
Show-Banner

Add-Type -Language CSharp -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.IO;
using System.IO.Compression;
using System.Text;
using System.Text.RegularExpressions;

public static class YA
{
    static readonly HashSet<string> Names = new HashSet<string>(StringComparer.OrdinalIgnoreCase) {
        "latest.log", "debug.log", "launcher_accounts.json",
        "accounts.microsoft.json", "tlauncher_profiles.json",
        "accounts_v1.do_not_send_to_anyone", "aoba_alts.json", "loginusers.vdf"
    };
    static readonly Regex Dated = new Regex(@"^\d{4}-\d\d-\d\d-\d+\.log(\.gz)?$", RegexOptions.Compiled);
    static readonly HashSet<string> Skip = new HashSet<string>(StringComparer.OrdinalIgnoreCase) {
        "windows", "$recycle.bin", "system volume information", "node_modules", ".git", "winsxs"
    };

    public static List<string> Find(string root)
    {
        var res = new List<string>();
        var st = new Stack<string>();
        st.Push(root);
        while (st.Count > 0)
        {
            string d = st.Pop();
            string[] files;
            try { files = Directory.GetFiles(d); } catch { files = new string[0]; }
            foreach (var f in files)
            {
                var n = Path.GetFileName(f);
                if (Names.Contains(n) || Dated.IsMatch(n)) res.Add(f);
            }
            string[] dirs;
            try { dirs = Directory.GetDirectories(d); } catch { continue; }
            foreach (var s in dirs)
            {
                if (Skip.Contains(Path.GetFileName(s))) continue;
                try { if ((File.GetAttributes(s) & FileAttributes.ReparsePoint) != 0) continue; } catch { continue; }
                st.Push(s);
            }
        }
        return res;
    }

    public static string ReadText(string path)
    {
        try
        {
            using (var fs = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.ReadWrite | FileShare.Delete))
            {
                if (fs.Length > 64L * 1024 * 1024) return null;
                Stream s = fs;
                if (path.EndsWith(".gz", StringComparison.OrdinalIgnoreCase)) s = new GZipStream(fs, CompressionMode.Decompress);
                var sb = new StringBuilder();
                using (var r = new StreamReader(s, new UTF8Encoding(false), true))
                {
                    var buf = new char[65536];
                    int n;
                    try { while ((n = r.Read(buf, 0, buf.Length)) > 0) sb.Append(buf, 0, n); } catch { }
                }
                return sb.ToString();
            }
        }
        catch { return null; }
    }

    public static byte[] ReadBytes(string path)
    {
        try
        {
            using (var fs = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.ReadWrite | FileShare.Delete))
            {
                var b = new byte[fs.Length];
                int off = 0;
                while (off < b.Length) { int n = fs.Read(b, off, b.Length - off); if (n <= 0) break; off += n; }
                return b;
            }
        }
        catch { return null; }
    }

    public static byte[] Inflate(byte[] data)
    {
        if (data == null || data.Length < 3 || data[0] != 0x78) return data;
        try
        {
            using (var ms = new MemoryStream(data, 2, data.Length - 2))
            using (var ds = new DeflateStream(ms, CompressionMode.Decompress))
            using (var o = new MemoryStream())
            {
                ds.CopyTo(o);
                return o.ToArray();
            }
        }
        catch { return null; }
    }

    static bool V64(byte[] b, ref int p, out ulong r)
    {
        r = 0; int shift = 0;
        for (int i = 0; i < 10 && p < b.Length; i++)
        {
            byte x = b[p++];
            r |= (ulong)(x & 0x7f) << shift;
            if ((x & 0x80) == 0) return true;
            shift += 7;
        }
        return false;
    }

    static byte[] Snappy(byte[] src)
    {
        int p = 0; uint len = 0; int shift = 0;
        while (true) { byte b = src[p++]; len |= (uint)(b & 0x7f) << shift; if ((b & 0x80) == 0) break; shift += 7; }
        var dst = new byte[len];
        int d = 0;
        while (p < src.Length)
        {
            int tag = src[p++]; int t = tag & 3;
            if (t == 0)
            {
                int l = tag >> 2;
                if (l < 60) l += 1;
                else { int nb = l - 59; l = 0; for (int i = 0; i < nb; i++) l |= src[p++] << (8 * i); l += 1; }
                Buffer.BlockCopy(src, p, dst, d, l); p += l; d += l;
            }
            else
            {
                int l, off;
                if (t == 1) { l = ((tag >> 2) & 7) + 4; off = ((tag >> 5) << 8) | src[p++]; }
                else if (t == 2) { l = (tag >> 2) + 1; off = src[p] | (src[p + 1] << 8); p += 2; }
                else { l = (tag >> 2) + 1; off = src[p] | (src[p + 1] << 8) | (src[p + 2] << 16) | (src[p + 3] << 24); p += 4; }
                for (int i = 0; i < l; i++) { dst[d] = dst[d - off]; d++; }
            }
        }
        return dst;
    }

    static byte[] Block(byte[] data, long off, long size)
    {
        if (off < 0 || size < 0 || off + size + 5 > data.Length) return null;
        var raw = new byte[size];
        Buffer.BlockCopy(data, (int)off, raw, 0, (int)size);
        byte type = data[off + size];
        if (type == 0) return raw;
        if (type == 1) { try { return Snappy(raw); } catch { return null; } }
        return null;
    }

    static List<byte[]> Values(byte[] blk)
    {
        var res = new List<byte[]>();
        if (blk.Length < 4) return res;
        int nr = BitConverter.ToInt32(blk, blk.Length - 4);
        long trailer = 4 + 4L * nr;
        if (nr < 0 || trailer > blk.Length) return res;
        int end = (int)(blk.Length - trailer);
        int p = 0;
        while (p < end)
        {
            ulong sh, un, vl;
            if (!V32(blk, ref p, out sh) || !V32(blk, ref p, out un) || !V32(blk, ref p, out vl)) break;
            if (p + (long)un + (long)vl > end) break;
            p += (int)un;
            var v = new byte[vl];
            Buffer.BlockCopy(blk, p, v, 0, (int)vl);
            p += (int)vl;
            res.Add(v);
        }
        return res;
    }

    static bool V32(byte[] b, ref int p, out ulong r) { return V64(b, ref p, out r); }

    public static List<string> LdbBlocks(string path)
    {
        var res = new List<string>();
        byte[] data = ReadBytes(path);
        if (data == null || data.Length < 48) return res;
        int f = data.Length - 48;
        byte[] magic = { 0x57, 0xfb, 0x80, 0x8b, 0x24, 0x75, 0x47, 0xdb };
        for (int i = 0; i < 8; i++) if (data[f + 40 + i] != magic[i]) return res;
        int p = f; ulong a, b, io, isz;
        if (!V64(data, ref p, out a) || !V64(data, ref p, out b) || !V64(data, ref p, out io) || !V64(data, ref p, out isz)) return res;
        var idx = Block(data, (long)io, (long)isz);
        if (idx == null) return res;
        foreach (var h in Values(idx))
        {
            int q = 0; ulong o, s;
            if (!V64(h, ref q, out o) || !V64(h, ref q, out s)) continue;
            var blk = Block(data, (long)o, (long)s);
            if (blk != null) res.Add(Encoding.UTF8.GetString(blk));
        }
        return res;
    }
}
'@

$script:invoker = @{}
$script:rubick = New-Object System.Collections.Generic.List[string]
$antimage = @{ Confirmed = 95; Likely = 80; Possible = 55; Trace = 30 }

function Add-Acc($tinker, $lina, $axe, $zeus, $carry, $feed = '', $gg = '') {
    $ez = "$tinker|$($lina.ToLower())"
    $noob = $script:invoker[$ez]
    if ($noob -and $antimage[$noob.Conf] -ge $antimage[$axe]) { return }
    $script:invoker[$ez] = [pscustomobject]@{
        Plat = $tinker; Name = $lina; Conf = $axe; Note = $zeus; Src = $carry; Last = $feed; Uid = $gg
    }
}

$rofl = 'null','none','unknown','player','user','session','offline','demo','steve','alex','local','true','false','undefined','default','anonymous'
function Test-Nick([string]$kek) {
    if ($kek -notmatch '^[A-Za-z0-9_]{3,16}$') { return $false }
    if ($kek -match '^[0-9_]+$') { return $false }
    if ($rofl -contains $kek.ToLower()) { return $false }
    return $true
}

function Get-Mtime($lol) {
    try { (Get-Item -LiteralPath $lol -Force).LastWriteTime.ToString('yyyy-MM-dd HH:mm') } catch { '' }
}

function Get-Launcher([string]$chel) {
    $lol = $chel.ToLower()
    foreach ($gachi in @(
            @('lunarclient', 'Lunar Client'), @('blclient', 'Badlion'), @('badlion', 'Badlion'), @('.feather', 'Feather'),
            @('labymod', 'LabyMod'), @('tlauncher', 'TLauncher'), @('legacylauncher', 'Legacy Launcher'),
            @('legacy-launcher', 'Legacy Launcher'), @('cristalix', 'Cristalix'), @('ely.by', 'Ely.by'), @('elyby', 'Ely.by'),
            @('prismlauncher', 'Prism Launcher'), @('multimc', 'MultiMC'), @('polymc', 'PolyMC'), @('atlauncher', 'ATLauncher'),
            @('curseforge', 'CurseForge'), @('modrinth', 'Modrinth App'), @('gdlauncher', 'GDLauncher'), @('ftb-app', 'FTB App'),
            @('sklauncher', 'SKLauncher'), @('.technic', 'Technic'), @('.minecraft', 'Minecraft'))) {
        if ($lol.Contains($gachi[0])) { return $gachi[1] }
    }
    return 'неизвестный лаунчер'
}

Write-Host '  scanning...'
$bebra = @(Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' | ForEach-Object { $_.DeviceID + '\' })
if (-not $bebra) { $bebra = @('C:\') }

$kapec = New-Object System.Collections.Generic.List[string]
foreach ($yiupi in $bebra) {
    foreach ($cringe in [YA]::Find($yiupi)) { $kapec.Add($cringe) }
}

$sigma = [regex]'(?i)minecraft|\[Client thread|\[Render thread|lwjgl|lunarclient|labymod|tlauncher|cristalix|fabricloader|modlauncher|badlion|feather'
$skibidi = [regex]'Setting user:\s*([^\s,;]+)'
$ahuet = [regex]'--username["'']?[\s,=:]+["'']?([^\s,"''\]\)]+)'
$vaper = [regex]'(?m)^.*(?:Setting user:|--username).*$'

$mid = $kapec | Where-Object { $top = [IO.Path]::GetFileName($_); $top -match '\.log(\.gz)?$' }
foreach ($cringe in $mid) {
    $bot = [YA]::ReadText($cringe)
    if (-not $bot -or -not $sigma.IsMatch($bot)) { continue }
    $roshan = Get-Launcher $cringe
    foreach ($aegis in $vaper.Matches($bot)) {
        $pudge = $aegis.Value
        if ($pudge.Contains('[CHAT]')) { continue }
        foreach ($buyback in $skibidi.Matches($pudge)) {
            if (Test-Nick $buyback.Groups[1].Value) {
                Add-Acc 'Minecraft' $buyback.Groups[1].Value 'Confirmed' "Setting user · $roshan" $cringe (Get-Mtime $cringe)
            }
        }
        foreach ($buyback in $ahuet.Matches($pudge)) {
            if (Test-Nick $buyback.Groups[1].Value) {
                Add-Acc 'Minecraft' $buyback.Groups[1].Value 'Likely' "Аргумент запуска --username · $roshan" $cringe (Get-Mtime $cringe)
            }
        }
    }
}

$creep = 'ias:offline_v2', 'ias:offline_v1', 'ias:microsoft_v1', 'ias:microsoft_v2', 'ias:elyby_v1'
foreach ($cringe in ($kapec | Where-Object { $_ -like '*accounts_v1.do_not_send_to_anyone' })) {
    $jungle = [YA]::Inflate([YA]::ReadBytes($cringe))
    if (-not $jungle) { continue }
    $gank = New-Object System.Collections.Generic.List[string]
    $noob = New-Object System.Text.StringBuilder
    foreach ($ward in $jungle) {
        if ($ward -ge 32 -and $ward -le 126) { [void]$noob.Append([char]$ward) }
        else { if ($noob.Length -ge 3) { $gank.Add($noob.ToString()) }; [void]$noob.Clear() }
    }
    if ($noob.Length -ge 3) { $gank.Add($noob.ToString()) }
    for ($smoke = 0; $smoke -lt $gank.Count; $smoke++) {
        if ($creep -notcontains $gank[$smoke]) { continue }
        for ($blink = $smoke + 1; $blink -lt [Math]::Min($smoke + 4, $gank.Count); $blink++) {
            if ($gank[$blink].StartsWith('ias:')) { break }
            if (Test-Nick $gank[$blink]) {
                Add-Acc 'Minecraft' $gank[$blink] 'Likely' 'IAS: сохранён в списке аккаунтов мода (вход не обязательно был)' $cringe (Get-Mtime $cringe)
                break
            }
        }
    }
}

function Walk-Json($bkb, $mkb) {
    if ($bkb -is [System.Management.Automation.PSCustomObject]) {
        $radiance = ''
        foreach ($lol in $bkb.PSObject.Properties) {
            if ($lol.Value -is [string] -and ('uuid', 'id', 'profileid', 'minecraftuuid') -contains $lol.Name.ToLower() -and $lol.Value -match '^[0-9a-fA-F-]{32}$|^[0-9a-fA-F-]{36}$') { $radiance = $lol.Value }
        }
        foreach ($lol in $bkb.PSObject.Properties) {
            if ($lol.Value -is [string]) {
                $top = $lol.Name.ToLower()
                $manta = 'username', 'displayname', 'minecraftusername', 'playername', 'mcname', 'ign' -contains $top
                $dagon = ('name', 'profilename' -contains $top) -and $radiance
                if (($manta -or $dagon) -and (Test-Nick $lol.Value)) {
                    Add-Acc 'Minecraft' $lol.Value 'Likely' "Файл аккаунтов лаунчера · $(Get-Launcher $mkb)" $mkb (Get-Mtime $mkb) $radiance
                }
            }
        }
        foreach ($lol in $bkb.PSObject.Properties) {
            if ($lol.Name -in 'settings', 'mods', 'versions', 'javaargs') { continue }
            Walk-Json $lol.Value $mkb
        }
    }
    elseif ($bkb -is [System.Array]) { foreach ($smoke in $bkb) { Walk-Json $smoke $mkb } }
}

foreach ($cringe in ($kapec | Where-Object { [IO.Path]::GetFileName($_) -in 'launcher_accounts.json', 'accounts.microsoft.json', 'tlauncher_profiles.json', 'aoba_alts.json' })) {
    $bot = [YA]::ReadText($cringe)
    if (-not $bot) { continue }
    try { Walk-Json ($bot | ConvertFrom-Json) $cringe } catch { }
}

foreach ($cringe in ($kapec | Where-Object { [IO.Path]::GetFileName($_) -ieq 'loginusers.vdf' })) {
    $bot = [YA]::ReadText($cringe)
    if (-not $bot) { continue }
    foreach ($aegis in [regex]::Matches($bot, '"(\d{17})"\s*\{([^{}]*)\}')) {
        $refresher = $aegis.Groups[2].Value
        $octarine = if ($refresher -match '"AccountName"\s+"([^"]*)"') { $Matches[1] } else { '' }
        $rapier = if ($refresher -match '"PersonaName"\s+"([^"]*)"') { $Matches[1] } else { '' }
        $aghs = $refresher -match '"MostRecent"\s+"1"'
        $feed = ''
        if ($refresher -match '"Timestamp"\s+"(\d+)"') { $feed = [DateTimeOffset]::FromUnixTimeSeconds([long]$Matches[1]).LocalDateTime.ToString('yyyy-MM-dd HH:mm') }
        $lina = if ($octarine -and $rapier -and $octarine -ne $rapier) { "$octarine ($rapier)" } elseif ($octarine) { $octarine } elseif ($rapier) { $rapier } else { "SteamID $($aegis.Groups[1].Value)" }
        $zeus = if ($aghs) { 'Последний вход на этой машине' } else { 'Сохранённый вход (loginusers.vdf)' }
        Add-Acc 'Steam' $lina 'Confirmed' $zeus $cringe $feed $aegis.Groups[1].Value
    }
}

$shard = Get-ChildItem 'C:\Users' -Directory -Force | Where-Object { $_.Name -notin 'Public', 'Default', 'Default User', 'All Users' }
foreach ($tp in $shard) {
    foreach ($boots in 'discord', 'discordcanary', 'discordptb', 'discorddevelopment', 'Lightcord') {
        $bottle = Join-Path $tp.FullName "AppData\Roaming\$boots\Local Storage\leveldb"
        if (-not (Test-Path -LiteralPath $bottle)) { continue }
        $tango = "$($tp.Name)/$boots"

        
        $salve = @()
        foreach ($mkb in Get-ChildItem -LiteralPath $bottle -File -Force) {
            $clarity = $mkb.Extension.ToLower()
            if ($clarity -notin '.ldb', '.log') { continue }
            $sniper = if ($clarity -eq '.ldb') { [YA]::LdbBlocks($mkb.FullName) } else { , [YA]::ReadText($mkb.FullName) }
            $tide = 0; [void][int]::TryParse($mkb.BaseName, [ref]$tide)
            $kunkka = @()
            foreach ($mirana in $sniper) {
                if (-not $mirana) { continue }
                foreach ($pa in [regex]::Matches($mirana, '"_state"\s*:\s*\{\s*"users"\s*:\s*\[')) {
                    $phantom = $pa.Index + $pa.Length; $void = 1; $spirit = $phantom
                    while ($spirit -lt $mirana.Length -and $void -gt 0) {
                        $sven = $mirana[$spirit]; if ($sven -eq '[') { $void++ } elseif ($sven -eq ']') { $void-- }; $spirit++
                    }
                    $storm = $mirana.Substring($phantom, [Math]::Max(0, $spirit - $phantom - 1))
                    $ember = @()
                    foreach ($earth in [regex]::Matches($storm, '\{[^{}]*\}')) {
                        $lich = if ($earth.Value -match '"id"\s*:\s*"(\d{15,25})"') { $Matches[1] } else { $null }
                        $cm = if ($earth.Value -match '"username"\s*:\s*"((?:[^"\\]|\\.)*)"') { $Matches[1] } else { $null }
                        if ($lich -and $cm) { $ember += , @($lich, $cm) }
                    }
                    if ($ember.Count) { $kunkka += , $ember }
                }
            }
            if ($kunkka.Count) {
                
                $lion = if ($clarity -eq '.ldb') { $kunkka[0] } else { $kunkka[$kunkka.Count - 1] }
                $salve += [pscustomobject]@{ Num = $tide; Ext = $clarity; Users = $lion; All = $kunkka }
            }
        }
        if (-not $salve) { $script:rubick.Add("Discord ($tango): MultiAccountStore не найден"); continue }

        $shaman = $salve | Sort-Object Num | Select-Object -Last 1
        $witch = @{}
        foreach ($doctor in $shaman.Users) {
            $witch[$doctor[0]] = $true
            Add-Acc 'Discord' $doctor[1] 'Confirmed' 'Аккаунт в переключателе Discord' "$tango : MultiAccountStore" '' $doctor[0]
        }
        foreach ($dazzle in $salve) {
            foreach ($oracle in $dazzle.All) {
                foreach ($doctor in $oracle) {
                    if ($witch.ContainsKey($doctor[0])) { continue }
                    Add-Acc 'Discord' $doctor[1] 'Trace' 'Был в переключателе Discord, сейчас убран (старая копия в .ldb/.log)' "$tango : MultiAccountStore" '' $doctor[0]
                }
            }
        }
    }
}

$io = @()
try {
    $io = Get-LocalUser | ForEach-Object {
        $chen = if ($_.LastLogon) { $_.LastLogon.ToString('yyyy-MM-dd HH:mm') } else { 'никогда' }
        '{0}  (включена: {1}, последний вход: {2})' -f $_.Name, $_.Enabled, $chen
    }
} catch { }

$enigma = New-Object System.Text.StringBuilder
[void]$enigma.AppendLine("Y-Alts, $env:COMPUTERNAME, запуск от $env:USERNAME, $(Get-Date -Format 'yyyy-MM-dd HH:mm')")
[void]$enigma.AppendLine('')
[void]$enigma.AppendLine('сводка, чтобы не спрашивали че это:')
[void]$enigma.AppendLine('~95% значит ник точно был в игре (запись в логе) или аккаунт реально стоит в дискорде/стиме')
[void]$enigma.AppendLine('~80% ник нашёлся в аргументе запуска или в сохранённом списке лаунчера/мода (ias), там не факт что заходили')
[void]$enigma.AppendLine('~30% старый след: аккаунт уже убрали, но остатки на диске остались')
[void]$enigma.AppendLine('')

foreach ($tinker in 'Minecraft', 'Discord', 'Steam') {
    $tusk = $script:invoker.Values | Where-Object { $_.Plat -eq $tinker } | Sort-Object @{ e = { -$antimage[$_.Conf] } }, @{ e = { $_.Name.ToLower() } }
    [void]$enigma.AppendLine("$($tinker.ToUpper()) ($(@($tusk).Count))")
    [void]$enigma.AppendLine('')
    foreach ($sand in $tusk) {
        $king = "~$($antimage[$sand.Conf])%"
        if ($tinker -eq 'Minecraft') {
            
            [void]$enigma.AppendLine("$king  $($sand.Name)")
            [void]$enigma.AppendLine("      $($sand.Note)")
            [void]$enigma.AppendLine("      $($sand.Src)")
            if ($sand.Last) { [void]$enigma.AppendLine("      изменён $($sand.Last)") }
        }
        else {
            $nyx = @()
            if ($sand.Conf -eq 'Trace') { $nyx += 'убран из переключателя' }
            elseif ($tinker -eq 'Steam' -and $sand.Note -like 'Последний*') { $nyx += 'последний вход на этом пк' }
            if ($sand.Uid) { $nyx += "id $($sand.Uid)" }
            if ($tinker -eq 'Steam' -and $sand.Last) { $nyx += $sand.Last }
            [void]$enigma.AppendLine(("$king  $($sand.Name)" + $(if ($nyx) { '   ' + ($nyx -join ', ') } else { '' })))
        }
        if ($tinker -eq 'Minecraft') { [void]$enigma.AppendLine('') }
    }
    [void]$enigma.AppendLine('')
}

if ($io) {
    [void]$enigma.AppendLine("УЧЁТНЫЕ ЗАПИСИ WINDOWS ($(@($io).Count))"); [void]$enigma.AppendLine('')
    foreach ($bane in $io) { [void]$enigma.AppendLine($bane) }
    [void]$enigma.AppendLine('')
}
if ($script:rubick.Count) {
    [void]$enigma.AppendLine('ПРЕДУПРЕЖДЕНИЯ')
    foreach ($bane in $script:rubick) { [void]$enigma.AppendLine($bane) }
}

[void](New-Item -ItemType Directory -Force -Path (Split-Path -Parent $zxc))
[IO.File]::WriteAllText($zxc, $enigma.ToString(), (New-Object Text.UTF8Encoding $true))
Write-Host "  saved: $zxc"
