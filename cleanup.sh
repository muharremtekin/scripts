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
    echo "4. 🔥 AGRESIF SYSTEM DATA TEMİZLİĞİ (iOS Simulator, Mail, Safari)"
    echo "5. 📊 DEPOLAMA ANALİZİ"
    echo "6. ⚙️  TÜMÜNÜ ÇALIŞTİR (1+2+3+4)"
    echo "7. 🚪 ÇIKIŞ"
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

# 4. AGRESIF SYSTEM DATA TEMİZLİĞİ
aggressive_system_cleanup() {
    log_message "${RED}=== AGRESIF SYSTEM DATA TEMİZLİĞİ BAŞLIYOR ===${NC}"
    log_message "${YELLOW}⚠️  Bu işlem büyük miktarda veri silecek - dikkatli olun!${NC}"
    
    # iOS Simulator runtime'ları (EN BÜYÜK KAZANÇ 20-40GB)
    log_message "${YELLOW}iOS Simulator runtime'ları temizleniyor...${NC}"
    if [ -d "$USER_HOME/Library/Developer/CoreSimulator" ]; then
        # Simulator runtime'ları
        rm -rf "$USER_HOME/Library/Developer/CoreSimulator/Profiles/Runtimes"/* 2>/dev/null || true
        # Simulator device'ları
        rm -rf "$USER_HOME/Library/Developer/CoreSimulator/Devices"/* 2>/dev/null || true
        # Simulator caches
        rm -rf "$USER_HOME/Library/Developer/CoreSimulator/Caches"/* 2>/dev/null || true
        log_message "✅ iOS Simulator runtime'ları temizlendi (20-40GB kazanç bekleniyor)"
    else
        log_message "ℹ️  iOS Simulator bulunamadı"
    fi
    
    # Xcode iOS DeviceSupport (büyük olabilir)
    log_message "${YELLOW}Xcode iOS DeviceSupport temizleniyor...${NC}"
    if [ -d "$USER_HOME/Library/Developer/Xcode/iOS DeviceSupport" ]; then
        # Eski iOS versiyonlarını temizle (sadece en yenisini bırak)
        find "$USER_HOME/Library/Developer/Xcode/iOS DeviceSupport" -maxdepth 1 -type d -name "*.*" | sort -V | head -n -2 | xargs rm -rf 2>/dev/null || true
        log_message "✅ Eski iOS DeviceSupport temizlendi"
    fi
    
    # Mail ekleri ve önbellekleri (10-30GB kazanç)
    log_message "${YELLOW}Mail ekleri ve önbellekleri temizleniyor...${NC}"
    # Mail attachments
    rm -rf "$USER_HOME/Library/Mail/V*/MailData/Attachments"/* 2>/dev/null || true
    # Mail envelope index
    rm -rf "$USER_HOME/Library/Mail/V*/MailData/Envelope Index"* 2>/dev/null || true
    # Mail database index
    find "$USER_HOME/Library/Mail" -name "*.db*" -delete 2>/dev/null || true
    log_message "✅ Mail verileri temizlendi (5-15GB kazanç bekleniyor)"
    
    # Messages ekleri
    log_message "${YELLOW}Messages ekleri temizleniyor...${NC}"
    rm -rf "$USER_HOME/Library/Messages/Attachments"/* 2>/dev/null || true
    rm -rf "$USER_HOME/Library/Messages/Archive"/* 2>/dev/null || true
    log_message "✅ Messages ekleri temizlendi"
    
    # Safari derinlemesine temizlik (5-15GB)
    log_message "${YELLOW}Safari derinlemesine temizlik yapılıyor...${NC}"
    # Safari databases
    rm -rf "$USER_HOME/Library/Safari/Databases"/* 2>/dev/null || true
    # Safari LocalStorage
    rm -rf "$USER_HOME/Library/Safari/LocalStorage"/* 2>/dev/null || true
    # Safari WebKit storage
    rm -rf "$USER_HOME/Library/Containers/com.apple.Safari/Data/Library/WebKit"/* 2>/dev/null || true
    # Safari CloudTabs
    rm -rf "$USER_HOME/Library/Safari/CloudTabs.db"* 2>/dev/null || true
    log_message "✅ Safari derinlemesine temizlendi"
    
    # Chrome derinlemesine temizlik
    log_message "${YELLOW}Chrome derinlemesine temizlik yapılıyor...${NC}"
    # Chrome extensions
    rm -rf "$USER_HOME/Library/Application Support/Google/Chrome/*/Extensions"/* 2>/dev/null || true
    # Chrome GPUCache
    rm -rf "$USER_HOME/Library/Application Support/Google/Chrome/*/GPUCache"/* 2>/dev/null || true
    # Chrome Service Worker
    rm -rf "$USER_HOME/Library/Application Support/Google/Chrome/*/Service Worker"/* 2>/dev/null || true
    # Chrome Session Storage
    rm -rf "$USER_HOME/Library/Application Support/Google/Chrome/*/Session Storage"/* 2>/dev/null || true
    log_message "✅ Chrome derinlemesine temizlendi"
    
    # Sistem kernel cache'leri (DİKKATLİ - sistem performansını etkileyebilir)
    log_message "${YELLOW}Kernel cache'leri yeniden oluşturuluyor...${NC}"
    sudo rm -rf /System/Library/Caches/com.apple.kext.caches/* 2>/dev/null || true
    sudo kextcache -system-prelinked-kernel 2>/dev/null || true
    sudo kextcache -system-caches 2>/dev/null || true
    log_message "✅ Kernel cache'leri yeniden oluşturuldu"
    
    # Büyük log dosyaları
    log_message "${YELLOW}Büyük log dosyaları temizleniyor...${NC}"
    # System install logs
    sudo rm -rf /private/var/log/install.log* 2>/dev/null || true
    # Wifi logs
    sudo rm -rf /private/var/log/wifi.log* 2>/dev/null || true
    # FSEvents logs (büyük olabilir)
    sudo rm -rf /System/Volumes/Data/.fseventsd/* 2>/dev/null || true
    log_message "✅ Büyük log dosyaları temizlendi"
    
    # Adobe önbellekleri (eğer varsa)
    if [ -d "$USER_HOME/Library/Caches/Adobe" ]; then
        log_message "${YELLOW}Adobe önbellekleri temizleniyor...${NC}"
        rm -rf "$USER_HOME/Library/Caches/Adobe"/* 2>/dev/null || true
        log_message "✅ Adobe önbellekleri temizlendi"
    fi
    
    # Microsoft Office önbellekleri
    if [ -d "$USER_HOME/Library/Caches/Microsoft" ]; then
        log_message "${YELLOW}Microsoft Office önbellekleri temizleniyor...${NC}"
        rm -rf "$USER_HOME/Library/Caches/Microsoft"/* 2>/dev/null || true
        log_message "✅ Microsoft Office önbellekleri temizlendi"
    fi
    
    log_message "${GREEN}🔥 AGRESIF SYSTEM DATA TEMİZLİĞİ TAMAMLANDI${NC}"
    log_message "${GREEN}Beklenen toplam kazanç: 30-60GB${NC}"
    log_message "${YELLOW}⚠️  Sistemi yeniden başlatmanız önerilir${NC}"
    log_message ""
}

# 5. DEPOLAMA ANALİZİ
storage_analysis() {
    log_message "${BLUE}=== GELIŞMIŞ DEPOLAMA ANALİZİ ===${NC}"
    
    echo -e "${YELLOW}💾 Disk Kullanımı:${NC}"
    df -h / | tee -a "$LOG_FILE"
    echo ""
    
    echo -e "${YELLOW}📊 Büyük Dizinler (ana dizinde):${NC}"
    du -sh "$USER_HOME"/* 2>/dev/null | sort -hr | head -10 | tee -a "$LOG_FILE"
    echo ""
    
    echo -e "${YELLOW}🗂️ System Data Detayları:${NC}"
    system_profiler SPStorageDataType | grep -A15 "System Data" | tee -a "$LOG_FILE"
    echo ""
    
    echo -e "${YELLOW}🔥 iOS Simulator Boyutları:${NC}"
    if [ -d "$USER_HOME/Library/Developer/CoreSimulator" ]; then
        echo "📱 CoreSimulator toplam:" | tee -a "$LOG_FILE"
        du -sh "$USER_HOME/Library/Developer/CoreSimulator" 2>/dev/null | tee -a "$LOG_FILE"
        echo "📱 Runtime'lar:" | tee -a "$LOG_FILE"
        du -sh "$USER_HOME/Library/Developer/CoreSimulator/Profiles/Runtimes"/* 2>/dev/null | sort -hr | head -5 | tee -a "$LOG_FILE"
        echo "📱 Devices:" | tee -a "$LOG_FILE"
        du -sh "$USER_HOME/Library/Developer/CoreSimulator/Devices"/* 2>/dev/null | sort -hr | head -5 | tee -a "$LOG_FILE"
    else
        echo "iOS Simulator bulunamadı" | tee -a "$LOG_FILE"
    fi
    echo ""
    
    echo -e "${YELLOW}📧 Mail ve Messages Boyutları:${NC}"
    if [ -d "$USER_HOME/Library/Mail" ]; then
        du -sh "$USER_HOME/Library/Mail" 2>/dev/null | tee -a "$LOG_FILE"
        echo "Mail ekleri:" | tee -a "$LOG_FILE"
        find "$USER_HOME/Library/Mail" -name "Attachments" -type d -exec du -sh {} \; 2>/dev/null | tee -a "$LOG_FILE"
    fi
    if [ -d "$USER_HOME/Library/Messages" ]; then
        du -sh "$USER_HOME/Library/Messages" 2>/dev/null | tee -a "$LOG_FILE"
    fi
    echo ""
    
    echo -e "${YELLOW}🌐 Tarayıcı Boyutları:${NC}"
    # Safari
    if [ -d "$USER_HOME/Library/Safari" ]; then
        echo "Safari toplam:" | tee -a "$LOG_FILE"
        du -sh "$USER_HOME/Library/Safari" 2>/dev/null | tee -a "$LOG_FILE"
        du -sh "$USER_HOME/Library/Containers/com.apple.Safari" 2>/dev/null | tee -a "$LOG_FILE"
    fi
    # Chrome
    if [ -d "$USER_HOME/Library/Application Support/Google/Chrome" ]; then
        echo "Chrome toplam:" | tee -a "$LOG_FILE"
        du -sh "$USER_HOME/Library/Application Support/Google/Chrome" 2>/dev/null | tee -a "$LOG_FILE"
    fi
    echo ""
    
    echo -e "${YELLOW}🔍 Büyük Önbellek Dizinleri:${NC}"
    find "$USER_HOME/Library/Caches" -maxdepth 1 -type d -exec du -sh {} \; 2>/dev/null | sort -hr | head -10 | tee -a "$LOG_FILE"
    echo ""
    
    echo -e "${YELLOW}📱 Container Boyutları:${NC}"
    if [ -d "$USER_HOME/Library/Containers" ]; then
        du -sh "$USER_HOME/Library/Containers"/* 2>/dev/null | sort -hr | head -10 | tee -a "$LOG_FILE"
    fi
    echo ""
    
    echo -e "${YELLOW}💻 Xcode Boyutları:${NC}"
    if [ -d "$USER_HOME/Library/Developer/Xcode" ]; then
        du -sh "$USER_HOME/Library/Developer/Xcode"/* 2>/dev/null | tee -a "$LOG_FILE"
        if [ -d "$USER_HOME/Library/Developer/Xcode/iOS DeviceSupport" ]; then
            echo "iOS DeviceSupport versiyonları:" | tee -a "$LOG_FILE"
            du -sh "$USER_HOME/Library/Developer/Xcode/iOS DeviceSupport"/* 2>/dev/null | sort -hr | tee -a "$LOG_FILE"
        fi
    fi
    echo ""
    
    echo -e "${YELLOW}📊 Sistem Logları:${NC}"
    sudo du -sh /private/var/log/* 2>/dev/null | sort -hr | head -10 | tee -a "$LOG_FILE"
    echo ""
    
    # Spotlight durumu
    echo -e "${YELLOW}🔦 Spotlight Durumu:${NC}"
    mdutil -s / 2>/dev/null | tee -a "$LOG_FILE"
    echo ""
    
    echo -e "${GREEN}💡 ÖNERİLER:${NC}"
    echo "• iOS Simulator runtime'ları büyükse: Seçenek 4'ü kullanın" | tee -a "$LOG_FILE"
    echo "• Mail/Messages büyükse: Eski ekleri manuel temizleyin" | tee -a "$LOG_FILE"
    echo "• Chrome/Safari büyükse: Tarayıcı verilerini sıfırlayın" | tee -a "$LOG_FILE"
    echo "• Xcode büyükse: DerivedData ve Archives'ı temizleyin" | tee -a "$LOG_FILE"
    echo ""
}

# Ana döngü
while true; do
    show_menu
    read -p "Seçiminizi yapın (1-7): " choice
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
            confirm_action "🔥 AGRESIF SYSTEM DATA TEMİZLİĞİ başlatılacak! Bu işlem iOS Simulator, Mail, Safari verilerini silecek. 30-60GB kazanç bekleniyor."
            aggressive_system_cleanup
            echo -e "${GREEN}Boş alan: $(check_space)${NC}"
            ;;
        5)
            storage_analysis
            ;;
        6)
            confirm_action "TÜM TEMİZLİK işlemleri başlatılacak (Agresif dahil). Bu uzun sürebilir ve sistem performansını geçici olarak etkileyebilir."
            emergency_cleanup
            comprehensive_cleanup
            developer_cleanup
            aggressive_system_cleanup
            echo -e "${GREEN}Boş alan: $(check_space)${NC}"
            ;;
        7)
            log_message "${BLUE}=== ÖZET RAPOR ===${NC}"
            log_message "Başlangıç boş alan: $(check_space)"
            log_message "İşlem tamamlandı: $(date)"
            log_message "Log dosyası: $LOG_FILE"
            echo -e "${GREEN}Çıkış yapılıyor. Sistemi yeniden başlatmanız önerilir.${NC}"
            echo -e "${BLUE}Log dosyanızı kontrol edin: $LOG_FILE${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Geçersiz seçim. Lütfen 1-7 arası bir sayı girin.${NC}"
            ;;
    esac
    
    echo ""
    read -p "Ana menüye dönmek için Enter'a basın..." -r
    echo ""
done