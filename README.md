# Astrofilia 🚀

Jogo de aventura e sobrevivência espacial em **3D**, feito com **Godot 4.7** e exportável para **Android**.

**Versão do código: 0.3.1** — animais em movimento, nave explorável no solo, lago intransponível e mais detalhes espaciais.

APK mais recente:

[![Release](https://img.shields.io/badge/release-v0.3.1-brightgreen)](https://github.com/alunoadsnoite/astrofilia/releases/tag/v0.3.1)

[⬇️ Baixar Astrofilia.apk (v0.3.1)](https://github.com/alunoadsnoite/astrofilia/releases/download/v0.3.1/Astrofilia.apk)

## 📖 História

Um astronauta pousa em um planeta desconhecido. O capítulo 1 é um tutorial em que ele coleta minerais e plantas. Ao voltar para a nave, encontra o interior vazio e os sistemas desligados — e agora precisa sobreviver aos perigos do planeta: animais, comida venenosa e o clima local.

## 🌍 Biomas

- 🏜️ Deserto rochoso
- 🌲 Floresta
- ❄️ Nevado

## 🎮 Modos de jogo

- **Singleplayer**: você é Coletor e Biólogo ao mesmo tempo.
- **Multiplayer**: escolha sua função (Coletor ou Biólogo).

### ⛏️ Coletor
- Facão para coletar plantas
- Picareta para coletar pedras e minerais

### 🔬 Biólogo
- Câmera especial para fotografar e obter informações sobre plantas, frutas, vegetais e animais

## ✨ Funcionalidades

- Cutscene inicial: foguete partindo com aplausos, nave pousando e astronauta descendo
- Caixa de texto vermelha no topo com missões sequenciais (8 do Coletor + 8 do Biólogo)
- Missões alternadas no singleplayer e por função no multiplayer
- Missão final: "Virem juntos para casa!" / "Volte para casa!"
- **Capítulos**: aviso central de 3 segundos ("CAPÍTULO 1", "CAPÍTULO 2"...) ao avançar o progresso, com bônus de XP
- **Nível (NV) e Experiência (EXP)**: barra na HUD, XP por coleta/missão/capítulo e cura parcial ao subir de nível
- HUD com vida, fome, sede, pontuação e inventário, com porcentagens e alertas coloridos
- Coleta de itens com feedback visual e efeitos sonoros de interface e de jogo (clique, coleta, missão, nível, capítulo e água)
- **Fome e sede**: decaimento contínuo influenciado pelo clima, avisos de nível baixo, dano ao chegar a zero e bônus ao comer fruta/carne, beber no lago ou consumir plantas
- Ciclo dia/noite com sol em órbita, luz da lua, estrelas e clima dinâmico (chuva, neve, tempestade de areia e poeira com partículas próprias)
- **Biomas com transição suave**: um único terreno com shader mistura deserto, floresta e nevado, sem emendas
- **Animais em movimento**: as criaturas patrulham ao redor do ponto onde nascem, viram-se para a direção do movimento e não entram no lago nem na nave
- **Nave explorável**: a nave pousou sobre uma plataforma iluminada no deserto; suba pela rampa para entrar no interior vazio, com console de voo e iluminação própria
- **Lago intransponível**: a água bloqueia a passagem e só pode ser contornada pelas margens
- Gráficos detalhados: cactos, cogumelos, arbustos, pinheiros, cristais de gelo, lago com água animada, margem e vitórias-régias
- **Céu espacial**: planeta gigante com anéis, lua distante, estrelas, sol em órbita e névoa atmosférica
- Pausa, Game Over e reinício
- Conquistas e salvamento automático
- Controles por teclado e touch (joystick virtual + botões)
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
│   ├── MainMenu.gd
│   ├── Cutscene.gd
│   ├── Gameplay.gd
│   ├── Player.gd
│   └── ItemColetavel.gd
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
| Mover | WASD / Setas | Joystick virtual |
| Pular | Espaço | Botão ⬆ |
| Coletar / analisar / beber | E, próximo ao alvo | Botão ✋ |
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
- EXP é ganha ao coletar (+10), analisar (+5), concluir missão (+25) e avançar capítulo (+50). Ao subir de nível, vida/fome/sede são parcialmente restauradas.
- Controles de toque aparecem em dispositivos com tela sensível ao toque.

## Verificação automatizada

```bash
XDG_DATA_HOME=/tmp/astrofilia-tests godot --headless --path . --log-file /tmp/astrofilia-tests.log --script tests/gameplay_smoke.gd
```

Verifica coleta única, reaparecimento de recursos, hidratação, as 16 missões do singleplayer, pausa e mapeamento de W/S. O diretório temporário isola os saves do teste.

Teste de capítulos, nível/EXP, clima, relógio, shader do terreno, lago, nave e animais:

```bash
XDG_DATA_HOME=/tmp/astrofilia-progress-tests godot --headless --path . --log-file /tmp/astrofilia-progress-tests.log --script tests/progression.gd
```

Teste de colisão real da rampa da nave e do bloqueio do lago:

```bash
XDG_DATA_HOME=/tmp/astrofilia-ship-tests godot --headless --path . --log-file /tmp/astrofilia-ship-tests.log --script tests/ship_walk.gd
```

## Salvamento e aparência

- Cada um dos dois slots guarda posição, vida, fome, hidratação, inventário, pontos e progresso parcial das missões.
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

O modo por função ainda é local; conexão multiplayer não está implementada.

## Controles com duas mãos no Android

Use o polegar esquerdo nas setas de movimento e o direito em **PULAR** ou **AÇÃO**. Os toques são identificados separadamente, permitindo mover enquanto pula ou coleta. Arrastar o dedo entre as setas muda a direção; soltar fora do botão, pausar ou sair do app interrompe o movimento.

Teste de toques simultâneos:

```bash
XDG_DATA_HOME=/tmp/astrofilia-touch-tests godot --headless --path . --log-file /tmp/astrofilia-touch-tests.log --script tests/multitouch.gd
```
