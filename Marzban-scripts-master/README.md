# Marzban-scripts
Скрипты для Marzban

## Установка Marzban
- **Установка Marzban с SQLite**:

```bash
sudo bash -c "$(curl -sL https://github.com/SiberMix/vpn_seller/raw/master/Marzban-scripts-master/marzban.sh)" @ install
```

- **Установка Marzban с MySQL**:

  ```bash
  sudo bash -c "$(curl -sL https://github.com/SiberMix/vpn_seller/raw/master/Marzban-scripts-master/marzban.sh)" @ install --database mysql
  ```

- **Установка Marzban с MariaDB**:

  ```bash
  sudo bash -c "$(curl -sL https://github.com/SiberMix/vpn_seller/raw/master/Marzban-scripts-master/marzban.sh)" @ install --database mariadb
  ```
  
- **Установка Marzban с MariaDB и веткой Dev**:

  ```bash
  sudo bash -c "$(curl -sL https://github.com/SiberMix/vpn_seller/raw/master/Marzban-scripts-master/marzban.sh)" @ install --database mariadb --dev
  ```

- **Установка Marzban с MariaDB и указанной версией**:

  ```bash
  sudo bash -c "$(curl -sL https://github.com/SiberMix/vpn_seller/raw/master/Marzban-scripts-master/marzban.sh)" @ install --database mariadb --version v0.5.2
  ```

- **Обновление или изменение версии Xray-core**:

  ```bash
  sudo marzban core-update
  ```


## Установка Marzban-node
Установите Marzban-node на вашем сервере с помощью этой команды:
```bash
sudo bash -c "$(curl -sL https://github.com/SiberMix/vpn_seller/raw/master/Marzban-scripts-master/marzban-node.sh)" @ install
```
Установите Marzban-node на вашем сервере с пользовательским именем:
```bash
sudo bash -c "$(curl -sL https://github.com/SiberMix/vpn_seller/raw/master/Marzban-scripts-master/marzban-node.sh)" @ install --name marzban-node2
```
Или вы можете просто установить этот скрипт (команду marzban-node) на вашем сервере с помощью этой команды:
```bash
sudo bash -c "$(curl -sL https://github.com/SiberMix/vpn_seller/raw/master/Marzban-scripts-master/marzban-node.sh)" @ install-script
```

Используйте `help` для просмотра всех команд:
```marzban-node help```

- **Обновление или изменение версии Xray-core**:

  ```bash
  sudo marzban-node core-update
  ```
