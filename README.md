# Astrofilia 🚀

Jogo de aventura e sobrevivência espacial em **3D**, feito com **Godot 4.7** e exportável para **Android**.

## 📖 História

Um astronauta visita um planeta desconhecido. O capítulo 1 é um tutorial em que ele coleta minerais e plantas. Ao voltar para a nave, descobre que ela foi destruída — e agora precisa sobreviver aos perigos do planeta: animais, comida venenosa e o clima local.

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
- Missão final: “Virem juntos para casa!” / “Volte para casa!”
- HUD com vida, fome, sede, pontuação e inventário
- Coleta de itens com feedback visual e sons de interface
- Ciclo dia/noite e clima dinâmico
- Pausa, Game Over e reinício
- Conquistas e salvamento automático
- Controles por teclado e **touch** (joystick virtual + botões)
- Menu com 2 slots de save, idioma (PT/EN/ES), aparência, volumes e modo de jogo

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
│   ├── MainMenu.gd
│   ├── Cutscene.gd
│   ├── Gameplay.gd
│   ├── Player.gd
│   └── ItemColetavel.gd
└── assets/
    ├── environment.tres
    ├── planet_shader.gdshader
    └── sprites/icon.png
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
| Pular | Espaço / Seta ↑ | Botão ⬆ |
| Interagir | E | Botão ✋ |
| Pausar | — | Botão ⏸ |

## 📄 Licença

MIT — veja [LICENSE](LICENSE).
