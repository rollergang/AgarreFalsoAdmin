import 'package:agarre_admin/screens/students/add_exercise_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StudentDetailScreen extends StatelessWidget {
  final String studentId;
  final Map<String, dynamic> studentData;

  const StudentDetailScreen({super.key, required this.studentId, required this.studentData});

  // Función para calcular IMC
  double _calculateBMI(int heightCm, double weightKg) {
    if (heightCm == 0 || weightKg == 0) return 0;
    double heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }

  void _editExercise(BuildContext context, String routineDocId, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddExerciseDialog(
        studentId: studentId,
        routineDocId: routineDocId, // Pasamos ID para editar
        initialData: data,          // Pasamos datos para pre-llenar
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String name = studentData['name'] ?? 'Alumno';
    final int height = studentData['heightCm'] ?? 0;
    final double weight = (studentData['weightKg'] ?? 0).toDouble();
    
    // Calculamos IMC
    final double bmi = _calculateBMI(height, weight);

    // Lógica Suscripción
    final Timestamp? endTimestamp = studentData['subscriptionEndDate'];
    final DateTime endDate = endTimestamp?.toDate() ?? DateTime.now();
    final bool isExpired = DateTime.now().isAfter(endDate);
    final String formattedDate = "${endDate.day}/${endDate.month}/${endDate.year}";

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(name),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (ctx) => AddExerciseDialog(studentId: studentId),
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
            
            // --- ESTADO DE SUSCRIPCIÓN ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: isExpired ? Colors.red.shade100 : Colors.green.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isExpired ? Colors.red.shade300 : Colors.green.shade300),
              ),
              child: Row(
                children: [
                  Icon(
                    isExpired ? Icons.cancel : Icons.check_circle,
                    color: isExpired ? Colors.red.shade900 : Colors.green.shade900,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isExpired ? "SUSCRIPCIÓN VENCIDA" : "SUSCRIPCIÓN ACTIVA",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isExpired ? Colors.red.shade900 : Colors.green.shade900,
                        ),
                      ),
                      Text(
                        isExpired ? "Venció el $formattedDate" : "Vence el $formattedDate",
                        style: TextStyle(
                          fontSize: 12,
                          color: isExpired ? Colors.red.shade900 : Colors.green.shade900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // --- TARJETA DE DATOS (Con IMC) ---
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
                  _buildStatItem("IMC", bmi.toStringAsFixed(1)), 
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
                  .orderBy('addedAt') 
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
                    child: Text("Error: ${snapshot.error}", style: TextStyle(color: Colors.red.shade900)),
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
                    
                    // Verificamos si hay notas
                    final String notes = exercise['notes'] ?? '';
                    final bool hasNotes = notes.isNotEmpty;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Column(
                          children: [
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.fitness_center, color: Colors.blue.shade800, size: 24),
                              ),
                              title: Text(
                                exercise['name'] ?? 'Ejercicio', 
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                              ),
                              // Subtítulo con Series x Reps
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  "${exercise['sets']} Series  •  ${exercise['reps']} Reps",
                                  style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.w500),
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _editExercise(context, exerciseDocId, exercise),
                                    tooltip: 'Editar',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text("¿Borrar ejercicio?"),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
                                            TextButton(
                                              onPressed: () {
                                                FirebaseFirestore.instance
                                                    .collection('users')
                                                    .doc(studentId)
                                                    .collection('routine')
                                                    .doc(exerciseDocId)
                                                    .delete();
                                                Navigator.pop(ctx);
                                              },
                                              child: const Text("Borrar", style: TextStyle(color: Colors.red)),
                                            )
                                          ],
                                        )
                                      );
                                    },
                                    tooltip: 'Borrar',
                                  ),
                                ],
                              ),
                            ),
                            
                            // --- SECCIÓN DE NOTAS (Visible solo si hay notas) ---
                            if (hasNotes) ...[
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.yellow.shade50, // Fondo amarillito tipo post-it
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.yellow.shade200),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.info_outline, size: 16, color: Colors.orange.shade800),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          notes,
                                          style: TextStyle(
                                            fontSize: 13, 
                                            color: Colors.grey.shade800,
                                            fontStyle: FontStyle.italic
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ]
                          ],
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