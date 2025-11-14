import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pet_loc/controller/desaparecidoController.dart';
import 'package:pet_loc/controller/grupoChatController.dart';
import 'package:pet_loc/controller/lojaController.dart';
import 'package:pet_loc/controller/petController.dart';
import 'package:provider/provider.dart';
import 'package:pet_loc/services/app_routes.dart';
import 'package:pet_loc/views/cadastro/login_view.dart';
import 'package:pet_loc/views/home.dart';
import 'package:pet_loc/controller/chatController.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializa o Firebase
  await Firebase.initializeApp();
  
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Adicione o PetController como um Provider
        ChangeNotifierProvider(create: (context) => PetController()),
        // Adicione o ChatController como um Provider
        ChangeNotifierProvider(create: (context) => ChatController()),
        ChangeNotifierProvider(create: (context) => DesaparecidosController()),
        ChangeNotifierProvider(create: (context) => GroupChatController()),
        ChangeNotifierProvider(create: (context)=> LojaController()),
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

// Widget que verifica o estado de autenticação
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
      // Verifica o usuário atual
      final currentUser = FirebaseAuth.instance.currentUser;
      
      if (mounted) {
        setState(() {
          _user = currentUser;
          _isCheckingAuth = false;
        });
      }

      // Escuta mudanças futuras no estado de autenticação
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
    // Mostra tela de splash enquanto verifica autenticação
    if (_isCheckingAuth) {
      return const SplashScreen();
    }

    // Se usuário está logado, vai para Home
    if (_user != null) {
      return const HomeView();
    }

    // Se não está logado, mostra Login
    return const LoginScreen();
  }
}

// Tela de splash personalizada
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
            // Ícone do app
            const Icon(
              Icons.pets,
              size: 80,
              color: Colors.white,
            ),
            const SizedBox(height: 20),
            // Nome do app
            const Text(
              'PetLoc',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            // Subtítulo
            const Text(
              'Cuidando dos seus pets',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 30),
            // Loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}