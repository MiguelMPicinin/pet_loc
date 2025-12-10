import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pet_loc/controller/desaparecidoController.dart';
import 'package:pet_loc/controller/grupoChatController.dart';
import 'package:pet_loc/controller/locationController.dart';
import 'package:pet_loc/controller/lojaController.dart';
import 'package:pet_loc/controller/petController.dart';
import 'package:provider/provider.dart';
import 'package:pet_loc/services/app_routes.dart';
import 'package:pet_loc/views/cadastro/login_view.dart';
import 'package:pet_loc/views/home.dart';
import 'package:pet_loc/controller/chatController.dart';
import 'package:pet_loc/controller/authController.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp();
  
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // AuthController deve ser o primeiro
        ChangeNotifierProvider(create: (context) => AuthController()),
        ChangeNotifierProvider(create: (context) => PetController()),
        ChangeNotifierProvider(create: (context) => ChatController()),
        ChangeNotifierProvider(create: (context) => DesaparecidosController()),
        ChangeNotifierProvider(create: (context) => GroupChatController()),
        ChangeNotifierProvider(create: (context) => LojaController()),
        ChangeNotifierProvider(create: (context) => LocationController()),
      ],
      child: MaterialApp(
        title: 'PetLoc',
        theme: ThemeData(
          primaryColor: const Color(0xFF1a237e),
          colorScheme: ColorScheme.fromSwatch(
            primarySwatch: Colors.blue,
            accentColor: const Color(0xFF00bcd4),
          ),
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1a237e),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Color(0xFF1a237e),
            foregroundColor: Colors.white,
          ),
        ),
        home: const AuthWrapper(),
        routes: AppRoutes.getRoutes(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  User? _user;
  bool _isCheckingAuth = true;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      
      if (mounted) {
        setState(() {
          _user = currentUser;
          _isCheckingAuth = false;
        });
      }

      FirebaseAuth.instance.authStateChanges().listen((User? user) {
        if (mounted) {
          setState(() {
            _user = user;
          });
        }
      });
    } catch (e) {
      print('Erro na verificação de autenticação: $e');
      if (mounted) {
        setState(() {
          _isCheckingAuth = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) {
      return const SplashScreen();
    }

    if (_user != null) {
      return const HomeView();
    }

    return const LoginScreen();
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a237e),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.pets,
              size: 80,
              color: Colors.white,
            ),
            const SizedBox(height: 20),
            const Text(
              'PetLoc',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Cuidando dos seus pets',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}