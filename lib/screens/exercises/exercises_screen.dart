import 'package:agarre_admin/screens/exercises/exercise_editor.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ExercisesScreen extends StatefulWidget {
  const ExercisesScreen({super.key});

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  String _searchQuery = '';
  String _selectedMuscle = 'Todos';

  // Lista de músculos para el filtro 
  final List<String> _filterOptions = [
    'Todos', 'Pecho', 'Espalda', 'Piernas', 'Hombros', 'Bíceps', 'Tríceps', 'Abdominales', 'Cardio', 'Otro'
  ];

  void _deleteExercise(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar ejercicio?'),
        content: const Text('Esta acción lo borrará del catálogo general.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('exercises').doc(id).delete();
              Navigator.pop(ctx);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Helper visual para iconos según músculo
  IconData _getIconForMuscle(String? muscle) {
    switch (muscle) {
      case 'Pecho': return Icons.accessibility_new;
      case 'Piernas': return Icons.directions_walk;
      case 'Cardio': return Icons.directions_run;
      case 'Bíceps': 
      case 'Tríceps': return Icons.fitness_center;
      case 'Espalda': return Icons.accessibility;
      case 'Hombros': return Icons.emoji_people;
      default: return Icons.sports_gymnastics;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Catálogo de Ejercicios'),
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.orange.shade800,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Nuevo Ejercicio", style: TextStyle(color: Colors.white)),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ExerciseEditor()));
        },
      ),
      body: Column(
        children: [
          // --- ZONA DE FILTROS ---
          Container(
            color: Colors.orange.shade800,
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: Column(
              children: [
                TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre...',
                    prefixIcon: const Icon(Icons.search, color: Colors.orange),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
                const SizedBox(height: 12),
                
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filterOptions.map((muscle) {
                      final isSelected = _selectedMuscle == muscle;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(
                            muscle,
                            style: TextStyle(
                              color: isSelected ? Colors.orange.shade900 : Colors.white,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: Colors.white,
                          backgroundColor: Colors.orange.shade900, // Color de fondo no seleccionado
                          checkmarkColor: Colors.orange.shade900,
                          onSelected: (bool selected) {
                            if (selected) {
                              setState(() => _selectedMuscle = muscle);
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('exercises').orderBy('name').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allDocs = snapshot.data!.docs;

                final filteredDocs = allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  final muscle = (data['muscle'] ?? 'Otro').toString();
                  final matchesSearch = name.contains(_searchQuery.toLowerCase());
                  final matchesMuscle = _selectedMuscle == 'Todos' || muscle == _selectedMuscle;

                  return matchesSearch && matchesMuscle;
                }).toList();

                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 60, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No se encontraron ejercicios.',
                          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredDocs.length,
                  itemBuilder: (ctx, i) {
                    final data = filteredDocs[i].data() as Map<String, dynamic>;
                    final id = filteredDocs[i].id;

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: Colors.orange.shade100,
                          child: Icon(_getIconForMuscle(data['muscle']), color: Colors.orange.shade900),
                        ),
                        title: Text(
                          data['name'] ?? 'Sin nombre',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Text(
                          data['muscle'] ?? 'General',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                Navigator.push(
                                  context, 
                                  MaterialPageRoute(
                                    builder: (_) => ExerciseEditor(exerciseId: id, initialData: data)
                                  )
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteExercise(context, id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}