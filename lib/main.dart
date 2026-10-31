import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image_picker/image_picker.dart';
import 'textbook_database.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TextbookDatabase.load();
  runApp(const MyApp());
}

const Color ink = Color(0xFF18233A);
const Color purple = Color(0xFF7257F5);
const Color mint = Color(0xFFBDF5D5);
const Color paper = Color(0xFFF7F7FC);

class GdzOfflineApp extends StatelessWidget {
  const GdzOfflineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ГДЗ ОФЛАЙН',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: paper,
        colorScheme: ColorScheme.fromSeed(seedColor: purple),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: paper,
          foregroundColor: ink,
          elevation: 0,
          centerTitle: false,
        ),
      ),
      home: const HomeShell(),
    );
  }
}

class Textbook {
  final String id;
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
      : id = j['id'],
        grade = j['grade'],
        subject = j['subject'],
        title = j['title'],
        authors = List<String>.from(j['authors']),
        editor = j['editor'] ?? '',
        publisher = j['publisher'],
        year = j['year'],
        edition = j['edition'],
        isbn = j['isbn'],
        fpuCode = j['fpu_code'],
        fpuRow = j['fpu_row'],
        status = j['status'],
        parts = j['parts'];
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int tab = 0;
  List<Textbook> books = [];
  bool loading = true;
  String query = '';
  int grade = 9;
  String subject = 'Алгебра';
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
      final decoded = jsonDecode(raw) as List<dynamic>;
      books = decoded
          .map((e) => Textbook.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      books = [];
    }
    if (mounted) setState(() => loading = false);
  }

  List<Textbook> get filteredBooks {
    final q = query.trim().toLowerCase();
    return books.where((b) {
      final matchesGrade = b.grade == grade;
      final matchesSubject = b.subject == subject;
      final searchable =
          '${b.title} ${b.authors.join(' ')} ${b.publisher} ${b.isbn}'
              .toLowerCase();
      return matchesGrade &&
          matchesSubject &&
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
        SnackBar(content: Text('Не удалось открыть изображение: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      homePage(),
      catalogPage(),
      photoPage(),
      aboutPage(),
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
            icon: Icon(Icons.person_rounded),
            label: 'Профиль',
          ),
        ],
      ),
    );
  }

  Widget homePage() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: [
        Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: purple,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ГДЗ ОФЛАЙН',
                    style: TextStyle(
                      color: ink,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .3,
                    )),
                Text('Учись понимать, а не просто списывать',
                    style: TextStyle(color: Colors.black54, fontSize: 11)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7257F5), Color(0xFF9C83FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ТВОЯ УЧЁБА.\nТВОЙ ТЕМП.',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 27,
                    height: 1.12,
                  )),
              const SizedBox(height: 10),
              const Text(
                'Находи учебники, ищи задания и разбирайся в решениях.',
                style: TextStyle(color: Colors.white, height: 1.4),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: mint,
                  foregroundColor: ink,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 17, vertical: 13),
                ),
                onPressed: () => setState(() => tab = 1),
                icon: const Icon(Icons.search_rounded),
                label: const Text('Открыть каталог'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const Text('БЫСТРЫЙ СТАРТ',
            style: TextStyle(
                color: ink, fontWeight: FontWeight.w900, letterSpacing: .8)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: actionTile(
                icon: Icons.menu_book_rounded,
                title: 'Учебники',
                subtitle: 'Найти по классу',
                color: const Color(0xFFECE8FF),
                onTap: () => setState(() => tab = 1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: actionTile(
                icon: Icons.photo_camera_back_rounded,
                title: 'Фото задания',
                subtitle: 'Выбрать снимок',
                color: const Color(0xFFDFF8EB),
                onTap: () => setState(() => tab = 2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFEAEAF2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.wifi_off_rounded, color: purple, size: 25),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Каталог работает офлайн',
                        style: TextStyle(
                            color: ink, fontWeight: FontWeight.w800)),
                    SizedBox(height: 4),
                    Text(
                      'Учебники, добавленные в локальную базу приложения, будут доступны без сети.',
                      style: TextStyle(color: Colors.black54, height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: ink, size: 27),
            const SizedBox(height: 17),
            Text(title,
                style: const TextStyle(
                    color: ink, fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 3),
            Text(subtitle,
                style: const TextStyle(color: Colors.black54, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget catalogPage() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: [
        const Text('Каталог учебников',
            style: TextStyle(
                color: ink, fontSize: 25, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        const Text('Выбери класс и предмет',
            style: TextStyle(color: Colors.black54)),
        const SizedBox(height: 20),
        const Text('КЛАСС',
            style: TextStyle(
                color: ink, fontWeight: FontWeight.w800, fontSize: 11)),
        const SizedBox(height: 9),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(11, (i) {
            final value = i + 1;
            final selected = grade == value;
            return ChoiceChip(
              label: Text('$value'),
              selected: selected,
              onSelected: (_) => setState(() => grade = value),
              selectedColor: purple,
              labelStyle: TextStyle(
                color: selected ? Colors.white : ink,
                fontWeight: FontWeight.w800,
              ),
              side: BorderSide.none,
              backgroundColor: Colors.white,
            );
          }),
        ),
        const SizedBox(height: 18),
        const Text('ПРЕДМЕТ',
            style: TextStyle(
                color: ink, fontWeight: FontWeight.w800, fontSize: 11)),
        const SizedBox(height: 9),
        DropdownButtonFormField<String>(
          value: subject,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
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
          ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: (v) => setState(() => subject = v ?? 'Алгебра'),
        ),
        const SizedBox(height: 15),
        TextField(
          onChanged: (v) => setState(() => query = v),
          decoration: InputDecoration(
            hintText: 'Автор, название, ISBN…',
            prefixIcon: const Icon(Icons.search_rounded),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 18),
        if (loading)
          const Center(child: CircularProgressIndicator())
        else if (filteredBooks.isEmpty)
          emptyCatalog()
        else
          ...filteredBooks.map(bookCard),
        const SizedBox(height: 12),
        const Text(
          'Важно: это начальная база, а не полный федеральный каталог. Новые записи добавляются после проверки источников и прав на контент.',
          style: TextStyle(color: Colors.black54, fontSize: 12, height: 1.4),
        ),
      ],
    );
  }

  Widget emptyCatalog() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        children: [
          Icon(Icons.menu_book_outlined, size: 38, color: purple),
          SizedBox(height: 10),
          Text('Пока нет учебников по этому выбору',
              textAlign: TextAlign.center,
              style: TextStyle(color: ink, fontWeight: FontWeight.w800)),
          SizedBox(height: 5),
          Text('Каталог будет пополняться проверенными записями.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }

  Widget bookCard(Textbook b) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: const Color(0xFFEAEAF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFECE8FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${b.grade} класс · ${b.subject}',
                    style: const TextStyle(
                        color: purple,
                        fontWeight: FontWeight.w800,
                        fontSize: 11)),
              ),
              const Spacer(),
              const Icon(Icons.verified_rounded, color: Color(0xFF20A56B)),
            ],
          ),
          const SizedBox(height: 12),
          Text(b.title,
              style: const TextStyle(
                  color: ink, fontWeight: FontWeight.w900, fontSize: 17)),
          const SizedBox(height: 8),
          Text('Авторы: ${b.authors.join(', ')}',
              style: const TextStyle(color: Colors.black87, height: 1.35)),
          const SizedBox(height: 5),
          Text('Редактор: ${b.editor}',
              style: const TextStyle(color: Colors.black54)),
          Text('Издательство: ${b.publisher} · ${b.year}',
              style: const TextStyle(color: Colors.black54)),
          Text('Издание: ${b.edition}-е · ISBN: ${b.isbn}',
              style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 10),
          Text('ФПУ: ${b.fpuCode}, строка ${b.fpuRow}',
              style: const TextStyle(
                  color: ink, fontWeight: FontWeight.w700, fontSize: 12)),
          const SizedBox(height: 5),
          Text(b.status,
              style: const TextStyle(
                  color: Color(0xFF18885A), fontSize: 11)),
          if (b.parts == null)
            const Padding(
              padding: EdgeInsets.only(top: 5),
              child: Text('Количество частей: в источнике не указано',
                  style: TextStyle(color: Colors.black54, fontSize: 11)),
            ),
        ],
      ),
    );
  }

  Widget photoPage() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: [
        const Text('Фото задания',
            style: TextStyle(
                color: ink, fontSize: 25, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        const Text('Добавь фото, чтобы подготовить его к разбору.',
            style: TextStyle(color: Colors.black54)),
        const SizedBox(height: 22),
        Container(
          constraints: const BoxConstraints(minHeight: 230),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE4E0FF), width: 1.5),
          ),
          child: pickedPhoto == null
              ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo_rounded,
                        color: purple, size: 54),
                    SizedBox(height: 12),
                    Text('Здесь появится фото задания',
                        style: TextStyle(
                            color: ink, fontWeight: FontWeight.w800)),
                    SizedBox(height: 5),
                    Text('Снимок должен быть чётким и хорошо освещённым.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54, fontSize: 12)),
                  ],
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    File(pickedPhoto!.path),
                    fit: BoxFit.contain,
                    height: 320,
                  ),
                ),
        ),
        const SizedBox(height: 15),
        FilledButton.icon(
          onPressed: () => choosePhoto(ImageSource.camera),
          icon: const Icon(Icons.camera_alt_rounded),
          label: const Text('Сделать фото'),
          style: FilledButton.styleFrom(
            backgroundColor: purple,
            padding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
        const SizedBox(height: 9),
        OutlinedButton.icon(
          onPressed: () => choosePhoto(ImageSource.gallery),
          icon: const Icon(Icons.photo_library_outlined),
          label: const Text('Выбрать из галереи'),
          style: OutlinedButton.styleFrom(
            foregroundColor: ink,
            padding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
        if (pickedPhoto != null) ...[
          const SizedBox(height: 9),
          TextButton.icon(
            onPressed: () => setState(() => pickedPhoto = null),
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Убрать фото'),
          ),
        ],
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3D9),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, color: Color(0xFF9A6711)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Загрузка фото и его просмотр работают. Автоматическое распознавание и объяснение через ИИ пока не подключены.',
                  style: TextStyle(
                      color: Color(0xFF775313), height: 1.35, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget aboutPage() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
      children: [
        const Text('О приложении',
            style: TextStyle(
                color: ink, fontSize: 25, fontWeight: FontWeight.w900)),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ГДЗ ОФЛАЙН',
                  style: TextStyle(
                      color: purple,
                      fontWeight: FontWeight.w900,
                      fontSize: 22)),
              SizedBox(height: 8),
              Text(
                'Учебный помощник для поиска учебников и разбора школьных заданий.',
                style: TextStyle(color: ink, height: 1.4),
              ),
              SizedBox(height: 16),
              Divider(),
              Text('Версия 0.1.0 · MVP',
                  style: TextStyle(color: Colors.black54)),
              SizedBox(height: 7),
              Text(
                'Приложение не содержит полного набора ГДЗ. Материалы учебников и готовые решения можно добавлять только при наличии законных оснований и разрешений.',
                style: TextStyle(color: Colors.black54, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
