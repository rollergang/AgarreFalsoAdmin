import 'package:agarre_admin/screens/students/student_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Mis Alumnos'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // --- BUSCADOR ---
          Container(
            color: Colors.blue.shade800,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o email...',
                prefixIcon: const Icon(Icons.search, color: Colors.blue),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // --- LISTA ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'student')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allDocs = snapshot.data!.docs;

                // Filtrado Local
                final filteredDocs = allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  final email = (data['email'] ?? '').toString().toLowerCase();
                  final query = _searchQuery.toLowerCase();
                  return name.contains(query) || email.contains(query);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_off, size: 60, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No se encontraron alumnos.',
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
                    
                    // Lógica de Vencimiento
                    final Timestamp? endTimestamp = data['subscriptionEndDate'];
                    final bool isExpired = endTimestamp != null 
                        ? DateTime.now().isAfter(endTimestamp.toDate()) 
                        : true;

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: Text(
                            (data['name'] ?? '?').substring(0, 1).toUpperCase(),
                            style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          data['name'] ?? 'Sin nombre',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Text(data['email'] ?? ''),
                        
                        // --- ESTADO DE SUSCRIPCIÓN ---
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min, // Vital para evitar errores de layout
                          children: [
                            const Text(
                              "Estado", 
                              style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)
                            ),
                            const SizedBox(height: 4),
                            Icon(
                              isExpired ? Icons.cancel : Icons.check_circle,
                              color: isExpired ? Colors.red : Colors.green,
                              size: 24,
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StudentDetailScreen(studentId: id, studentData: data),
                            ),
                          );
                        },
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