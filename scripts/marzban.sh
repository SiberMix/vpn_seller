#!/usr/bin/env bash
set -e

INSTALL_DIR="/opt"
if [ -z "$APP_NAME" ]; then
    APP_NAME="vanish_vpn"
fi
APP_DIR="$INSTALL_DIR/$APP_NAME"
DATA_DIR="/var/lib/$APP_NAME"
COMPOSE_FILE="$APP_DIR/docker-compose.yml"
ENV_FILE="$APP_DIR/.env"
LAST_XRAY_CORES=10

colorized_echo() {
    local color=$1
    local text=$2
    
    case $color in
        "red")
        printf "\e[91m${text}\e[0m\n";;
        "green")
        printf "\e[92m${text}\e[0m\n";;
        "yellow")
        printf "\e[93m${text}\e[0m\n";;
        "blue")
        printf "\e[94m${text}\e[0m\n";;
        "magenta")
        printf "\e[95m${text}\e[0m\n";;
        "cyan")
        printf "\e[96m${text}\e[0m\n";;
        *)
            echo "${text}"
        ;;
    esac
}

check_running_as_root() {
    if [ "$(id -u)" != "0" ]; then
        colorized_echo red "Эта команда должна быть запущена от имени root."
        exit 1
    fi
}

detect_os() {
    # Определение операционной системы
    if [ -f /etc/lsb-release ]; then
        OS=$(lsb_release -si)
    elif [ -f /etc/os-release ]; then
        OS=$(awk -F= '/^NAME/{print $2}' /etc/os-release | tr -d '"')
    elif [ -f /etc/redhat-release ]; then
        OS=$(cat /etc/redhat-release | awk '{print $1}')
    elif [ -f /etc/arch-release ]; then
        OS="Arch"
    else
        colorized_echo red "Неподдерживаемая операционная система"
        exit 1
    fi
}

detect_and_update_package_manager() {
    colorized_echo blue "Обновление пакетного менеджера"
    if [[ "$OS" == "Ubuntu"* ]] || [[ "$OS" == "Debian"* ]]; then
        PKG_MANAGER="apt-get"
        $PKG_MANAGER update
    elif [[ "$OS" == "CentOS"* ]] || [[ "$OS" == "AlmaLinux"* ]]; then
        PKG_MANAGER="yum"
        $PKG_MANAGER update -y
        $PKG_MANAGER install -y epel-release
    elif [ "$OS" == "Fedora"* ]; then
        PKG_MANAGER="dnf"
        $PKG_MANAGER update
    elif [ "$OS" == "Arch" ]; then
        PKG_MANAGER="pacman"
        $PKG_MANAGER -Sy
    elif [[ "$OS" == "openSUSE"* ]]; then
        PKG_MANAGER="zypper"
        $PKG_MANAGER refresh
    else
        colorized_echo red "Неподдерживаемая операционная система"
        exit 1
    fi
}

install_package() {
    if [ -z $PKG_MANAGER ]; then
        detect_and_update_package_manager
    fi
    
    PACKAGE=$1
    colorized_echo blue "Установка $PACKAGE"
    if [[ "$OS" == "Ubuntu"* ]] || [[ "$OS" == "Debian"* ]]; then
        $PKG_MANAGER -y install "$PACKAGE"
    elif [[ "$OS" == "CentOS"* ]] || [[ "$OS" == "AlmaLinux"* ]]; then
        $PKG_MANAGER install -y "$PACKAGE"
    elif [ "$OS" == "Fedora"* ]; then
        $PKG_MANAGER install -y "$PACKAGE"
    elif [ "$OS" == "Arch" ]; then
        $PKG_MANAGER -S --noconfirm "$PACKAGE"
    else
        colorized_echo red "Неподдерживаемая операционная система"
        exit 1
    fi
}

install_docker() {
    # Установка Docker и Docker Compose используя официальный установочный скрипт
    colorized_echo blue "Установка Docker"
    curl -fsSL https://get.docker.com | sh
    colorized_echo green "Docker успешно установлен"
}

detect_compose() {
    # Проверка наличия команды docker compose
    if docker compose version >/dev/null 2>&1; then
        COMPOSE='docker compose'
    elif docker-compose version >/dev/null 2>&1; then
        COMPOSE='docker-compose'
    else
        colorized_echo red "docker compose не найден"
        exit 1
    fi
}

install_vanish_vpn_script() {
    FETCH_REPO="SiberMix/vpn_seller"
    SCRIPT_URL="https://github.com/$FETCH_REPO/raw/master/scripts/vanish_vpn.sh"
    colorized_echo blue "Установка скрипта vanish_vpn"
    curl -sSL $SCRIPT_URL | install -m 755 /dev/stdin /usr/local/bin/vanish_vpn
    colorized_echo green "Скрипт vanish_vpn успешно установлен"
}

is_vanish_vpn_installed() {
    if [ -d $APP_DIR ]; then
        return 0
    else
        return 1
    fi
}

identify_the_operating_system_and_architecture() {
    if [[ "$(uname)" == 'Linux' ]]; then
        case "$(uname -m)" in
            'i386' | 'i686')
                ARCH='32'
            ;;
            'amd64' | 'x86_64')
                ARCH='64'
            ;;
            'armv5tel')
                ARCH='arm32-v5'
            ;;
            'armv6l')
                ARCH='arm32-v6'
                grep Features /proc/cpuinfo | grep -qw 'vfp' || ARCH='arm32-v5'
            ;;
            'armv7' | 'armv7l')
                ARCH='arm32-v7a'
                grep Features /proc/cpuinfo | grep -qw 'vfp' || ARCH='arm32-v5'
            ;;
            'armv8' | 'aarch64')
                ARCH='arm64-v8a'
            ;;
            'mips')
                ARCH='mips32'
            ;;
            'mipsle')
                ARCH='mips32le'
            ;;
            'mips64')
                ARCH='mips64'
                lscpu | grep -q "Little Endian" && ARCH='mips64le'
            ;;
            'mips64le')
                ARCH='mips64le'
            ;;
            'ppc64')
                ARCH='ppc64'
            ;;
            'ppc64le')
                ARCH='ppc64le'
            ;;
            'riscv64')
                ARCH='riscv64'
            ;;
            's390x')
                ARCH='s390x'
            ;;
            *)
                echo "ошибка: Архитектура не поддерживается."
                exit 1
            ;;
        esac
    else
        echo "ошибка: Эта операционная система не поддерживается."
        exit 1
    fi
}

send_backup_to_telegram() {
    if [ -f "$ENV_FILE" ]; then
        while IFS='=' read -r key value; do
            if [[ -z "$key" || "$key" =~ ^# ]]; then
                continue
            fi
            key=$(echo "$key" | xargs)
            value=$(echo "$value" | xargs)
            if [[ "$key" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
                export "$key"="$value"
            else
                colorized_echo yellow "Пропуск некорректной строки в .env: $key=$value"
            fi
        done < "$ENV_FILE"
    else
        colorized_echo red "Файл окружения (.env) не найден."
        exit 1
    fi

    if [ "$BACKUP_SERVICE_ENABLED" != "true" ]; then
        colorized_echo yellow "Сервис резервного копирования не включен. Пропуск загрузки в Telegram."
        return
    fi

    local server_ip=$(curl -s ifconfig.me || echo "Неизвестный IP")
    local latest_backup=$(ls -t "$APP_DIR/backup" | head -n 1)
    local backup_path="$APP_DIR/backup/$latest_backup"

    if [ ! -f "$backup_path" ]; then
        colorized_echo red "Резервные копии для отправки не найдены."
        return
    fi

    local backup_size=$(du -m "$backup_path" | cut -f1)
    local split_dir="/tmp/vanish_vpn_backup_split"
    local is_single_file=true

    mkdir -p "$split_dir"

    if [ "$backup_size" -gt 49 ]; then
        colorized_echo yellow "Резервная копия больше 49МБ. Разделение архива..."
        split -b 49M "$backup_path" "$split_dir/part_"
        is_single_file=false
    else
        cp "$backup_path" "$split_dir/part_aa"
    fi

    local backup_time=$(date "+%Y-%m-%d %H:%M:%S %Z")

    for part in "$split_dir"/*; do
        local part_name=$(basename "$part")
        local custom_filename="backup_${part_name}.tar.gz"
        local caption="📦 *Информация о резервной копии*\n🌐 *IP Сервера*: \`${server_ip}\`\n📁 *Файл*: \`${custom_filename}\`\n⏰ *Время*: \`${backup_time}\`"
        curl -s -F chat_id="$BACKUP_TELEGRAM_CHAT_ID" \
            -F document=@"$part;filename=$custom_filename" \
            -F caption="$(echo -e "$caption" | sed 's/-/\\-/g;s/\./\\./g;s/_/\\_/g')" \
            -F parse_mode="MarkdownV2" \
            "https://api.telegram.org/bot$BACKUP_TELEGRAM_BOT_KEY/sendDocument" >/dev/null 2>&1 && \
        colorized_echo green "Часть резервной копии $custom_filename успешно отправлена в Telegram." || \
        colorized_echo red "Не удалось отправить часть резервной копии $custom_filename в Telegram."
    done

    rm -rf "$split_dir"
}

send_backup_error_to_telegram() {
    local error_messages=$1
    local log_file=$2
    local server_ip=$(curl -s ifconfig.me || echo "Неизвестный IP")
    local error_time=$(date "+%Y-%m-%d %H:%M:%S %Z")
    local message="⚠️ *Уведомление об ошибке резервного копирования*\n"
    message+="🌐 *IP Сервера*: \`${server_ip}\`\n"
    message+="❌ *Ошибки*:\n\`${error_messages//_/\\_}\`\n"
    message+="⏰ *Время*: \`${error_time}\`"

    message=$(echo -e "$message" | sed 's/-/\\-/g;s/\./\\./g;s/_/\\_/g;s/(/\\(/g;s/)/\\)/g')

    local max_length=1000
    if [ ${#message} -gt $max_length ]; then
        message="${message:0:$((max_length - 50))}...\n\`[Сообщение обрезано]\`"
    fi

    curl -s -X POST "https://api.telegram.org/bot$BACKUP_TELEGRAM_BOT_KEY/sendMessage" \
        -d chat_id="$BACKUP_TELEGRAM_CHAT_ID" \
        -d parse_mode="MarkdownV2" \
        -d text="$message" >/dev/null 2>&1 && \
    colorized_echo green "Уведомление об ошибке резервного копирования отправлено в Telegram." || \
    colorized_echo red "Не удалось отправить уведомление об ошибке в Telegram."

    if [ -f "$log_file" ]; then
        response=$(curl -s -w "%{http_code}" -o /tmp/tg_response.json \
            -F chat_id="$BACKUP_TELEGRAM_CHAT_ID" \
            -F document=@"$log_file;filename=backup_error.log" \
            -F caption="📜 *Лог ошибок резервного копирования* - ${error_time}" \
            "https://api.telegram.org/bot$BACKUP_TELEGRAM_BOT_KEY/sendDocument")

        http_code="${response:(-3)}"
        if [ "$http_code" -eq 200 ]; then
            colorized_echo green "Лог ошибок резервного копирования отправлен в Telegram."
        else
            colorized_echo red "Не удалось отправить лог ошибок в Telegram. HTTP код: $http_code"
            cat /tmp/tg_response.json
        fi
    else
        colorized_echo red "Файл лога не найден: $log_file"
    fi
}

backup_service() {
    local telegram_bot_key=""
    local telegram_chat_id=""
    local cron_schedule=""
    local interval_hours=""

    colorized_echo blue "====================================="
    colorized_echo blue "      Добро пожаловать в сервис резервного копирования      "
    colorized_echo blue "====================================="

    if grep -q "BACKUP_SERVICE_ENABLED=true" "$ENV_FILE"; then
        telegram_bot_key=$(awk -F'=' '/^BACKUP_TELEGRAM_BOT_KEY=/ {print $2}' "$ENV_FILE")
        telegram_chat_id=$(awk -F'=' '/^BACKUP_TELEGRAM_CHAT_ID=/ {print $2}' "$ENV_FILE")
        cron_schedule=$(awk -F'=' '/^BACKUP_CRON_SCHEDULE=/ {print $2}' "$ENV_FILE" | tr -d '"')

        if [[ "$cron_schedule" == "0 0 * * *" ]]; then
            interval_hours=24
        else
            interval_hours=$(echo "$cron_schedule" | grep -oP '(?<=\*/)[0-9]+')
        fi

        colorized_echo green "====================================="
        colorized_echo green "Текущая конфигурация резервного копирования:"
        colorized_echo cyan "API ключ Telegram бота: $telegram_bot_key"
        colorized_echo cyan "ID чата Telegram: $telegram_chat_id"
        colorized_echo cyan "Интервал копирования: Каждые $interval_hours час(ов)"
        colorized_echo green "====================================="
        echo "Выберите опцию:"
        echo "1. Переконфигурировать сервис резервного копирования"
        echo "2. Удалить сервис резервного копирования"
        echo "3. Выход"
        read -p "Введите ваш выбор (1-3): " user_choice

        case $user_choice in
            1)
                colorized_echo yellow "Начинаем переконфигурацию..."
                remove_backup_service
                ;;
            2)
                colorized_echo yellow "Удаление сервиса резервного копирования..."
                remove_backup_service
                return
                ;;
            3)
                colorized_echo yellow "Выход..."
                return
                ;;
            *)
                colorized_echo red "Неверный выбор. Выход."
                return
                ;;
        esac
    else
        colorized_echo yellow "Сервис резервного копирования не настроен."
    fi

    while true; do
        printf "Введите API ключ вашего Telegram бота: "
        read telegram_bot_key
        if [[ -n "$telegram_bot_key" ]]; then
            break
        else
            colorized_echo red "API ключ не может быть пустым. Попробуйте снова."
        fi
    done

    while true; do
        printf "Введите ID чата Telegram: "
        read telegram_chat_id
        if [[ -n "$telegram_chat_id" ]]; then
            break
        else
            colorized_echo red "ID чата не может быть пустым. Попробуйте снова."
        fi
    done

    while true; do
        printf "Установите интервал резервного копирования в часах (1-24):\n"
        read interval_hours

        if ! [[ "$interval_hours" =~ ^[0-9]+$ ]]; then
            colorized_echo red "Неверный ввод. Пожалуйста, введите корректное число."
            continue
        fi

        if [[ "$interval_hours" -eq 24 ]]; then
            cron_schedule="0 0 * * *"
            colorized_echo green "Установка резервного копирования на ежедневное выполнение в полночь."
            break
        fi

        if [[ "$interval_hours" -ge 1 && "$interval_hours" -le 23 ]]; then
            cron_schedule="0 */$interval_hours * * *"
            colorized_echo green "Установка резервного копирования каждые $interval_hours час(ов)."
            break
        else
            colorized_echo red "Неверный ввод. Пожалуйста, введите число от 1 до 24."
        fi
    done

    sed -i '/^BACKUP_SERVICE_ENABLED/d' "$ENV_FILE"
    sed -i '/^BACKUP_TELEGRAM_BOT_KEY/d' "$ENV_FILE"
    sed -i '/^BACKUP_TELEGRAM_CHAT_ID/d' "$ENV_FILE"
    sed -i '/^BACKUP_CRON_SCHEDULE/d' "$ENV_FILE"

    {
        echo ""
        echo "# Конфигурация сервиса резервного копирования"
        echo "BACKUP_SERVICE_ENABLED=true"
        echo "BACKUP_TELEGRAM_BOT_KEY=$telegram_bot_key"
        echo "BACKUP_TELEGRAM_CHAT_ID=$telegram_chat_id"
        echo "BACKUP_CRON_SCHEDULE=\"$cron_schedule\""
    } >> "$ENV_FILE"

    colorized_echo green "Конфигурация сервиса резервного копирования сохранена в $ENV_FILE."

    local backup_command="$(which bash) -c '$APP_NAME backup'"
    add_cron_job "$cron_schedule" "$backup_command"

    colorized_echo green "Сервис резервного копирования успешно настроен."
    if [[ "$interval_hours" -eq 24 ]]; then
        colorized_echo cyan "Резервные копии будут отправляться в Telegram ежедневно (каждые 24 часа в полночь)."
    else
        colorized_echo cyan "Резервные копии будут отправляться в Telegram каждые $interval_hours час(ов)."
    fi
    colorized_echo green "====================================="
}

add_cron_job() {
    local schedule="$1"
    local command="$2"
    local temp_cron=$(mktemp)

    crontab -l 2>/dev/null > "$temp_cron" || true
    grep -v "$command" "$temp_cron" > "${temp_cron}.tmp" && mv "${temp_cron}.tmp" "$temp_cron"
    echo "$schedule $command # vanish_vpn-backup-service" >> "$temp_cron"
    
    if crontab "$temp_cron"; then
        colorized_echo green "Задача Cron успешно добавлена."
    else
        colorized_echo red "Не удалось добавить задачу Cron. Пожалуйста, проверьте вручную."
    fi
    rm -f "$temp_cron"
}

remove_backup_service() {
    colorized_echo red "в процессе..."

    sed -i '/^# Backup service configuration/d' "$ENV_FILE"
    sed -i '/BACKUP_SERVICE_ENABLED/d' "$ENV_FILE"
    sed -i '/BACKUP_TELEGRAM_BOT_KEY/d' "$ENV_FILE"
    sed -i '/BACKUP_TELEGRAM_CHAT_ID/d' "$ENV_FILE"
    sed -i '/BACKUP_CRON_SCHEDULE/d' "$ENV_FILE"

    local temp_cron=$(mktemp)
    crontab -l 2>/dev/null > "$temp_cron"

    sed -i '/# vanish_vpn-backup-service/d' "$temp_cron"

    if crontab "$temp_cron"; then
        colorized_echo green "Задача сервиса резервного копирования удалена из crontab."
    else
        colorized_echo red "Не удалось обновить crontab. Пожалуйста, проверьте вручную."
    fi

    rm -f "$temp_cron"

    colorized_echo green "Сервис резервного копирования был удален."
}

backup_command() {
    local backup_dir="$APP_DIR/backup"
    local temp_dir="/tmp/vanish_vpn_backup"
    local timestamp=$(date +"%Y%m%d%H%M%S")
    local backup_file="$backup_dir/backup_$timestamp.tar.gz"
    local error_messages=()
    local log_file="/var/log/vanish_vpn_backup_error.log"
    > "$log_file"
    echo "Лог резервного копирования - $(date)" > "$log_file"

    if ! command -v rsync >/dev/null 2>&1; then
        detect_os
        install_package rsync
    fi

    rm -rf "$backup_dir"
    mkdir -p "$backup_dir"
    mkdir -p "$temp_dir"

    if [ -f "$ENV_FILE" ]; then
        while IFS='=' read -r key value; do
            if [[ -z "$key" || "$key" =~ ^# ]]; then
                continue
            fi
            key=$(echo "$key" | xargs)
            value=$(echo "$value" | xargs)
            if [[ "$key" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
                export "$key"="$value"
            else
                echo "Пропуск некорректной строки в .env: $key=$value" >> "$log_file"
            fi
        done < "$ENV_FILE"
    else
        error_messages+=("Файл окружения (.env) не найден.")
        echo "Файл окружения (.env) не найден." >> "$log_file"
        send_backup_error_to_telegram "${error_messages[*]}" "$log_file"
        exit 1
    fi

    local db_type=""
    local sqlite_file=""
    if grep -q "image: mariadb" "$COMPOSE_FILE"; then
        db_type="mariadb"
        container_name=$(docker compose -f "$COMPOSE_FILE" ps -q mariadb || echo "mariadb")

    elif grep -q "image: mysql" "$COMPOSE_FILE"; then
        db_type="mysql"
        container_name=$(docker compose -f "$COMPOSE_FILE" ps -q mysql || echo "mysql")

    elif grep -q "SQLALCHEMY_DATABASE_URL = .*sqlite" "$ENV_FILE"; then
        db_type="sqlite"
        sqlite_file=$(grep -Po '(?<=SQLALCHEMY_DATABASE_URL = "sqlite:////).*"' "$ENV_FILE" | tr -d '"')
        if [[ ! "$sqlite_file" =~ ^/ ]]; then
            sqlite_file="/$sqlite_file"
        fi
    fi

    if [ -n "$db_type" ]; then
        echo "База данных обнаружена: $db_type" >> "$log_file"
        case $db_type in
            mariadb)
                if ! docker exec "$container_name" mariadb-dump -u root -p"$MYSQL_ROOT_PASSWORD" --all-databases > "$temp_dir/db_backup.sql" 2>>"$log_file"; then
                    error_messages+=("Ошибка дампа MariaDB.")
                fi
                ;;
            mysql)
                if ! docker exec "$container_name" mysqldump -u root -p"$MYSQL_ROOT_PASSWORD" --all-databases > "$temp_dir/db_backup.sql" 2>>"$log_file"; then
                    error_messages+=("Ошибка дампа MySQL.")
                fi
                ;;
            sqlite)
                if [ -f "$sqlite_file" ]; then
                    if ! cp "$sqlite_file" "$temp_dir/db_backup.sqlite" 2>>"$log_file"; then
                        error_messages+=("Не удалось скопировать базу данных SQLite.")
                    fi
                else
                    error_messages+=("Файл базы данных SQLite не найден: $sqlite_file.")
                fi
                ;;
        esac
    fi

    cp "$APP_DIR/.env" "$temp_dir/" 2>>"$log_file"
    cp "$APP_DIR/docker-compose.yml" "$temp_dir/" 2>>"$log_file"
    rsync -av --exclude 'xray-core' --exclude 'mysql' "$DATA_DIR/" "$temp_dir/vanish_vpn_data/" >>"$log_file" 2>&1

    if ! tar -czf "$backup_file" -C "$temp_dir" .; then
        error_messages+=("Не удалось создать архив резервной копии.")
        echo "Не удалось создать архив резервной копии." >> "$log_file"
    fi

    rm -rf "$temp_dir"

    if [ ${#error_messages[@]} -gt 0 ]; then
        send_backup_error_to_telegram "${error_messages[*]}" "$log_file"
        return
    fi
    colorized_echo green "Резервная копия создана: $backup_file"
    send_backup_to_telegram "$backup_file"
}

get_xray_core() {
    identify_the_operating_system_and_architecture
    clear

    validate_version() {
        local version="$1"
        
        local response=$(curl -s "https://api.github.com/repos/XTLS/Xray-core/releases/tags/$version")
        if echo "$response" | grep -q '"message": "Not Found"'; then
            echo "invalid"
        else
            echo "valid"
        fi
    }

    print_menu() {
        clear
        echo -e "\033[1;32m==============================\033[0m"
        echo -e "\033[1;32m      Установщик Xray-core     \033[0m"
        echo -e "\033[1;32m==============================\033[0m"
        echo -e "\033[1;33mДоступные версии Xray-core:\033[0m"
        for ((i=0; i<${#versions[@]}; i++)); do
            echo -e "\033[1;34m$((i + 1)):\033[0m ${versions[i]}"
        done
        echo -e "\033[1;32m==============================\033[0m"
        echo -e "\033[1;35mM:\033[0m Ввести версию вручную"
        echo -e "\033[1;31mQ:\033[0m Выход"
        echo -e "\033[1;32m==============================\033[0m"
    }

    latest_releases=$(curl -s "https://api.github.com/repos/XTLS/Xray-core/releases?per_page=$LAST_XRAY_CORES")

    versions=($(echo "$latest_releases" | grep -oP '"tag_name": "\K(.*?)(?=")'))

    while true; do
        print_menu
        read -p "Выберите версию для установки (1-${#versions[@]}), или нажмите M для ручного ввода, Q для выхода: " choice
        
        if [[ "$choice" =~ ^[1-9][0-9]*$ ]] && [ "$choice" -le "${#versions[@]}" ]; then
            choice=$((choice - 1))
            selected_version=${versions[choice]}
            break
        elif [ "$choice" == "M" ] || [ "$choice" == "m" ]; then
            while true; do
                read -p "Введите версию вручную (например, v1.2.3): " custom_version
                if [ "$(validate_version "$custom_version")" == "valid" ]; then
                    selected_version="$custom_version"
                    break 2
                else
                    echo -e "\033[1;31mНеверная версия или версия не существует. Попробуйте снова.\033[0m"
                fi
            done
        elif [ "$choice" == "Q" ] || [ "$choice" == "q" ]; then
            echo -e "\033[1;31mВыход.\033[0m"
            exit 0
        else
            echo -e "\033[1;31mНеверный выбор. Попробуйте снова.\033[0m"
            sleep 2
        fi
    done

    echo -e "\033[1;32mВыбрана версия $selected_version для установки.\033[0m"

    # Проверка установленных пакетов
    if ! command -v unzip >/dev/null 2>&1; then
        echo -e "\033[1;33mУстановка необходимых пакетов...\033[0m"
        detect_os
        install_package unzip
    fi
    if ! command -v wget >/dev/null 2>&1; then
        echo -e "\033[1;33mУстановка необходимых пакетов...\033[0m"
        detect_os
        install_package wget
    fi

    mkdir -p $DATA_DIR/xray-core
    cd $DATA_DIR/xray-core

    xray_filename="Xray-linux-$ARCH.zip"
    xray_download_url="https://github.com/XTLS/Xray-core/releases/download/${selected_version}/${xray_filename}"

    echo -e "\033[1;33mЗагрузка Xray-core версии ${selected_version}...\033[0m"
    wget -q -O "${xray_filename}" "${xray_download_url}"

    echo -e "\033[1;33mРаспаковка Xray-core...\033[0m"
    unzip -o "${xray_filename}" >/dev/null 2>&1
    rm "${xray_filename}"
}

# Функция обновления основного ядра vanish_vpn
update_core_command() {
    check_running_as_root
    get_xray_core
    # Изменение ядра vanish_vpn
    xray_executable_path="XRAY_EXECUTABLE_PATH=\"var/lib/vanish/xray-core/xray\""
    
    echo "Изменение ядра vanish_vpn..."
    # Проверка существования строки XRAY_EXECUTABLE_PATH в файле .env
    if ! grep -q "^XRAY_EXECUTABLE_PATH=" "$ENV_FILE"; then
        # Если строка не существует, добавляем её
        echo "${xray_executable_path}" >> "$ENV_FILE"
    else
        # Обновляем существующую строку XRAY_EXECUTABLE_PATH
        sed -i "s~^XRAY_EXECUTABLE_PATH=.*~${xray_executable_path}~" "$ENV_FILE"
    fi
    
    # Перезапуск vanish_vpn
    colorized_echo red "Перезапуск vanish_vpn..."
    if restart_command -n >/dev/null 2>&1; then
        colorized_echo green "vanish_vpn успешно перезапущен!"
    else
        colorized_echo red "Ошибка перезапуска vanish_vpn!"
    fi
    colorized_echo blue "Установка версии Xray-core $selected_version завершена."
}

install_vanish_vpn() {
    local vanish_vpn_version=$1
    local database_type=$2
    # Получение релизов
    FILES_URL_PREFIX="https://raw.githubusercontent.com/SiberMix/vpn_seller/master/backend"
    
    mkdir -p "$DATA_DIR"
    mkdir -p "$APP_DIR"
    
    colorized_echo blue "Настройка docker-compose.yml"
    docker_file_path="$APP_DIR/docker-compose.yml"

    echo "----------------------------"
    colorized_echo red "Using SQLite as database"
    echo "----------------------------"
    colorized_echo blue "Fetching compose file"
    curl -sL "$FILES_URL_PREFIX/docker-compose.yml" -o "$docker_file_path"

    colorized_echo blue "Fetching Dockerfile"
    curl -sL "$FILES_URL_PREFIX/Dockerfile" -o "$APP_DIR/Dockerfile"

    # Install requested version
    if [ "$vanish_vpn_version" == "latest" ]; then
            yq -i '.services.vanish_vpn.image = "sibermixru/vpn_queue:latest"' "$docker_file_path"
    fi
    echo "Installing $vanish_vpn_version version"
    colorized_echo green "File saved in $APP_DIR/docker-compose.yml"


    colorized_echo blue "Fetching .env file"
    curl -sL "$FILES_URL_PREFIX/.env.example" -o "$APP_DIR/.env"

    sed -i 's/^# \(XRAY_JSON = .*\)$/\1/' "$APP_DIR/.env"
    sed -i 's/^# \(SQLALCHEMY_DATABASE_URL = .*\)$/\1/' "$APP_DIR/.env"
    sed -i 's~\(XRAY_JSON = \).*~\1"var/lib/vanish/xray_config.json"~' "$APP_DIR/.env"
    sed -i 's~\(SQLALCHEMY_DATABASE_URL = \).*~\1"sqlite:///var/lib/vanish/db.sqlite3"~' "$APP_DIR/.env"





        
    colorized_echo green "File saved in $APP_DIR/.env"

    colorized_echo blue "Fetching xray config file"
    curl -sL "$FILES_URL_PREFIX/xray_config.json" -o "$DATA_DIR/xray_config.json"
    colorized_echo green "File saved in $DATA_DIR/xray_config.json"
    
    colorized_echo green "vanish_vpn's files downloaded successfully"
}

up_vanish_vpn() {
    $COMPOSE -f $COMPOSE_FILE -p "$APP_NAME" up -d --remove-orphans
}

follow_vanish_vpn_logs() {
    $COMPOSE -f $COMPOSE_FILE -p "$APP_NAME" logs -f
}

status_command() {
    
    # Проверка установлен ли vanish_vpn
    if ! is_vanish_vpn_installed; then
        echo -n "Статус: "
        colorized_echo red "Не установлен"
        exit 1
    fi
    
    detect_compose
    
    if ! is_vanish_vpn_up; then
        echo -n "Статус: "
        colorized_echo blue "Остановлен"
        exit 1
    fi
    
    echo -n "Статус: "
    colorized_echo green "Работает"
    
    json=$($COMPOSE -f $COMPOSE_FILE ps -a --format=json)
    services=$(echo "$json" | jq -r 'if type == "array" then .[] else . end | .Service')
    states=$(echo "$json" | jq -r 'if type == "array" then .[] else . end | .State')
    # Вывод имен сервисов и их статусов
    for i in $(seq 0 $(expr $(echo $services | wc -w) - 1)); do
        service=$(echo $services | cut -d' ' -f $(expr $i + 1))
        state=$(echo $states | cut -d' ' -f $(expr $i + 1))
        echo -n "- $service: "
        if [ "$state" == "running" ]; then
            colorized_echo green $state
        else
            colorized_echo red $state
        fi
    done
}

prompt_for_vanish_vpn_password() {
    colorized_echo cyan "Этот пароль будет использоваться для доступа к базе данных и должен быть надежным."
    colorized_echo cyan "Если вы не введете собственный пароль, будет автоматически сгенерирован безопасный 20-символьный пароль."

    read -p "Введите пароль для пользователя vanish_vpn (или нажмите Enter для генерации безопасного пароля по умолчанию): " MYSQL_PASSWORD

    if [ -z "$MYSQL_PASSWORD" ]; then
        MYSQL_PASSWORD=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 20)
        colorized_echo green "Безопасный пароль был сгенерирован автоматически."
    fi
    colorized_echo green "Этот пароль будет сохранен в файле .env для дальнейшего использования."

    sleep 3
}

install_command() {
    check_running_as_root

    # Значения по умолчанию
    database_type="sqlite"
    vanish_vpn_version="latest"
    vanish_vpn_version_set="false"

    # Разбор параметров
    while [[ $# -gt 0 ]]; do
        key="$1"
        case $key in
            --database)
                database_type="$2"
                shift 2
            ;;
            --dev)
                if [[ "$vanish_vpn_version_set" == "true" ]]; then
                    colorized_echo red "Ошибка: Нельзя использовать опции --dev и --version одновременно."
                    exit 1
                fi
                vanish_vpn_version="dev"
                vanish_vpn_version_set="true"
                shift
            ;;
            --version)
                if [[ "$vanish_vpn_version_set" == "true" ]]; then
                    colorized_echo red "Ошибка: Нельзя использовать опции --dev и --version одновременно."
                    exit 1
                fi
                vanish_vpn_version="$2"
                vanish_vpn_version_set="true"
                shift 2
            ;;
            *)
                echo "Неизвестная опция: $1"
                exit 1
            ;;
        esac
    done

    # Проверка, установлен ли уже vanish_vpn
    if is_vanish_vpn_installed; then
        colorized_echo red "vanish_vpn уже установлен в $APP_DIR"
        read -p "Хотите переустановить предыдущую установку? (y/n) "
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            colorized_echo red "Установка прервана"
            exit 1
        fi
    fi
    detect_os
    if ! command -v jq >/dev/null 2>&1; then
        install_package jq
    fi
    if ! command -v curl >/dev/null 2>&1; then
        install_package curl
    fi
    if ! command -v docker >/dev/null 2>&1; then
        install_docker
    fi
    if ! command -v yq >/dev/null 2>&1; then
        install_yq
    fi
    detect_compose
    install_vanish_vpn_script
    
    # Функция для проверки существования версии в релизах GitHub
    check_version_exists() {
        local version=$1
        repo_url="https://api.github.com/repos/SiberMix/vpn_seller/releases"
        if [ "$version" == "latest" ] || [ "$version" == "dev" ]; then
            return 0
        fi
        
        # Получение данных релиза из GitHub API
        response=$(curl -s "$repo_url")
        
        # Проверка содержит ли ответ тег версии
        if echo "$response" | jq -e ".[] | select(.tag_name == \"${version}\")" > /dev/null; then
            return 0
        else
            return 1
        fi
    }
    
    # Проверка валидности версии
    if [[ "$vanish_vpn_version" == "latest" || "$vanish_vpn_version" == "dev" || "$vanish_vpn_version" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        if check_version_exists "$vanish_vpn_version"; then
            install_vanish_vpn "$vanish_vpn_version" "$database_type"
            echo "Установка версии $vanish_vpn_version"
        else
            echo "Версия $vanish_vpn_version не существует. Пожалуйста, введите правильную версию (например, v0.5.2)"
            exit 1
        fi
    else
        echo "Неверный формат версии. Пожалуйста, введите правильную версию (например, v0.5.2)"
        exit 1
    fi
    up_vanish_vpn
    follow_vanish_vpn_logs
}

install_yq() {
    if command -v yq &>/dev/null; then
        colorized_echo green "yq уже установлен."
        return
    fi

    identify_the_operating_system_and_architecture

    local base_url="https://github.com/mikefarah/yq/releases/latest/download"
    local yq_binary=""

    case "$ARCH" in
        '64' | 'x86_64')
            yq_binary="yq_linux_amd64"
            ;;
        'arm32-v7a' | 'arm32-v6' | 'arm32-v5' | 'armv7l')
            yq_binary="yq_linux_arm"
            ;;
        'arm64-v8a' | 'aarch64')
            yq_binary="yq_linux_arm64"
            ;;
        '32' | 'i386' | 'i686')
            yq_binary="yq_linux_386"
            ;;
        *)
            colorized_echo red "Неподдерживаемая архитектура: $ARCH"
            exit 1
            ;;
    esac

    local yq_url="${base_url}/${yq_binary}"
    colorized_echo blue "Загрузка yq из ${yq_url}..."

    if ! command -v curl &>/dev/null && ! command -v wget &>/dev/null; then
        colorized_echo yellow "Ни curl, ни wget не установлены. Попытка установить curl."
        install_package curl || {
            colorized_echo red "Не удалось установить curl. Пожалуйста, установите curl или wget вручную."
            exit 1
        }
    fi

    if command -v curl &>/dev/null; then
        if curl -L "$yq_url" -o /usr/local/bin/yq; then
            chmod +x /usr/local/bin/yq
            colorized_echo green "yq успешно установлен!"
        else
            colorized_echo red "Не удалось загрузить yq с помощью curl. Проверьте подключение к интернету."
            exit 1
        fi
    elif command -v wget &>/dev/null; then
        if wget -O /usr/local/bin/yq "$yq_url"; then
            chmod +x /usr/local/bin/yq
            colorized_echo green "yq успешно установлен!"
        else
            colorized_echo red "Не удалось загрузить yq с помощью wget. Проверьте подключение к интернету."
            exit 1
        fi
    fi

    if ! echo "$PATH" | grep -q "/usr/local/bin"; then
        export PATH="/usr/local/bin:$PATH"
    fi

    hash -r

    if command -v yq &>/dev/null; then
        colorized_echo green "yq готов к использованию."
    elif [ -x "/usr/local/bin/yq" ]; then
        colorized_echo yellow "yq установлен в /usr/local/bin/yq, но не найден в PATH."
        colorized_echo yellow "Вы можете добавить /usr/local/bin в переменную окружения PATH."
    else
        colorized_echo red "Установка yq не удалась. Попробуйте снова или установите вручную."
        exit 1
    fi
}

down_vanish_vpn() {
    $COMPOSE -f $COMPOSE_FILE -p "$APP_NAME" down
}

show_vanish_vpn_logs() {
    $COMPOSE -f $COMPOSE_FILE -p "$APP_NAME" logs
}

follow_vanish_vpn_logs() {
    $COMPOSE -f $COMPOSE_FILE -p "$APP_NAME" logs -f
}

vanish_vpn_cli() {
    $COMPOSE -f $COMPOSE_FILE -p "$APP_NAME" exec -e CLI_PROG_NAME="vanish_vpn cli" vanish_vpn vanish_vpn-cli "$@"
}

is_vanish_vpn_up() {
    if [ -z "$($COMPOSE -f $COMPOSE_FILE ps -q -a)" ]; then
        return 1
    else
        return 0
    fi
}

uninstall_command() {
    check_running_as_root
    # Проверка установлен ли vanish_vpn
    if ! is_vanish_vpn_installed; then
        colorized_echo red "vanish_vpn не установлен!"
        exit 1
    fi
    
    read -p "Вы действительно хотите удалить vanish_vpn? (y/n) "
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        colorized_echo red "Отменено"
        exit 1
    fi
    
    detect_compose
    if is_vanish_vpn_up; then
        down_vanish_vpn
    fi
    uninstall_vanish_vpn_script
    uninstall_vanish_vpn
    uninstall_vanish_vpn_docker_images
    
    read -p "Хотите также удалить файлы данных vanish_vpn ($DATA_DIR)? (y/n) "
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        colorized_echo green "vanish_vpn uninstalled successfully"
    else
        uninstall_vanish_vpn_data_files
        colorized_echo green "vanish_vpn uninstalled successfully"
    fi
}

uninstall_vanish_vpn_script() {
    if [ -f "/usr/local/bin/vanish_vpn" ]; then
        colorized_echo yellow "Удаление скрипта vanish_vpn"
        rm "/usr/local/bin/vanish_vpn"
    fi
}

uninstall_vanish_vpn() {
    if [ -d "$APP_DIR" ]; then
        colorized_echo yellow "Удаление директории: $APP_DIR"
        rm -r "$APP_DIR"
    fi
}

uninstall_vanish_vpn_docker_images() {
    images=$(docker images | grep vanish_vpn | awk '{print $3}')
    
    if [ -n "$images" ]; then
        colorized_echo yellow "Удаление Docker образов vanish_vpn"
        for image in $images; do
            if docker rmi "$image" >/dev/null 2>&1; then
                colorized_echo yellow "Образ $image удален"
            fi
        done
    fi
}

uninstall_vanish_vpn_data_files() {
    if [ -d "$DATA_DIR" ]; then
        colorized_echo yellow "Удаление директории: $DATA_DIR"
        rm -r "$DATA_DIR"
    fi
}

restart_command() {
    help() {
        colorized_echo red "Использование: vanish_vpn restart [опции]"
        echo
        echo "ОПЦИИ:"
        echo "  -h, --help        показать это сообщение справки"
        echo "  -n, --no-logs     не следить за логами после запуска"
    }
    
    local no_logs=false
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            -n|--no-logs)
                no_logs=true
            ;;
            -h|--help)
                help
                exit 0
            ;;
            *)
                echo "Ошибка: Неверная опция: $1" >&2
                help
                exit 0
            ;;
        esac
        shift
    done
    
    # Проверка установлен ли vanish_vpn
    if ! is_vanish_vpn_installed; then
        colorized_echo red "vanish_vpn не установлен!"
        exit 1
    fi
    
    detect_compose
    
    down_vanish_vpn
    up_vanish_vpn
    if [ "$no_logs" = false ]; then
        follow_vanish_vpn_logs
    fi
    colorized_echo green "vanish_vpn успешно перезапущен!"
}

logs_command() {
    help() {
        colorized_echo red "Использование: vanish_vpn logs [опции]"
        echo ""
        echo "ОПЦИИ:"
        echo "  -h, --help        показать это сообщение справки"
        echo "  -n, --no-follow   не следить за логами"
    }
    
    local no_follow=false
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            -n|--no-follow)
                no_follow=true
            ;;
            -h|--help)
                help
                exit 0
            ;;
            *)
                echo "Ошибка: Неверная опция: $1" >&2
                help
                exit 0
            ;;
        esac
        shift
    done
    
    # Проверка установлен ли vanish_vpn
    if ! is_vanish_vpn_installed; then
        colorized_echo red "vanish_vpn не установлен!"
        exit 1
    fi
    
    detect_compose
    
    if ! is_vanish_vpn_up; then
        colorized_echo red "vanish_vpn не запущен."
        exit 1
    fi
    
    if [ "$no_follow" = true ]; then
        show_vanish_vpn_logs
    else
        follow_vanish_vpn_logs
    fi
}

down_command() {
    
    # Проверка установлен ли vanish_vpn
    if ! is_vanish_vpn_installed; then
        colorized_echo red "vanish_vpn не установлен!"
        exit 1
    fi
    
    detect_compose
    
    if ! is_vanish_vpn_up; then
        colorized_echo red "vanish_vpn уже остановлен"
        exit 1
    fi
    
    down_vanish_vpn
}

cli_command() {
    # Проверка установлен ли vanish_vpn
    if ! is_vanish_vpn_installed; then
        colorized_echo red "vanish_vpn не установлен!"
        exit 1
    fi
    
    detect_compose
    
    if ! is_vanish_vpn_up; then
        colorized_echo red "vanish_vpn не запущен."
        exit 1
    fi
    
    vanish_vpn_cli "$@"
}

up_command() {
    help() {
        colorized_echo red "Использование: vanish_vpn up [опции]"
        echo ""
        echo "ОПЦИИ:"
        echo "  -h, --help        показать это сообщение справки"
        echo "  -n, --no-logs     не следить за логами после запуска"
    }
    
    local no_logs=false
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            -n|--no-logs)
                no_logs=true
            ;;
            -h|--help)
                help
                exit 0
            ;;
            *)
                echo "Ошибка: Неверная опция: $1" >&2
                help
                exit 0
            ;;
        esac
        shift
    done
    
    # Проверка установлен ли vanish_vpn
    if ! is_vanish_vpn_installed; then
        colorized_echo red "vanish_vpn не установлен!"
        exit 1
    fi
    
    detect_compose
    
    if is_vanish_vpn_up; then
        colorized_echo red "vanish_vpn уже запущен"
        exit 1
    fi
    
    up_vanish_vpn
    if [ "$no_logs" = false ]; then
        follow_vanish_vpn_logs
    fi
}

update_command() {
    check_running_as_root
    # Проверка установлен ли vanish_vpn
    if ! is_vanish_vpn_installed; then
        colorized_echo red "vanish_vpn не установлен!"
        exit 1
    fi
    
    detect_compose
    
    update_vanish_vpn_script
    colorized_echo blue "Загрузка последней версии"
    update_vanish_vpn
    
    colorized_echo blue "Перезапуск служб vanish_vpn"
    down_vanish_vpn
    up_vanish_vpn
    
    colorized_echo blue "vanish_vpn успешно обновлен"
}

update_vanish_vpn_script() {
    FETCH_REPO="SiberMix/vpn_seller"
    SCRIPT_URL="https://github.com/$FETCH_REPO/raw/master/scripts/vanish_vpn.sh"
    colorized_echo blue "Обновление скрипта vanish_vpn"
    curl -sSL $SCRIPT_URL | install -m 755 /dev/stdin /usr/local/bin/vanish_vpn
    colorized_echo green "Скрипт vanish_vpn успешно обновлен"
}

update_vanish_vpn() {
    $COMPOSE -f $COMPOSE_FILE -p "$APP_NAME" pull
}

check_editor() {
    if [ -z "$EDITOR" ]; then
        if command -v nano >/dev/null 2>&1; then
            EDITOR="nano"
            elif command -v vi >/dev/null 2>&1; then
            EDITOR="vi"
        else
            detect_os
            install_package nano
            EDITOR="nano"
        fi
    fi
}

edit_command() {
    detect_os
    check_editor
    if [ -f "$COMPOSE_FILE" ]; then
        $EDITOR "$COMPOSE_FILE"
    else
        colorized_echo red "Файл compose не найден в $COMPOSE_FILE"
        exit 1
    fi
}

edit_env_command() {
    detect_os
    check_editor
    if [ -f "$ENV_FILE" ]; then
        $EDITOR "$ENV_FILE"
    else
        colorized_echo red "Файл окружения не найден в $ENV_FILE"
        exit 1
    fi
}

usage() {
    local script_name="${0##*/}"
    colorized_echo blue "=============================="
    colorized_echo magenta "           Справка vanish_vpn"
    colorized_echo blue "=============================="
    colorized_echo cyan "Использование:"
    echo "  ${script_name} [команда]"
    echo

    colorized_echo cyan "Команды:"
    colorized_echo yellow "  up              $(tput sgr0)– Запуск служб"
    colorized_echo yellow "  down            $(tput sgr0)– Остановка служб"
    colorized_echo yellow "  restart         $(tput sgr0)– Перезапуск служб"
    colorized_echo yellow "  status          $(tput sgr0)– Показать статус"
    colorized_echo yellow "  logs            $(tput sgr0)– Показать логи"
    colorized_echo yellow "  cli             $(tput sgr0)– Интерфейс командной строки vanish_vpn"
    colorized_echo yellow "  install         $(tput sgr0)– Установить vanish_vpn"
    colorized_echo yellow "  update          $(tput sgr0)– Обновить до последней версии"
    colorized_echo yellow "  uninstall       $(tput sgr0)– Удалить vanish_vpn"
    colorized_echo yellow "  install-script  $(tput sgr0)– Установить скрипт vanish_vpn"
    colorized_echo yellow "  backup          $(tput sgr0)– Запуск ручного резервного копирования"
    colorized_echo yellow "  backup-service  $(tput sgr0)– Сервис резервного копирования vanish_vpn в Telegram и новая задача в crontab"
    colorized_echo yellow "  core-update     $(tput sgr0)– Обновить/Изменить ядро Xray"
    colorized_echo yellow "  edit            $(tput sgr0)– Редактировать docker-compose.yml (через редактор nano или vi)"
    colorized_echo yellow "  edit-env        $(tput sgr0)– Редактировать файл окружения (через редактор nano или vi)"
    colorized_echo yellow "  help            $(tput sgr0)– Показать это сообщение справки"
    
    
    echo
    colorized_echo cyan "Директории:"
    colorized_echo magenta "  Директория приложения: $APP_DIR"
    colorized_echo magenta "  Директория данных: $DATA_DIR"
    colorized_echo blue "================================"
    echo
}

case "$1" in
    up)
        shift; up_command "$@";;
    down)
        shift; down_command "$@";;
    restart)
        shift; restart_command "$@";;
    status)
        shift; status_command "$@";;
    logs)
        shift; logs_command "$@";;
    cli)
        shift; cli_command "$@";;
    backup)
        shift; backup_command "$@";;
    backup-service)
        shift; backup_service "$@";;
    install)
        shift; install_command "$@";;
    update)
        shift; update_command "$@";;
    uninstall)
        shift; uninstall_command "$@";;
    install-script)
        shift; install_vanish_vpn_script "$@";;
    core-update)
        shift; update_core_command "$@";;
    edit)
        shift; edit_command "$@";;
    edit-env)
        shift; edit_env_command "$@";;
    help|*)
        usage;;
esac
