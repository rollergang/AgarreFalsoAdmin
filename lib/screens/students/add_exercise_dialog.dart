import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddExerciseDialog extends StatefulWidget {
  final String studentId;
  // Nuevos campos opcionales para EDICIÓN
  final String? routineDocId; 
  final Map<String, dynamic>? initialData;

  const AddExerciseDialog({
    super.key, 
    required this.studentId, 
    this.routineDocId, 
    this.initialData
  });

  @override
  State<AddExerciseDialog> createState() => _AddExerciseDialogState();
}

class _AddExerciseDialogState extends State<AddExerciseDialog> {
  int _step = 1;
  
  Map<String, dynamic>? _selectedExercise;
  String? _selectedExerciseId;
  String _searchQuery = '';

  late TextEditingController _setsController;
  late TextEditingController _repsController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    
    // Si hay datos iniciales (Modo Edición), los cargamos
    if (widget.initialData != null) {
      _step = 2; // Saltamos directo a configurar
      _selectedExercise = {
        'name': widget.initialData!['name'],
        'videoUrl': widget.initialData!['videoUrl'],
        // 'muscle' podría no estar guardado en la rutina, lo dejamos genérico si falta
        'muscle': 'Ejercicio Asignado' 
      };
      // Recuperamos el ID original si existe, sino null
      _selectedExerciseId = widget.initialData!['exerciseId'];

      _setsController = TextEditingController(text: widget.initialData!['sets']);
      _repsController = TextEditingController(text: widget.initialData!['reps']);
      _notesController = TextEditingController(text: widget.initialData!['notes']);
    } else {
      // Modo Creación (Valores por defecto)
      _setsController = TextEditingController(text: '4');
      _repsController = TextEditingController(text: '10-12');
      _notesController = TextEditingController();
    }
  }

  void _saveToRoutine() async {
    if (_selectedExercise == null) return;

    final data = {
      'exerciseId': _selectedExerciseId,
      'name': _selectedExercise!['name'],
      'videoUrl': _selectedExercise!['videoUrl'],
      'sets': _setsController.text,
      'reps': _repsController.text,
      'notes': _notesController.text,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      if (widget.routineDocId != null) {
        // --- ACTUALIZAR ---
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.studentId)
            .collection('routine')
            .doc(widget.routineDocId)
            .update(data);
      } else {
        // --- CREAR NUEVO ---
        // Agregamos fecha de creación solo si es nuevo
        data['addedAt'] = FieldValue.serverTimestamp(); 
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.studentId)
            .collection('routine')
            .add(data);
      }

      if (mounted) Navigator.pop(context); 
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.routineDocId != null;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: EdgeInsets.only(
        top: 20, 
        left: 20, 
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (_step == 2 && !isEditing) // Solo mostramos 'atrás' si estamos creando
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => setState(() => _step = 1),
                ),
              Expanded(
                child: Text(
                  isEditing 
                    ? "Editar Ejercicio" 
                    : (_step == 1 ? "Selecciona un Ejercicio" : "Configurar Rutina"),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: _step == 1 && !isEditing ? TextAlign.center : TextAlign.left,
                ),
              ),
              if (_step == 2 && !isEditing) const SizedBox(width: 48), 
            ],
          ),
          const SizedBox(height: 10),

          Expanded(
            child: _step == 1 ? _buildExerciseList() : _buildConfigForm(isEditing),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseList() {
    return Column(
      children: [
        TextField(
          onChanged: (val) => setState(() => _searchQuery = val),
          decoration: InputDecoration(
            hintText: "Buscar ejercicios...",
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
        const SizedBox(height: 10),

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('exercises').orderBy('name').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              
              final allDocs = snapshot.data!.docs;
              final filteredDocs = allDocs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name = (data['name'] ?? '').toString().toLowerCase();
                final query = _searchQuery.toLowerCase();
                return name.contains(query);
              }).toList();

              if (filteredDocs.isEmpty) {
                return const Center(child: Text("No se encontraron ejercicios."));
              }

              return ListView.builder(
                itemCount: filteredDocs.length,
                itemBuilder: (ctx, i) {
                  final data = filteredDocs[i].data() as Map<String, dynamic>;
                  final id = filteredDocs[i].id;

                  return Card(
                    elevation: 0,
                    color: Colors.grey[50], 
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.orange.shade100,
                        child: Icon(Icons.fitness_center, color: Colors.orange.shade900, size: 20),
                      ),
                      title: Text(data['name'] ?? 'Sin nombre', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(data['muscle'] ?? 'General'),
                      trailing: const Icon(Icons.add_circle_outline, color: Colors.blue),
                      onTap: () {
                        setState(() {
                          _selectedExercise = data;
                          _selectedExerciseId = id;
                          _step = 2; 
                        });
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildConfigForm(bool isEditing) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedExercise?['name'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                // Si estamos editando, no permitimos cambiar el ejercicio base, solo las reps
                if (!isEditing)
                  TextButton(
                    onPressed: () => setState(() => _step = 1),
                    child: const Text("Cambiar"),
                  )
              ],
            ),
          ),
          
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _setsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Series",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.repeat),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _repsController,
                  decoration: const InputDecoration(
                    labelText: "Repeticiones",
                    border: OutlineInputBorder(),
                    hintText: "Ej: 10-12",
                    prefixIcon: Icon(Icons.numbers),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),

          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: "Instrucciones especiales",
              hintText: "Ej: Descanso de 1 min...",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.notes),
              alignLabelWithHint: true,
            ),
            maxLines: 3,
          ),

          const SizedBox(height: 30),

          ElevatedButton(
            onPressed: _saveToRoutine,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade800,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(isEditing ? "GUARDAR CAMBIOS" : "AGREGAR A LA RUTINA", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}