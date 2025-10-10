import 'package:cloud_firestore/cloud_firestore.dart';

class Cat {
  final String id;
  final String ownerId;
  final String name;
  final String breed;
  final String gender; // 'male' | 'female'
  final DateTime? birthdate; // แทน age
  final String description;
  final List<String> imageUrls;

  Cat({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.breed,
    required this.gender,
    required this.birthdate,
    required this.description,
    required this.imageUrls,
  });

  factory Cat.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Cat(
      id: doc.id,
      ownerId: d['ownerId'] as String,
      name: d['name'] as String,
      breed: d['breed'] as String? ?? 'Other',
      gender: d['gender'] as String? ?? 'unknown',
      birthdate: (d['birthdate'] as Timestamp?)?.toDate(),
      description: d['description'] as String? ?? '',
      imageUrls: (d['imageUrls'] as List?)?.cast<String>() ?? const [],
    );
  }

  Map<String, dynamic> toMap() => {
    'ownerId': ownerId,
    'name': name,
    'breed': breed,
    'gender': gender,
    'birthdate': birthdate != null ? Timestamp.fromDate(birthdate!) : null,
    'description': description,
    'imageUrls': imageUrls,
    'createdAt': FieldValue.serverTimestamp(),
  };
}

// Records (หลายครั้ง)
class VaccineRecord {
  final String id; final DateTime date; final String type; final String? notes;
  VaccineRecord({required this.id, required this.date, required this.type, this.notes});
  factory VaccineRecord.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return VaccineRecord(id: doc.id, date: (d['date'] as Timestamp).toDate(), type: d['type'], notes: d['notes']);
  }
  Map<String, dynamic> toMap() => {'date': Timestamp.fromDate(date), 'type': type, 'notes': notes};
}

class IllnessRecord {
  final String id; final DateTime date; final String diagnosis; final String? treatment; final String? notes;
  IllnessRecord({required this.id, required this.date, required this.diagnosis, this.treatment, this.notes});
  factory IllnessRecord.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return IllnessRecord(id: doc.id, date: (d['date'] as Timestamp).toDate(), diagnosis: d['diagnosis'], treatment: d['treatment'], notes: d['notes']);
  }
  Map<String, dynamic> toMap() => {'date': Timestamp.fromDate(date), 'diagnosis': diagnosis, 'treatment': treatment, 'notes': notes};
}

class CheckupRecord {
  final String id; final DateTime date; final String? clinic; final double? weightKg; final String? notes;
  CheckupRecord({required this.id, required this.date, this.clinic, this.weightKg, this.notes});
  factory CheckupRecord.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return CheckupRecord(id: doc.id, date: (d['date'] as Timestamp).toDate(), clinic: d['clinic'], weightKg: (d['weightKg'] as num?)?.toDouble(), notes: d['notes']);
  }
  Map<String, dynamic> toMap() => {'date': Timestamp.fromDate(date), 'clinic': clinic, 'weightKg': weightKg, 'notes': notes};
}

class BirthRecord {
  final String id; final DateTime date; final int kittens; final String? notes;
  BirthRecord({required this.id, required this.date, required this.kittens, this.notes});
  factory BirthRecord.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return BirthRecord(id: doc.id, date: (d['date'] as Timestamp).toDate(), kittens: d['kittens'] ?? 0, notes: d['notes']);
  }
  Map<String, dynamic> toMap() => {'date': Timestamp.fromDate(date), 'kittens': kittens, 'notes': notes};
}

// helper แปลงอายุจากวันเกิด
String ageLabel(DateTime? birth) {
  if (birth == null) return '—';
  final now = DateTime.now();
  int y = now.year - birth.year;
  int m = now.month - birth.month;
  int d = now.day - birth.day;
  if (d < 0) m -= 1;
  if (m < 0) { y -= 1; m += 12; }
  return y > 0 ? '${y}y ${m}m' : '${m}m';
}
