# Y-Alts — Alts Checker

Локальный форензик-инструмент для поиска альт-аккаунтов на Windows-машине:
Minecraft, Discord, Steam. Работает офлайн, только на чтение — ничего не
отправляет в сеть, ничего не удаляет и не меняет на диске проверяемого ПК.

## Что находит

**Minecraft**
- Активный вход в аккаунт: строки `Setting user:` из логов клиента
  (vanilla/Forge/Fabric/Quilt, Lunar Client, LabyMod, TLauncher, Cristallix,
  Ely.by и другие).
- Файлы аккаунтов лаунчеров: `launcher_accounts.json`, `launcher_profiles.json`,
  `tlauncher_profiles.json`, `accounts.microsoft.json`.
- **IAS** (In-Game Account Switcher) — шифрованное хранилище аккаунтов мода,
  `_IAS_ACCOUNTS_DO_NOT_SEND_TO_ANYONE/.hidden/...`.
- **Aoba Client** — список алтов чит-клиента (`aoba_alts.json`).
- Автообнаружение лаунчеров: Mojang, PrismLauncher, ATLauncher, CurseForge,
  Modrinth App (все профили, не только запущенный), TLauncher (включая
  вложенный `legacy\Minecraft\game`), MultiMC, GDLauncher, Technic,
  LunarClient, Badlion, Feather.
- Полный обход `C:\Users\*` в поиске любых `*.log`/`*.log.gz` — ловит
  нестандартные и портативные лаунчеры вне списка известных путей.

**Discord**
- `MultiAccountStore` — список аккаунтов в переключателе клиента (id + ник).
  Читается напрямую из LevelDB (Local Storage), без прикосновения к токенам
  авторизации.
- Восстановление **удалённых** из переключателя аккаунтов: LevelDB не стирает
  старые версии значений сразу (LSM-дерево), они остаются в
  ещё не сжатых `.ldb`-файлах — свой минимальный SSTable-парсер вытаскивает их
  напрямую в обход версионирования.

**Steam**
- `loginusers.vdf` — сохранённые входы, включая отметку последнего активного.
- `userdata/<id3>` — папки остаются даже после выхода из аккаунта.

**Windows**
- Список локальных учётных записей машины (`NetUserEnum`) — имя, полное имя,
  описание, последний вход. Пароли и хеши не читаются никогда.

**USN Journal** (опционально, нужны права администратора)
- Чтение журнала изменений NTFS напрямую через `DeviceIoControl` — находит
  следы **удалённых** файлов Minecraft/Discord/Steam, которых уже нет на диске.

## Как это устроено

- Приложение написано на Rust, интерфейс — `egui`/`eframe` (нативный,
  без Electron/Node).
- При старте сразу запрашивает права администратора через UAC (нужны для
  USN Journal) и перезапускается с ними — см. `src/elevate.rs`.
- Модуль `src/scan/leveldb_raw.rs` — самодельный читатель формата LevelDB
  SSTable (footer → index block → data blocks, с распаковкой Snappy), без
  внешних тяжёлых зависимостей типа `libleveldb`.
- Уровень доверия к находке (Confirmed / Likely / Possible / Trace)
  показывает, насколько силён источник: живой вход в аккаунт vs. восстановленный
  след удалённых данных.

## Сборка

```bash
cargo build --release
```

Бинарник: `target/release/Y-Alts.exe`.

## Запуск тестов

```bash
cargo test --release
```

## Экспорт результатов

Кнопка **Export .txt** сохраняет все найденные аккаунты одним файлом —
`Desktop\papa\alts.txt`.

## Важно

Инструмент предназначен для проверки **своей собственной** машины (или с явного
согласия её владельца) — например, при скриншере в античит-модерации. Не
используйте его для доступа к чужим устройствам без разрешения.
