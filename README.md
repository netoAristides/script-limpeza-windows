# Windows Cleanup (PowerShell)

Script em PowerShell para limpeza automatizada de arquivos temporários e resíduos do sistema Windows, com geração de logs detalhados.

---

## Sobre o projeto

Este script foi desenvolvido com o objetivo de automatizar a limpeza de arquivos desnecessários no Windows, ajudando a:

* Liberar espaço em disco
* Melhorar desempenho do sistema
* Manter o ambiente organizado
* Facilitar auditoria através de logs

---

## Funcionalidades

✔ Limpeza de arquivos temporários do usuário atual
✔ Limpeza de temporários de todos os usuários do sistema
✔ Limpeza da pasta `C:\Windows\Temp`
✔ Limpeza de arquivos do Windows Update
✔ Limpeza de logs do sistema
✔ Remoção de arquivos de dump (`Minidump` e `MEMORY.DMP`)
✔ Limpeza completa da lixeira (todos os usuários)
✔ Geração de logs detalhados por execução

---

## Estrutura de Logs

Os logs são armazenados automaticamente no diretório:

```
C:\Logs\<NOME-DA-MAQUINA>\
```

Exemplo:

```
C:\Logs\PC-01\limpeza_2026-04-09_10-30.log
```

Cada execução gera um novo arquivo contendo:

* Data e hora das operações
* Itens removidos
* Espaço liberado
* Tempo total de execução

---

## Como funciona

O script percorre diretórios específicos do sistema e remove arquivos com base em critérios definidos, como:

* Idade dos arquivos (`$dias`)
* Localização (Temp, Logs, Update, etc.)
* Permissões do sistema

---

##  Como usar

1. Primeiro pode ser necessário abrir o PowerShell como administrador e executar o script Set-ExecutionPolicy RemoteSigned

2. Execute o PowerShell como Administrador

3. Vá até o diretório onde você salvou, exemplo: cd C:/arquivodelimpeza

4. Rode o script:

```
.\limpeza_total.ps1
```

---

## Agendamento (Opcional)

Recomendado agendar via **Task Scheduler**:

* Frequência diária, ou como preferir
* Ideal ser em horário fora do expediente (ex: 03:00)
* Execução com privilégios elevados

---

## Observações importantes

* O script remove arquivos permanentemente (sem confirmação)
* Certifique-se de revisar antes de usar em ambiente produtivo
* Alguns arquivos podem não ser removidos se estiverem em uso

---

## Diferenciais

- Script seguro com verificação de privilégios administrativos
- Tratamento de erros com try/catch
- Cálculo detalhado de espaço liberado
- Logs organizados por máquina e execução
- Estrutura preparada para automação em ambiente corporativo

---

## Autor

Desenvolvido por **Aristides Evangelista Neto**

---