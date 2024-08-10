import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'HabitDB.dart';
import 'objectbox.g.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await openStore();
  final habitBox = store.box<HabitDB>();
  final habitListBox = store.box<HabitList>(); // Add this line
  runApp(
    ChangeNotifierProvider(
      create: (context) => HabitProvider(),
      child: MyApp(habitBox, habitListBox), // Pass habitListBox here
    ),
  );
}

class MyApp extends StatelessWidget {
  final Box<HabitDB> habitBox;
  final Box<HabitList> habitListBox;
  const MyApp(this.habitBox, this.habitListBox, {super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
      routes: {
        '/habit': (context) => RecordHabit(habitBox: habitBox, habitListBox: habitListBox),
        '/report': (context) => ViewReport(habitListBox: habitListBox,),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  void _navigateToHabit() {
    Navigator.pushNamed(context, '/habit');
  }
  void _navigateToReport() {
    Navigator.pushNamed(context, '/report');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDE4F5),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _navigateToHabit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF874AB7),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
                padding: const EdgeInsets.symmetric(horizontal: 70, vertical: 20),
              ),
              child: const Text(
                "Record Habit",
                style: TextStyle(color: Colors.white, fontSize: 18, fontFamily: 'Cursive'),
              ),
            ),
            const SizedBox(height: 80),
            ElevatedButton(
              onPressed: _navigateToReport,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF874AB7),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
                padding: const EdgeInsets.symmetric(horizontal: 74, vertical: 20)
              ),
              child: const Text(
                'View Report',
                style: TextStyle(color: Colors.white, fontSize: 18, fontFamily: 'Cursive'),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class Habit {
  String title;
  bool isSelected;

  Habit({required this.title, this.isSelected = false});

  void toggleSelection() {
    isSelected = !isSelected;
  }
}

class HabitProvider with ChangeNotifier {
  final List<Habit> _habits = [];

  List<Habit> get habits => _habits;

  void addHabit(String title) {
    _habits.add(Habit(title: title));
    notifyListeners();
  }

  void toggleHabitCheckbox(int index) {
    _habits[index].toggleSelection();
    notifyListeners();
  }
}

class RecordHabit extends StatefulWidget {
  final Box<HabitDB> habitBox;
  final Box<HabitList> habitListBox;
  RecordHabit({required this.habitBox, required this.habitListBox});

  @override
  _RecordHabitState createState() => _RecordHabitState();
}

class _RecordHabitState extends State<RecordHabit> {
  final TextEditingController _controller = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  List<HabitList> _habitList = [];
  Map<int, bool> _selectedHabits = {};

  @override
  void initState() {
    super.initState();
    _fetchHabits();
  }

  void _fetchHabits(){
    setState(() {
      _habitList = widget.habitListBox.getAll();
      _habitList.forEach((habit) {
        _selectedHabits[habit.id] = false;
      });
    });
  }

  void _toggleCheckbox(int id) {
    setState(() {
      _selectedHabits[id] = !_selectedHabits[id]!;
    });
  }

  void _addHabitToList(String habit) {
    final habitListEntry = HabitList(habit: habit);
    widget.habitListBox.put(habitListEntry);
    _fetchHabits();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDE4F5),
      appBar: AppBar(
        title: const Text('Activities Done:'),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Selected Date: ${DateFormat.yMMMd().format(_selectedDate)}',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: _pickDate,
                )
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _habitList.length,
              itemBuilder: (context, index) {
                final habit = _habitList[index];
                return ListTile(
                  title: Text(habit.habit),
                  trailing: Checkbox(
                    value: _selectedHabits[habit.id],
                    onChanged: (bool? value) {
                      _toggleCheckbox(habit.id);
                    },
                  ),
                );
              },
            )
          ),
          ElevatedButton(
            onPressed: _saveSelectedHabits,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF874AB7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0)
              ),
              padding: const EdgeInsets.symmetric(horizontal: 70, vertical: 20)
            ),
            child: const Text(
              'Submit',
              style: TextStyle(
                color: Colors.white,
                fontSize: 25,
                fontFamily: 'Cursive'
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Add a new activity'
                    ),
                    controller: _controller,
                    onSubmitted: (abc) {
                      if (abc.isNotEmpty) {
                        _addHabitToList(abc);
                        _controller.clear();
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    if (_controller.text.isNotEmpty) {
                      _addHabitToList(_controller.text);
                      _controller.clear();
                    }
                  },
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  void _pickDate() async {
    DateTime initialDate = _selectedDate;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Date'),
          content: SizedBox(
            height: 300,  // Adjust the height as needed
            width: 300,
            child: Column(
              children: [
                Expanded(
                  child: CalendarDatePicker(
                    initialDate: initialDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                    onDateChanged: (newDate) {
                      initialDate = newDate;
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedDate = initialDate;
                });
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _saveSelectedHabits() {
    final selectedHabits = _habitList.where((habit) => _selectedHabits[habit.id] == true);
    for (var habit in selectedHabits) {
      final habitDB = HabitDB(habit: habit.habit, date: _selectedDate);
      widget.habitBox.put(habitDB);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Selected habits saved successfully!')),
    );
  }
}

class ViewReport extends StatefulWidget {
  final Box<HabitList> habitListBox;

  ViewReport({required this.habitListBox});

  @override
  _ViewReportState createState() => _ViewReportState();
}

class _ViewReportState extends State<ViewReport> {
  late DateTime _selectedDate;
  final Map<DateTime, Color> _dateColors = {};
  late HabitList _selectedHabit;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    final habitList = widget.habitListBox.getAll();
    _selectedHabit = habitList.isNotEmpty ? habitList.first : HabitList(habit: 'No Habit');
  }

  void _changeHabit(bool isNext){
    final habitList = widget.habitListBox.getAll();
    if (habitList.isEmpty) return;

    final currentIndex = habitList.indexOf(_selectedHabit);
    final nextIndex = (currentIndex + (isNext ? 1 : -1)) % habitList.length;
    setState(() {
      _selectedHabit = habitList[nextIndex < 0 ? habitList.length -1 : nextIndex];
    });
  }

  void _changeMonth(bool isNext) {
    setState(() {
      _selectedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month + (isNext ? 1 : -1)
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Habit Report"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_left),
                  onPressed: () => _changeHabit(false),
                ),
                Text(
                  _selectedHabit.habit,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(Icons.arrow_right),
                  onPressed: () => _changeHabit(true),
                )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_left),
                  onPressed: () => _changeMonth(false),
                ),
                Text(
                  DateFormat('MMMM yyyy').format(_selectedDate),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(Icons.arrow_right),
                  onPressed: () => _changeMonth(true),
                )
              ],
            )
          ),
          Expanded(child: _buildCalendar()),

        ],
      ),
    );
  }

  Widget _buildCalendar() {
    final firstDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final lastDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
    final dayInMonth = lastDayOfMonth.day;

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.0,
      ),
      itemCount: dayInMonth + firstDayOfMonth.weekday,
      itemBuilder: (context, index) {
        if (index < firstDayOfMonth.weekday) {
          return Container();
        }
        final day = index - firstDayOfMonth.weekday + 1;
        final date = DateTime(_selectedDate.year, _selectedDate.month, day);
        final color = _dateColors[date] ?? Colors.white;

        return GestureDetector(
          onTap: () {},
          child: Container(
            margin: const EdgeInsets.all(4.0),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey),
            ),
            child: Center(
              child: Text(
                '$day',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
        );
      },
    );
  }


}

