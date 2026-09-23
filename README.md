# Wildside

**Prototype 0.14 · Godot 4.7.x**

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
| Habilidade do Murno — Eclipse | `3` |
| Capturar Wild | `Q` |
| Mochila | `Tab` |
| Mostrar / ocultar minimapa | `M` |
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

Murno entra na coleção depois da captura. A equipe ativa comporta no máximo 2 Wilds; o Terminal Wild no apartamento permite alternar Nib, Volt e Murno entre equipe e reserva.

Depois da estabilização da Zona Sul, Jade libera a **ANOMALIA #004 — Sinal do Cais**:

1. falar novamente com Jade e receber a pista do Porto Ferrugem;
2. encontrar Cora entre os armazéns;
3. investigar o relé anômalo no extremo leste do cais;
4. enfrentar três Raiders que fecham o píer;
5. acessar novamente o relé e retirar o núcleo de transmissão;
6. retornar para Cora;
7. receber `$500` e um Dispositivo Wild extra.

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


### Cidade reativa — Prototype 0.11

Wildside agora muda e reage mesmo quando o jogador não está executando uma missão:

- relógio global contínuo com dia, entardecer, noite e amanhecer;
- um dia completo dura aproximadamente 12 minutos reais na configuração atual;
- iluminação geral acompanha o horário e os postes urbanos acendem progressivamente ao anoitecer;
- o apagão da ANOMALIA #003 agora se mistura ao horário real do mundo em vez de substituir a iluminação;
- eventos urbanos surgem espontaneamente enquanto o jogador explora sem procura ativa;
- `Carga Perdida` cria uma caixa temporária com dinheiro e um consumível;
- `Confronto nas Ruas` cria dois Raiders independentes das missões e paga recompensas individuais mais um bônus de `$150`;
- eventos concluídos entram em um contador persistente;
- a procura foi expandida de 2 para 5 estrelas;
- 3 estrelas ativam uma terceira unidade e o estado `CERCO ATIVO`;
- 4 estrelas liberam resposta tática mais rápida e fiança de até `$160`;
- 5 estrelas ativam cinco viaturas, agentes mais rápidos, prisão acelerada e fiança de até `$200`;
- a perda de heat fica progressivamente mais lenta nos níveis altos;
- trocar de veículo ainda ajuda na fuga, mas reduz menos heat em 4–5 estrelas;
- save version 7 persiste horário, dia e histórico de eventos, mantendo compatibilidade com saves 5 e 6.


### Navegação — Prototype 0.12

- corrige o erro de parser do Godot 4.7.2 no bloqueio de eventos durante etapas críticas;
- adiciona minimapa norte-fixo no canto inferior esquerdo;
- o minimapa representa Mata Norte, bairros, avenidas e principais pontos de serviço;
- marcador branco acompanha o jogador ou o veículo dirigido;
- objetivo principal aparece em ciano, atividade secundária em laranja e evento urbano em rosa;
- corrida de rua mostra largada ou próximo checkpoint diretamente no minimapa;
- viaturas e policiais aparecem em vermelho quando há procura;
- o Cobalto R aparece no mapa quando está estacionado e já pertence ao jogador;
- `M` mostra ou oculta o minimapa.



### Equipe Wild — Prototype 0.13

- adiciona uma coleção persistente de Wilds capturados;
- limita a equipe ativa a 2 companheiros para evitar poluição visual e bloqueios de interação;
- adiciona um Terminal Wild ao lado do apartamento;
- no terminal, `1`, `2` e `3` alternam Nib, Volt e Murno entre equipe ativa e reserva;
- Wilds na reserva ficam ocultos e deixam de disputar foco de interação;
- Nib e Volt passam a ocupar posições de formação conforme o slot atual da equipe;
- Murno agora pode sair da reserva e acompanhar o jogador;
- Murno ganha a habilidade ativa `Eclipse` no `3`, causando dano em área e stun;
- mochila mostra a formação ativa;
- abrir mochila ou Terminal Wild limpa temporariamente os painéis de missão, evento e minimapa para reduzir a sobreposição do HUD;
- save version 8 persiste coleção e formação ativa, mantendo compatibilidade com saves anteriores.


### Expansão do Porto — Prototype 0.14

- o limite leste da cidade cresce de `x=1800` para `x=3000` e o limite sul passa a `y=2200`;
- nasce o distrito `PORTO FERRUGEM`, com armazéns, vias próprias, píer, faixa d'água, guindastes, contêineres, postes e equipamentos portuários;
- o minimapa e a câmera passam a cobrir toda a nova área;
- duas novas rotas de tráfego ocupam a expansão e um veículo estacionado aparece no porto;
- a população cresce com Cora, Malik, Dante, Noemi, Ravi, Helena, Rui e Bia;
- `ANOMALIA #004 — Sinal do Cais` continua diretamente a trama das anomalias depois de Murno;
- três Raiders exclusivos defendem o relé do cais;
- a missão recompensa `$500` e um Dispositivo Wild extra;
- Malik oferece a atividade repetível `Frete do Cais`: buscar um manifesto com Dante e retornar por `$160`;
- eventos urbanos agora também podem surgir no Porto Ferrugem;
- save version 9 persiste o progresso de combate da ANOMALIA #004 e continua aceitando saves anteriores.


Roubar veículo, atropelar cidadãos e crimes reportados alimentam uma escala completa de 0–5 estrelas. Quanto maior a procura, maior a presença policial, mais difícil é quebrar contato e maior a fiança em caso de prisão.

## Sistemas implementados

- Movimento com aceleração, desaceleração, corrida, direção visual e estados idle/walk/run.
- Câmera suave com look-ahead e limites compatíveis com a área ampliada.
- Cidade ampliada para 18 quarteirões, quatro eixos verticais, duas avenidas principais e uma via de cais.
- `Cidade Viva`: prédios ganharam claraboias, entradas, toldos, volumes de telhado e sombras; ruas receberam marcações, estacionamento e bordas mais legíveis.
- Props urbanos distribuídos pelos distritos: postes, bancos, vasos, caçambas, cones, containers, placas de região e letreiros de estabelecimentos.
- Oito carros civis circulam continuamente em rotas pelas avenidas principais e pelo Porto Ferrugem.
- Regiões reconhecíveis: Centro de Wildside, Bairro Residencial, Distrito Industrial, Zona Sul, Mata Norte e Porto Ferrugem.
- Transição de bairro exibida no HUD ao cruzar de uma região para outra.
- Mais cidadãos e veículos estacionados espalhados pelo mapa, incluindo uma população portuária própria.
- População ampliada com Jade, Otto, Vera, Rico, Lia, Celso, Cora, Malik, Dante, Noemi, Ravi, Helena, Rui, Bia e outros moradores/trabalhadores.
- Quatro variações visuais de cidadãos evitam que toda a população pareça o mesmo personagem recolorido.
- NPCs recebem variações visuais e falas ambientais espontâneas enquanto caminham ou esperam na rua.
- Interação local usando `Area2D`, sem varrer todos os objetos da cena a cada frame.
- Veículo com aceleração, ré, freio, derrapagem leve, dano, colisão, som de motor procedural e saída segura.
- NPCs com estados `IDLE`, `WANDER`, `TALK` e `FLEE`.
- Nib com estados `IDLE`, `WANDER`, `FLEE` e `FOLLOW`, chance de captura e acompanhamento do jogador.
- Volt como segundo Wild, liberado pela `ANOMALIA #002` e capturado com um Dispositivo Wild.
- Murno como primeiro Wild-boss: 180 HP, comportamento agressivo, estado enfraquecido abaixo de 35%, captura obrigatória na `ANOMALIA #003` e uso posterior como companheiro de reserva.
- Durante o apagão, a cidade recebe uma modulação visual escura/arroxeada e pulsante que desaparece quando a crise termina.
- Oficina Cobalto com compra funcional de dispositivos por `$100`.
- Combate corpo a corpo com `F`, alcance direcional, cooldown e feedback visual.
- Sistema de vida do jogador com 100 HP, breve invulnerabilidade após dano e respawn com penalidade de até `$50`.
- Raiders hostis no Distrito Industrial, liberados após a `ANOMALIA #002`, com perseguição, ataque, vida e recompensa em dinheiro.
- A limpeza dos galpões agora é uma missão rastreada em `0/2`, `1/2` e `2/2`; o segundo Raider conclui automaticamente a missão e paga bônus de `$150`.
- Carros em movimento podem atropelar e causar dano aos Raiders.
- Nib e Volt ajudam automaticamente no combate quando há inimigos próximos.
- Habilidades ativas de Wild: Nib usa `Impacto`, Volt usa `Sobrecarga` e Murno usa `Eclipse`, um pulso em área com dano e stun.
- Cooldowns das habilidades aparecem no HUD e mudam para `PRONTO` quando podem ser usados novamente.
- Até dois companheiros capturados entram em formação atrás/lateral do player e abrem espaço automaticamente perto de NPCs e outros pontos de interação; os demais permanecem na reserva.
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
- Ciclo contínuo de dia/noite com relógio, fases visuais e postes que respondem ao horário.
- Eventos urbanos dinâmicos de carga perdida e confronto com Raiders, independentes da campanha e agora distribuídos também pelo porto.
- Sistema de procura completo de 0–5 estrelas com cinco viaturas escalonadas e agentes mais agressivos nos níveis altos.
- Minimapa funcional com posição do jogador, serviços, objetivos, corrida, eventos urbanos, carro próprio, polícia e toda a expansão portuária.
- Terminal Wild com coleção persistente, equipe ativa de 2 slots e troca entre Nib, Volt e Murno.
- Porto Ferrugem com nova malha viária, população, tráfego, ANOMALIA #004 e Frete do Cais repetível.

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

O teste cobre movimento, direção, trânsito civil, população, Mercado 24H, mochila, consumíveis, minimapa e rastreamento de objetivos, Corrida Noturna, Frete do Cais, Corrida de Rua, garagem, carro próprio, reparos, esconderijos, ciclo dia/noite, eventos urbanos, procura 0–5 estrelas, resposta policial escalonada, Terminal Wild, formação de equipe, Murno como companheiro, Porto Ferrugem, safehouse/save, persistência de relógio/eventos/recordes/exploração/equipe, regiões, as quatro anomalias, economia, Wilds, armas, combate, habilidades, recompensas e respawn.

## Critério de conclusão

Esta slice só está pronta quando o loop inteiro pode ser concluído em uma sessão e o smoke test termina com:

```text
VERTICAL SLICE SMOKE TEST: PASS
```

