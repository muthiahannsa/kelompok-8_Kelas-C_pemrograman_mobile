class Student {
  String name;
  List<int> scores;
  int attendance;

  Student(this.name, this.scores, this.attendance);
}

double calculateAverage(List<int> scores) {
  int total = 0;
  for (int score in scores) {
    total += score;
  }
  return total / scores.length;
}

String determineGrade(double average) {
  if (average >= 85) {
    return 'A';
  } else if (average >= 75) {
    return 'B';
  } else if (average >= 65) {
    return 'C';
  } else if (average >= 50) {
    return 'D';
  } else {
    return 'E';
  }
}

String determineStatus(String grade, int attendance) {
  if (grade != 'E' && attendance >= 80) {
    return 'LULUS';
  } else {
    return 'TIDAK LULUS';
  }
}

void printReport(Student student) {
  double average = calculateAverage(student.scores);
  String grade = determineGrade(average);
  String status = determineStatus(grade, student.attendance);

  print('Nama      : ${student.name}');
  print('Nilai     : ${student.scores}');
  print('Rata-rata : ${average.toStringAsFixed(2)}');
  print('Kehadiran : ${student.attendance}%');
  print('Grade     : $grade');
  print('Status    : $status');
}

void main() {
  List<Student> students = [
    Student('Andi', [90, 85, 88], 95),
    Student('Budi', [70, 65, 72], 82),
    Student('Citra', [55, 60, 50], 78),
    Student('Dewi', [40, 45, 38], 60),
    Student('Eka', [95, 92, 98], 88),
  ];

  print('STUDENT GRADE TRACKER\n');

  for (Student student in students) {
    printReport(student);
  }

  int lulusCount = 0;
  for (Student student in students) {
    double avg = calculateAverage(student.scores);
    String grade = determineGrade(avg);
    String status = determineStatus(grade, student.attendance);
    if (status == 'LULUS') {
      lulusCount++;
    }
  }

  print('\nTotal mahasiswa : ${students.length}');
  print('Total lulus       : $lulusCount');
  print('Total tidak lulus : ${students.length - lulusCount}');
}