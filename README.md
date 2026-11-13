# Input Overlay: WASD + мышь (минимальный пресет)

Простой пресет для плагина [Input Overlay](https://github.com/univrsal/input-overlay) в OBS. Только нужные клавиши и мышка, ничего лишнего. Удобно, чтобы на записи или стриме было видно, что нажимает тестировщик или игрок.

![preview](preview.png)

**Клавиатура:** `Esc` · `Q W E R` · `A S D F` · `Shift Z X C` · `Ctrl` · `Space`
**Мышь:** левая и правая кнопки, колесо (подсвечивается при нажатии и прокрутке), точка движения.
Подсветка нажатия цвета циан.

## Что нужно

- OBS Studio 33+
- Input Overlay **5.1.1 или новее** ([релизы](https://github.com/univrsal/input-overlay/releases)). Старые версии (5.0.x) не загружаются в OBS 33. Для Windows берите `input-overlay-X.Y.Z-windows-x64-Installer.exe`.

## Установка (1 минута)

1. Скачайте этот репозиторий: **Code → Download ZIP** или архив из [Releases](../../releases). Распакуйте его в любую папку.
2. В OBS добавьте источник **Input Overlay**, назовите его, например, «Клавиатура».
   - Overlay image file: `keyboard/keys.png`
   - Overlay config file: `keyboard/keys.json`
3. Добавьте ещё один **Input Overlay** («Мышь»).
   - Overlay image file: `mouse/mouse.png`
   - Overlay config file: `mouse/mouse.json`
4. Расставьте оба источника на сцене как удобно.

Включать websocket-сервер и что-то ещё настраивать не нужно.

## Как добавить или убрать кнопки

Набор клавиш задаётся в файле **`keyboard-layout.txt`**. Программировать ничего не нужно, файл редактируется в обычном Блокноте. Одна строка в нём соответствует одному ряду клавиш на экране:

```
ESC
Q W E R
A S D F
SHIFT Z X C
CTRL SPACE*3
```

### Пошагово

1. Откройте `keyboard-layout.txt` в Блокноте (правый клик → «Открыть с помощью» → Блокнот).
2. Измените раскладку (примеры ниже) и сохраните файл (`Ctrl+S`).
3. Дважды щёлкните **`make-presets.bat`**. Откроется окно с надписью `Done: N keys`, где N — сколько клавиш получилось. Закройте окно любой клавишей.
4. В OBS откройте свойства источника клавиатуры и выберите `keyboard/keys.png` и `keyboard/keys.json` заново, чтобы OBS перечитал файлы.

### Примеры

**Добавить клавишу в ряд.** Допишите её название через пробел:
```
Q W E R T        ← добавили T
```

**Убрать клавишу.** Сотрите её название:
```
A S D            ← убрали F
```

**Добавить целый ряд.** Допишите новую строку, например цифры:
```
1 2 3 4 5
```

**Убрать целый ряд.** Удалите строку целиком.

**Сделать клавишу шире.** Допишите `*` и ширину в обычных клавишах:
```
CAPS*1.5 A S D F
CTRL SPACE*4
```

**Оставить пустое место.** Поставьте `_` (тоже можно с шириной, `_*2`):
```
ESC _ F1 F2 F3 F4
```

**Стрелки:**
```
_ UP
LEFT DOWN RIGHT
```

### Названия клавиш

| Что | Как писать |
|---|---|
| Буквы и цифры | `A`–`Z`, `0`–`9` |
| Функциональные | `F1`–`F24` |
| Служебные | `ESC` `TAB` `CAPS` `ENTER` `BACKSPACE` `SPACE` |
| Модификаторы (левые) | `SHIFT` `CTRL` `ALT` `WIN` |
| Модификаторы (правые) | `RSHIFT` `RCTRL` `RALT` |
| Стрелки | `UP` `DOWN` `LEFT` `RIGHT` |
| Навигация | `INS` `DEL` `HOME` `END` `PGUP` `PGDN` |
| Символы | `` ` `` `-` `=` `[` `]` `\` `;` `'` `,` `.` `/` |
| Numpad | `NUM0`–`NUM9` `NUM+` `NUM-` `NUM*` `NUM/` `NUMENTER` |

Регистр не важен: `esc` и `ESC` работают одинаково. Строки, которые начинаются с `#`, считаются комментариями и пропускаются.

Если в названии опечатка, окно покажет `Unknown keys in layout: ...` с неизвестными словами, а старые файлы останутся как были. Исправьте опечатку и запустите `make-presets.bat` ещё раз.

**Вернуть исходный набор:** скопируйте в `keyboard-layout.txt` пять строк из начала этого раздела и запустите `make-presets.bat`.

## Другой цвет подсветки

Запустите `make-presets.bat` с цветом из командной строки:

```bat
make-presets.bat #FF4FA3
```

Или из PowerShell: `powershell -ExecutionPolicy Bypass -File tools\make-presets.ps1 -Accent "#FF4FA3"`.

## Если не работает

- **Источник пустой или серый.** Проверьте версию Input Overlay (нужна 5.1.1+). В логе OBS (Справка → Файлы журнала) не должно быть строки `input-overlay.dll not loaded`.
- **Не реагирует на нажатия в игре.** Некоторые игры перехватывают ввод. Обычно помогает запустить OBS от имени администратора.
- **Подсвечиваются только левые Shift и Ctrl.** Так задумано. Если нужны правые, добавьте в `keyboard-layout.txt` клавиши `RSHIFT` и `RCTRL`.

---

### English

Minimal preset for the OBS [Input Overlay](https://github.com/univrsal/input-overlay) plugin (5.1.1+, OBS 33+). Keyboard: Esc, QWER, ASDF, Shift ZXC, Ctrl, Space. Mouse: L/R buttons, wheel, movement dot. Cyan highlight.
Add two *Input Overlay* sources: `keyboard/keys.png` + `keyboard/keys.json` and `mouse/mouse.png` + `mouse/mouse.json`. To change the keys, edit `keyboard-layout.txt` (one line per row, `SPACE*3` = 3 units wide, `_` = empty slot) and double-click `make-presets.bat`. To change the highlight color, run `make-presets.bat #RRGGBB`.

## License

MIT
