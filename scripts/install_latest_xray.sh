#!/usr/bin/env bash

# Загрузка последней версии Xray

RELEASE_TAG="latest"

if [[ "$1" ]]; then
    RELEASE_TAG="$1"
fi

check_if_running_as_root() {
    # Если вы хотите запустить от имени другого пользователя, измените $EUID на ID этого пользователя
    if [[ "$EUID" -ne '0' ]]; then
        echo "ошибка: Вы должны запустить этот скрипт от имени root!"
        exit 1
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
                echo "ошибка: Эта архитектура не поддерживается."
                exit 1
            ;;
        esac
    else
        echo "ошибка: Эта операционная система не поддерживается."
        exit 1
    fi
}

download_xray() {
    if [[ "$RELEASE_TAG" == "latest" ]]; then
        DOWNLOAD_LINK="https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-$ARCH.zip"
    else
        DOWNLOAD_LINK="https://github.com/XTLS/Xray-core/releases/download/$RELEASE_TAG/Xray-linux-$ARCH.zip"
    fi
    
    echo "Загрузка архива Xray: $DOWNLOAD_LINK"
    if ! curl -RL -H 'Cache-Control: no-cache' -o "$ZIP_FILE" "$DOWNLOAD_LINK"; then
        echo 'ошибка: Загрузка не удалась! Пожалуйста, проверьте ваше подключение к сети или попробуйте снова.'
        return 1
    fi
}

extract_xray() {
    if ! unzip -q "$ZIP_FILE" -d "$TMP_DIRECTORY"; then
        echo 'ошибка: Распаковка Xray не удалась.'
        "rm" -rf "$TMP_DIRECTORY"
        echo "удалено: $TMP_DIRECTORY"
        exit 1
    fi
    echo "Архив Xray распакован в $TMP_DIRECTORY"
}

place_xray() {
    install -m 755 "${TMP_DIRECTORY}/xray" "/usr/local/bin/xray"
    install -d "/usr/local/share/xray/"
    install -m 644 "${TMP_DIRECTORY}/geoip.dat" "/usr/local/share/xray/geoip.dat"
    install -m 644 "${TMP_DIRECTORY}/geosite.dat" "/usr/local/share/xray/geosite.dat"
    echo "Файлы Xray установлены"
}

check_if_running_as_root
identify_the_operating_system_and_architecture

TMP_DIRECTORY="$(mktemp -d)"
ZIP_FILE="${TMP_DIRECTORY}/Xray-linux-$ARCH.zip"

download_xray
extract_xray
place_xray

"rm" -rf "$TMP_DIRECTORY"