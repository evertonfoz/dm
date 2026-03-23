# Solução para Upload de Foto em Web (Flutter Web)

## Problema Identificado
A funcionalidade de inserir foto no perfil não funcionava em `flutter run -d chrome` porque:
- `image_picker` não funciona corretamente em web
- Não havia integração com bibliotecas que suportam web adequadamente

## Solução Implementada

### 1. Novas Dependências Adicionadas
```yaml
file_picker: ^6.1.0          # Funciona melhor em web
universal_html: ^2.2.3       # Suporte melhorado para web
```

### 2. Novo Serviço: `ImagePickerService`
Arquivo: `lib/services/image_picker_service.dart`

- Detecta automaticamente se está em web ou mobile com `kIsWeb`
- Em **web**: usa `file_picker` que tem suporte nativo a browser
- Em **mobile**: usa `image_picker` para acesso a câmera e galeria
- Retorna `File` em ambos os casos para manter compatibilidade

### 3. Serviço Atualizado: `LocalPhotoStore`
Arquivo: `lib/services/local_photo_store.dart`

**Mudanças principais:**
- Em **web**: salva imagem como base64 em `SharedPreferences` (LocalStorage do navegador)
- Em **mobile**: continua usando `path_provider` e compressão
- Funções adaptadas para detectar a plataforma e usar armazenamento apropriado

### 4. Tela Atualizada: `ProfileEditScreen`
Arquivo: `lib/screens/profile_edit_screen.dart`

- Agora usa `ImagePickerService.pickImageFromGallery()` em vez de `ImagePicker` direto
- Método `_pickImage()` funciona em web e mobile
- Mantém feedback visual (SnackBar) do sucesso/erro

### 5. Widget Atualizado: `AvatarWidget`
Arquivo: `lib/widgets/avatar_widget.dart`

- Suporta exibição em web e mobile
- Detecta tipo de arquivo (arquivo ou base64)
- Renderiza corretamente em ambas as plataformas

## Como Testar

### Para Web:
```bash
flutter run -d chrome
# 1. Clique no avatar na tela de edição
# 2. Selecione uma imagem do seu computador
# 3. A imagem será carregada e exibida
```

### Para Mobile (Android/iOS):
```bash
flutter run
# Funciona como antes
```

## Fluxo de Funcionamento

### Web:
1. Usuário clica no avatar
2. `_pickImage()` chamado
3. `ImagePickerService.pickImageFromGallery()` abre seletor de arquivo
4. Arquivo convertido para bytes
5. `LocalPhotoStore.savePhoto()` converte para base64
6. Base64 salvo em `SharedPreferences`
7. Avatar atualizado e exibido

### Mobile:
1. Usuário clica no avatar
2. `_pickImage()` chamado
3. `ImagePickerService.pickImageFromGallery()` abre galeria
4. Foto selecionada
5. `LocalPhotoStore.savePhoto()` comprime a imagem
6. Imagem salva em `getApplicationDocumentsDirectory()`
7. Avatar atualizado e exibido

## Benefícios

✅ Funciona em web (Chrome, Firefox, Safari)  
✅ Compatível com mobile (Android, iOS)  
✅ Privacidade mantida (sem servidor externo)  
✅ Imagens comprimidas (mobile) ou otimizadas (web)  
✅ EXIF data removida (privacy)  
✅ Fallback para iniciais se sem foto  
✅ Feedback visual de ações

## Próximas Melhorias (Opcional)

- Adicionar suporte a câmera em web (se possível)
- Melhorar compressão de imagem em web
- Adicionar preview da imagem antes de salvar
- Migrar base64 de localStorage para IndexedDB para melhor performance
