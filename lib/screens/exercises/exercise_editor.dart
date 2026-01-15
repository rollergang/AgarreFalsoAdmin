import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ExerciseEditor extends StatefulWidget {
  final String? exerciseId; // Si es null, es modo CREAR. Si tiene ID, es EDITAR.
  final Map<String, dynamic>? initialData;

  const ExerciseEditor({super.key, this.exerciseId, this.initialData});

  @override
  State<ExerciseEditor> createState() => _ExerciseEditorState();
}

class _ExerciseEditorState extends State<ExerciseEditor> {
  final _formKey = GlobalKey<FormState>();
  
  // Controladores
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _videoController;
  String _selectedMuscle = 'Pecho'; // Valor por defecto

  bool _isLoading = false;

  final List<String> _muscleGroups = [
    'Pecho', 'Espalda', 'Piernas', 'Hombros', 'Bíceps', 'Tríceps', 'Abdominales', 'Cardio', 'Otro'
  ];

  @override
  void initState() {
    super.initState();
    // Inicializar con datos si estamos editando
    _nameController = TextEditingController(text: widget.initialData?['name'] ?? '');
    _descController = TextEditingController(text: widget.initialData?['description'] ?? '');
    _videoController = TextEditingController(text: widget.initialData?['videoUrl'] ?? '');
    
    if (widget.initialData != null && _muscleGroups.contains(widget.initialData!['muscle'])) {
      _selectedMuscle = widget.initialData!['muscle'];
    }
  }

  void _saveExercise() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final data = {
        'name': _nameController.text.trim(),
        'muscle': _selectedMuscle,
        'description': _descController.text.trim(),
        'videoUrl': _videoController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      try {
        if (widget.exerciseId == null) {
          // CREAR
          await FirebaseFirestore.instance.collection('exercises').add(data);
        } else {
          // ACTUALIZAR
          await FirebaseFirestore.instance.collection('exercises').doc(widget.exerciseId).update(data);
        }
        
        if (mounted) Navigator.pop(context); // Volver a la lista
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.exerciseId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Ejercicio' : 'Nuevo Ejercicio'),
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Nombre
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Ejercicio',
                  hintText: 'Ej: Press de Banca',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.fitness_center),
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 20),

              // Grupo Muscular
              DropdownButtonFormField<String>(
                value: _selectedMuscle,
                decoration: const InputDecoration(
                  labelText: 'Grupo Muscular',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.accessibility_new),
                ),
                items: _muscleGroups.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (v) => setState(() => _selectedMuscle = v!),
              ),
              const SizedBox(height: 20),

              // Descripción
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Descripción / Técnica',
                  hintText: 'Ej: Bajar la barra hasta el pecho...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 20),

              // Video URL
              TextFormField(
                controller: _videoController,
                decoration: const InputDecoration(
                  labelText: 'Link de Video (Youtube/Vimeo)',
                  hintText: 'https://youtube.com/...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.play_circle_outline),
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 40),

              //Guardar
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveExercise,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade800,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('GUARDAR CAMBIOS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}