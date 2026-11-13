# SSH на VK Капсуле (dropbear)

## Бинарник

`dropbearmulti` — статический (static-pie, musl) aarch64, Dropbear **2025.89**, 659 КБ.

- Источник: pkgforge bincache, `github.com.mkj.dropbear.multicall`, сборка `HEAD-4214d7c-260105T132547` (git HEAD mkj/dropbear, 2026-01-05)
- Скачан: `https://api.ghcr.pkgforge.dev/pkgforge/bincache/dropbear/multicall/dropbearmulti?tag=HEAD-4214d7c-260105T132547-aarch64-linux&download=dropbearmulti`
- Рецепт: https://github.com/pkgforge/soarpkgs/blob/main/binaries/dropbear/static.multicall.source.yaml
- sha256 совпал с индексом `meta.pkgforge.dev/bincache/aarch64-Linux.json` (см. `SHA256SUMS`)
- Multicall: имя симлинка выбирает режим (`dropbear`, `dropbearkey`, `dbclient`, `scp`)
- Проверен на устройстве 2026-11-12: `-V`, генерация ed25519 ключа

Рассмотренные альтернативы:

| Сборка | Тип | Версия | Итог |
|---|---|---|---|
| Marker284/yandex-station-binaries `bin/dropbear` | armv7 static, zig/musl | 2026.94 | работает (compat), но автор неизвестен |
| OpenWrt 24.10.8 armsr/armv8 ipk | aarch64 musl, нужен `libc.so` + `libgcc_s.so.1` | 2024.86-r3 | работает через `libc.so --library-path` |
| ryanwoodsmall/static-binaries | aarch64 static | 2024.85 | старая (май 2024) |

## Устройство

- Wi-Fi IP 10.0.0.227, adb `10.0.0.227:5555` (без авторизации)
- Userspace aarch64, glibc 2.33, busybox; `/` = overlayfs, upper на `/data/overlay/upper` (ext2 80 МБ)
- iptables INPUT policy ACCEPT
- Factory-reset (`S22factory-reset.sh`) стирает `/data` → всё ниже пропадёт вместе с джейлбрейком

## Установка

```sh
./install.sh                       # 10.0.0.227:5555, ~/.ssh/id_ed25519.pub
./install.sh 10.0.0.227:5555 ~/.ssh/other.pub
```

Что делает:

- `/usr/sbin/dropbearmulti` + симлинки `dropbear dropbearkey dbclient scp`
- `/etc/init.d/S50dropbear` — автозапуск; при первом старте генерирует `/etc/dropbear/dropbear_ed25519_host_key`
- ключ дописывается в `/root/.ssh/authorized_keys`
- `/usr/bin/id` — замена на чистом sh (в busybox нет `id` и `awk`); без него `/etc/profile` при логине пишет `id: not found` / `bad number` и даёт PS1 `$` вместо `#`
- запуск: `dropbear -r <hostkey> -p 2222 -s` (`-s` — вход по паролю выключен, только ключи)

Всё попадает в overlay на `/data`, переживает перезагрузку.

## Использование

```sh
ssh -p 2222 root@10.0.0.227
scp -O -P 2222 file root@10.0.0.227:/tmp/     # -O: legacy scp, sftp-server на устройстве нет
```

Управление на устройстве: `/etc/init.d/S50dropbear {start|stop|restart}`.

## Удаление

```sh
adb -s 10.0.0.227:5555 shell '/etc/init.d/S50dropbear stop; rm -f /etc/init.d/S50dropbear /usr/sbin/dropbear* /usr/sbin/dbclient /usr/sbin/scp /usr/bin/id; rm -rf /etc/dropbear /root/.ssh'
```
