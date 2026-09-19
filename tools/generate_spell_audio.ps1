# Generador de audios pre-grabados para HNZHealingTools MRT/NSRT TTS.
#
# Uso:
#   powershell.exe -ExecutionPolicy Bypass -File tools\generate_spell_audio.ps1
#
# Genera archivos WAV para cada (spellID, idioma) en Sounds\Spells\<locale>\<id>.wav
# usando System.Speech.Synthesis (SAPI). Requiere las voces:
#   - "Microsoft Sabina Desktop" (es-MX) para esES
#   - "Microsoft Zira Desktop"   (en-US) para enUS
# Si tu sistema tiene otras voces espanolas/inglesas, edita las constantes
# $VoiceES / $VoiceEN abajo.
#
# Para agregar/cambiar nombres editar $Spells (campo .ES o .EN).

Add-Type -AssemblyName System.Speech

$VoiceES = "Microsoft Sabina Desktop"
$VoiceEN = "Microsoft Zira Desktop"

$OutRoot = Join-Path $PSScriptRoot ".." | Resolve-Path
$OutES = Join-Path $OutRoot "Sounds\Spells\esES"
$OutEN = Join-Path $OutRoot "Sounds\Spells\enUS"
New-Item -ItemType Directory -Force -Path $OutES | Out-Null
New-Item -ItemType Directory -Force -Path $OutEN | Out-Null

# Top 20 healing/raid CDs comunes en notas MRT.
# Si Blizzard cambia un nombre o vos preferis otra traduccion, editar aqui y
# re-correr el script.
$Spells = @(
    @{ ID=740;    EN="Tranquility";          ES="Tranquilidad" }
    @{ ID=98008;  EN="Spirit Link Totem";    ES="Totem de eslabon espiritual" }
    @{ ID=64843;  EN="Divine Hymn";          ES="Himno divino" }
    @{ ID=64901;  EN="Hymn of Hope";         ES="Himno de esperanza" }
    @{ ID=265202; EN="Holy Word Salvation";  ES="Palabra sagrada Salvacion" }
    @{ ID=31821;  EN="Aura Mastery";         ES="Maestria del aura" }
    @{ ID=29166;  EN="Innervate";            ES="Enervar" }
    @{ ID=32182;  EN="Heroism";              ES="Heroismo" }
    @{ ID=2825;   EN="Bloodlust";            ES="Ansia de sangre" }
    @{ ID=80353;  EN="Time Warp";            ES="Pliegue temporal" }
    @{ ID=264667; EN="Primal Rage";          ES="Furia primaria" }
    @{ ID=62618;  EN="Power Word Barrier";   ES="Palabra de poder Barrera" }
    @{ ID=97462;  EN="Rallying Cry";         ES="Grito reanimante" }
    @{ ID=33206;  EN="Pain Suppression";     ES="Supresion del dolor" }
    @{ ID=102342; EN="Ironbark";             ES="Corteza de hierro" }
    @{ ID=116849; EN="Life Cocoon";          ES="Capullo vital" }
    @{ ID=51052;  EN="Anti-Magic Zone";      ES="Zona antimagia" }
    @{ ID=196718; EN="Darkness";             ES="Oscuridad" }
    @{ ID=115310; EN="Revival";              ES="Reanimar" }
    @{ ID=106898; EN="Stampeding Roar";      ES="Rugido en estampida" }
)

$synthES = New-Object System.Speech.Synthesis.SpeechSynthesizer
$synthEN = New-Object System.Speech.Synthesis.SpeechSynthesizer

try {
    $synthES.SelectVoice($VoiceES)
    $synthEN.SelectVoice($VoiceEN)
} catch {
    Write-Error "No se pudo seleccionar la voz. Voces instaladas:"
    $synthES.GetInstalledVoices() | ForEach-Object { Write-Host "  - $($_.VoiceInfo.Name) ($($_.VoiceInfo.Culture))" }
    exit 1
}

$count = 0
foreach ($s in $Spells) {
    $pathES = Join-Path $OutES "$($s.ID).wav"
    $pathEN = Join-Path $OutEN "$($s.ID).wav"

    $synthES.SetOutputToWaveFile($pathES)
    $synthES.Speak($s.ES)

    $synthEN.SetOutputToWaveFile($pathEN)
    $synthEN.Speak($s.EN)

    $count++
    Write-Host "[$count/$($Spells.Count)] ID=$($s.ID)  ES='$($s.ES)'  EN='$($s.EN)'"
}

$synthES.Dispose()
$synthEN.Dispose()

Write-Host ""
Write-Host "Generados $count audios x 2 idiomas = $($count*2) archivos." -ForegroundColor Green
Write-Host "Output: $OutRoot\Sounds\Spells\{esES,enUS}\*.wav"
