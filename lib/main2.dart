
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image_picker/image_picker.dart';
import 'textbook_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await TextbookDatabase.load();
  } catch (_) {
    // Приложение сможет открыться и без дополнительной базы.
  }

  runApp(const GdzOfflineApp());
}

const Color purple = Color(0xFF8065F5);

class GdzOfflineApp extends StatefulWidget {
  const GdzOfflineApp({super.key});

  @override
  State<GdzOfflineApp> createState() => _GdzOfflineAppState();
}

class _GdzOfflineAppState extends State<GdzOfflineApp> {
  ThemeMode themeMode = ThemeMode.dark;

  void toggleTheme(bool light) {
    setState(() {
      themeMode = light ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ГДЗ ОФЛАЙН',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: purple,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F4FA),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: purple,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF11121A),
        cardTheme: CardThemeData(
          color: const Color(0xFF1D1E2A),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
      ),
      home: HomeShell(
        isLight: themeMode == ThemeMode.light,
        onThemeChanged: toggleTheme,
      ),
    );
  }
}

class Textbook {
  final int grade;
  final String subject;
  final String title;
  final List<String> authors;
  final String editor;
  final String publisher;
  final int year;
  final int edition;
  final String isbn;
  final String fpuCode;
  final int fpuRow;
  final String status;
  final int? parts;

  Textbook.fromJson(Map<String, dynamic> j)
      : grade = (j['grade'] as num?)?.toInt() ?? 0,
        subject = j['subject']?.toString() ?? '',
        title = j['title']?.toString() ?? 'Без названия',
        authors = (j['authors'] as List? ?? [])
            .map((e) => e.toString())
            .toList(),
        editor = j['editor']?.toString() ?? '',
        publisher = j['publisher']?.toString() ?? '',
        year = (j['year'] as num?)?.toInt() ?? 0,
        edition = (j['edition'] as num?)?.toInt() ?? 1,
        isbn = j['isbn']?.toString() ?? '',
        fpuCode = j['fpu_code']?.toString() ?? '',
        fpuRow = (j['fpu_row'] as num?)?.toInt() ?? 0,
        status = j['status']?.toString() ?? '',
        parts = (j['parts'] as num?)?.toInt();
}

class HomeShell extends StatefulWidget {
  final bool isLight;
  final ValueChanged<bool> onThemeChanged;

  const HomeShell({
    super.key,
    required this.isLight,
    required this.onThemeChanged,
  });

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int tab = 0;
  int grade = 9;
  String subject = 'Алгебра';
  String query = '';
  bool loading = true;

  List<Textbook> books = [];
  XFile? pickedPhoto;

  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    loadCatalog();
  }

  Future<void> loadCatalog() async {
    try {
      final raw = await rootBundle.loadString('assets/catalog.json');
      final decoded = jsonDecode(raw) as List;

      books = decoded
          .map((e) => Textbook.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList();
    } catch (_) {
      books = [];
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  List<Textbook> get filteredBooks {
    final q = query.trim().toLowerCase();

    return books.where((b) {
      final searchable =
          '${b.title} ${b.authors.join(' ')} ${b.publisher} ${b.isbn}'
              .toLowerCase();

      return b.grade == grade &&
          b.subject == subject &&
          (q.isEmpty || searchable.contains(q));
    }).toList();
  }

  Future<void> choosePhoto(ImageSource source) async {
    try {
      final file = await picker.pickImage(
        source: source,
        imageQuality: 88,
        maxWidth: 2000,
      );

      if (file != null && mounted) {
        setState(() => pickedPhoto = file);
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось открыть фото: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      homePage(),
      catalogPage(),
      photoPage(),
      profilePage(),
    ];

    return Scaffold(
      body: SafeArea(child: pages[tab]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (v) => setState(() => tab = v),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_rounded),
            label: 'Главная',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_rounded),
            label: 'Каталог',
          ),
          NavigationDestination(
            icon: Icon(Icons.camera_alt_rounded),
            label: 'Фото',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_rounded),
            label: 'Настройки',
          ),
        ],
      ),
    );
  }

  Widget heading(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget homePage() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: purple,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ГДЗ ОФЛАЙН',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'Твой учебный помощник',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => setState(() => tab = 3),
              icon: const Icon(Icons.settings_outlined),
            ),
          ],
        ),
        const SizedBox(height: 25),
        Container(
          padding: const EdgeInsets.all(23),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7054E8), Color(0xFFAA83FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(27),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ТВОЯ УЧЁБА.\nТВОЙ ТЕМП.',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 28,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Находи учебники, работай с заданиями и планируй учёбу.',
                style: TextStyle(
                  color: Colors.white,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => setState(() => tab = 1),
                icon: const Icon(Icons.search),
                label: const Text('Открыть каталог'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF6046D0),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 25),
        const Text(
          'БЫСТРЫЙ ДОСТУП',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: actionTile(
                Icons.menu_book_rounded,
                'Учебники',
                'Поиск по классу',
                () => setState(() => tab = 1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: actionTile(
                Icons.photo_camera_rounded,
                'Фото задания',
                'Добавить снимок',
                () => setState(() => tab = 2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Card(
          child: ListTile(
            leading: const Icon(
              Icons.wifi_off_rounded,
              color: purple,
            ),
            title: const Text(
              'Работа без интернета',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: const Text(
              'Локально сохранённые данные доступны офлайн.',
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.calendar_month_rounded),
            title: const Text('Школьный планер'),
            subtitle: const Text(
              'Расписание и домашние задания появятся в следующих обновлениях.',
            ),
          ),
        ),
      ],
    );
  }

  Widget actionTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: purple, size: 29),
              const SizedBox(height: 17),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget catalogPage() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        heading('Каталог', 'Выбери класс и предмет'),
        const SizedBox(height: 22),
        const Text(
          'КЛАСС',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(11, (i) {
            final value = i + 1;

            return ChoiceChip(
              label: Text('$value'),
              selected: grade == value,
              onSelected: (_) => setState(() => grade = value),
            );
          }),
        ),
        const SizedBox(height: 20),
        const Text(
          'ПРЕДМЕТ',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 9),
        DropdownButtonFormField<String>(
          value: subject,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          items: const [
            'Алгебра',
            'Геометрия',
            'Русский язык',
            'Литература',
            'Физика',
            'Химия',
            'Биология',
            'История',
            'Английский язык',
            'Информатика',
          ].map((s) {
            return DropdownMenuItem(
              value: s,
              child: Text(s),
            );
          }).toList(),
          onChanged: (v) {
            if (v != null) setState(() => subject = v);
          },
        ),
        const SizedBox(height: 14),
        TextField(
          onChanged: (v) => setState(() => query = v),
          decoration: const InputDecoration(
            hintText: 'Автор, название, ISBN...',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 18),
        if (loading)
          const Center(child: CircularProgressIndicator())
        else if (filteredBooks.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  const Icon(
                    Icons.menu_book_outlined,
                    size: 40,
                    color: purple,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Учебники не найдены',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'В локальной базе пока нет записей для этого выбора.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...filteredBooks.map(bookCard),
        const SizedBox(height: 15),
        const Text(
          'Это начальная база, а не полный каталог учебников.',
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget bookCard(Textbook b) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${b.grade} класс · ${b.subject}',
              style: const TextStyle(
                color: purple,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              b.title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text('Авторы: ${b.authors.join(', ')}'),
            if (b.editor.isNotEmpty) Text('Редактор: ${b.editor}'),
            Text('Издательство: ${b.publisher} · ${b.year}'),
            Text('Издание: ${b.edition}-е'),
            if (b.isbn.isNotEmpty) Text('ISBN: ${b.isbn}'),
            if (b.fpuCode.isNotEmpty)
              Text('ФПУ: ${b.fpuCode}, строка ${b.fpuRow}'),
            if (b.status.isNotEmpty) Text(b.status),
            if (b.parts == null)
              const Text(
                'Количество частей не указано.',
                style: TextStyle(fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }

  Widget photoPage() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        heading('Фото задания', 'Добавь снимок для будущего разбора.'),
        const SizedBox(height: 22),
        Card(
          child: SizedBox(
            height: 260,
            child: pickedPhoto == null
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo_rounded,
                        color: purple,
                        size: 55,
                      ),
                      SizedBox(height: 12),
                      Text('Здесь появится фото задания'),
                      SizedBox(height: 6),
                      Text(
                        'Постарайся сделать чёткий снимок.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Image.file(
                      File(pickedPhoto!.path),
                      fit: BoxFit.contain,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 15),
        FilledButton.icon(
          onPressed: () => choosePhoto(ImageSource.camera),
          icon: const Icon(Icons.camera_alt),
          label: const Text('Сделать фото'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => choosePhoto(ImageSource.gallery),
          icon: const Icon(Icons.photo_library),
          label: const Text('Выбрать из галереи'),
        ),
        if (pickedPhoto != null)
          TextButton.icon(
            onPressed: () => setState(() => pickedPhoto = null),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Убрать фото'),
          ),
        const SizedBox(height: 15),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Пока здесь доступны съёмка и просмотр фотографии. '
              'Распознавание заданий и объяснение через ИИ ещё не подключены.',
            ),
          ),
        ),
      ],
    );
  }

  Widget profilePage() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        heading('Настройки', 'Настрой приложение под себя.'),
        const SizedBox(height: 22),
        Card(
          child: SwitchListTile(
            secondary: Icon(
              widget.isLight
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
              color: purple,
            ),
            title: const Text(
              'Светлая тема',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(
              widget.isLight
                  ? 'Сейчас включена светлая тема'
                  : 'Сейчас включена тёмная тема',
            ),
            value: widget.isLight,
            onChanged: widget.onThemeChanged,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.school_outlined, color: purple),
            title: const Text('Класс'),
            subtitle: const Text('Настройка класса появится позже.'),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.person_outline, color: purple),
            title: const Text('Имя или псевдоним'),
            subtitle: const Text('Персонализация появится позже.'),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.info_outline, color: purple),
            title: const Text('О приложении'),
            subtitle: const Text(
              'ГДЗ ОФЛАЙН · версия 0.2.0',
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Приложение не содержит полного набора ГДЗ. '
          'Материалы добавляются при наличии законных оснований.',
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
