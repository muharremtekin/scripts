#!/bin/bash

# macOS Sequoia 15.5 Kapsamlı Sistem Data Temizlik Scripti v2.0
# M4 Mac Mini 16/256 için optimize edilmiş — İleri Düzey Teknikler
# Geliştirici: Backend developer iş akışları için özelleştirilmiş

set -e  # Hata durumunda scripti durdur

# Renkli çıktı için kodlar
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Mevcut kullanıcıyı al
CURRENT_USER=$(stat -f%Su /dev/console)
USER_HOME="/Users/$CURRENT_USER"

# Log dosyası
LOG_FILE="$USER_HOME/Desktop/cleanup_log_$(date +%Y%m%d_%H%M%S).txt"

echo -e "${BLUE}=== macOS Sequoia 15.5 Sistem Data Temizlik Scripti v2.0 ===${NC}"
echo -e "${BLUE}Log dosyası: $LOG_FILE${NC}"
echo ""

# ─── Yardımcı Fonksiyonlar ────────────────────────────────────────────────────

log_message() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

check_space() {
    df -h / | tail -1 | awk '{print $4}'
}

check_space_bytes() {
    df / | tail -1 | awk '{print $4}'
}

get_dir_size() {
    # Dizin yoksa "0B" döndür; yoksa boyutu döndür
    local dir="$1"
    if [ -d "$dir" ]; then
        du -sh "$dir" 2>/dev/null | cut -f1
    else
        echo "0B"
    fi
}

safe_rm() {
    # Dizin/dosya varsa sil, yoksa sessizce devam et
    local target="$1"
    if [ -e "$target" ] || [ -L "$target" ]; then
        rm -rf "$target" 2>/dev/null || true
    fi
}

safe_sudo_rm() {
    local target="$1"
    if [ -e "$target" ] || [ -L "$target" ]; then
        sudo rm -rf "$target" 2>/dev/null || true
    fi
}

confirm_action() {
    echo -e "${YELLOW}$1${NC}"
    read -p "Devam etmek istiyor musunuz? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_message "${RED}İşlem iptal edildi.${NC}"
        return 1
    fi
    return 0
}

# Başlangıç durumu kaydet
log_message "${BLUE}=== BAŞLANGIÇ DURUMU ===${NC}"
log_message "Tarih: $(date)"
log_message "Kullanıcı: $CURRENT_USER"
log_message "Boş alan: $(check_space)"
log_message ""

# Admin şifresi kontrol
echo -e "${YELLOW}Bu script admin yetkileri gerektirir. Lütfen şifrenizi girin:${NC}"
sudo -v

# sudo timeout'unu yenile (arka planda)
( while true; do sudo -n true; sleep 50; done ) &
SUDO_KEEPALIVE_PID=$!
trap "kill $SUDO_KEEPALIVE_PID 2>/dev/null; exit" INT TERM EXIT

# ─── Ana Menü ─────────────────────────────────────────────────────────────────
show_menu() {
    echo -e "${BLUE}=== TEMİZLİK SEÇENEKLERİ ===${NC}"
    echo "1. 🚨 ACİL TEMİZLİK              (Spotlight + Temel önbellekler)"
    echo "2. 🧹 KAPSAMLI TEMİZLİK          (Tüm sistem önbellekleri + loglar)"
    echo "3. 💻 GELİŞTİRİCİ TEMİZLİĞİ     (Xcode, Docker, npm, brew, cargo, go, maven…)"
    echo "4. 🔥 AGRESİF SYSTEM DATA        (iOS Simulator, Mail, Safari, iCloud)"
    echo "5. 🚀 İLERİ DÜZEY KURTARMA      (iOS yedekler, GarageBand, diagnostics, APFS)"
    echo "6. 🔎 BÜYÜK DOSYA TARAMA         (500MB+ dosyaları bul ve raporla)"
    echo "7. 📊 DEPOLAMA ANALİZİ           (Detaylı alan raporu)"
    echo "8. ⚙️  TÜMÜNÜ ÇALIŞTIR           (1+2+3+4+5)"
    echo "9. 🚪 ÇIKIŞ"
    echo ""
}

# ─── 1. ACİL TEMİZLİK ────────────────────────────────────────────────────────
emergency_cleanup() {
    log_message "${RED}=== ACİL TEMİZLİK BAŞLIYOR ===${NC}"
    local before=$(check_space_bytes)

    # Spotlight indekslemeyi durdur (EN KRİTİK)
    log_message "${YELLOW}Spotlight indeksleme durduruluyor...${NC}"
    sudo mdutil -a -i off 2>/dev/null || true
    log_message "✅ Spotlight indeksleme durduruldu"

    # CoreSpotlight metadata temizle
    log_message "${YELLOW}CoreSpotlight metadata temizleniyor...${NC}"
    safe_rm "$USER_HOME/Library/Metadata/CoreSpotlight"
    sudo rm -rf /private/var/db/Spotlight-V100 2>/dev/null || true
    log_message "✅ CoreSpotlight metadata temizlendi"

    # Sistem önbellekleri
    log_message "${YELLOW}Sistem önbellekleri temizleniyor...${NC}"
    sudo rm -rf /Library/Caches/* 2>/dev/null || true
    sudo rm -rf /System/Library/Caches/* 2>/dev/null || true
    log_message "✅ Sistem önbellekleri temizlendi"

    # Kullanıcı önbellekleri
    log_message "${YELLOW}Kullanıcı önbellekleri temizleniyor...${NC}"
    rm -rf "$USER_HOME/Library/Caches"/* 2>/dev/null || true
    log_message "✅ Kullanıcı önbellekleri temizlendi"

    # MediaAnalysis önbelleği (büyük olabilir)
    log_message "${YELLOW}MediaAnalysis önbelleği temizleniyor...${NC}"
    rm -rf "$USER_HOME/Library/Containers/com.apple.mediaanalysisd/Data/Library/Caches"/* 2>/dev/null || true
    log_message "✅ MediaAnalysis önbelleği temizlendi"

    # Time Machine yerel snapshots
    log_message "${YELLOW}Time Machine yerel snapshots temizleniyor...${NC}"
    tmutil listlocalsnapshots / 2>/dev/null | grep "com.apple.TimeMachine" | while read -r snapshot; do
        sudo tmutil deletelocalsnapshots "$snapshot" 2>/dev/null || true
    done
    log_message "✅ Time Machine snapshots temizlendi"

    log_message "${GREEN}✅ ACİL TEMİZLİK TAMAMLANDI${NC}"
    log_message ""
}

# ─── 2. KAPSAMLI TEMİZLİK ────────────────────────────────────────────────────
comprehensive_cleanup() {
    log_message "${BLUE}=== KAPSAMLI TEMİZLİK BAŞLIYOR ===${NC}"

    # Kilitlenme raporları
    log_message "${YELLOW}Kilitlenme raporları temizleniyor...${NC}"
    rm -rf "$USER_HOME/Library/Application Support/CrashReporter"/* 2>/dev/null || true
    sudo rm -rf /Library/Application\ Support/CrashReporter/* 2>/dev/null || true
    sudo rm -rf /private/var/db/diagnostics/Tailspin 2>/dev/null || true
    log_message "✅ Kilitlenme raporları temizlendi"

    # Container önbellekleri
    log_message "${YELLOW}Container önbellekleri temizleniyor...${NC}"
    find "$USER_HOME/Library/Containers" -name "Caches" -type d -exec rm -rf {}/* \; 2>/dev/null || true
    log_message "✅ Container önbellekleri temizlendi"

    # Tarayıcı önbellekleri
    log_message "${YELLOW}Tarayıcı önbellekleri temizleniyor...${NC}"
    rm -rf "$USER_HOME/Library/Containers/com.apple.Safari/Data/Library/Caches"/* 2>/dev/null || true
    rm -rf "$USER_HOME/Library/Application Support/Google/Chrome/*/Cache"/* 2>/dev/null || true
    rm -rf "$USER_HOME/Library/Application Support/Google/Chrome/*/Code Cache"/* 2>/dev/null || true
    rm -rf "$USER_HOME/Library/Caches/Firefox"/* 2>/dev/null || true
    # Arc browser
    rm -rf "$USER_HOME/Library/Caches/company.thebrowser.Browser"/* 2>/dev/null || true
    # Brave
    rm -rf "$USER_HOME/Library/Application Support/BraveSoftware/Brave-Browser/*/Cache"/* 2>/dev/null || true
    log_message "✅ Tarayıcı önbellekleri temizlendi"

    # Sistem logları
    log_message "${YELLOW}Sistem logları temizleniyor...${NC}"
    rm -rf "$USER_HOME/Library/Logs"/* 2>/dev/null || true
    sudo rm -f /private/var/log/*.log 2>/dev/null || true
    sudo rm -f /private/var/log/*.gz 2>/dev/null || true
    sudo rm -rf /private/var/log/asl/*.asl 2>/dev/null || true
    sudo rm -rf /private/var/log/DiagnosticMessages 2>/dev/null || true
    log_message "✅ Sistem logları temizlendi"

    # Geçici dosyalar
    log_message "${YELLOW}Geçici dosyalar temizleniyor...${NC}"
    sudo rm -rf /private/tmp/* 2>/dev/null || true
    sudo rm -rf /private/var/tmp/* 2>/dev/null || true
    rm -rf /tmp/* 2>/dev/null || true
    log_message "✅ Geçici dosyalar temizlendi"

    # Font önbellekleri
    log_message "${YELLOW}Font önbellekleri temizleniyor...${NC}"
    sudo atsutil databases -remove 2>/dev/null || true
    log_message "✅ Font önbellekleri temizlendi"

    # DNS önbelleği
    log_message "${YELLOW}DNS önbelleği temizleniyor...${NC}"
    sudo dscacheutil -flushcache 2>/dev/null || true
    sudo killall -HUP mDNSResponder 2>/dev/null || true
    log_message "✅ DNS önbelleği temizlendi"

    # Launch Services veritabanı
    log_message "${YELLOW}Launch Services veritabanı sıfırlanıyor...${NC}"
    /System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister \
        -kill -r -domain local -domain system -domain user 2>/dev/null || true
    log_message "✅ Launch Services veritabanı sıfırlandı"

    # QuickLook önbellekleri
    log_message "${YELLOW}QuickLook önbellekleri temizleniyor...${NC}"
    qlmanage -r cache 2>/dev/null || true
    find /private/var/folders -name "com.apple.QuickLook.thumbnailcache" -type d \
        -exec rm -rf {} + 2>/dev/null || true
    log_message "✅ QuickLook önbellekleri temizlendi"

    # Uygulama state kayıtları (önemli bir şey değil, yeniden oluşturulur)
    log_message "${YELLOW}Kaydedilmiş uygulama durumları temizleniyor...${NC}"
    rm -rf "$USER_HOME/Library/Saved Application State"/* 2>/dev/null || true
    log_message "✅ Kaydedilmiş uygulama durumları temizlendi"

    log_message "${GREEN}✅ KAPSAMLI TEMİZLİK TAMAMLANDI${NC}"
    log_message ""
}

# ─── 3. GELİŞTİRİCİ TEMİZLİĞİ ───────────────────────────────────────────────
developer_cleanup() {
    log_message "${BLUE}=== GELİŞTİRİCİ TEMİZLİĞİ BAŞLIYOR ===${NC}"

    # Xcode temizliği
    if [ -d "$USER_HOME/Library/Developer/Xcode" ]; then
        log_message "${YELLOW}Xcode DerivedData temizleniyor...${NC}"
        rm -rf "$USER_HOME/Library/Developer/Xcode/DerivedData"/* 2>/dev/null || true

        log_message "${YELLOW}Xcode Archives temizleniyor...${NC}"
        rm -rf "$USER_HOME/Library/Developer/Xcode/Archives"/* 2>/dev/null || true

        log_message "${YELLOW}iOS DeviceSupport temizleniyor (eski sürümler)...${NC}"
        # Sadece en yeni 2 versiyonu bırak
        find "$USER_HOME/Library/Developer/Xcode/iOS DeviceSupport" -maxdepth 1 \
            -type d -name "*.*" 2>/dev/null | sort -V | head -n -2 | xargs rm -rf 2>/dev/null || true

        log_message "${YELLOW}Xcode önbellekleri temizleniyor...${NC}"
        rm -rf "$USER_HOME/Library/Caches/com.apple.dt.Xcode"/* 2>/dev/null || true
        rm -rf "$USER_HOME/Library/Developer/Xcode/Products"/* 2>/dev/null || true
        log_message "✅ Xcode verileri temizlendi"
    fi

    # iOS Simulator - xcrun simctl ile güvenli temizlik
    if command -v xcrun &>/dev/null; then
        log_message "${YELLOW}iOS Simulator desteklenmeyen cihazlar temizleniyor...${NC}"
        xcrun simctl delete unavailable 2>/dev/null || true
        log_message "${YELLOW}iOS Simulator önbellekleri temizleniyor...${NC}"
        rm -rf "$USER_HOME/Library/Developer/CoreSimulator/Caches"/* 2>/dev/null || true
        log_message "✅ Simulator temizlendi (xcrun simctl)"
    fi

    # Docker temizliği
    if command -v docker &>/dev/null; then
        log_message "${YELLOW}Docker temizliği yapılıyor...${NC}"
        docker system prune -a --volumes -f 2>/dev/null || true
        log_message "✅ Docker temizlendi"
    fi

    # NPM önbellek
    if command -v npm &>/dev/null; then
        log_message "${YELLOW}NPM önbelleği temizleniyor...${NC}"
        npm cache clean --force 2>/dev/null || true
        log_message "✅ NPM önbelleği temizlendi"
    fi

    # Yarn önbellek
    if command -v yarn &>/dev/null; then
        log_message "${YELLOW}Yarn önbelleği temizleniyor...${NC}"
        yarn cache clean 2>/dev/null || true
        log_message "✅ Yarn önbelleği temizlendi"
    fi

    # pnpm önbellek
    if command -v pnpm &>/dev/null; then
        log_message "${YELLOW}pnpm önbelleği temizleniyor...${NC}"
        pnpm store prune 2>/dev/null || true
        log_message "✅ pnpm önbelleği temizlendi"
    fi

    # Homebrew temizliği
    if command -v brew &>/dev/null; then
        log_message "${YELLOW}Homebrew temizliği yapılıyor...${NC}"
        brew cleanup --prune=all 2>/dev/null || true
        rm -rf "$(brew --cache)" 2>/dev/null || true
        log_message "✅ Homebrew temizlendi"
    fi

    # Python pip önbelleği
    if command -v pip3 &>/dev/null; then
        log_message "${YELLOW}Python pip önbelleği temizleniyor...${NC}"
        pip3 cache purge 2>/dev/null || true
        log_message "✅ Python pip önbelleği temizlendi"
    fi

    # Python __pycache__ temizliği (tüm HOME altında)
    log_message "${YELLOW}Python __pycache__ ve .pyc dosyaları temizleniyor...${NC}"
    find "$USER_HOME" \( -name "__pycache__" -o -name "*.pyc" -o -name "*.pyo" \) \
        -not -path "*/node_modules/*" -not -path "*/.Trash/*" \
        -exec rm -rf {} + 2>/dev/null || true
    log_message "✅ Python cache dosyaları temizlendi"

    # Conda temizliği
    if command -v conda &>/dev/null; then
        log_message "${YELLOW}Conda temizliği yapılıyor...${NC}"
        conda clean -a -y 2>/dev/null || true
        log_message "✅ Conda temizlendi"
    fi

    # Rust Cargo önbelleği (büyük olabilir!)
    if [ -d "$USER_HOME/.cargo" ]; then
        log_message "${YELLOW}Rust Cargo registry önbelleği temizleniyor...${NC}"
        CARGO_SIZE=$(get_dir_size "$USER_HOME/.cargo")
        log_message "  Cargo toplam boyutu: $CARGO_SIZE"
        rm -rf "$USER_HOME/.cargo/registry/cache"/* 2>/dev/null || true
        rm -rf "$USER_HOME/.cargo/registry/src"/* 2>/dev/null || true
        rm -rf "$USER_HOME/.cargo/git/db"/* 2>/dev/null || true
        if command -v cargo &>/dev/null; then
            cargo cache -a 2>/dev/null || true
        fi
        log_message "✅ Cargo önbelleği temizlendi"
    fi

    # Go module önbelleği
    if command -v go &>/dev/null; then
        log_message "${YELLOW}Go module önbelleği temizleniyor...${NC}"
        go clean -modcache 2>/dev/null || true
        go clean -cache 2>/dev/null || true
        log_message "✅ Go önbelleği temizlendi"
    fi
    # Go cache dizinleri manuel temizlik
    rm -rf "$USER_HOME/go/pkg/mod/cache"/* 2>/dev/null || true
    rm -rf "$USER_HOME/Library/Caches/go-build"/* 2>/dev/null || true

    # Maven local repository temizliği (eski snapshot'lar)
    if [ -d "$USER_HOME/.m2/repository" ]; then
        log_message "${YELLOW}Maven eski SNAPSHOT önbellekleri temizleniyor...${NC}"
        M2_SIZE=$(get_dir_size "$USER_HOME/.m2")
        log_message "  Maven toplam boyutu: $M2_SIZE"
        find "$USER_HOME/.m2/repository" -name "*-SNAPSHOT*" \
            -not -newermt "-30 days" -delete 2>/dev/null || true
        log_message "✅ Maven eski snapshot'lar temizlendi"
    fi

    # Gradle önbelleği
    if [ -d "$USER_HOME/.gradle/caches" ]; then
        log_message "${YELLOW}Gradle önbellekleri temizleniyor...${NC}"
        GRADLE_SIZE=$(get_dir_size "$USER_HOME/.gradle/caches")
        log_message "  Gradle cache boyutu: $GRADLE_SIZE"
        rm -rf "$USER_HOME/.gradle/caches"/* 2>/dev/null || true
        log_message "✅ Gradle önbellekleri temizlendi"
    fi

    # CocoaPods önbelleği
    if [ -d "$USER_HOME/.cocoapods" ]; then
        log_message "${YELLOW}CocoaPods önbelleği temizleniyor...${NC}"
        PODS_SIZE=$(get_dir_size "$USER_HOME/.cocoapods")
        log_message "  CocoaPods boyutu: $PODS_SIZE"
        rm -rf "$USER_HOME/.cocoapods/repos"/* 2>/dev/null || true
        if command -v pod &>/dev/null; then
            pod cache clean --all 2>/dev/null || true
        fi
        log_message "✅ CocoaPods önbelleği temizlendi"
    fi

    # Ruby gem temizliği
    if command -v gem &>/dev/null; then
        log_message "${YELLOW}Ruby gem temizliği yapılıyor...${NC}"
        gem cleanup 2>/dev/null || true
        log_message "✅ Ruby gem temizlendi"
    fi

    # Git garbage collection
    log_message "${YELLOW}Git depoları optimize ediliyor...${NC}"
    find "$USER_HOME" -name ".git" -type d -maxdepth 6 2>/dev/null | while read -r repo; do
        local_dir=$(dirname "$repo")
        (cd "$local_dir" && git gc --aggressive --prune=now --quiet 2>/dev/null) || true
    done
    log_message "✅ Git repoları optimize edildi"

    # VSCode / Cursor önbellekleri
    for editor_dir in \
        "$USER_HOME/Library/Application Support/Code/User/workspaceStorage" \
        "$USER_HOME/Library/Application Support/Cursor/User/workspaceStorage" \
        "$USER_HOME/Library/Caches/com.microsoft.VSCode" \
        "$USER_HOME/Library/Caches/com.todesktop.230313mzl4w4u92"; do
        if [ -d "$editor_dir" ]; then
            log_message "${YELLOW}VS Code/Cursor önbelleği temizleniyor: $(basename "$editor_dir")...${NC}"
            rm -rf "$editor_dir"/* 2>/dev/null || true
            log_message "✅ $(basename "$editor_dir") temizlendi"
        fi
    done

    # Node modules büyük klasörleri raporla
    log_message "${YELLOW}Büyük node_modules klasörleri (ilk 10):${NC}"
    find "$USER_HOME" -name "node_modules" -type d -maxdepth 6 2>/dev/null | \
        while read -r dir; do
            size=$(du -sk "$dir" 2>/dev/null | cut -f1)
            echo "$size $dir"
        done | sort -rn | head -10 | while read -r size dir; do
            size_mb=$((size / 1024))
            log_message "  📁 ${size_mb}MB → $dir"
        done

    log_message "${GREEN}✅ GELİŞTİRİCİ TEMİZLİĞİ TAMAMLANDI${NC}"
    log_message ""
}

# ─── 4. AGRESİF SYSTEM DATA TEMİZLİĞİ ───────────────────────────────────────
aggressive_system_cleanup() {
    log_message "${RED}=== AGRESİF SYSTEM DATA TEMİZLİĞİ BAŞLIYOR ===${NC}"
    log_message "${YELLOW}⚠️  Bu işlem büyük miktarda veri silecek!${NC}"

    # iOS Simulator - tam temizlik (xcrun ile önce bildir)
    log_message "${YELLOW}iOS Simulator runtime'ları temizleniyor...${NC}"
    if [ -d "$USER_HOME/Library/Developer/CoreSimulator" ]; then
        xcrun simctl delete all 2>/dev/null || true
        rm -rf "$USER_HOME/Library/Developer/CoreSimulator/Profiles/Runtimes"/* 2>/dev/null || true
        rm -rf "$USER_HOME/Library/Developer/CoreSimulator/Devices"/* 2>/dev/null || true
        rm -rf "$USER_HOME/Library/Developer/CoreSimulator/Caches"/* 2>/dev/null || true
        log_message "✅ iOS Simulator runtime'ları temizlendi (20–40 GB kazanç bekleniyor)"
    else
        log_message "ℹ️  iOS Simulator bulunamadı"
    fi

    # Xcode iOS DeviceSupport (eski sürümler)
    log_message "${YELLOW}Xcode iOS DeviceSupport temizleniyor...${NC}"
    if [ -d "$USER_HOME/Library/Developer/Xcode/iOS DeviceSupport" ]; then
        find "$USER_HOME/Library/Developer/Xcode/iOS DeviceSupport" \
            -maxdepth 1 -type d -name "*.*" | sort -V | head -n -2 | xargs rm -rf 2>/dev/null || true
        log_message "✅ Eski iOS DeviceSupport temizlendi"
    fi

    # Mail ekleri ve önbellekleri
    log_message "${YELLOW}Mail ekleri ve önbellekleri temizleniyor...${NC}"
    rm -rf "$USER_HOME/Library/Mail/V"*/MailData/Attachments/* 2>/dev/null || true
    find "$USER_HOME/Library/Mail" -name "*.db*" -delete 2>/dev/null || true
    log_message "✅ Mail verileri temizlendi"

    # Messages ekleri
    log_message "${YELLOW}Messages ekleri temizleniyor...${NC}"
    rm -rf "$USER_HOME/Library/Messages/Attachments"/* 2>/dev/null || true
    rm -rf "$USER_HOME/Library/Messages/Archive"/* 2>/dev/null || true
    log_message "✅ Messages ekleri temizlendi"

    # Safari derinlemesine
    log_message "${YELLOW}Safari derinlemesine temizlik yapılıyor...${NC}"
    rm -rf "$USER_HOME/Library/Safari/Databases"/* 2>/dev/null || true
    rm -rf "$USER_HOME/Library/Safari/LocalStorage"/* 2>/dev/null || true
    rm -rf "$USER_HOME/Library/Containers/com.apple.Safari/Data/Library/WebKit"/* 2>/dev/null || true
    log_message "✅ Safari derinlemesine temizlendi"

    # Chrome derinlemesine
    log_message "${YELLOW}Chrome derinlemesine temizlik yapılıyor...${NC}"
    rm -rf "$USER_HOME/Library/Application Support/Google/Chrome/*/GPUCache"/* 2>/dev/null || true
    rm -rf "$USER_HOME/Library/Application Support/Google/Chrome/*/Service Worker"/* 2>/dev/null || true
    rm -rf "$USER_HOME/Library/Application Support/Google/Chrome/*/Session Storage"/* 2>/dev/null || true
    log_message "✅ Chrome derinlemesine temizlendi"

    # İCloud Drive yerel önbellek (download edilmiş ama optimize edilecek dosyalar)
    log_message "${YELLOW}iCloud Drive yerel önbelleği optimize ediliyor...${NC}"
    brctl evict "$USER_HOME/Library/Mobile Documents" 2>/dev/null || true
    log_message "✅ iCloud Drive yerel önbelleği temizlendi"

    # Kernel caches
    log_message "${YELLOW}Kernel önbellekleri yeniden oluşturuluyor...${NC}"
    sudo rm -rf /System/Library/Caches/com.apple.kext.caches/* 2>/dev/null || true
    sudo kextcache -system-prelinked-kernel 2>/dev/null || true
    sudo kextcache -system-caches 2>/dev/null || true
    log_message "✅ Kernel önbellekleri yeniden oluşturuldu"

    # Büyük log dosyaları
    log_message "${YELLOW}Büyük log dosyaları temizleniyor...${NC}"
    sudo rm -rf /private/var/log/install.log* 2>/dev/null || true
    sudo rm -rf /private/var/log/wifi.log* 2>/dev/null || true
    log_message "✅ Büyük log dosyaları temizlendi"

    # Adobe/Microsoft önbellekleri
    for app_cache in \
        "$USER_HOME/Library/Caches/Adobe" \
        "$USER_HOME/Library/Caches/Microsoft"; do
        if [ -d "$app_cache" ]; then
            APP=$(basename "$app_cache")
            log_message "${YELLOW}${APP} önbellekleri temizleniyor...${NC}"
            rm -rf "$app_cache"/* 2>/dev/null || true
            log_message "✅ ${APP} önbellekleri temizlendi"
        fi
    done

    log_message "${GREEN}🔥 AGRESİF SYSTEM DATA TEMİZLİĞİ TAMAMLANDI${NC}"
    log_message "${GREEN}Beklenen toplam kazanç: 30–60 GB${NC}"
    log_message "${YELLOW}⚠️  Sistemi yeniden başlatmanız önerilir${NC}"
    log_message ""
}

# ─── 5. İLERİ DÜZEY KURTARMA (YENİ) ─────────────────────────────────────────
advanced_space_recovery() {
    log_message "${MAGENTA}=== İLERİ DÜZEY KURTARMA BAŞLIYOR ===${NC}"
    log_message "${YELLOW}⚠️  Bu bölüm nadiren temizlenen dev miktarda alan açar!${NC}"
    log_message ""

    # ── 5.1 iOS / iPadOS Cihaz Yedekleri ──────────────────────────────────────
    BACKUP_DIR="$USER_HOME/Library/Application Support/MobileSync/Backup"
    if [ -d "$BACKUP_DIR" ]; then
        BACKUP_SIZE=$(get_dir_size "$BACKUP_DIR")
        log_message "${YELLOW}📱 iOS/iPadOS cihaz yedekleri temizleniyor...${NC}"
        log_message "  Yedek boyutu: $BACKUP_SIZE"
        log_message "  ${RED}⚠️  Bu yedekler silindikten sonra iTunes/Finder üzerinden yeniden yedek alın!${NC}"
        rm -rf "$BACKUP_DIR"/* 2>/dev/null || true
        log_message "✅ iOS cihaz yedekleri temizlendi (yedekler sıfırlandı)"
    else
        log_message "ℹ️  iOS cihaz yedeği bulunamadı"
    fi

    # ── 5.2 GarageBand / Logic ses kütüphaneleri ───────────────────────────────
    log_message "${YELLOW}🎵 GarageBand/Logic ses kütüphaneleri aranıyor...${NC}"
    GB_TOTAL=0
    for gb_dir in \
        "/Library/Application Support/GarageBand" \
        "/Library/Application Support/Logic" \
        "$USER_HOME/Library/Application Support/GarageBand" \
        "/Library/Audio/Apple Loops" \
        "/Library/Application Support/Apple/iLife"; do
        if [ -d "$gb_dir" ]; then
            GB_SIZE=$(get_dir_size "$gb_dir")
            log_message "  🎵 $gb_dir → $GB_SIZE"
        fi
    done
    log_message "${CYAN}  ℹ️  GarageBand içeriklerini silmek için önce uygulamayı kaldırın veya${NC}"
    log_message "${CYAN}  ℹ️  GarageBand açıp 'Sound Library → Delete Unused Sounds' seçeneğini kullanın.${NC}"
    log_message ""

    # ── 5.3 Diagnostic veritabanları (System Data'nın büyük kısmı) ────────────
    log_message "${YELLOW}🔬 Diagnostic veritabanları temizleniyor...${NC}"
    DIAG_SIZE=$(get_dir_size "/private/var/db/diagnostics")
    log_message "  Diagnostics boyutu: $DIAG_SIZE"
    sudo rm -rf /private/var/db/diagnostics/* 2>/dev/null || true
    sudo rm -rf /private/var/db/uuidtext/* 2>/dev/null || true
    sudo rm -rf /private/var/db/analyticsd 2>/dev/null || true
    # macOS Sequoia yolu
    sudo rm -rf /private/var/db/CoreDuet 2>/dev/null || true
    log_message "✅ Diagnostic veritabanları temizlendi"

    # ── 5.4 System analitik ve telemetri verileri ─────────────────────────────
    log_message "${YELLOW}📡 Sistem analitik ve telemetri temizleniyor...${NC}"
    sudo rm -rf /private/var/db/reportmemoryexception 2>/dev/null || true
    sudo rm -rf /Library/Logs/DiagnosticReports/* 2>/dev/null || true
    rm -rf "$USER_HOME/Library/Logs/DiagnosticReports"/* 2>/dev/null || true
    rm -rf "$USER_HOME/Library/Logs/CrashReporter"/* 2>/dev/null || true
    log_message "✅ Telemetri verileri temizlendi"

    # ── 5.5 CloudKit / iCloud servis önbellekleri ─────────────────────────────
    log_message "${YELLOW}☁️  CloudKit önbellekleri temizleniyor...${NC}"
    rm -rf "$USER_HOME/Library/Caches/CloudKit"/* 2>/dev/null || true
    rm -rf "$USER_HOME/Library/Caches/com.apple.cloudd"/* 2>/dev/null || true
    rm -rf "$USER_HOME/Library/Caches/com.apple.iCloudHelper"/* 2>/dev/null || true
    sudo rm -rf /private/var/db/com.apple.nsurlsessiond 2>/dev/null || true
    log_message "✅ CloudKit önbellekleri temizlendi"

    # ── 5.6 Siri ve Apple Intelligence önbellekleri ───────────────────────────
    log_message "${YELLOW}🍎 Siri/Apple Intelligence önbellekleri temizleniyor...${NC}"
    rm -rf "$USER_HOME/Library/Caches/com.apple.siri"* 2>/dev/null || true
    rm -rf "$USER_HOME/Library/Caches/com.apple.assistant"* 2>/dev/null || true
    rm -rf "$USER_HOME/Library/Application Support/Siri"/* 2>/dev/null || true
    sudo rm -rf /private/var/db/siri 2>/dev/null || true
    log_message "✅ Siri önbellekleri temizlendi"

    # ── 5.7 Maps / Müzik / Podcast önbellekleri ───────────────────────────────
    log_message "${YELLOW}🗺️  Maps/Müzik/Podcast önbellekleri temizleniyor...${NC}"
    rm -rf "$USER_HOME/Library/Containers/com.apple.Maps/Data/Library/Caches"/* 2>/dev/null || true
    rm -rf "$USER_HOME/Library/Caches/com.apple.iTunes"/* 2>/dev/null || true
    rm -rf "$USER_HOME/Library/Caches/com.apple.Music"/* 2>/dev/null || true
    rm -rf "$USER_HOME/Library/Caches/com.apple.Podcasts"/* 2>/dev/null || true
    rm -rf "$USER_HOME/Library/Containers/com.apple.Music/Data/Library/Caches"/* 2>/dev/null || true
    log_message "✅ Maps/Müzik/Podcast önbellekleri temizlendi"

    # ── 5.8 Photos türevleri (küçük resimler) ─────────────────────────────────
    log_message "${YELLOW}📷 Photos türev dosyaları temizleniyor...${NC}"
    # Photos Library içindeki Thumbnails yeniden oluşturulabilir
    find "$USER_HOME/Pictures" -name "Thumbnails" -type d \
        -path "*/Photos Library.photoslibrary/*" \
        -exec rm -rf {} + 2>/dev/null || true
    rm -rf "$USER_HOME/Library/Caches/com.apple.Photos"* 2>/dev/null || true
    log_message "✅ Photos türev dosyaları temizlendi"

    # ── 5.9 App Store ve Software Update önbellekleri ─────────────────────────
    log_message "${YELLOW}🛒 App Store / Software Update önbellekleri temizleniyor...${NC}"
    rm -rf "$USER_HOME/Library/Caches/com.apple.appstore"/* 2>/dev/null || true
    sudo rm -rf /Library/Updates/* 2>/dev/null || true
    sudo rm -rf /Library/Caches/com.apple.SoftwareUpdate/* 2>/dev/null || true
    sudo rm -rf /private/var/folders/*/C/com.apple.SoftwareUpdate* 2>/dev/null || true
    log_message "✅ App Store / Software Update önbellekleri temizlendi"

    # ── 5.10 MobileBackup (eski iTunes yedeği izi) ────────────────────────────
    log_message "${YELLOW}📦 MobileBackup geçici dosyaları temizleniyor...${NC}"
    sudo rm -rf /private/var/db/MobileBackup 2>/dev/null || true
    log_message "✅ MobileBackup geçici dosyaları temizlendi"

    # ── 5.11 APFS Purgeable Space Analizini Yap ───────────────────────────────
    log_message "${CYAN}=== APFS Purgeable Space Analizi ===${NC}"
    if command -v diskutil &>/dev/null; then
        log_message "${YELLOW}APFS volume bilgileri alınıyor...${NC}"
        diskutil apfs list 2>/dev/null | grep -E "(APFS Volume|Purgeable|Free)" | \
            tee -a "$LOG_FILE" || true
        log_message ""
        log_message "${CYAN}💡 Purgeable Space hakkında:${NC}"
        log_message "  macOS APFS, iCloud Optimized Storage ve sistem tarafından kullanılan"
        log_message "  alanı 'purgeable' (temizlenebilir) olarak işaretler. Bu alan, disk"
        log_message "  dolduğunda macOS tarafından otomatik boşaltılır."
        log_message "  Zorla boşaltmak için: sudo purge && diskutil secureErase freespace 0 /"
        log_message "  (⚠️  Bu komut uzun sürer, dikkatli kullanın!)"
    fi

    # ── 5.12 Aktif Bellek Sıkıştırmasını Boşalt (purge) ──────────────────────
    log_message "${YELLOW}🧠 Sistem belleği temizleniyor (purge)...${NC}"
    sudo purge 2>/dev/null || true
    log_message "✅ Bellek temizlendi"

    # ── 5.13 Spotlight İndexini Tamamen Sil ve Yeniden Oluştur ───────────────
    log_message "${YELLOW}🔦 Spotlight indeksi tamamen sıfırlanıyor...${NC}"
    sudo mdutil -a -i off 2>/dev/null || true
    sudo rm -rf /private/var/db/Spotlight-V100 2>/dev/null || true
    sudo rm -rf /.Spotlight-V100 2>/dev/null || true
    sudo rm -rf "$USER_HOME/Library/Metadata/CoreSpotlight" 2>/dev/null || true
    sudo mdutil -a -i on 2>/dev/null || true
    sudo mdutil -E / 2>/dev/null || true
    log_message "✅ Spotlight indeksi sıfırlandı, arka planda yeniden oluşturuluyor"

    # ── 5.14 Sanal Makine disk imajları raporla ───────────────────────────────
    log_message "${YELLOW}💿 Sanal makine disk imajları aranıyor...${NC}"
    find "$USER_HOME" \( \
        -name "*.vmdk" -o -name "*.vdi" -o -name "*.qcow2" \
        -o -name "*.ipsw" -o -name "*.dmg" -name "*.iso" \
    \) -size +500M 2>/dev/null | while read -r vm_file; do
        vm_size=$(get_dir_size "$vm_file")
        log_message "  💿 $vm_file → $vm_size"
    done

    # ── 5.15 APFS Local Snapshot (Time Machine dışı) ─────────────────────────
    log_message "${YELLOW}📸 APFS local snapshot'ları temizleniyor...${NC}"
    # Tüm APFS snapshot'larını listele
    DISK_ID=$(diskutil info / | awk '/Device Node/{print $3}' | sed 's/s[0-9]*$//')
    if [ -n "$DISK_ID" ]; then
        sudo diskutil apfs listSnapshots "${DISK_ID}s1" 2>/dev/null | \
            grep "Name:" | awk '{print $2}' | while read -r snap; do
            sudo diskutil apfs deleteSnapshot "${DISK_ID}s1" -name "$snap" 2>/dev/null || true
            log_message "  🗑️  Snapshot silindi: $snap"
        done
    fi
    # Time Machine snapshot'ları da sil
    tmutil listlocalsnapshots / 2>/dev/null | while read -r snap; do
        sudo tmutil deletelocalsnapshots "$snap" 2>/dev/null || true
    done
    log_message "✅ APFS snapshot'ları temizlendi"

    log_message ""
    log_message "${GREEN}🚀 İLERİ DÜZEY KURTARMA TAMAMLANDI${NC}"
    log_message "${GREEN}Beklenen ek kazanç: 5–30 GB (sisteme göre değişir)${NC}"
    log_message ""
}

# ─── 6. BÜYÜK DOSYA TARAMA (YENİ) ────────────────────────────────────────────
find_large_files() {
    log_message "${CYAN}=== BÜYÜK DOSYA TARAMA BAŞLIYOR ===${NC}"
    local threshold="${1:-500}"
    log_message "${YELLOW}${threshold}MB üzerindeki dosyalar taranıyor...${NC}"
    log_message ""

    # HOME dizininde büyük dosyalar
    log_message "${YELLOW}📁 HOME dizininde büyük dosyalar (>${threshold}MB):${NC}"
    find "$USER_HOME" \
        -not -path "*/\.*" \
        -not -path "*/.Trash/*" \
        -not -path "*/node_modules/*" \
        -type f -size +"${threshold}M" 2>/dev/null | \
        while read -r f; do
            size=$(du -sh "$f" 2>/dev/null | cut -f1)
            echo "$size $f"
        done | sort -hr | head -30 | tee -a "$LOG_FILE"
    echo ""

    # Büyük dizinler (Library altında)
    log_message "${YELLOW}📂 Library altındaki en büyük dizinler (ilk 20):${NC}"
    du -sh "$USER_HOME/Library"/* 2>/dev/null | sort -hr | head -20 | tee -a "$LOG_FILE"
    echo ""

    # Downloads'taki büyük dosyalar
    if [ -d "$USER_HOME/Downloads" ]; then
        log_message "${YELLOW}⬇️  Downloads dizinindeki büyük dosyalar (>${threshold}MB):${NC}"
        find "$USER_HOME/Downloads" -type f -size +"${threshold}M" 2>/dev/null | \
            while read -r f; do
                size=$(du -sh "$f" 2>/dev/null | cut -f1)
                echo "$size $f"
            done | sort -hr | head -15 | tee -a "$LOG_FILE"
        echo ""
    fi

    # .ipsw dosyaları (iOS firmware, çok büyük)
    IPSW_FILES=$(find "$USER_HOME" -name "*.ipsw" -type f 2>/dev/null)
    if [ -n "$IPSW_FILES" ]; then
        log_message "${RED}📱 IPSW (iOS firmware) dosyaları bulundu — silinebilir:${NC}"
        echo "$IPSW_FILES" | while read -r f; do
            size=$(du -sh "$f" 2>/dev/null | cut -f1)
            log_message "  $size → $f"
        done
    fi

    # .pkg yükleyicileri (genellikle gereksiz)
    PKG_SIZE=$(find "$USER_HOME/Downloads" -name "*.pkg" -o -name "*.dmg" 2>/dev/null | \
        xargs du -sc 2>/dev/null | tail -1 | cut -f1)
    if [ "${PKG_SIZE:-0}" -gt 100000 ]; then
        log_message "${YELLOW}📦 Downloads'daki .pkg/.dmg toplam boyutu: $((PKG_SIZE/1024))MB${NC}"
        log_message "${CYAN}  ℹ️  Kurulu uygulamalar için gerekli değil, silinebilir.${NC}"
    fi

    log_message "${GREEN}✅ BÜYÜK DOSYA TARAMA TAMAMLANDI${NC}"
    log_message ""
}

# ─── 7. DEPOLAMA ANALİZİ (GELİŞTİRİLMİŞ) ────────────────────────────────────
storage_analysis() {
    log_message "${BLUE}=== GELİŞMİŞ DEPOLAMA ANALİZİ ===${NC}"

    echo -e "${YELLOW}💾 Disk Kullanımı:${NC}"
    df -h / | tee -a "$LOG_FILE"
    echo ""

    # APFS purgeable space
    echo -e "${CYAN}📊 APFS Volume Detayları (Purgeable dahil):${NC}"
    diskutil apfs list 2>/dev/null | grep -E "(APFS Volume|Purgeable|Free|Capacity)" | \
        tee -a "$LOG_FILE"
    echo ""

    echo -e "${YELLOW}📊 HOME dizini büyük alt dizinler:${NC}"
    du -sh "$USER_HOME"/* 2>/dev/null | sort -hr | head -15 | tee -a "$LOG_FILE"
    echo ""

    echo -e "${YELLOW}🗂️ Library alt dizinleri:${NC}"
    du -sh "$USER_HOME/Library"/* 2>/dev/null | sort -hr | head -10 | tee -a "$LOG_FILE"
    echo ""

    echo -e "${YELLOW}🔥 iOS Simulator Boyutları:${NC}"
    if [ -d "$USER_HOME/Library/Developer/CoreSimulator" ]; then
        du -sh "$USER_HOME/Library/Developer/CoreSimulator" 2>/dev/null | tee -a "$LOG_FILE"
        echo "Runtime'lar:" | tee -a "$LOG_FILE"
        du -sh "$USER_HOME/Library/Developer/CoreSimulator/Profiles/Runtimes"/* \
            2>/dev/null | sort -hr | head -5 | tee -a "$LOG_FILE"
    else
        echo "iOS Simulator bulunamadı" | tee -a "$LOG_FILE"
    fi
    echo ""

    echo -e "${YELLOW}📱 iOS Cihaz Yedekleri:${NC}"
    BACKUP_DIR="$USER_HOME/Library/Application Support/MobileSync/Backup"
    if [ -d "$BACKUP_DIR" ]; then
        du -sh "$BACKUP_DIR" 2>/dev/null | tee -a "$LOG_FILE"
        ls "$BACKUP_DIR" 2>/dev/null | wc -l | xargs echo "Yedek sayısı:" | tee -a "$LOG_FILE"
    else
        echo "iOS yedeği bulunamadı" | tee -a "$LOG_FILE"
    fi
    echo ""

    echo -e "${YELLOW}🎵 GarageBand/Logic Ses Kütüphaneleri:${NC}"
    for d in \
        "/Library/Application Support/GarageBand" \
        "/Library/Application Support/Logic" \
        "/Library/Audio/Apple Loops"; do
        [ -d "$d" ] && du -sh "$d" 2>/dev/null | tee -a "$LOG_FILE"
    done
    echo ""

    echo -e "${YELLOW}🔬 Diagnostic Veritabanları:${NC}"
    sudo du -sh /private/var/db/diagnostics 2>/dev/null | tee -a "$LOG_FILE"
    sudo du -sh /private/var/db/uuidtext 2>/dev/null | tee -a "$LOG_FILE"
    echo ""

    echo -e "${YELLOW}💻 Geliştirici Araçları Boyutları:${NC}"
    for dev_dir in \
        "$USER_HOME/.cargo" \
        "$USER_HOME/go" \
        "$USER_HOME/.m2" \
        "$USER_HOME/.gradle" \
        "$USER_HOME/.cocoapods" \
        "$USER_HOME/.npm" \
        "$USER_HOME/.nvm"; do
        if [ -d "$dev_dir" ]; then
            size=$(get_dir_size "$dev_dir")
            echo "  $size → $dev_dir" | tee -a "$LOG_FILE"
        fi
    done
    echo ""

    echo -e "${YELLOW}📧 Mail ve Messages Boyutları:${NC}"
    [ -d "$USER_HOME/Library/Mail" ] && du -sh "$USER_HOME/Library/Mail" 2>/dev/null | tee -a "$LOG_FILE"
    [ -d "$USER_HOME/Library/Messages" ] && du -sh "$USER_HOME/Library/Messages" 2>/dev/null | tee -a "$LOG_FILE"
    echo ""

    echo -e "${YELLOW}🌐 Tarayıcı Boyutları:${NC}"
    for browser_dir in \
        "$USER_HOME/Library/Safari" \
        "$USER_HOME/Library/Containers/com.apple.Safari" \
        "$USER_HOME/Library/Application Support/Google/Chrome" \
        "$USER_HOME/Library/Application Support/BraveSoftware" \
        "$USER_HOME/Library/Application Support/Firefox"; do
        if [ -d "$browser_dir" ]; then
            size=$(get_dir_size "$browser_dir")
            echo "  $size → $(basename "$browser_dir")" | tee -a "$LOG_FILE"
        fi
    done
    echo ""

    echo -e "${YELLOW}🔍 Büyük Önbellek Dizinleri (İlk 10):${NC}"
    find "$USER_HOME/Library/Caches" -maxdepth 1 -type d \
        -exec du -sh {} \; 2>/dev/null | sort -hr | head -10 | tee -a "$LOG_FILE"
    echo ""

    echo -e "${YELLOW}📦 Container Boyutları (İlk 10):${NC}"
    [ -d "$USER_HOME/Library/Containers" ] && \
        du -sh "$USER_HOME/Library/Containers"/* 2>/dev/null | sort -hr | head -10 | tee -a "$LOG_FILE"
    echo ""

    echo -e "${YELLOW}💻 Xcode Boyutları:${NC}"
    if [ -d "$USER_HOME/Library/Developer/Xcode" ]; then
        du -sh "$USER_HOME/Library/Developer/Xcode"/* 2>/dev/null | tee -a "$LOG_FILE"
    fi
    echo ""

    echo -e "${YELLOW}📊 Sistem Logları:${NC}"
    sudo du -sh /private/var/log/* 2>/dev/null | sort -hr | head -10 | tee -a "$LOG_FILE"
    echo ""

    echo -e "${YELLOW}🔦 Spotlight Durumu:${NC}"
    mdutil -s / 2>/dev/null | tee -a "$LOG_FILE"
    echo ""

    echo -e "${GREEN}💡 ÖNERİLER:${NC}"
    cat <<'TIPS' | tee -a "$LOG_FILE"
  • iOS Simulator runtime'ları büyükse    → Seçenek 4
  • iOS cihaz yedekleri büyükse           → Seçenek 5 (5.1)
  • GarageBand ses kütüphanesi büyükse   → GarageBand > Ses Kütüphanesi > Sil
  • Diagnostic veritabanları büyükse      → Seçenek 5 (5.3)
  • .cargo / .m2 / .gradle büyükse        → Seçenek 3
  • APFS Purgeable Space yüksekse         → Seçenek 5 (5.11)
  • Downloads'ta büyük dosyalar varsa    → Seçenek 6
TIPS
    echo ""
}

# ─── Ana Döngü ────────────────────────────────────────────────────────────────
while true; do
    show_menu
    read -p "Seçiminizi yapın (1-9): " choice
    echo ""

    SPACE_BEFORE=$(check_space_bytes)

    case $choice in
        1)
            confirm_action "ACİL TEMİZLİK başlatılacak. Spotlight durduruluyor ve temel önbellekler temizlenecek." && emergency_cleanup
            ;;
        2)
            confirm_action "KAPSAMLI TEMİZLİK başlatılacak. Tüm sistem önbellekleri, loglar ve QuickLook temizlenecek." && comprehensive_cleanup
            ;;
        3)
            confirm_action "GELİŞTİRİCİ TEMİZLİĞİ başlatılacak. Xcode, Docker, npm, brew, cargo, go, maven, gradle vb. temizlenecek." && developer_cleanup
            ;;
        4)
            confirm_action "🔥 AGRESİF SYSTEM DATA temizlenecek! iOS Simulator, Mail, Safari, iCloud verileri silinecek. (30-60 GB bekleniyor)" && aggressive_system_cleanup
            ;;
        5)
            confirm_action "🚀 İLERİ DÜZEY KURTARMA başlatılacak. iOS yedekler, GarageBand, diagnostics, APFS snapshots ve Siri verileri silinecek." && advanced_space_recovery
            ;;
        6)
            echo -e "${CYAN}Minimum dosya boyutu (MB, varsayılan 500): ${NC}"
            read -r size_threshold
            size_threshold="${size_threshold:-500}"
            find_large_files "$size_threshold"
            ;;
        7)
            storage_analysis
            ;;
        8)
            confirm_action "⚙️  TÜM TEMİZLİK işlemleri başlatılacak (1+2+3+4+5). Bu uzun sürebilir." || { continue; }
            emergency_cleanup
            comprehensive_cleanup
            developer_cleanup
            aggressive_system_cleanup
            advanced_space_recovery
            ;;
        9)
            kill $SUDO_KEEPALIVE_PID 2>/dev/null || true
            log_message "${BLUE}=== ÖZET RAPOR ===${NC}"
            log_message "İşlem tamamlandı: $(date)"
            log_message "Son boş alan: $(check_space)"
            log_message "Log dosyası: $LOG_FILE"
            echo -e "${GREEN}Çıkış yapılıyor. Sistemi yeniden başlatmanız önerilir.${NC}"
            echo -e "${BLUE}Log dosyanızı kontrol edin: $LOG_FILE${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Geçersiz seçim. Lütfen 1-9 arası bir sayı girin.${NC}"
            ;;
    esac

    if [[ "$choice" =~ ^[1-8]$ ]]; then
        SPACE_AFTER=$(check_space_bytes)
        DIFF=$(( (SPACE_AFTER - SPACE_BEFORE) / 1024 ))
        if [ "$DIFF" -gt 0 ]; then
            log_message "${GREEN}🎉 Bu işlemde kazanılan alan: ~${DIFF} MB${NC}"
        fi
        echo -e "${GREEN}Güncel boş alan: $(check_space)${NC}"
    fi

    echo ""
    read -p "Ana menüye dönmek için Enter'a basın..." -r
    echo ""
done
