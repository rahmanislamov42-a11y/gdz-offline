import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'textbook_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await TextbookDatabase.load();
  } catch (_) {}
  runApp(const GdzOfflineApp());
}

const ink = Color(0xFF18233A);
const purple = Color(0xFF7257F5);
const mint = Color(0xFFBDF5D5);
const paper = Color(0xFFF7F7FC);

const days = [
  'Понедельник',
  'Вторник',
  'Среда',
  'Четверг',
  'Пятница',
  'Суббота',
];

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
        appBarTheme: const AppBarTheme(
          backgroundColor: paper,
          foregroundColor: ink,
        ),
      ),
      home: const HomeShell(),
    );
  }
}

class SchoolLesson {
  final String id;
  final int day;
  final String subject;
  final String time;
  final String room;

  const SchoolLesson({
    required this.id,
    required this.day,
    required this.subject,
    required this.time,
    required this.room,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'day': day,
        'subject': subject,
        'time': time,
        'room': room,
      };

  factory SchoolLesson.fromJson(Map<String, dynamic> json) {
    return SchoolLesson(
      id: json['id'] ?? '',
      day: json['day'] ?? 0,
      subject: json['subject'] ?? '',
      time: json['time'] ?? '',
      room: json['room'] ?? '',
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
      : grade = j['grade'] ?? 0,
        subject = j['subject'] ?? '',
        title = j['title'] ?? '',
        authors = List<String>.from(j['authors'] ?? []),
        editor = j['editor'] ?? '',
        publisher = j['publisher'] ?? '',
        year = j['year'] ?? 0,
        edition = j['edition'] ?? 0,
        isbn = j['isbn'] ?? '',
        fpuCode = j['fpu_code'] ?? '',
        fpuRow = j['fpu_row'] ?? 0,
        status = j['status'] ?? '',
        parts = j['parts'];
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int tab = 0;
  int selectedDay = DateTime.now().weekday - 1;

  List<SchoolLesson> lessons = [];
  List<Textbook> books = [];

  bool scheduleLoading = true;
  bool catalogLoading = true;

  int grade = 9;
  String subject = 'Алгебра';
  String query = '';

  XFile? pickedPhoto;
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    loadSchedule();
    loadCatalog();
  }

  Future<void> loadSchedule() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('school_schedule');

      if (raw != null) {
        final decoded = jsonDecode(raw) as List;
        lessons = decoded
            .map((e) => SchoolLesson.fromJson(
                Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (_) {
      lessons = [];
    }

    if (mounted) {
      setState(() => scheduleLoading = false);
    }
  }

  Future<void> saveSchedule() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(
      lessons.map((e) => e.toJson()).toList(),
    );
    await prefs.setString('school_schedule', raw);
  }

  Future<void> loadCatalog() async {
    try {
      final raw = await rootBundle.loadString('assets/catalog.json');
      final decoded = jsonDecode(raw) as List;
      books = decoded
          .map((e) => Textbook.fromJson(
              Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      books = [];
    }

    if (mounted) {
      setState(() => catalogLoading = false);
    }
  }

  List<SchoolLesson> get dayLessons {
    final result = lessons
        .where((e) => e.day == selectedDay)
        .toList();
    result.sort((a, b) => a.time.compareTo(b.time));
    return result;
  }

  List<Textbook> get filteredBooks {
    final q = query.toLowerCase().trim();

    return books.where((b) {
      final text =
          '${b.title} ${b.authors.join(' ')} ${b.publisher} ${b.isbn}'
              .toLowerCase();

      return b.grade == grade &&
          b.subject == subject &&
          (q.isEmpty || text.contains(q));
    }).toList();
  }

  Future<void> editLesson({SchoolLesson? lesson}) async {
    final subjectController =
        TextEditingController(text: lesson?.subject ?? '');
    final timeController =
        TextEditingController(text: lesson?.time ?? '');
    final roomController =
        TextEditingController(text: lesson?.room ?? '');

    int day = lesson?.day ?? selectedDay;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, updateDialog) {
            return AlertDialog(
              title: Text(
                lesson == null ? 'Добавить урок' : 'Изменить урок',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: subjectController,
                      decoration: const InputDecoration(
                        labelText: 'Название предмета',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: day,
                      decoration: const InputDecoration(
                        labelText: 'День недели',
                      ),
                      items: List.generate(
                        days.length,
                        (i) => DropdownMenuItem(
                          value: i,
                          child: Text(days[i]),
                        ),
                      ),
                      onChanged: (v) {
                        if (v != null) {
                          updateDialog(() => day = v);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: timeController,
                      decoration: const InputDecoration(
                        labelText: 'Время, например 08:30',
                      ),
                      keyboardType: TextInputType.datetime,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: roomController,
                      decoration: const InputDecoration(
                        labelText: 'Кабинет (необязательно)',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(dialogContext, false),
                  child: const Text('Отмена'),
                ),
                FilledButton(
                  onPressed: () {
                    if (subjectController.text.trim().isEmpty ||
                        timeController.text.trim().isEmpty) {
                      return;
                    }
                    Navigator.pop(dialogContext, true);
                  },
                  child: const Text('Сохранить'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      final updated = SchoolLesson(
        id: lesson?.id ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        day: day,
        subject: subjectController.text.trim(),
        time: timeController.text.trim(),
        room: roomController.text.trim(),
      );

      setState(() {
        if (lesson == null) {
          lessons.add(updated);
        } else {
          final index =
              lessons.indexWhere((e) => e.id == lesson.id);
          if (index != -1) lessons[index] = updated;
        }
        selectedDay = day;
      });

      await saveSchedule();
    }

    subjectController.dispose();
    timeController.dispose();
    roomController.dispose();
  }

  Future<void> deleteLesson(SchoolLesson lesson) async {
    setState(() {
      lessons.removeWhere((e) => e.id == lesson.id);
    });
    await saveSchedule();
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
        SnackBar(content: Text('Ошибка открытия фото: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      homePage(),
      schedulePage(),
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
            icon: Icon(Icons.calendar_month_rounded),
            label: 'Расписание',
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
    final today = DateTime.now().weekday - 1;
    final todayLessons = lessons
        .where((e) => e.day == today && today < 6)
        .toList()
      ..sort((a, b) => a.time.compareTo(b.time));

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Row(
          children: [
            CircleAvatar(
              backgroundColor: purple,
              child: Icon(Icons.auto_awesome, color: Colors.white),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ГДЗ ОФЛАЙН',
                  style: TextStyle(
                    color: ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Твой учебный помощник',
                  style: TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [purple, Color(0xFF9C83FF)],
            ),
            borderRadius: BorderRadius.circular(26),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ТВОЯ УЧЁБА.\nТВОЙ ТЕМП.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Расписание, учебники и задания в одном месте.',
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => setState(() => tab = 1),
                icon: const Icon(Icons.calendar_month),
                label: const Text('Моё расписание'),
                style: FilledButton.styleFrom(
                  backgroundColor: mint,
                  foregroundColor: ink,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'СЕГОДНЯ',
          style: TextStyle(
            color: ink,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        if (todayLessons.isEmpty)
          emptyBox('На сегодня уроки пока не добавлены.')
        else
          ...todayLessons.map(lessonCard),
        const SizedBox(height: 20),
        actionTile(
          icon: Icons.menu_book,
          title: 'Учебники',
          subtitle: 'Открыть каталог',
          onTap: () => setState(() => tab = 2),
        ),
        const SizedBox(height: 10),
        actionTile(
          icon: Icons.photo_camera,
          title: 'Фото задания',
          subtitle: 'Выбрать снимок',
          onTap: () => setState(() => tab = 3),
        ),
      ],
    );
  }

  Widget schedulePage() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Моё расписание',
          style: TextStyle(
            color: ink,
            fontSize: 25,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Добавляй уроки и редактируй свою неделю.',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 7,
          runSpacing: 8,
          children: List.generate(days.length, (i) {
            return ChoiceChip(
              label: Text(days[i].substring(0, 3)),
              selected: selectedDay == i,
              selectedColor: purple,
              labelStyle: TextStyle(
                color: selectedDay == i ? Colors.white : ink,
              ),
              onSelected: (_) => setState(() => selectedDay = i),
            );
          }),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Text(
                days[selectedDay],
                style: const TextStyle(
                  color: ink,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            FilledButton.icon(
              onPressed: () => editLesson(),
              icon: const Icon(Icons.add),
              label: const Text('Добавить'),
            ),
          ],
        ),
        const SizedBox(height: 15),
        if (scheduleLoading)
          const Center(child: CircularProgressIndicator())
        else if (dayLessons.isEmpty)
          emptyBox('Уроков пока нет. Нажми «Добавить».')
        else
          ...dayLessons.map(lessonCard),
        const SizedBox(height: 12),
        const Text(
          'Расписание сохраняется на этом телефоне.',
          style: TextStyle(color: Colors.black54, fontSize: 12),
        ),
      ],
    );
  }

  Widget lessonCard(SchoolLesson lesson) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEAEAF2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: const Color(0xFFECE8FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              lesson.time,
              style: const TextStyle(
                color: purple,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson.subject,
                  style: const TextStyle(
                    color: ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  lesson.room.isEmpty
                      ? 'Кабинет не указан'
                      : 'Кабинет: ${lesson.room}',
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') editLesson(lesson: lesson);
              if (value == 'delete') deleteLesson(lesson);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'edit',
                child: Text('Изменить'),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text('Удалить'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget emptyBox(String message) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.event_note_rounded,
            size: 38,
            color: purple,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, color: purple, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  Widget catalogPage() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Каталог учебников',
          style: TextStyle(
            color: ink,
            fontSize: 25,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 15),
        const Text('КЛАСС'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: List.generate(11, (i) {
            final value = i + 1;
            return ChoiceChip(
              label: Text('$value'),
              selected: grade == value,
              onSelected: (_) => setState(() => grade = value),
              selectedColor: purple,
              labelStyle: TextStyle(
                color: grade == value ? Colors.white : ink,
              ),
            );
          }),
        ),
        const SizedBox(height: 15),
        DropdownButtonFormField<String>(
          value: subject,
          decoration: const InputDecoration(
            labelText: 'Предмет',
            filled: true,
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
            return DropdownMenuItem(value: s, child: Text(s));
          }).toList(),
          onChanged: (v) {
            setState(() => subject = v ?? 'Алгебра');
          },
        ),
        const SizedBox(height: 12),
        TextField(
          onChanged: (v) => setState(() => query = v),
          decoration: const InputDecoration(
            hintText: 'Автор, название, ISBN…',
            prefixIcon: Icon(Icons.search),
            filled: true,
          ),
        ),
        const SizedBox(height: 18),
        if (catalogLoading)
          const Center(child: CircularProgressIndicator())
        else if (filteredBooks.isEmpty)
          emptyBox('Пока нет учебников по этому выбору.')
        else
          ...filteredBooks.map(bookCard),
        const SizedBox(height: 12),
        const Text(
          'Это начальная база, а не полный федеральный каталог.',
          style: TextStyle(color: Colors.black54, fontSize: 12),
        ),
      ],
    );
  }

  Widget bookCard(Textbook b) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
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
          const SizedBox(height: 10),
          Text(
            b.title,
            style: const TextStyle(
              color: ink,
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 8),
          Text('Авторы: ${b.authors.join(', ')}'),
          Text('Редактор: ${b.editor}'),
          Text('Издательство: ${b.publisher} · ${b.year}'),
          Text('Издание: ${b.edition}-е · ISBN: ${b.isbn}'),
          const SizedBox(height: 8),
          Text('ФПУ: ${b.fpuCode}, строка ${b.fpuRow}'),
          Text(
            b.status,
            style: const TextStyle(color: Colors.green),
          ),
        ],
      ),
    );
  }

  Widget photoPage() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Фото задания',
          style: TextStyle(
            color: ink,
            fontSize: 25,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 15),
        Container(
          constraints: const BoxConstraints(minHeight: 230),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: pickedPhoto == null
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo,
                        color: purple,
                        size: 54,
                      ),
                      SizedBox(height: 12),
                      Text('Здесь появится фото задания'),
                    ],
                  ),
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
          icon: const Icon(Icons.camera_alt),
          label: const Text('Сделать фото'),
        ),
        const SizedBox(height: 9),
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
        const Text(
          'Фото можно выбрать и просмотреть. Распознавание и объяснение через ИИ пока не подключены.',
          style: TextStyle(color: Colors.black54),
        ),
      ],
    );
  }

  Widget aboutPage() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'О приложении',
          style: TextStyle(
            color: ink,
            fontSize: 25,
            fontWeight: FontWeight.w900,
          ),
        ),
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
              Text(
                'ГДЗ ОФЛАЙН',
                style: TextStyle(
                  color: purple,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Учебный помощник для учебников, расписания и школьных заданий.',
                style: TextStyle(color: ink, height: 1.4),
              ),
              SizedBox(height: 16),
              Divider(),
              Text('Версия 0.2.0'),
              SizedBox(height: 7),
              Text(
                'Каталог является начальным. Материалы можно добавлять при наличии законных оснований.',
                style: TextStyle(
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
