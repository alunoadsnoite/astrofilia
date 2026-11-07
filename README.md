# Astrofilia 🚀

Jogo de aventura e sobrevivência espacial em **3D**, feito com **Godot 4.7** e exportável para **Android**.

**Versão do código: 0.4.0** — multiplayer online por IP (host e cliente), interior da nave como cenário separado, cobras noturnas, joystick analógico de 360° e otimização para Android.

APK mais recente:

[![Release](https://img.shields.io/badge/release-v0.4.0-brightgreen)](https://github.com/alunoadsnoite/astrofilia/releases/tag/v0.4.0)

[⬇️ Baixar Astrofilia.apk (v0.4.0)](https://github.com/alunoadsnoite/astrofilia/releases/download/v0.4.0/Astrofilia.apk)

## 📖 História

Um astronauta pousa em um planeta desconhecido. O capítulo 1 é um tutorial em que ele coleta minerais e plantas. Ao voltar para a nave, encontra o interior silencioso, o console sem energia e a robô **ARIA**, que acompanha as missões. Ele precisa sobreviver aos perigos do planeta (animais, comida venenosa e o clima local), dormir no beliche durante a noite e reunir recursos para reativar o console e voltar para casa.

## 🌍 Biomas

- 🏜️ Deserto rochoso
- 🌲 Floresta
- ❄️ Nevado

## 🎮 Modos de jogo

- **Singleplayer**: você é Coletor e Biólogo ao mesmo tempo.
- **Multijogador local**: escolha sua função (Coletor ou Biólogo) no mesmo dispositivo.
- **Multijogador online por IP**: até 4 jogadores em rede, com host e clientes (veja a seção abaixo).

## 🌐 Multiplayer online por IP

O host é a autoridade da sessão e compartilha o mundo com os convidados:

- A **seed do planeta** é escolhida pelo host e enviada aos clientes, então recursos, lagos, nave e cobras ficam nas mesmas posições.
- **Avatares remotos** usam o mesmo astronauta, com nome flutuante e a aparência escolhida por cada jogador.
- **Itens são compartilhados**: quando alguém coleta, o recurso some para todos e reaparece após 12 segundos.
- **Cobras** são simuladas pelo host e replicadas com posição, vida e visibilidade; o dano de clientes é validado pelo host.
- Cada jogador conclui as próprias missões da sua função, com NV/EXP e conquistas locais.
- Entrar e sair da nave é individual: o avatar remoto fica oculto quando o outro jogador está em outro cenário.
- Sessões online **não gravam nos slots locais**; ao sair, o progresso online é encerrado.

**Como hospedar**

1. No menu, abra **Jogar → Jogar online (IP)**.
2. Informe seu nome, escolha a função e toque em **Criar sala (host)**.
3. Compartilhe seu IP e a porta (padrão **7911/UDP**) com os outros jogadores.

**Como entrar**

1. Abra **Jogar → Jogar online (IP)**.
2. Informe o nome, a função, o **IP do host** e a porta.
3. Toque em **Entrar na sala**. A conexão tem tempo limite de 8 segundos.

Na mesma rede, use o IP local do host (por exemplo `192.168.0.10`). Pela internet, o host precisa liberar/encaminhar a porta UDP no roteador. Não há matchmaking nem travessia de NAT: a conexão é direta por IP. Todos devem usar a mesma versão do jogo.

**Limitações da v1 online**

- Máximo de 4 jogadores por sala.
- A IA de animais e do clima continua local em cada cliente; pequenas diferenças visuais são esperadas.
- As cobras perseguem o jogador do host; clientes podem atacá-las e recebem o crédito da derrota.
- Não há reconexão automática: se o host fechar a sala, os clientes voltam ao menu.

### ⛏️ Coletor
- Facão para coletar plantas
- Picareta para coletar pedras e minerais

### 🔬 Biólogo
- Câmera especial para fotografar e obter informações sobre plantas, frutas, vegetais e animais

## ✨ Funcionalidades

- Introdução: o planeta gira lentamente sob as estrelas, sem astronauta caindo no vazio
- Caixa de texto vermelha no topo com missões sequenciais (8 do Coletor + 8 do Biólogo)
- Missões alternadas no singleplayer e por função no multiplayer
- Missão final: "Virem juntos para casa! Ativem o console da nave" / "Volte para casa! Ative o console da nave"
- **Interior da nave como cenário separado**: ao subir a rampa, o jogo carrega uma sala própria (console, ARIA, beliche, janelas e escotilha); sair pela escotilha recarrega o planeta no ponto da rampa
- **ARIA, a robô de missões**: dentro da nave, conversa com o jogador, apresenta a missão atual, o progresso e dicas; também aponta o console quando tudo for concluído
- **Cobras noturnas na floresta**: aparecem só à noite, dão o bote quando o jogador se aproxima, podem ser atacadas e derrotadas, e reaparecem depois
- **Beliche de duas camas**: dentro da nave, permite dormir à noite, avançar até o amanhecer, recuperar vida e iniciar um novo dia
- **Desfecho narrativo**: ao concluir as 16 missões, ative o console no fundo da nave para ver a tela final com nível, pontos, recursos e missões concluídas; escolha **Continuar explorando** ou voltar ao **Menu principal**
- **Capítulos**: aviso central de 3 segundos ("CAPÍTULO 1", "CAPÍTULO 2"...) ao avançar o progresso, com bônus de XP
- **Nível (NV) e Experiência (EXP)**: barra na HUD, XP por coleta/missão/capítulo e cura parcial ao subir de nível
- HUD com vida, fome, sede, pontuação e inventário, com porcentagens e alertas coloridos
- **Vida, fome e sede**: o astronauta perde vida com ataques de animais e com fome/sede zeradas; dormir e subir de nível recuperam vida
- Coleta de itens com feedback visual e efeitos sonoros de interface e de jogo (clique, coleta, missão, nível, capítulo e água)
- **Fome e sede**: decaimento contínuo influenciado pelo clima, avisos de nível baixo, dano ao chegar a zero e bônus ao comer fruta/carne, beber no lago ou consumir plantas
- Ciclo dia/noite com sol em órbita, luz da lua, estrelas, contador de dias e clima dinâmico (limpo, chuva, neve e tempestade de areia com partículas próprias)
- HUD de ciclos mostra **Dia N**, horário, ícone do clima e nome do clima atual
- **Biomas com transição suave**: um único terreno com shader mistura deserto, floresta e nevado, sem emendas
- **Animais em movimento e combate**: as criaturas patrulham ao redor do ponto onde nascem, viram-se para a direção do movimento e não entram no lago nem na nave
- **Combate com animais**: use **E / AÇÃO** para atacar; criaturas agressivas revidam e perseguem o jogador, criaturas ariscas (ou feridas) fogem. Ao perder a vida, a criatura vira carne e reaparece depois
- **Limite de gravidade**: paredes invisíveis contornam a área jogável e, se o astronauta escapar, a gravidade do planeta o traz de volta
- **Nave explorável**: a nave pousou sobre uma plataforma iluminada no deserto; suba pela rampa para entrar no interior, com console de voo e iluminação própria — o console só responde quando todas as missões forem concluídas
- **Lago intransponível**: a água bloqueia a passagem e só pode ser contornada pelas margens
- Gráficos detalhados: cactos, cogumelos, arbustos, pinheiros, cristais de gelo, lago com água animada, margem e vitórias-régias
- **Céu espacial**: planeta gigante com anéis, lua distante, estrelas, sol em órbita e névoa atmosférica
- Pausa, Game Over e reinício
- Conquistas (incluindo **Voltou para casa**) e salvamento automático
- Controles por teclado e touch: **joystick analógico de 360°** com velocidade proporcional à inclinação, além dos botões de pular e ação
- **Otimização para Android**: sombras de cenário desligadas, menos props, partículas e estrelas, terreno com menos subdivisões e escala 3D reduzida — sem mudar o visual no desktop
- **Multiplayer online por IP (ENet)**: host autoritativo, até 4 jogadores, seed compartilhada, avatares com nome, itens e cobras sincronizados
- Menu com 2 slots de save, idioma (PT/EN/ES), aparência, volumes e modo de jogo
- Salvamento avançado com JSON (placeholders, progresso e cooldown de itens)
- Ícone do aplicativo: foguete com o nome **Astrofilia**

## 📁 Estrutura

```
Astrofilia/
├── project.godot
├── export_presets.cfg
├── scenes/
│   ├── MainMenu.tscn
│   ├── Cutscene.tscn
│   ├── Gameplay.tscn
│   ├── Player.tscn
│   └── Item.tscn
├── scripts/
│   ├── GameManager.gd   (autoload)
│   ├── Sfx.gd           (autoload de efeitos sonoros)
│   ├── Net.gd           (autoload de rede ENet)
│   ├── MainMenu.gd
│   ├── Cutscene.gd
│   ├── Gameplay.gd
│   ├── Player.gd
│   ├── ItemColetavel.gd
│   └── Snake.gd
└── assets/
    ├── environment.tres
    ├── biome_ground.gdshader
    ├── water.gdshader
    ├── planet_shader.gdshader
    ├── audio/
    │   └── *.wav
    └── sprites/
        ├── icon.png
        ├── icon_192.png
        ├── icon_adaptive_fg.png
        └── icon_adaptive_bg.png
```

## ▶️ Como rodar

1. Instale o **Godot 4.7+**.
2. Abra `project.godot` no editor.
3. Pressione **F5**.

## 📱 Exportar para Android

```bash
export ANDROID_HOME="$HOME/Android/Sdk"
export JAVA_HOME="$HOME/development/jdks/temurin-17"
godot --headless --path . --export-debug "Astrofilia" build/Astrofilia.apk
```

O APK de depuração é gerado em `build/Astrofilia.apk`.

## 🕹️ Controles

| Ação | Teclado | Touch |
|------|---------|-------|
| Mover | WASD / Setas | Joystick analógico (360°) |
| Pular | Espaço | Botão ⬆ |
| Coletar / analisar / beber / atacar | E, próximo ao alvo | Botão ✋ |
| Falar com ARIA / dormir / sair da nave | E, dentro da nave | Botão ✋ |
| Pausar | — | Botão ⏸ |

## 📄 Licença

MIT — veja [LICENSE](LICENSE).

## Ajustes de jogabilidade e visual

- Iluminação diurna neutra e noite azulada, com sol em órbita, lua e estrelas que aparecem à noite.
- Terreno único com shader que mistura deserto, floresta e nevado por ruído, criando transições suaves.
- Recursos com formatos próprios e marcos visuais para orientação.
- A coleta é manual: aproxime-se e pressione **E / AÇÃO**. Nas missões do Biólogo, a ação analisa o alvo sem consumi-lo.
- Recursos reaparecem após 12 segundos para permitir concluir missões mesmo após coletas antecipadas.
- O lago com água animada recupera 40 pontos de hidratação por interação, inclusive após o tutorial.
- Fome e sede diminuem continuamente; o clima altera a velocidade da sede. Frutas (+20 fome, +6 sede), carne (+25 fome) e plantas (+8 sede) ajudam a sobreviver. Abaixo de 25% a HUD avisa e tinge o medidor.
- A cada capítulo avançado aparece um painel central por 3 segundos e o jogador ganha 50 EXP.
- Com todas as missões concluídas, o console da nave fica ativo. Aproxime-se e pressione **E / AÇÃO** para iniciar o desfecho; a tela final resume a jornada e permite continuar explorando.
- ARIA fica à esquerda do interior da nave e o beliche à direita. Ao anoitecer, o beliche permite dormir até o amanhecer; durante o dia ele apenas informa que é cedo demais.
- Cada ataque causa 14 de dano e as criaturas têm 30 de vida. Criaturas agressivas revidam; ariscas fogem. Ataques de animais causam 8 de vida, com breve invulnerabilidade após cada mordida.
- O astronauta não cai mais no vazio: a área do planeta tem limites invisíveis e qualquer queda é revertida para o último ponto firme.
- EXP é ganha ao coletar (+10), analisar (+5), concluir missão (+25) e avançar capítulo (+50). Ao subir de nível, vida/fome/sede são parcialmente restauradas.
- Controles de toque aparecem em dispositivos com tela sensível ao toque.

## Verificação automatizada

```bash
XDG_DATA_HOME=/tmp/astrofilia-tests godot --headless --path . --log-file /tmp/astrofilia-tests.log --script tests/gameplay_smoke.gd
```

Verifica coleta única, reaparecimento de recursos, hidratação, as 16 missões do singleplayer, pausa e mapeamento de W/S. O diretório temporário isola os saves do teste.

Teste de capítulos, nível/EXP, clima, relógio, shader do terreno, lago, nave, animais, combate, cobras, interior da nave, ARIA, beliche, limite do planeta e desfecho:

```bash
XDG_DATA_HOME=/tmp/astrofilia-progress-tests godot --headless --path . --log-file /tmp/astrofilia-progress-tests.log --script tests/progression.gd
```

Teste de colisão real da rampa, da troca para o cenário interior e do bloqueio do lago:

```bash
XDG_DATA_HOME=/tmp/astrofilia-ship-tests godot --headless --path . --log-file /tmp/astrofilia-ship-tests.log --script tests/ship_walk.gd
```

## Testes de rede

Os testes sobem dois processos Godot headless em localhost e validam o ENet de verdade: registro de jogadores, seed, estado, itens e cobras.

```bash
./tests/net_session.sh
./tests/net_gameplay.sh
```

O primeiro cobre os RPCs do autoload `Net`; o segundo roda `Gameplay.tscn` dos dois lados e valida avatares remotos, nomes, posição e coleta compartilhada de itens.

## Salvamento e aparência

- Cada um dos dois slots guarda posição, vida, fome, hidratação, inventário, pontos, contador de dias e progresso parcial das missões.
- Horário, clima, disposição da decoração e tempo de reaparecimento dos recursos são preservados.
- **Continuar:** clique no slot salvo para voltar diretamente ao planeta, sem repetir a introdução.
- Salvamento automático a cada 10 segundos, ao perder o foco e antes de sair; botão **Salvar partida** no menu de pausa.
- O último estado com vida é mantido após uma morte. **Reiniciar** começa um novo tutorial no slot ativo.
- **Novo jogo** usa um slot vazio. Com ambos ocupados, selecione um slot e confirme a substituição.
- Slots antigos que só continham nome/data iniciam um novo tutorial.
- As opções de traje branco, azul, vermelho e verde agora mudam o material do astronauta.

Teste adicional de persistência, slots, fluxo do menu, trajes e missões por função:

```bash
XDG_DATA_HOME=/tmp/astrofilia-save-tests godot --headless --path . --log-file /tmp/astrofilia-save-tests.log --script tests/save_roundtrip.gd
```

O modo por função continua disponível localmente; para jogar em rede, use **Jogar online (IP)** e siga a seção de multiplayer online.

## Controles com duas mãos no Android

Use o polegar esquerdo no **joystick analógico** e o direito em **PULAR** ou **AÇÃO**. Os toques são identificados separadamente, permitindo mover enquanto pula ou coleta. Inclinar mais o joystick acelera o astronauta e arrastar o dedo para fora da base continua controlando a direção; pausar ou sair do app interrompe o movimento.

Teste de toques simultâneos:

```bash
XDG_DATA_HOME=/tmp/astrofilia-touch-tests godot --headless --path . --log-file /tmp/astrofilia-touch-tests.log --script tests/multitouch.gd
```

Teste do orçamento gráfico móvel (sombras, escala 3D, terreno, estrelas e partículas):

```bash
XDG_DATA_HOME=/tmp/astrofilia-mobile-tests godot --headless --path . --log-file /tmp/astrofilia-mobile-tests.log --script tests/mobile_budget.gd
```
