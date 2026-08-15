# dControl Enhanced - notas tecnicas

## Arquitetura

- dControl-Enhanced.ps1: ponto de entrada compativel.
- dControl-Enhanced.Core.ps1: implementacao validada para PowerShell 5.1.
- dcontrol/dControl.exe: interface original da Sordum.
- dcontrol-enhanced-state.json: snapshot criado somente durante a desativacao.

## Fluxo de desativacao

1. Exige elevacao.
2. Consulta Tamper Protection. Estado desconhecido ou ativo interrompe o fluxo.
3. Abre o dControl e aguarda o fechamento da interface.
4. Confirma que o Defender ficou desabilitado.
5. Salva os valores originais do Registro.
6. Aplica cinco politicas extras. Falha provoca rollback.

## Fluxo de ativacao

1. Exige elevacao.
2. Restaura exatamente os valores salvos no snapshot.
3. Abre o dControl para a ativacao.
4. Confirma que o Defender ficou ativo.

## Status

O modo status e somente leitura. Ele mostra o estado operacional, Tamper
Protection, existencia do snapshot e estado/tipo de inicio de servicos relevantes.

## Decisoes de seguranca

- Nenhum binario protegido do Windows e renomeado.
- Tamper Protection nao e alterado diretamente no Registro.
- Erros nao sao convertidos em estado seguro.
- Os launchers propagam o codigo de saida do PowerShell.
- Valores preexistentes sao preservados em vez de substituidos por defaults fixos.

## Limitacoes

O dControl continua sendo interativo. Politicas legadas podem ser ignoradas pelo
Windows atual e por dispositivos gerenciados.

Desabilitar o antivirus reduz significativamente a seguranca do computador.
