# vanish-scripts
Скрипты для vanish

## Установка vanish
- **Установка vanish с SQLite**:

```bash
sudo bash -c "$(curl -sL https://github.com/SiberMix/vpn_seller/raw/master/scripts/vanish.sh)" @ install
```

- **Установка vanish с MySQL**:

  ```bash
  sudo bash -c "$(curl -sL https://github.com/SiberMix/vpn_seller/raw/master/scripts/vanish.sh)" @ install --database mysql
  ```

- **Установка vanish с MariaDB**:

  ```bash
  sudo bash -c "$(curl -sL https://github.com/SiberMix/vpn_seller/raw/master/scripts/vanish.sh)" @ install --database mariadb
  ```
  
- **Установка vanish с MariaDB и веткой Dev**:

  ```bash
  sudo bash -c "$(curl -sL https://github.com/SiberMix/vpn_seller/raw/master/scripts/vanish.sh)" @ install --database mariadb --dev
  ```

- **Установка vanish с MariaDB и указанной версией**:

  ```bash
  sudo bash -c "$(curl -sL https://github.com/SiberMix/vpn_seller/raw/master/scripts/vanish.sh)" @ install --database mariadb --version v0.5.2
  ```

- **Обновление или изменение версии Xray-core**:

  ```bash
  sudo vanish core-update
  ```


## Установка vanish-node
Установите vanish-node на вашем сервере с помощью этой команды:
```bash
sudo bash -c "$(curl -sL https://github.com/SiberMix/vpn_seller/raw/master/scripts/vanish-node.sh)" @ install
```
Установите vanish-node на вашем сервере с пользовательским именем:
```bash
sudo bash -c "$(curl -sL https://github.com/SiberMix/vpn_seller/raw/master/scripts/vanish-node.sh)" @ install --name vanish-node2
```
Или вы можете просто установить этот скрипт (команду vanish-node) на вашем сервере с помощью этой команды:
```bash
sudo bash -c "$(curl -sL https://github.com/SiberMix/vpn_seller/raw/master/scripts/vanish-node.sh)" @ install-script
```

Используйте `help` для просмотра всех команд:
```vanish-node help```

- **Обновление или изменение версии Xray-core**:

  ```bash
  sudo vanish-node core-update
  ```
