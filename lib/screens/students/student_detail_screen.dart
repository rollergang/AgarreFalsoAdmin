import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StudentDetailScreen extends StatelessWidget {
  final String studentId;
  final Map<String, dynamic> studentData;

  const StudentDetailScreen({super.key, required this.studentId, required this.studentData});

  @override
  Widget build(BuildContext context) {
    final String name = studentData['name'] ?? 'Alumno';
    final int height = studentData['heightCm'] ?? 0;
    final double weight = (studentData['weightKg'] ?? 0).toDouble();
    
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(name),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Implementar el selector de ejercicios
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Próximamente: Agregar Ejercicio"))
          );
        },
        backgroundColor: Colors.blue.shade800,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Agregar Ejercicio", style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- TARJETA DE DATOS ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem("Altura", "$height cm"),
                  _buildStatItem("Peso", "$weight kg"),
                  _buildStatItem("Sexo", studentData['sex'] ?? '?'),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            const Text(
              "Rutina Asignada",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // --- LISTA DE RUTINA ---
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(studentId)
                  .collection('routine')
                  .snapshots(),
              builder: (context, snapshot) {
                // Manejo de errores
                if (snapshot.hasError) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    width: double.infinity,
                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
                    child: Text("Error cargando rutina (Revisa Permisos): ${snapshot.error}", style: TextStyle(color: Colors.red.shade900)),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final routineDocs = snapshot.data!.docs;

                if (routineDocs.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: const [
                        Icon(Icons.fitness_center_outlined, size: 40, color: Colors.grey),
                        SizedBox(height: 10),
                        Text("Este alumno no tiene ejercicios asignados.", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: routineDocs.length,
                  itemBuilder: (ctx, i) {
                    final exercise = routineDocs[i].data() as Map<String, dynamic>;
                    final exerciseDocId = routineDocs[i].id;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.fitness_center, color: Colors.blue.shade800),
                        ),
                        title: Text(exercise['name'] ?? 'Ejercicio', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("${exercise['sets']} Series x ${exercise['reps']} Reps"),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () {
                            FirebaseFirestore.instance
                                .collection('users')
                                .doc(studentId)
                                .collection('routine')
                                .doc(exerciseDocId)
                                .delete();
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}