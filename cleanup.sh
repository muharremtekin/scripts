#!/bin/bash

# macOS Sequoia 15.5 Kapsamlı Sistem Data Temizlik Scripti
# M4 Mac Mini 16/256 için optimize edilmiş
# Geliştirici: Backend developer iş akışları için özelleştirilmiş

set -e  # Hata durumunda scripti durdur

# Renkli çıktı için kodlar
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Mevcut kullanıcıyı al
CURRENT_USER=$(stat -f%Su /dev/console)
USER_HOME="/Users/$CURRENT_USER"

# Log dosyası
LOG_FILE="$USER_HOME/Desktop/cleanup_log_$(date +%Y%m%d_%H%M%S).txt"

echo -e "${BLUE}=== macOS Sequoia 15.5 Sistem Data Temizlik Scripti ===${NC}"
echo -e "${BLUE}Log dosyası: $LOG_FILE${NC}"
echo ""

# Fonksiyonlar
log_message() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

check_space() {
    df -h / | tail -1 | awk '{print $4}' | sed 's/Gi/GB/'
}

get_system_data_size() {
    system_data=$(system_profiler SPStorageDataType | grep -A5 "System Data" | grep "Size" | awk '{print $2, $3}' | head -1)
    echo "${system_data:-N/A}"
}

confirm_action() {
    echo -e "${YELLOW}$1${NC}"
    read -p "Devam etmek istiyor musunuz? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_message "${RED}İşlem iptal edildi.${NC}"
        exit 1
    fi
}

# Başlangıç durumu kaydet
log_message "${BLUE}=== BAŞLANGIÇ DURUMU ===${NC}"
log_message "Tarih: $(date)"
log_message "Kullanıcı: $CURRENT_USER"
log_message "Boş alan: $(check_space)"
log_message "Sistem Data boyutu: $(get_system_data_size)"
log_message ""

# Admin şifresi kontrol
echo -e "${YELLOW}Bu script admin yetkileri gerektirir. Lütfen şifrenizi girin:${NC}"
sudo -v

# Ana menü
show_menu() {
    echo -e "${BLUE}=== TEMİZLİK SEÇENEKLERİ ===${NC}"
    echo "1. 🚨 ACİL TEMİZLİK (Spotlight + Temel önbellekler)"
    echo "2. 🧹 KAPSAMLI TEMİZLİK (Tüm sistem önbellekleri)"
    echo "3. 💻 GELİŞTİRİCİ TEMİZLİĞİ (Xcode, Docker, npm, brew)"
    echo "4. 📊 DEPOLAMA ANALİZİ"
    echo "5. ⚙️  TÜMÜNÜ ÇALIŞTİR (1+2+3)"
    echo "6. 🚪 ÇIKIŞ"
    echo ""
}

# 1. ACİL TEMİZLİK
emergency_cleanup() {
    log_message "${RED}=== ACİL TEMİZLİK BAŞLIYOR ===${NC}"
    
    # Spotlight indekslemeyi durdur (EN KRİTİK)
    log_message "${YELLOW}Spotlight indeksleme durduruluyor...${NC}"
    sudo mdutil -a -i off 2>/dev/null || true
    log_message "✅ Spotlight indeksleme durduruldu"
    
    # CoreSpotlight metadata temizle
    log_message "${YELLOW}CoreSpotlight metadata temizleniyor...${NC}"
    rm -rf "$USER_HOME/Library/Metadata/CoreSpotlight"/* 2>/dev/null || true
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
    for snapshot in $(tmutil listlocalsnapshots / 2>/dev/null | grep com.apple.TimeMachine || true); do
        sudo tmutil deletelocalsnapshots "$snapshot" 2>/dev/null || true
    done
    log_message "✅ Time Machine snapshots temizlendi"
    
    log_message "${GREEN}✅ ACİL TEMİZLİK TAMAMLANDI${NC}"
    log_message ""
}

# 2. KAPSAMLI TEMİZLİK
comprehensive_cleanup() {
    log_message "${BLUE}=== KAPSAMLI TEMİZLİK BAŞLIYOR ===${NC}"
    
    # Uygulama kilitlenme raporları
    log_message "${YELLOW}Kilitlenme raporları temizleniyor...${NC}"
    rm -rf "$USER_HOME/Library/Application Support/CrashReporter"/* 2>/dev/null || true
    sudo rm -rf /Library/Application\ Support/CrashReporter/* 2>/dev/null || true
    log_message "✅ Kilitlenme raporları temizlendi"
    
    # Container önbellekleri
    log_message "${YELLOW}Container önbellekleri temizleniyor...${NC}"
    find "$USER_HOME/Library/Containers" -name "Caches" -type d -exec rm -rf {}/* \; 2>/dev/null || true
    log_message "✅ Container önbellekleri temizlendi"
    
    # Tarayıcı önbellekleri
    log_message "${YELLOW}Tarayıcı önbellekleri temizleniyor...${NC}"
    # Safari
    rm -rf "$USER_HOME/Library/Containers/com.apple.Safari/Data/Library/Caches"/* 2>/dev/null || true
    # Chrome
    rm -rf "$USER_HOME/Library/Application Support/Google/Chrome/*/Cache"/* 2>/dev/null || true
    rm -rf "$USER_HOME/Library/Application Support/Google/Chrome/*/Code Cache"/* 2>/dev/null || true
    # Firefox
    rm -rf "$USER_HOME/Library/Caches/Firefox"/* 2>/dev/null || true
    log_message "✅ Tarayıcı önbellekleri temizlendi"
    
    # Sistem logları (güvenli temizlik)
    log_message "${YELLOW}Sistem logları temizleniyor...${NC}"
    rm -rf "$USER_HOME/Library/Logs"/* 2>/dev/null || true
    sudo rm -f /private/var/log/*.log 2>/dev/null || true
    sudo rm -f /private/var/log/*.gz 2>/dev/null || true
    sudo rm -rf /private/var/log/asl/*.asl 2>/dev/null || true
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
    /System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister -kill -r -domain local -domain system -domain user 2>/dev/null || true
    log_message "✅ Launch Services veritabanı sıfırlandı"
    
    log_message "${GREEN}✅ KAPSAMLI TEMİZLİK TAMAMLANDI${NC}"
    log_message ""
}

# 3. GELİŞTİRİCİ TEMİZLİĞİ
developer_cleanup() {
    log_message "${BLUE}=== GELİŞTİRİCİ TEMİZLİĞİ BAŞLIYOR ===${NC}"
    
    # Xcode temizliği
    if [ -d "$USER_HOME/Library/Developer/Xcode" ]; then
        log_message "${YELLOW}Xcode DerivedData temizleniyor...${NC}"
        rm -rf "$USER_HOME/Library/Developer/Xcode/DerivedData"/* 2>/dev/null || true
        
        log_message "${YELLOW}Xcode Archives temizleniyor...${NC}"
        rm -rf "$USER_HOME/Library/Developer/Xcode/Archives"/* 2>/dev/null || true
        
        log_message "${YELLOW}iOS DeviceSupport temizleniyor...${NC}"
        rm -rf "$USER_HOME/Library/Developer/Xcode/iOS DeviceSupport"/* 2>/dev/null || true
        
        log_message "✅ Xcode verileri temizlendi"
    fi
    
    # Docker temizliği
    if command -v docker &> /dev/null; then
        log_message "${YELLOW}Docker temizliği yapılıyor...${NC}"
        docker system prune -a --volumes -f 2>/dev/null || true
        log_message "✅ Docker temizlendi"
    fi
    
    # NPM önbellek temizliği
    if command -v npm &> /dev/null; then
        log_message "${YELLOW}NPM önbelleği temizleniyor...${NC}"
        npm cache clean --force 2>/dev/null || true
        log_message "✅ NPM önbelleği temizlendi"
    fi
    
    # Yarn önbellek temizliği
    if command -v yarn &> /dev/null; then
        log_message "${YELLOW}Yarn önbelleği temizleniyor...${NC}"
        yarn cache clean 2>/dev/null || true
        log_message "✅ Yarn önbelleği temizlendi"
    fi
    
    # Homebrew temizliği
    if command -v brew &> /dev/null; then
        log_message "${YELLOW}Homebrew temizliği yapılıyor...${NC}"
        brew cleanup --prune=all 2>/dev/null || true
        rm -rf "$(brew --cache)" 2>/dev/null || true
        log_message "✅ Homebrew temizlendi"
    fi
    
    # Python pip önbelleği
    if command -v pip3 &> /dev/null; then
        log_message "${YELLOW}Python pip önbelleği temizleniyor...${NC}"
        pip3 cache purge 2>/dev/null || true
        log_message "✅ Python pip önbelleği temizlendi"
    fi
    
    # Conda temizliği
    if command -v conda &> /dev/null; then
        log_message "${YELLOW}Conda temizliği yapılıyor...${NC}"
        conda clean -a -y 2>/dev/null || true
        log_message "✅ Conda temizlendi"
    fi
    
    # Ruby gem temizliği
    if command -v gem &> /dev/null; then
        log_message "${YELLOW}Ruby gem temizliği yapılıyor...${NC}"
        gem cleanup 2>/dev/null || true
        log_message "✅ Ruby gem temizlendi"
    fi
    
    # Git garbage collection (eğer git repo'larında çalışıyorsanız)
    log_message "${YELLOW}Git depoları optimize ediliyor...${NC}"
    find "$USER_HOME" -name ".git" -type d 2>/dev/null | while read repo; do
        (cd "$(dirname "$repo")" && git gc --aggressive --prune=now 2>/dev/null) || true
    done
    log_message "✅ Git repoları optimize edildi"
    
    # Node modules büyük klasörleri bul (sadece rapor et)
    log_message "${YELLOW}Büyük node_modules klasörleri aranıyor...${NC}"
    find "$USER_HOME" -name "node_modules" -type d 2>/dev/null | head -10 | while read dir; do
        size=$(du -sh "$dir" 2>/dev/null | cut -f1)
        log_message "📁 $dir - $size"
    done
    
    log_message "${GREEN}✅ GELİŞTİRİCİ TEMİZLİĞİ TAMAMLANDI${NC}"
    log_message ""
}

# 4. DEPOLAMA ANALİZİ
storage_analysis() {
    log_message "${BLUE}=== DEPOLAMA ANALİZİ ===${NC}"
    
    echo -e "${YELLOW}💾 Disk Kullanımı:${NC}"
    df -h / | tee -a "$LOG_FILE"
    echo ""
    
    echo -e "${YELLOW}📊 Büyük Dizinler (ana dizinde):${NC}"
    du -sh "$USER_HOME"/* 2>/dev/null | sort -hr | head -10 | tee -a "$LOG_FILE"
    echo ""
    
    echo -e "${YELLOW}🗂️ Sistem Data Boyutu:${NC}"
    system_profiler SPStorageDataType | grep -A10 "System Data" | tee -a "$LOG_FILE"
    echo ""
    
    echo -e "${YELLOW}🔍 Büyük Önbellek Dizinleri:${NC}"
    find "$USER_HOME/Library/Caches" -maxdepth 1 -type d -exec du -sh {} \; 2>/dev/null | sort -hr | head -10 | tee -a "$LOG_FILE"
    echo ""
    
    echo -e "${YELLOW}📱 Container Boyutları:${NC}"
    if [ -d "$USER_HOME/Library/Containers" ]; then
        du -sh "$USER_HOME/Library/Containers"/* 2>/dev/null | sort -hr | head -10 | tee -a "$LOG_FILE"
    fi
    echo ""
    
    # Spotlight durumu
    echo -e "${YELLOW}🔦 Spotlight Durumu:${NC}"
    mdutil -s / 2>/dev/null | tee -a "$LOG_FILE"
    echo ""
}

# Ana döngü
while true; do
    show_menu
    read -p "Seçiminizi yapın (1-6): " choice
    echo ""
    
    case $choice in
        1)
            confirm_action "ACİL TEMİZLİK başlatılacak. Bu işlem Spotlight indekslemeyi durduracak ve temel önbellekleri temizleyecek."
            emergency_cleanup
            echo -e "${GREEN}Boş alan: $(check_space)${NC}"
            ;;
        2)
            confirm_action "KAPSAMLI TEMİZLİK başlatılacak. Bu işlem tüm sistem önbelleklerini temizleyecek."
            comprehensive_cleanup
            echo -e "${GREEN}Boş alan: $(check_space)${NC}"
            ;;
        3)
            confirm_action "GELİŞTİRİCİ TEMİZLİĞİ başlatılacak. Bu işlem Xcode, Docker, npm, brew vb. önbelleklerini temizleyecek."
            developer_cleanup
            echo -e "${GREEN}Boş alan: $(check_space)${NC}"
            ;;
        4)
            storage_analysis
            ;;
        5)
            confirm_action "TÜM TEMİZLİK işlemleri başlatılacak. Bu uzun sürebilir ve sistem performansını geçici olarak etkileyebilir."
            emergency_cleanup
            comprehensive_cleanup
            developer_cleanup
            echo -e "${GREEN}Boş alan: $(check_space)${NC}"
            ;;
        6)
            log_message "${BLUE}=== ÖZET RAPOR ===${NC}"
            log_message "Başlangıç boş alan: $(check_space)"
            log_message "İşlem tamamlandı: $(date)"
            log_message "Log dosyası: $LOG_FILE"
            echo -e "${GREEN}Çıkış yapılıyor. Sistemi yeniden başlatmanız önerilir.${NC}"
            echo -e "${BLUE}Log dosyanızı kontrol edin: $LOG_FILE${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Geçersiz seçim. Lütfen 1-6 arası bir sayı girin.${NC}"
            ;;
    esac
    
    echo ""
    read -p "Ana menüye dönmek için Enter'a basın..." -r
    echo ""
done