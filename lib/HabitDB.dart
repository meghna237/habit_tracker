
import 'package:objectbox/objectbox.dart';


@Entity()
class HabitDB {
  int id;
  String habit;
  //IconData icon;
  DateTime date;

  HabitDB({this.id=0, required this.habit, required this.date});
}

@Entity()
class HabitList {
  int id;
  String habit;

  HabitList({this.id = 0, required this.habit});
}
