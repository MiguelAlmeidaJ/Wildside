# Project Anomaly

Protótipo 2D top-down em Godot 4. A meta desta versão é validar o núcleo de exploração antes de adicionar combate, criaturas ou sistemas de mundo aberto.

## Executar

1. Abra esta pasta no Godot 4.3 ou mais recente.
2. Aguarde a importação dos SVGs.
3. Pressione **F6/F5** para executar `main.tscn`.

Para uma checagem automatizada, execute no terminal:

```powershell
godot --headless --path . --script res://tests/smoke_test.gd
```

## Controles

| Ação | Teclas |
| --- | --- |
| Andar / dirigir | `WASD` ou setas |
| Interagir / entrar / sair | `E` |

## Conteúdo jogável

- movimento do personagem em oito direções;
- câmera suave com limites da cidade;
- quatro quarteirões, avenidas, calçadas, obstáculos e colisões;
- dois NPCs e um telefone interativo;
- carro com aceleração, ré, direção, colisão e câmera própria.

## Critério para encerrar a Fase 1

O protótipo só avança quando for possível iniciar o jogo, circular a pé pela cidade, colidir corretamente com o cenário, interagir com os três tipos de alvo e completar um circuito de carro entrando e saindo do veículo sem travamentos.

## Próximas fases

1. Movimento — implementado
2. Cidade — protótipo implementado
3. Interações — base implementada
4. Carros — primeiro veículo implementado
5. NPCs
6. Combate
7. Criaturas
8. Captura
9. Inventário
10. Itens
11. Polícia
12. Missões
13. Dinheiro
14. Base
15. Crafting
16. Save
17. Mundo maior
18. Multiplayer

Cada fase deve terminar em uma build jogável antes da próxima começar.
