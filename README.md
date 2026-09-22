# Wildside

**Prototype 0.1 · Godot 4.7.x**

Vertical slice 2D top-down que combina exploração urbana, crime, perseguição e captura de criaturas. O foco desta versão é validar um pequeno loop completo antes de expandir inventário, combate, crafting ou o tamanho do mundo.

## Executar

1. Instale o Godot 4.7.2 ou outra versão compatível da linha 4.7.
2. Importe esta pasta pelo Project Manager.
3. Abra `main.tscn` e pressione **F6/F5**.

## Controles

| Ação | Teclas |
| --- | --- |
| Mover / dirigir | `WASD` ou setas |
| Correr | `Shift` |
| Interagir / entrar / sair | `E` |
| Capturar Wild | `Q` |
| Freio de mão / derrapagem | `Espaço` |

## Vertical slice

O loop de `ANOMALIA #001` é:

1. sair do ponto inicial e conversar com Maya;
2. atender o telefone da praça;
3. pegar o carro e dirigir até a mata ao norte;
4. aproximar-se do Nib e tentar capturá-lo;
5. fugir das viaturas até zerar o nível de procura;
6. voltar para Maya e receber `$250`.

Roubar o veículo gera procura. Atropelar um cidadão também aumenta o heat e faz o NPC fugir. A versão atual implementa os níveis 0–2; os níveis 3–5 ficam para slices posteriores.

## Sistemas implementados

- Movimento com aceleração, desaceleração, corrida, direção visual e estados idle/walk/run.
- Câmera suave com look-ahead e limites compatíveis com a área ampliada.
- Cidade ampliada para 12 quarteirões, três eixos verticais e duas avenidas horizontais.
- Regiões reconhecíveis: Centro de Wildside, Bairro Residencial, Distrito Industrial, Zona Sul e Mata Norte.
- Transição de bairro exibida no HUD ao cruzar de uma região para outra.
- Mais cidadãos e veículos estacionados espalhados pelo mapa.
- Interação local usando `Area2D`, sem varrer todos os objetos da cena a cada frame.
- Veículo com aceleração, ré, freio, derrapagem leve, dano, colisão, som de motor procedural e saída segura.
- NPCs com estados `IDLE`, `WANDER`, `TALK` e `FLEE`.
- Nib com estados `IDLE`, `WANDER`, `FLEE` e `FOLLOW`, chance de captura e acompanhamento do jogador.
- Missão guiada, distância do objetivo, dinheiro e recompensa.
- Heat, estrelas de procura e até duas viaturas em perseguição.
- Gerenciadores globais pequenos para jogo, missões, procura, save e áudio.

## Arquitetura da cena principal

```text
Game
├── World
│   ├── City
│   ├── Wilderness
│   ├── Entities
│   │   ├── NPCs
│   │   ├── Vehicles
│   │   └── Creatures
│   └── Props
├── Player
└── UI
```

A cidade procedural continua útil para esta slice. O crescimento do mapa deve acontecer gradualmente com `TileMapLayer` e cenas modulares, sem reescrever o protótipo inteiro de uma vez.

## Teste automatizado

```powershell
godot --headless --path . --audio-driver Dummy --script res://tests/smoke_test.gd
```

O teste cobre movimento, corrida, roubo e condução do carro, saída segura, procura, aparecimento da polícia, detecção das cinco regiões, interação real com o telefone, captura do Nib e recompensa.

## Critério de conclusão

Esta slice só está pronta quando o loop inteiro pode ser concluído em uma sessão e o smoke test termina com:

```text
VERTICAL SLICE SMOKE TEST: PASS
```

