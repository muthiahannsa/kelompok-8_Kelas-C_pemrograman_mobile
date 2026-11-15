import 'dart:async';

void main(){
  List<Map<String, dynamic>> mahasiswa = [
    {'nama': 'anu', 'nilai':85, 'kehadiran':90},
    {'nama':'ini', 'nilai':60, 'kehadiran':70},
    {'nama':'ler', 'nilai':45, 'kehadiran':56},
  ];

  for (var mhs in mahasiswa){
    String grade = tentukanGrade(mhs['nilai']);
    String status = tentukanStatus(mhs['nilai'], mhs['kehadiran']);

    print('nama           :${mhs['nama']}');
    print('nilai          :${mhs['nilai']}');
    print('kehadiran      :${mhs['kehadiran']}%');
    print('grade          :${grade}');
    print('status         :${status}');
    print('==================================');
  }
}

String tentukanGrade(int nilai){
  if (nilai >= 85){
      return 'A';
  }   else if (nilai >= 70){
      return 'B';
  }   else if (nilai >= 55){
      return 'C';
  }   else {
    return 'D';
  }
}

String tentukanStatus(int nilai, int kehadiran){
  if (nilai >= 55 && kehadiran >= 75){
    return 'LULUS';
  } else {
    return 'TIDAK LULUS';
  }
}