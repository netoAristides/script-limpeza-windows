# ================================
# VERIFICAR ADMIN
# ================================
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltinRole]::Administrator)) {

    Write-Host "Execute este script como Administrador!" -ForegroundColor Red
    Pause
    exit
}

# ================================
# CONFIGURAÇÕES
# ================================
$usuario = $env:USERNAME
$maquina = $env:COMPUTERNAME
$data = Get-Date -Format "yyyy-MM-dd_HH-mm"

$logDir = "C:\Logs\$maquina"
$logPath = "$logDir\limpeza_$data.log"

# Criar pasta de log se não existir
if (!(Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

$dias = 7
$totalLiberado = 0
$inicioExecucao = Get-Date

# Criar pasta de log se não existir
if (!(Test-Path "C:\Logs")) {
    New-Item -ItemType Directory -Path "C:\Logs" | Out-Null
}


# ================================
# FUNÇÃO DE LOG
# ================================
function Escrever-Log {
    param ($mensagem)

    $data = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logPath -Value "$data - $mensagem"
    Add-Content -Path $logPath -Value ""  # linha em branco
}

# ================================
# FUNÇÃO PARA CONVERTER TAMANHO
# ================================
function Converter-Tamanho {
    param ($bytes)

    if ($bytes -ge 1GB) { return "{0:N2} GB" -f ($bytes / 1GB) }
    elseif ($bytes -ge 1MB) { return "{0:N2} MB" -f ($bytes / 1MB) }
    elseif ($bytes -ge 1KB) { return "{0:N2} KB" -f ($bytes / 1KB) }
    else { return "$bytes Bytes" }
}

Escrever-Log "=== INICIO DA LIMPEZA ==="

# ================================
# FUNÇÃO PADRÃO DE LIMPEZA
# ================================
function Limpar-Pasta {
    param ($caminho, $descricao)

    Escrever-Log "Iniciando: $descricao"

    try {
        if (Test-Path $caminho -ErrorAction SilentlyContinue) {

            $arquivos = Get-ChildItem $caminho -Recurse -Force -ErrorAction SilentlyContinue |
                Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$dias) }

            $tamanho = ($arquivos | Measure-Object -Property Length -Sum).Sum
            if (-not $tamanho) { $tamanho = 0 }

            $quantidade = ($arquivos | Measure-Object).Count

            $arquivos | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

            $totalLiberado += $tamanho

            if ($tamanho -eq 0) {
                Escrever-Log "$descricao - Nenhum arquivo para limpar"
            } else {
                Escrever-Log "$descricao - Arquivos removidos: $quantidade | Liberado: $(Converter-Tamanho $tamanho)"
            }
        } else {
            Escrever-Log "$descricao - Caminho nao encontrado"
        }
    }
    catch {
        Escrever-Log "Erro em $descricao"
    }
}

# ================================
# TEMP USUÁRIO ATUAL
# ================================
Limpar-Pasta $env:TEMP "Temp usuario atual"

# ================================
# TEMP TODOS USUÁRIOS
# ================================
Get-ChildItem "C:\Users" -Directory | Where-Object {
    $_.Name -notin @("Default", "Public", "All Users", "Default User") -and
    (Test-Path "$($_.FullName)\AppData\Local\Temp")
} | ForEach-Object {
    try {
        $tempPath = "$($_.FullName)\AppData\Local\Temp"
        Limpar-Pasta $tempPath "Temp usuario ($($_.Name))"
    }
    catch {
        Escrever-Log "Erro ao acessar usuario $($_.Name)"
    }
}

# ================================
# TEMP WINDOWS
# ================================
Limpar-Pasta "C:\Windows\Temp" "Temp Windows"

# ================================
# WINDOWS UPDATE
# ================================
try {
    Escrever-Log "Iniciando: Windows Update"

    if (Get-Service wuauserv -ErrorAction SilentlyContinue) {
        Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
}

    $path = "C:\Windows\SoftwareDistribution\Download"

    if (Test-Path $path) {
        $arquivos = Get-ChildItem $path -Recurse -Force -ErrorAction SilentlyContinue
        $tamanho = ($arquivos | Measure-Object -Property Length -Sum).Sum
        if (-not $tamanho) { $tamanho = 0 }

        $quantidade = ($arquivos | Measure-Object).Count

        $arquivos | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

        $totalLiberado += $tamanho

        if ($tamanho -eq 0) {
            Escrever-Log "Windows Update - Nenhum arquivo para limpar"
        } else {
            Escrever-Log "Windows Update - Arquivos removidos: $quantidade | Liberado: $(Converter-Tamanho $tamanho)"
        }
    }
}
catch {
    Escrever-Log "Erro no Windows Update"
}
finally {
    if (Get-Service wuauserv -ErrorAction SilentlyContinue) {
        Start-Service wuauserv -ErrorAction SilentlyContinue
    }
}

# ================================
# LOGS WINDOWS
# ================================
Limpar-Pasta "C:\Windows\Logs" "Logs do Windows"

# ================================
# MINIDUMP
# ================================
try {
    Escrever-Log "Iniciando: Minidump"

    $paths = @("C:\Windows\Minidump", "C:\Windows\MEMORY.DMP")
    $tamanhoTotal = 0
    $quantidadeTotal = 0

    foreach ($path in $paths) {
        if (Test-Path $path -ErrorAction SilentlyContinue) {

            $arquivos = Get-ChildItem $path -Recurse -Force -ErrorAction SilentlyContinue
            $tamanho = ($arquivos | Measure-Object -Property Length -Sum).Sum
            if (-not $tamanho) { $tamanho = 0 }

            $quantidade = ($arquivos | Measure-Object).Count

            Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue

            $tamanhoTotal += $tamanho
            $quantidadeTotal += $quantidade
            $totalLiberado += $tamanho
        }
    }

    if ($tamanhoTotal -eq 0) {
        Escrever-Log "Minidump - Nenhum arquivo para limpar"
    } else {
        Escrever-Log "Minidump - Arquivos removidos: $quantidadeTotal | Liberado: $(Converter-Tamanho $tamanhoTotal)"
    }
}
catch {
    Escrever-Log "Erro no Minidump"
}

# ================================
# LIXEIRA
# ================================
try {
    Escrever-Log "Iniciando limpeza da lixeira (modo forçado)"

    Get-ChildItem "C:\$Recycle.Bin" -Force -ErrorAction SilentlyContinue | ForEach-Object {
        try {
            Remove-Item $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
        }
        catch {
            Escrever-Log "Erro ao remover item da lixeira: $($_.FullName)"
        }
    }

    Escrever-Log "Lixeira limpa (ou ja estava vazia)"
}
catch {
    Escrever-Log "Erro geral na limpeza da lixeira"
}

# ================================
# TOTAL FINAL
# ================================
$fimExecucao = Get-Date
$tempoExecucao = ($fimExecucao - $inicioExecucao).TotalSeconds

Escrever-Log "TOTAL LIBERADO: $(Converter-Tamanho $totalLiberado)"
Escrever-Log "TEMPO DE EXECUCAO: $([math]::Round($tempoExecucao,2)) segundos"
Escrever-Log "=== FIM DA LIMPEZA ==="