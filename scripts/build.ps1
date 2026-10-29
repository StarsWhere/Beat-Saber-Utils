[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$GameRoot)
$ErrorActionPreference = 'Stop'
$GameRoot = [IO.Path]::GetFullPath($GameRoot)
if ((Get-Content -LiteralPath (Join-Path $GameRoot 'BeatSaberVersion.txt') -Raw).Trim() -ne '1.45.2_28848') { throw 'Unsupported game build.' }
$root = Split-Path -Parent $PSScriptRoot
$obj = Join-Path $root '.tmp/obj/'
$out = Join-Path $root '.tmp/bin/'
$publicized = Join-Path $root '.tmp/publicized'
[IO.Directory]::CreateDirectory($publicized) | Out-Null
Add-Type -LiteralPath (Join-Path $GameRoot 'Libs/Mono.Cecil.dll')
$resolver = [Mono.Cecil.DefaultAssemblyResolver]::new()
$resolver.AddSearchDirectory((Join-Path $GameRoot 'Beat Saber_Data/Managed'))
$resolver.AddSearchDirectory((Join-Path $GameRoot 'Libs'))
$resolver.AddSearchDirectory((Join-Path $GameRoot 'Plugins'))
$reader = [Mono.Cecil.ReaderParameters]::new()
$reader.AssemblyResolver = $resolver
foreach ($name in @('BGLib.AppFlow','DataModels','Main','PlatformUserModel')) {
    $source = Join-Path $GameRoot ("Beat Saber_Data/Managed/$name.dll")
    if (!(Test-Path -LiteralPath $source -PathType Leaf)) { throw "Missing reference: $source" }
    $module = [Mono.Cecil.ModuleDefinition]::ReadModule($source, $reader)
    try {
        foreach ($type in $module.GetTypes()) {
            if ($type.Name -eq '<Module>') { continue }
            if ($type.IsNested) { $type.IsNestedPublic = $true } else { $type.IsPublic = $true }
            foreach ($field in $type.Fields) { if (-not ($type.Events | Where-Object Name -eq $field.Name)) { $field.IsPublic = $true } }
            foreach ($method in $type.Methods) { if (!$method.IsVirtual) { $method.IsPublic = $true } }
        }
        $module.Write((Join-Path $publicized "$name.dll"))
    } finally { $module.Dispose() }
}
& dotnet build (Join-Path $PSScriptRoot 'compat.csproj') -c Release ('-p:GameRoot=' + $GameRoot) ('-p:PublicizedDir=' + $publicized) ('-p:BaseIntermediateOutputPath=' + $obj) ('-p:OutputPath=' + $out) '-p:RestoreSources=https://api.nuget.org/v3/index.json'
if ($LASTEXITCODE -ne 0) { throw 'Compatibility build failed.' }
