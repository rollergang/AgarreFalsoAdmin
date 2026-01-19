import 'package:agarre_admin/screens/home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  bool _isLoading = false;

  void _adminLogin() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);

      try {
        UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _email,
          password: _password,
        );

        final userDoc = await FirebaseFirestore.instance
            .collection('admins')
            .doc(userCredential.user!.uid)
            .get();

        if (userDoc.exists) {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
            );
          }
        } else {
          // ❌ NO ES ADMIN - Expulsar
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: const [
                    Icon(Icons.lock, color: Colors.white),
                    SizedBox(width: 10),
                    Expanded(child: Text('ACCESO DENEGADO: No tienes permisos de administrador.')),
                  ],
                ),
                backgroundColor: Colors.red.shade900,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }

      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.admin_panel_settings, size: 64, color: Colors.deepPurple),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "PANEL DE PROFESORES",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.deepPurple),
                    ),
                    const SizedBox(height: 32),
                    
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Email Institucional',
                        prefixIcon: const Icon(Icons.email),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      onSaved: (val) => _email = val!.trim(),
                      validator: (val) => val!.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      obscureText: true,
                      onSaved: (val) => _password = val!,
                      validator: (val) => val!.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _adminLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text("INGRESAR AL SISTEMA", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}