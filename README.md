# dControl Enhanced

Wrapper revisado para testar, desabilitar e reativar o Microsoft Defender com
validacao de estado, propagacao de erros e rollback das politicas extras.

## Aviso

Desabilitar o antivirus reduz significativamente a seguranca do computador.
Use apenas em maquina virtual descartavel, crie um snapshot antes do teste e
nao utilize em equipamento de producao.

## Melhorias desta revisao

- Compatibilidade com Windows PowerShell 5.1.
- Estado desconhecido de Tamper Protection interrompe operacoes perigosas.
- Snapshot dos valores originais do Registro antes da desativacao.
- Rollback automatico quando uma gravacao falha.
- Restauracao dos valores preexistentes em vez de defaults fixos.
- Nenhum executavel protegido do Windows e renomeado.
- Launchers BAT propagam corretamente os codigos de erro.
- Testes estaticos de sintaxe, caminhos, seguranca e integridade.

## Uso

Execute primeiro:

    TESTAR-PACOTE.bat
    VERIFICAR-STATUS-DEFENDER.bat

Leia COMO-USAR.txt antes de executar qualquer alteracao. Os fluxos de ativacao e
desativacao exigem uma sessao elevada de Administrador e confirmacao na interface
do dControl.

## Windows Server

Windows Server pode nao disponibilizar Tamper Protection. Nesse caso, o pacote
mostra o estado como Unknown e interrompe a desativacao por seguranca. O
comportamento nao representa necessariamente Windows 10 ou Windows 11.

## Executavel de terceiro

data/dcontrol/dControl.exe e o Defender Control 2.1, distribuido pela Sordum.
O executavel nao possui assinatura Authenticode.

SHA-256:

    1EF6C1A4DFDC39B63BFE650CA81AB89510DE6C0D3D7C608AC5BE80033E559326

O hash coincide com o publicado pelo fornecedor. Consulte
data/dcontrol/ReadMe.txt para informacoes da distribuicao original.

## Documentacao

- COMO-USAR.txt: procedimento operacional.
- LEIA-ME.txt: seguranca, recuperacao e compatibilidade.
- data/README-ENHANCED.md: arquitetura e detalhes tecnicos.
- tests/Test-Package.ps1: validacao estatica nao destrutiva.
