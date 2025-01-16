@echo off

:: Este script foi criado por mim, Nelson Pereira, aluno da UMa, nº de aluno 2084923, curso LEI
:: O objetivo deste script é provar que é sim possível usar o Xilinx 14.7 no Windows 10, 10 + WSL (há uma diferença) e 11
:: Chega de máquinas virtuais, o meu PC é fraquinho hahahaha :)
:: O Xilinx funciona normalmente no Windows 10 com um fix mais simples, mas quando existe a presença do WSL aí dá problemas maiores
:: As dlls modificadas são crédito do utilizador czietz
:: Fonte das dlls e o que foi modificado nelas: https://www.exxosforum.co.uk/forum/viewtopic.php?p=95884#p95884

:: Verificar se o script está a ser executado como administrador
:: Usa um comando que só funciona como administrador (fltmc) para validar
fltmc >nul 2>&1
if errorlevel 1 (
    echo Este script necessita de ser executado como administrador.
    pause
    exit /b
)

:: Definir o diretório de trabalho para o local do script
cd /d "%~dp0"

:: Perguntar ao utilizador para executar o instalador xsetup.exe
echo Por favor, execute o instalador (xsetup.exe) do Xilinx 14.7 e prossiga com a instalacao normalmente.
:: O script aguarda ate que o instalador inicie o processo xwebtalk.exe.

:: Esperar pelo processo xsetup.exe ser iniciado
:start_wait_xsetup
tasklist /FI "IMAGENAME eq xsetup.exe" 2>NUL | find /I "xsetup.exe" > NUL
if errorlevel 1 (
    echo O processo xsetup.exe nao foi encontrado. Verifique se o instalador do Xilinx foi iniciado.
    pause
    exit /b
)

:: Agora que o xsetup.exe está em execução, vamos aguardar pelo xwebtalk.exe
echo O processo xsetup.exe foi iniciado.
echo Aguardando o processo xwebtalk.exe (inicia +- nos 91)...

:start_wait_xwebtalk
tasklist /FI "IMAGENAME eq xwebtalk.exe" 2>NUL | find /I "xwebtalk.exe" > NUL
if errorlevel 1 (
    :: O processo xwebtalk.exe ainda nao foi iniciado, aguarda mais 10 segundos
    timeout /t 10 /nobreak > NUL
    goto start_wait_xwebtalk
)

:: O processo xwebtalk.exe foi encontrado, vamos terminar ele
echo O processo xwebtalk.exe foi detetado. Terminando o processo...

taskkill /F /IM xwebtalk.exe > NUL 2>&1
echo Processo xwebtalk.exe terminado com sucesso.

:: Verificar se o processo xwebtalk.exe ainda está em execução, se sim, terminar novamente
:start_process_check
tasklist /FI "IMAGENAME eq xwebtalk.exe" 2>NUL | find /I "xwebtalk.exe" > NUL
if not errorlevel 1 (
    taskkill /F /IM xwebtalk.exe > NUL 2>&1
    timeout /t 1 /nobreak > NUL
    goto start_process_check
)

:: Terminar processos do Xilinx se estiverem a correr tipo o gestor de licenças, ISE, etc...
echo A terminar processos xlcm.exe, _xlcm.exe, _pn.exe, ise.exe, isimgui.exe...
taskkill /f /im xlcm.exe >nul 2>&1
taskkill /f /im _xlcm.exe >nul 2>&1
taskkill /f /im _pn.exe >nul 2>&1
taskkill /f /im ise.exe >nul 2>&1
taskkill /f /im isimgui.exe >nul 2>&1

:: Após o xwebtalk.exe ser fechado, continua com o resto do script
:: Adicionar a variável de utilizador XILINX_VC_CHECK_NOOP com valor 1
:: Esta variável desativa os avisos relacionados com a ausência dos runtimes C++ 2008
echo A desativar os avisos relacionados com a ausencia dos runtimes C++ 2008...
setx XILINX_VC_CHECK_NOOP 1

:: Caminhos de origem dos ficheiros (ajustado para a estrutura da pasta onde está localizado o .bat)
set "source_nt=.\nt\libPortability.dll"
set "source_nt64=.\nt64\libPortability.dll"

:: Verifica se as pastas que contêm as dlls modificadas existem (nt = 32 bits; nt64 = 64 bits)
if not exist ".\nt" (
    echo A pasta .\nt nao foi encontrada.
    pause
    exit /b
)

if not exist ".\nt64" (
    echo A pasta .\nt64 nao foi encontrada.
    pause
    exit /b
)

:: Verifica se os ficheiros de origem existem
if not exist "%source_nt%" (
    echo O ficheiro %source_nt% nao foi encontrado.
    pause
    exit /b
)

if not exist "%source_nt64%" (
    echo O ficheiro %source_nt64% nao foi encontrado.
    pause
    exit /b
)

:: Loop de verificação para garantir que os processos foram fechados antes de copiar os ficheiros
echo Verificando se os processos Xilinx foram terminados corretamente antes de copiar os ficheiros...
:copy_loop
set "copied=0"

:: Copiar as dlls modificadas para os diretorios nt e nt64...
echo Copiando as dlls modificadas para os diretorios nt e nt64...

copy "%source_nt%" "C:\Xilinx\14.7\ISE_DS\.xinstall\bin\nt\libPortability.dll" /y
copy "%source_nt%" "C:\Xilinx\14.7\ISE_DS\common\lib\nt\libPortability.dll" /y
copy "%source_nt%" "C:\Xilinx\14.7\ISE_DS\EDK\lib\nt\libPortability.dll" /y

:: Verifica se este diretório de destino em específico existe, se não, cria-o
if not exist "C:\Xilinx\14.7\ISE_DS\EDK\lib\nt\sdk" (
    mkdir "C:\Xilinx\14.7\ISE_DS\EDK\lib\nt\sdk"
)

:: Copia o ficheiro para o diretório de destino específico
copy "%source_nt%" "C:\Xilinx\14.7\ISE_DS\EDK\lib\nt\sdk\libPortability.dll" /y

copy "%source_nt%" "C:\Xilinx\14.7\ISE_DS\ISE\sysgen\bin\nt\libPortability.dll" /y
copy "%source_nt%" "C:\Xilinx\14.7\ISE_DS\ISE\lib\nt\libPortability.dll" /y

copy "%source_nt64%" "C:\Xilinx\14.7\ISE_DS\.xinstall\bin\nt64\libPortability.dll" /y
copy "%source_nt64%" "C:\Xilinx\14.7\ISE_DS\common\lib\nt64\libPortability.dll" /y
copy "%source_nt64%" "C:\Xilinx\14.7\ISE_DS\EDK\lib\nt64\libPortability.dll" /y
copy "%source_nt64%" "C:\Xilinx\14.7\ISE_DS\EDK\lib\nt64\sdk\libPortability.dll" /y
copy "%source_nt64%" "C:\Xilinx\14.7\ISE_DS\ISE\sysgen\bin\nt64\libPortability.dll" /y
copy "%source_nt64%" "C:\Xilinx\14.7\ISE_DS\ISE\lib\nt64\libPortability.dll" /y

:: Estes 2 caminhos são os responsáveis pela parte das simulações, se estes 2 caminhos não forem modificados as simulações não arrancam corretamente
copy "%source_nt%" "C:\Xilinx\14.7\ISE_DS\ISE\lib\nt\libPortabilityNOSH.dll" /y
copy "%source_nt64%" "C:\Xilinx\14.7\ISE_DS\ISE\lib\nt64\libPortabilityNOSH.dll" /y

if errorlevel 1 (
    echo Falha ao copiar as dlls para os diretorios.
) else (
    set "copied=1"
	echo Correcao concluida. Ja pode encerrar o terminal.
)

:: Verificar se algum ficheiro foi copiado com sucesso
if %copied%==0 (
    echo Erro ao copiar ficheiros. Tentando novamente...
    timeout /t 5 /nobreak > NUL
    :: Terminar processos e tentar copiar novamente
    taskkill /f /im xlcm.exe >nul 2>&1
    taskkill /f /im _xlcm.exe >nul 2>&1
    taskkill /f /im _pn.exe >nul 2>&1
    taskkill /f /im ise.exe >nul 2>&1
    taskkill /f /im isimgui.exe >nul 2>&1
    goto copy_loop
)
pause
