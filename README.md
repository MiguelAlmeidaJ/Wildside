# Wildside

**Prototype 0.10 · Godot 4.7.x**

Vertical slice 2D top-down que combina exploração urbana, crime, perseguição, captura de criaturas e uma rotina urbana própria entre as missões principais.

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
| Atacar corpo a corpo | `F` |
| Atirar com pistola | `Mouse 1` |
| Recarregar pistola | `R` |
| Habilidade do Nib — Impacto | `1` |
| Habilidade do Volt — Sobrecarga | `2` |
| Capturar Wild | `Q` |
| Mochila | `Tab` |
| Kit médico | `H` |
| Energético | `J` |
| Lanche | `K` |
| Freio de mão / derrapagem | `Espaço` |

## Vertical slice

O loop de `ANOMALIA #001` é:

1. sair do ponto inicial e conversar com Maya;
2. atender o telefone da praça;
3. pegar o carro e dirigir até a mata ao norte;
4. aproximar-se do Nib e tentar capturá-lo;
5. fugir das viaturas até zerar o nível de procura;
6. voltar para Maya e receber `$250`.

Depois de concluir a primeira missão, Maya libera a `ANOMALIA #002`:

1. procurar Bruno no Distrito Industrial;
2. receber a indicação da Oficina Cobalto;
3. comprar um Dispositivo Wild por `$100`;
4. localizar Volt nos galpões;
5. capturá-lo usando o dispositivo;
6. voltar para Bruno e receber `$200`.

Depois da limpeza dos galpões, começa a `ANOMALIA #003 — APAGÃO`:

1. voltar a Bruno e descobrir os mapas de quedas de energia;
2. encontrar Jade no Centro;
3. investigar uma distorção elétrica na Zona Sul;
4. enfrentar uma emboscada com três invasores;
5. encarar Murno como primeiro Wild-boss do jogo;
6. reduzir Murno a 35% de vida e capturá-lo;
7. sobreviver ao pulso anômalo e perder duas estrelas de procura;
8. voltar para Jade e receber `$400`.

Murno é enviado para a reserva depois da captura, mantendo apenas Nib e Volt como companheiros ativos para não poluir a movimentação e as interações.

## Vida urbana

A Prototype 0.9 adiciona um loop fora das anomalias:

- o `Mercado 24H` vende Lanche por `$15`, Kit Médico por `$60` e Energético por `$35`;
- `Tab` abre a mochila e mostra os consumíveis disponíveis;
- Lanche recupera 20 HP, Kit Médico recupera 55 HP e Energético aumenta a velocidade por 10 segundos;
- Rico oferece a atividade repetível `Corrida Noturna`: retirar um pacote no Mercado 24H e entregar para Vera no Residencial por `$120`;
- o apartamento funciona como safehouse: restaura a vida, define o novo ponto de respawn e salva o progresso;
- saves da versão 5 restauram dinheiro, inventário, armas, missão principal, atividade secundária, posição, checkpoint e estado de captura de Nib, Volt e Murno;
- ao iniciar novamente o jogo, um save compatível é carregado automaticamente.

### Atividades livres — Prototype 0.10

A cidade agora também oferece progressão sem depender da campanha:

- Nando organiza uma `Corrida de Rua` repetível na Zona Sul;
- a corrida usa seis checkpoints espalhados pelas avenidas, cronômetro, melhor tempo e contador de vitórias;
- completar uma volta paga `$180`, com bônus de `$50` abaixo de 75s e `$100` abaixo de 55s;
- a `Garagem Cobalto` repara veículos danificados por um valor proporcional ao dano e recupera o Cobalto R perdido/destruído por `$50`;
- a garagem vende o `Cobalto R` por `$350`, o primeiro veículo próprio do jogador;
- entrar no Cobalto R não gera procura por roubo de veículo;
- cinco esconderijos únicos foram espalhados entre Residencial, Centro, Industrial, Zona Sul e Mata Norte;
- esconderijos entregam dinheiro e consumíveis e não podem ser coletados duas vezes;
- mochila mostra o progresso dos esconderijos encontrados;
- HUD passa a exibir integridade do veículo durante a direção e cronômetro/progresso da corrida;
- save version 6 persiste propriedade e durabilidade do carro, esconderijos encontrados, melhor tempo e vitórias;
- saves da Prototype 0.9 (version 5) continuam compatíveis e recebem os novos campos com valores padrão.



Roubar o veículo gera procura. Atropelar um cidadão também aumenta o heat e faz o NPC fugir. A versão atual implementa os níveis 0–2; os níveis 3–5 ficam para slices posteriores.

## Sistemas implementados

- Movimento com aceleração, desaceleração, corrida, direção visual e estados idle/walk/run.
- Câmera suave com look-ahead e limites compatíveis com a área ampliada.
- Cidade ampliada para 12 quarteirões, três eixos verticais e duas avenidas horizontais.
- `Cidade Viva`: prédios ganharam claraboias, entradas, toldos, volumes de telhado e sombras; ruas receberam marcações, estacionamento e bordas mais legíveis.
- Props urbanos distribuídos pelos distritos: postes, bancos, vasos, caçambas, cones, containers, placas de região e letreiros de estabelecimentos.
- Seis carros civis circulam continuamente em rotas pelas avenidas principais.
- Regiões reconhecíveis: Centro de Wildside, Bairro Residencial, Distrito Industrial, Zona Sul e Mata Norte.
- Transição de bairro exibida no HUD ao cruzar de uma região para outra.
- Mais cidadãos e veículos estacionados espalhados pelo mapa.
- População ampliada com Jade, Otto, Vera, Rico, Lia, Celso e novos moradores/trabalhadores espalhados pela cidade.
- Quatro variações visuais de cidadãos evitam que toda a população pareça o mesmo personagem recolorido.
- NPCs recebem variações visuais e falas ambientais espontâneas enquanto caminham ou esperam na rua.
- Interação local usando `Area2D`, sem varrer todos os objetos da cena a cada frame.
- Veículo com aceleração, ré, freio, derrapagem leve, dano, colisão, som de motor procedural e saída segura.
- NPCs com estados `IDLE`, `WANDER`, `TALK` e `FLEE`.
- Nib com estados `IDLE`, `WANDER`, `FLEE` e `FOLLOW`, chance de captura e acompanhamento do jogador.
- Volt como segundo Wild, liberado pela `ANOMALIA #002` e capturado com um Dispositivo Wild.
- Murno como primeiro Wild-boss: 180 HP, comportamento agressivo, estado enfraquecido abaixo de 35% e captura obrigatória na `ANOMALIA #003`.
- Durante o apagão, a cidade recebe uma modulação visual escura/arroxeada e pulsante que desaparece quando a crise termina.
- Oficina Cobalto com compra funcional de dispositivos por `$100`.
- Combate corpo a corpo com `F`, alcance direcional, cooldown e feedback visual.
- Sistema de vida do jogador com 100 HP, breve invulnerabilidade após dano e respawn com penalidade de até `$50`.
- Raiders hostis no Distrito Industrial, liberados após a `ANOMALIA #002`, com perseguição, ataque, vida e recompensa em dinheiro.
- A limpeza dos galpões agora é uma missão rastreada em `0/2`, `1/2` e `2/2`; o segundo Raider conclui automaticamente a missão e paga bônus de `$150`.
- Carros em movimento podem atropelar e causar dano aos Raiders.
- Nib e Volt ajudam automaticamente no combate quando há inimigos próximos.
- Habilidades ativas de Wild: Nib usa `Impacto`, um golpe de alvo único com alto dano e knockback; Volt usa `Sobrecarga`, que encadeia eletricidade entre até três inimigos e aplica stun.
- Cooldowns das habilidades aparecem no HUD e mudam para `PRONTO` quando podem ser usados novamente.
- Companheiros capturados entram em formação atrás/lateral do player e abrem espaço automaticamente perto de NPCs e outros pontos de interação.
- Sistema de prioridade de interação: NPCs, objetivos, telefone e oficina vencem os Wilds no `E`, mesmo quando Nib ou Volt estão mais próximos.
- Oficina Cobalto passa a vender uma pistola por `$150` após a ANOMALIA #002; ela vem com 8 munições no pente e 24 na reserva.
- Pistola com tiro hitscan pelo mouse, dano, cooldown, traçante visual, pente, reserva e recarga no `R`.
- Depois da compra da pistola, a Cobalto vende pacotes de 16 munições por `$40`.
- Estado da pistola e munição passa a ser persistido no save.
- Disparos agora emitem ruído no mundo: civis próximos fogem e Raiders investigam a origem mesmo antes de enxergar o player.
- Civis que escutam um disparo fogem e reportam o crime, gerando procura e ativando a polícia; uma rajada curta usa cooldown para não somar heat em toda bala.
- Sem testemunha próxima, o tiro ainda atrai inimigos, mas a polícia não recebe informação magicamente.
- Inventário simples de Dispositivos Wild exibido no HUD e persistido no save.
- Missão guiada, distância do objetivo, dinheiro e recompensa.
- Heat, estrelas de procura e até duas viaturas em perseguição.
- Perseguição agora distingue `VISTO` e `ESCAPANDO`: o heat não cai enquanto uma unidade mantém contato e passa a cair mais rápido depois que você quebra a perseguição.
- Viaturas não se teleportam continuamente durante a fuga; é possível abrir distância de verdade.
- Ao alcançar o jogador a pé, a viatura pode parar e desembarcar um policial que persegue e inicia uma barra de prisão.
- Se a barra de prisão completar, a procura zera, o player volta ao ponto inicial e paga até `$75` de fiança.
- Trocar para um veículo diferente durante a fuga reduz `15` de heat, com cooldown para impedir abuso.
- Gerenciadores globais pequenos para jogo, missões, atividade secundária, procura, save e áudio.
- Inventário funcional de consumíveis com mochila visual e atalhos de uso.
- Mercado 24H com interface de compra própria.
- Corrida Noturna como primeira atividade secundária repetível com objetivo separado da missão principal.
- Apartamento como safehouse funcional para cura, checkpoint, save e retomada automática da sessão.
- Corrida de Rua com largada, seis checkpoints sequenciais, cronômetro, bônus por tempo e recorde persistente.
- Garagem Cobalto com reparo de veículos e compra de um carro próprio legalizado.
- Cobalto R como primeiro veículo permanente que não gera procura ao entrar.
- Cinco esconderijos persistentes recompensam exploração livre com dinheiro e consumíveis.
- HUD de integridade do veículo, progresso de exploração e atividade de corrida.

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

O teste cobre movimento, direção, trânsito civil, população, Mercado 24H, mochila, consumíveis, Corrida Noturna, Corrida de Rua, garagem, carro próprio, reparos, esconderijos, safehouse/save, persistência dos recordes e exploração, procura, polícia, regiões, as três anomalias, boss Murno, economia, Wilds, armas, combate, habilidades, recompensas e respawn.

## Critério de conclusão

Esta slice só está pronta quando o loop inteiro pode ser concluído em uma sessão e o smoke test termina com:

```text
VERTICAL SLICE SMOKE TEST: PASS
```

