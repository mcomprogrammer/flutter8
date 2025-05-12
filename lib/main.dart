// main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart'; 



void main() async {

  WidgetsFlutterBinding.ensureInitialized(); // Initialize Flutter bindings first

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auth Demo',
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return LollapaloozaFormScreen();
          }
          return LoginScreen();
        },
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _error = '';

  Future<void> _login() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Login failed.';
      if (e.code == 'user-not-found') {
        message = 'No user found for that email. Please register first.';
      } else if (e.code == 'wrong-password') {
        message = 'Incorrect password. Please try again or reset your password.';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address format.';
      }
      setState(() => _error = message);
    } catch (e) {
      setState(() => _error = 'Login failed. Please check your credentials and try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Login', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            Text(_error, style: TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: _login,
              child: Text('Login'),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RegisterScreen()),
              ),
              child: Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _error = '';

  Future<void> _register() async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String message = 'Registration failed.';
      if (e.code == 'email-already-in-use') {
        message = 'This email is already in use. Try logging in or use another email.';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address format.';
      } else if (e.code == 'weak-password') {
        message = 'Password is too weak. Please use at least 6 characters.';
      }
      setState(() => _error = message);
    } catch (e) {
      setState(() => _error = 'Registration failed. Please check your details and try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Registration', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            Text(_error, style: TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: _register,
              child: Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}

class LollapaloozaFormScreen extends StatefulWidget {
  const LollapaloozaFormScreen({super.key});

  @override
  _LollapaloozaFormScreenState createState() => _LollapaloozaFormScreenState();
}

class _LollapaloozaFormScreenState extends State<LollapaloozaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ticketTypeController = TextEditingController();
  String? _editingDocId;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _ticketTypeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final data = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'ticketType': _ticketTypeController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      };
      if (_editingDocId == null) {
        await FirebaseFirestore.instance.collection('lollapalooza_registrations').add(data);
      } else {
        await FirebaseFirestore.instance.collection('lollapalooza_registrations').doc(_editingDocId).update(data);
        setState(() => _editingDocId = null);
      }
      _nameController.clear();
      _emailController.clear();
      _phoneController.clear();
      _ticketTypeController.clear();
    }
  }

  void _editRegistration(DocumentSnapshot doc) {
    setState(() {
      _editingDocId = doc.id;
      _nameController.text = doc['name'];
      _emailController.text = doc['email'];
      _phoneController.text = doc['phone'];
      _ticketTypeController.text = doc['ticketType'];
    });
  }

  void _deleteRegistration(String docId) {
    FirebaseFirestore.instance.collection('lollapalooza_registrations').doc(docId).delete();
    if (_editingDocId == docId) {
      setState(() => _editingDocId = null);
      _nameController.clear();
      _emailController.clear();
      _phoneController.clear();
      _ticketTypeController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Lollapalooza Event Registration')),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Menu', style: TextStyle(color: Colors.white, fontSize: 24)),
                  SizedBox(height: 16),
                  Text(
                    FirebaseAuth.instance.currentUser?.email ?? '',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                if (Navigator.canPop(context)) Navigator.pop(context); // close drawer
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: 'Name'),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(labelText: 'Email'),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(labelText: 'Phone'),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    keyboardType: TextInputType.phone,
                  ),
                  TextFormField(
                    controller: _ticketTypeController,
                    decoration: InputDecoration(labelText: 'Ticket Type'),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _submit,
                    child: Text(_editingDocId == null ? 'Register' : 'Update'),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('lollapalooza_registrations').orderBy('createdAt', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return CircularProgressIndicator();
                  final docs = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, i) {
                      final doc = docs[i];
                      return ListTile(
                        title: Text(doc['name']),
                        subtitle: Text('Email: ${doc['email']}\nPhone: ${doc['phone']}\nTicket: ${doc['ticketType']}'),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () => _editRegistration(doc),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () => _deleteRegistration(doc.id),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome, ${FirebaseAuth.instance.currentUser?.email}'),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return CircularProgressIndicator();
                return Column(
                  children: [
                    Text('Registered Users:'),
                    ...snapshot.data!.docs.map((doc) {
                      return ListTile(
                        title: Text(doc['name']),
                        subtitle: Text(doc['email']),
                        trailing: IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            FirebaseFirestore.instance
                                .collection('users')
                                .doc(doc.id)
                                .delete();
                          },
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
            
          ],
        ),
      ),
    );
  }
}