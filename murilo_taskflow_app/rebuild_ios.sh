#!/bin/bash

# Script de Rebuild Completo para Aplicar Correções de Permissão
# TaskFlow App - Correção de Câmera iOS

echo "🚀 Iniciando rebuild completo do TaskFlow..."
echo ""

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Diretório do projeto
PROJECT_DIR="/Users/evertoncoimbradearaujo/Downloads/TaskFlow-main/taskflow_app"

cd "$PROJECT_DIR" || exit 1

echo "📂 Diretório atual: $(pwd)"
echo ""

# Passo 1: Flutter Clean
echo "${YELLOW}Passo 1/5: Limpando cache do Flutter...${NC}"
flutter clean
if [ $? -eq 0 ]; then
    echo "${GREEN}✅ Flutter clean concluído${NC}"
else
    echo "${RED}❌ Erro no flutter clean${NC}"
    exit 1
fi
echo ""

# Passo 2: Limpar cache iOS
echo "${YELLOW}Passo 2/5: Limpando cache do iOS...${NC}"
cd ios || exit 1
rm -rf Pods
rm -rf Podfile.lock
rm -rf .symlinks
rm -rf Flutter/Flutter.framework
rm -rf Flutter/Flutter.podspec

echo "${GREEN}✅ Cache iOS limpo${NC}"
echo ""

# Passo 3: Pod install
echo "${YELLOW}Passo 3/5: Instalando pods...${NC}"
pod cache clean --all 2>/dev/null || true
pod install
if [ $? -eq 0 ]; then
    echo "${GREEN}✅ Pods instalados com sucesso${NC}"
else
    echo "${RED}❌ Erro ao instalar pods${NC}"
    exit 1
fi
echo ""

cd ..

# Passo 4: Flutter pub get
echo "${YELLOW}Passo 4/5: Baixando dependências Flutter...${NC}"
flutter pub get
if [ $? -eq 0 ]; then
    echo "${GREEN}✅ Dependências baixadas${NC}"
else
    echo "${RED}❌ Erro ao baixar dependências${NC}"
    exit 1
fi
echo ""

# Passo 5: Verificar configuração
echo "${YELLOW}Passo 5/5: Verificando configurações...${NC}"

# Verifica se entitlements existe
if [ -f "ios/Runner/Runner.entitlements" ]; then
    echo "${GREEN}✅ Runner.entitlements encontrado${NC}"
else
    echo "${RED}❌ Runner.entitlements NÃO encontrado${NC}"
    echo "   Verifique o arquivo em ios/Runner/Runner.entitlements"
fi

# Verifica Info.plist
if grep -q "NSCameraUsageDescription" ios/Runner/Info.plist; then
    echo "${GREEN}✅ NSCameraUsageDescription encontrado no Info.plist${NC}"
else
    echo "${RED}❌ NSCameraUsageDescription NÃO encontrado no Info.plist${NC}"
fi

if grep -q "NSPhotoLibraryUsageDescription" ios/Runner/Info.plist; then
    echo "${GREEN}✅ NSPhotoLibraryUsageDescription encontrado no Info.plist${NC}"
else
    echo "${RED}❌ NSPhotoLibraryUsageDescription NÃO encontrado no Info.plist${NC}"
fi

echo ""
echo "${GREEN}🎉 Rebuild preparado com sucesso!${NC}"
echo ""
echo "${YELLOW}⚠️  PRÓXIMOS PASSOS MANUAIS:${NC}"
echo ""
echo "1. Adicionar Runner.entitlements ao Xcode:"
echo "   ${YELLOW}open ios/Runner.xcworkspace${NC}"
echo "   - Clique com botão direito na pasta Runner (azul)"
echo "   - Add Files to Runner..."
echo "   - Selecione Runner.entitlements"
echo ""
echo "2. Verificar Signing & Capabilities no Xcode:"
echo "   - Target Runner > Signing & Capabilities"
echo "   - Verifique se tem Camera e Photo Library"
echo ""
echo "3. Resetar permissões no simulador (se já instalou antes):"
echo "   ${YELLOW}xcrun simctl privacy booted reset all com.example.taskflowApp${NC}"
echo ""
echo "4. Executar o app:"
echo "   ${YELLOW}flutter run${NC}"
echo ""
echo "5. Testar a câmera:"
echo "   - Toque no avatar"
echo "   - Escolha 'Tirar Foto'"
echo "   - Conceda permissão quando solicitado"
echo "   - Verifique em Ajustes > Privacidade > Câmera"
echo ""
echo "${GREEN}Documentação completa em: CAMERA_PERMISSIONS_FIX.md${NC}"
echo ""
