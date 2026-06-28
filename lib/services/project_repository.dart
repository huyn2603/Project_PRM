import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/project_finance.dart';

class ProjectRepository {
  ProjectRepository({
    required this.userId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final String userId;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _projects =>
      _firestore.collection('users').doc(userId).collection('projects');

  Stream<List<ProjectFinance>> watchProjects() {
    return _projects.orderBy('updatedAt', descending: true).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => ProjectFinance.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<void> add(ProjectFinance project) {
    return _projects.doc(project.id).set({
      ...project.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> update(ProjectFinance project) {
    return _projects.doc(project.id).set({
      ...project.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> delete(String projectId) => _projects.doc(projectId).delete();

  Future<void> updateReserveRate(
    List<ProjectFinance> projects,
    double rate,
  ) async {
    final batch = _firestore.batch();
    for (final project in projects) {
      batch.update(_projects.doc(project.id), {
        'reserveAmount': project.ownerNetReceived * rate,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }
}
