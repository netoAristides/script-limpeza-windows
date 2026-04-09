# ================================
# CONFIGURAÇÕES
# ================================
$logPath = "C:\Logs\limpeza_temp_$(Get-Date -Format 'yyyy-MM-dd_HH-mm').log"
$dias = 6
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
    "$data - $mensagem" | Out-File -FilePath $logPath -Append -Encoding utf8
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

Escrever-Log "=== INÍCIO DA LIMPEZA ==="

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
            Escrever-Log "$descricao - Caminho não encontrado"
        }
    }
    catch {
        Escrever-Log "Erro em $descricao"
    }
}

# ================================
# TEMP USUÁRIO ATUAL
# ================================
Limpar-Pasta $env:TEMP "Temp usuário atual"

# ================================
# TEMP TODOS USUÁRIOS
# ================================
Get-ChildItem "C:\Users" -Directory | Where-Object {
    $_.Name -notin @("Default", "Public", "All Users", "Default User") -and
    (Test-Path "$($_.FullName)\AppData\Local\Temp")
} | ForEach-Object {
    try {
        $tempPath = "$($_.FullName)\AppData\Local\Temp"
        Limpar-Pasta $tempPath "Temp usuário ($($_.Name))"
    }
    catch {
        Escrever-Log "Erro ao acessar usuário $($_.Name)"
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
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
    Escrever-Log "Lixeira limpa"
}
catch {
    Escrever-Log "Erro na lixeira"
}

# ================================
# TOTAL FINAL
# ================================
$fimExecucao = Get-Date
$tempoExecucao = ($fimExecucao - $inicioExecucao).TotalSeconds

Escrever-Log "TOTAL LIBERADO: $(Converter-Tamanho $totalLiberado)"
Escrever-Log "TEMPO DE EXECUÇÃO: $([math]::Round($tempoExecucao,2)) segundos"
Escrever-Log "=== FIM DA LIMPEZA ==="