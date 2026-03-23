# Guia: Construindo a Tela de Fornecedores com Persistência 📱

Um guia completo para construir a tela `HomePage` com funcionalidades de CRUD e persistência de dados usando SharedPreferences.

---

## 📋 Visão Geral do Projeto

**Objetivo:** Criar uma tela que permite:
- ✅ Visualizar lista de fornecedores com imagem
- ✅ Adicionar novos fornecedores
- ✅ Editar fornecedores existentes
- ✅ Remover fornecedores (swipe to dismiss)
- ✅ Ver detalhes de cada fornecedor
- ✅ Persistir dados no banco local (SharedPreferences)
- ✅ Atualizar lista (pull to refresh)
- ✅ Orientação visual para o usuário (tutorial)

---

## 🎯 Etapas de Implementação

### **ETAPA 1: Setup Inicial e Estrutura de Dados**

#### Objetivo
Criar a estrutura básica do widget com o DAO e estrutura de dados.

#### Passos

1. **Crie o DTO (Data Transfer Object)**
   - Arquivo: `lib/features/providers/infrastructure/dtos/provider_dto.dart`
   - Deve conter: `id`, `name`, `image_url`, `rating`, `distance_km`, `updated_at`, `metadata`, `brand_color_hex`
   - Implemente `toMap()` e `fromMap()` para serialização

2. **Implemente o DAO (Data Access Object)**
   - Arquivo: `lib/features/providers/infrastructure/local/providers_local_dao.dart`
   - Interface com métodos: `upsertAll()`, `listAll()`, `getById()`, `clear()`
   - Arquivo: `lib/features/providers/infrastructure/local/providers_local_dao_shared_prefs.dart`
   - Implementação usando SharedPreferences

3. **Crie a HomePage básica**
   ```dart
   class HomePage extends StatefulWidget {
     static const routeName = '/home';
     
     @override
     State<HomePage> createState() => _HomePageState();
   }

   class _HomePageState extends State<HomePage> {
     List<ProviderDto> _providers = [];
     bool _loadingProviders = true;
     
     @override
     void initState() {
       super.initState();
       _loadProviders();
     }
     
     @override
     Widget build(BuildContext context) {
       return Scaffold(
         appBar: AppBar(title: const Text('CeliLac Life')),
         body: _buildBody(),
       );
     }
   }
   ```

---

### **ETAPA 2: Carregar e Exibir Fornecedores em Lista**

#### Objetivo
Implementar o carregamento de dados e exibir em um ListView.

#### Passos

1. **Implemente `_loadProviders()`**
   - Carregue dados do DAO
   - Se vazio, crie dados de teste
   - Atualize o estado com `setState()`

   ```dart
   Future<void> _loadProviders() async {
     setState(() => _loadingProviders = true);
     try {
       final dao = ProvidersLocalDaoSharedPrefs();
       var list = await dao.listAll();
       
       if (list.isEmpty) {
         // Crie dados de teste
         list = await _createTestData();
         await dao.upsertAll(list);
       }
       
       setState(() {
         _providers = list;
         _loadingProviders = false;
       });
     } catch (e) {
       setState(() {
         _providers = [];
         _loadingProviders = false;
       });
     }
   }
   ```

2. **Crie ListView para exibir fornecedores**
   - Use `ListView.builder` com índice
   - Cada item é um `ListTile` ou `Row` personalizado
   - Exiba imagem, nome e nota

   ```dart
   ListView.builder(
     itemCount: _providers.length,
     itemBuilder: (context, idx) {
       final p = _providers[idx];
       return ListTile(
         leading: p.image_url != null
             ? Image.network(p.image_url!, width: 80, height: 80)
             : Icon(Icons.store),
         title: Text(p.name),
         subtitle: Text('Nota: ${p.rating.toStringAsFixed(1)}'),
       );
     },
   )
   ```

3. **Implemente RefreshIndicator (pull to refresh)**
   - Envolva a ListView em `RefreshIndicator`
   - `onRefresh` chama `_loadProviders()`

   ```dart
   RefreshIndicator(
     onRefresh: _loadProviders,
     child: ListView.builder(...)
   )
   ```

---

### **ETAPA 3: Adicionar Efeito Zebrado e Melhorar Visual**

#### Objetivo
Melhorar a experiência visual com alternância de cores e altura dinâmica.

#### Passos

1. **Adicione alternância de cores**
   - Calcule `isEven = idx % 2 == 0`
   - Use cores diferentes: `Colors.blue[50]` e `Colors.grey[100]`
   - Envolva cada item em `Container(color: backgroundColor)`

2. **Aumente altura dos itens**
   - Use `visualDensity: VisualDensity(vertical: 2)` ou crie Row customizado
   - Imagem com altura fixa (90-110px)
   - Layout: Imagem | Nome/Nota | Distância/Botões

3. **Adicione espaçamento entre itens**
   - `Padding(padding: EdgeInsets.only(bottom: 2))`

4. **Melhore o layout com Row customizado**
   - Substitua ListTile por Row para mais controle
   - Imagem em ClipRRect com BorderRadius
   - Conteúdo centralizado verticalmente

---

### **ETAPA 4: Implementar Clique para Ver Detalhes**

#### Objetivo
Abrir um modal com informações completas do fornecedor.

#### Passos

1. **Crie `_showProviderDetails()`**
   ```dart
   void _showProviderDetails(ProviderDto provider, int index) {
     showDialog(
       context: context,
       builder: (context) => AlertDialog(
         title: Text(provider.name),
         content: SingleChildScrollView(
           child: Column(
             mainAxisSize: MainAxisSize.min,
             children: [
               if (provider.image_url != null)
                 Image.network(provider.image_url!, height: 120, width: 280),
               Text('Nota: ${provider.rating}'),
               if (provider.distance_km != null)
                 Text('Distância: ${provider.distance_km} km'),
               Text('Atualizado: ${provider.updated_at}'),
             ],
           ),
         ),
         actions: [
           TextButton(onPressed: () => Navigator.pop(context), child: Text('Fechar')),
         ],
       ),
     );
   }
   ```

2. **Adicione GestureDetector**
   - Envolva cada item em `GestureDetector`
   - `onTap: () => _showProviderDetails(p, idx)`

3. **Melhore o tratamento de imagem no modal**
   - Adicione `errorBuilder` para imagens que falham
   - Adicione `loadingBuilder` com `CircularProgressIndicator`
   - Envolva em `ClipRRect` com BorderRadius

---

### **ETAPA 5: Adicionar Novo Fornecedor (Create)**

#### Objetivo
Permitir que o usuário crie novo fornecedor via formulário.

#### Passos

1. **Crie `_showProviderForm()`**
   ```dart
   void _showProviderForm({ProviderDto? provider, int? index}) async {
     final result = await showDialog<ProviderDto>(
       context: context,
       builder: (context) {
         final nameController = TextEditingController(text: provider?.name ?? '');
         final ratingController = TextEditingController(text: provider?.rating.toString() ?? '5.0');
         
         return AlertDialog(
           title: Text(provider == null ? 'Novo Fornecedor' : 'Editar Fornecedor'),
           content: SingleChildScrollView(
             child: Column(
               mainAxisSize: MainAxisSize.min,
               children: [
                 TextField(controller: nameController, decoration: InputDecoration(labelText: 'Nome')),
                 TextField(controller: ratingController, decoration: InputDecoration(labelText: 'Nota (0-5)')),
               ],
             ),
           ),
           actions: [
             TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancelar')),
             ElevatedButton(onPressed: () {
               final dto = ProviderDto(
                 id: provider?.id ?? DateTime.now().millisecondsSinceEpoch,
                 name: nameController.text,
                 rating: double.tryParse(ratingController.text) ?? 5.0,
                 // ... outros campos
               );
               Navigator.pop(context, dto);
             }, child: Text('Salvar')),
           ],
         );
       },
     );
     
     if (result != null) {
       final dao = ProvidersLocalDaoSharedPrefs();
       List<ProviderDto> newList = List.from(_providers);
       if (index != null) {
         newList[index] = result;
       } else {
         newList.add(result);
       }
       await dao.clear();
       await dao.upsertAll(newList);
       await _loadProviders();
     }
   }
   ```

2. **Adicione FloatingActionButton**
   ```dart
   floatingActionButton: FloatingActionButton(
     onPressed: () => _showProviderForm(),
     child: Icon(Icons.add),
   )
   ```

---

### **ETAPA 6: Editar Fornecedor (Update)**

#### Objetivo
Permitir que o usuário edite um fornecedor existente.

#### Passos

1. **Reutilize `_showProviderForm()`**
   - Passe `provider` e `index` como parâmetro
   - Se `index != null`, é edição; senão, é criação

2. **Adicione botão Editar no modal de detalhes**
   ```dart
   TextButton(
     onPressed: () {
       Navigator.pop(context);
       _showProviderForm(provider: provider, index: index);
     },
     child: Text('Editar'),
   )
   ```

3. **Implemente salvar edições**
   - Remova do banco com `clear()`
   - Insira lista atualizada com `upsertAll()`
   - Recarregue com `_loadProviders()`

---

### **ETAPA 7: Remover Fornecedor (Delete) com Swipe**

#### Objetivo
Implementar swipe to dismiss (UX padrão mobile) para remover.

#### Passos

1. **Implemente `_removeProvider()`**
   ```dart
   Future<void> _removeProvider(int index) async {
     final dao = ProvidersLocalDaoSharedPrefs();
     List<ProviderDto> newList = List.from(_providers);
     newList.removeAt(index);
     await dao.clear();
     await dao.upsertAll(newList);
     setState(() => _providers = newList);
   }
   ```

2. **Envolva items em `Dismissible`**
   ```dart
   Dismissible(
     key: Key(p.id.toString()),
     background: Container(
       color: Colors.red,
       alignment: Alignment.centerRight,
       child: Icon(Icons.delete, color: Colors.white),
     ),
     direction: DismissDirection.endToStart,
     confirmDismiss: (direction) async {
       return await showDialog<bool>(
         context: context,
         builder: (context) => AlertDialog(
           title: Text('Remover ${p.name}?'),
           actions: [
             TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancelar')),
             ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text('Remover')),
           ],
         ),
       ) ?? false;
     },
     onDismissed: (direction) async {
       await _removeProvider(_providers.indexOf(p));
     },
     child: // seu item aqui
   )
   ```

3. **Adicione botão Remover no modal (alternativo)**
   - Opcional: também ofereça remoção pelo botão

---

### **ETAPA 8: Tutorial/Orientação para o Usuário**

#### Objetivo
Mostrar um modal com instruções de como usar a tela.

#### Passos

1. **Crie variável de estado**
   ```dart
   bool _showProvidersTutorial = true;
   ```

2. **Crie `_buildTutorialItem()` helper**
   ```dart
   Widget _buildTutorialItem({
     required IconData icon,
     required String title,
     required String description,
   }) {
     return Row(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
         Icon(icon, color: Colors.blue),
         SizedBox(width: 12),
         Expanded(child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
             Text(description),
           ],
         )),
       ],
     );
   }
   ```

3. **Crie modal de orientação com Stack.Positioned**
   ```dart
   if (_showProvidersTutorial)
     Positioned.fill(
       child: Container(
         color: Colors.black26,
         child: Center(
           child: Card(
             child: Padding(
               padding: EdgeInsets.all(24),
               child: Column(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   Text('Como gerenciar fornecedores', style: Theme.of(context).textTheme.headlineSmall),
                   SizedBox(height: 16),
                   _buildTutorialItem(icon: Icons.edit, title: 'Editar fornecedor', description: 'Toque no ícone de lápis'),
                   _buildTutorialItem(icon: Icons.touch_app, title: 'Ver detalhes', description: 'Toque na linha'),
                   _buildTutorialItem(icon: Icons.add_circle, title: 'Adicionar fornecedor', description: 'Toque no botão +'),
                   _buildTutorialItem(icon: Icons.swipe_left, title: 'Remover fornecedor', description: 'Deslize para esquerda'),
                   SizedBox(height: 24),
                   ElevatedButton(onPressed: () => setState(() => _showProvidersTutorial = false), child: Text('Fechar')),
                 ],
               ),
             ),
           ),
         ),
       ),
     ),
   ```

4. **Exiba o tutorial sempre ou na primeira vez**
   - Opção 1: Sempre exibir (mais didático)
   - Opção 2: Salvar preferência e exibir só primeira vez

---

### **ETAPA 9: Ajustes Finais de Layout**

#### Objetivo
Polir a interface com espaçamento e dimensões corretas.

#### Passos

1. **Reduzir padding vertical do ListView**
   - De `16` para `0` para subir primeiro item perto da AppBar

2. **Adicionar espaçamento entre linhas**
   - `Padding(padding: EdgeInsets.only(bottom: 2))`

3. **Aumentar altura de items**
   - Imagem: `height: 90`, `width: 80`

4. **Melhorar BorderRadius**
   - Apenas canto superior esquerdo arredondado
   - `BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16))`

---

### **ETAPA 10: Corrigir Problemas de Persistência**

#### Objetivo
Garantir que dados removidos não reapareçam ao reiniciar.

#### Passos

1. **Problema**: `_loadProviders()` recria dados de teste toda vez
   - **Solução**: Carregar primeiro, só criar se vazio

   ```dart
   Future<void> _loadProviders() async {
     try {
       final dao = ProvidersLocalDaoSharedPrefs();
       var list = await dao.listAll(); // Carregue primeiro!
       
       if (list.isEmpty) {
         // Só crie dados de teste se não houver nada
         list = await _createTestData();
         await dao.upsertAll(list);
       }
       
       setState(() => _providers = list);
     } catch (e) {
       // ...
     }
   }
   ```

2. **Problema**: `upsertAll()` mescla dados em vez de substituir
   - **Solução**: Sempre fazer `clear()` antes de `upsertAll()`

   ```dart
   await dao.clear();
   await dao.upsertAll(newList);
   ```

---

## 🎨 Paleta de Cores Recomendada

- **Fundo zebrado (par)**: `Colors.blue[50]` (#E3F2FD)
- **Fundo zebrado (ímpar)**: `Colors.grey[100]` (#F5F5F5)
- **Primária**: `Colors.blue` ou tema do app
- **Remover**: `Colors.red`
- **Ícones desabilitados**: `Colors.grey[400]`

---

## 📦 Estrutura de Arquivos Final

```
lib/
├── features/
│   └── providers/
│       ├── infrastructure/
│       │   ├── dtos/
│       │   │   └── provider_dto.dart
│       │   └── local/
│       │       ├── providers_local_dao.dart
│       │       └── providers_local_dao_shared_prefs.dart
│       └── presentation/
│           └── pages/
│               └── home_page.dart
└── main.dart
```

---

## 🔗 Arquivos Relacionados

- `lib/services/shared_preferences_services.dart` - Serviço de preferências
- `lib/services/preferences_keys.dart` - Chaves de preferências
- `pubspec.yaml` - Dependências (shared_preferences)

---

## 💡 Dicas para Ensinar aos Alunos

1. **Comece simples**: Etapas 1-3 (estrutura e exibição)
2. **Incremente funcionalidade**: Etapas 4-7 (CRUD)
3. **Polir interface**: Etapa 9 (layout)
4. **Debug**: Etapa 10 (persistência)
5. **Oriente visualmente**: Etapa 8 (tutorial)

---

## 📚 Conceitos-Chave Ensinados

- ✅ Gerenciamento de Estado (setState)
- ✅ Padrão DAO (Data Access Object)
- ✅ Serialização/Desserialização JSON
- ✅ CRUD Operations (Create, Read, Update, Delete)
- ✅ Persistência Local (SharedPreferences)
- ✅ Widgets: ListView, AlertDialog, Dismissible, etc
- ✅ UX Padrão Mobile (swipe to dismiss, pull to refresh)
- ✅ Tratamento de Erros
- ✅ Animações básicas
- ✅ Modais e Diálogos

---

**Última atualização**: 28 de outubro de 2025
