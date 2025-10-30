import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/app_routes.dart';
import 'views/tela_splash.dart';
import 'views/cadastro/login_view.dart';
import 'views/cadastro/cadastro_view.dart';
import 'views/home.dart';
import 'views/pet/pet_view.dart';
import 'views/pet/pet_cadastro_view.dart';
import 'views/pet/pet_CRUD_view.dart';
import 'views/desaparecidos/desaparecido_view.dart';
import 'views/desaparecidos/desapareido_CRUD.dart';
import 'views/Loja/loja_view.dart';
import 'views/Loja/loja_cadastro_view.dart';
import 'views/Loja/loja_CRUD_view.dart';
import 'views/blog-chat/blog.dart';
import 'views/blog-chat/chat.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PetLoc',
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (context) => const TelaSplash(),
        AppRoutes.login: (context) => LoginScreen(),
        AppRoutes.cadastro: (context) => CadastroUsuarioScreen(),
        AppRoutes.home: (context) => const HomeView(),
        AppRoutes.pets: (context) => const PetView(),
        AppRoutes.cadastroPet: (context) => const PetCadastroView(),
        AppRoutes.editarPet: (context) => const PetCrudView(),
        AppRoutes.desaparecidos: (context) => const DesaparecidoView(),
        AppRoutes.editarDesaparecido: (context) => const DesaparecidoCrudView(),
        AppRoutes.criarDesaparecido: (context) => const DesaparecidoCrudView(),
        AppRoutes.loja: (context) => const LojaView(),
        AppRoutes.cadastrarProduto: (context) => const LojaCadastroView(),
        AppRoutes.atualizarProduto: (context) => const LojaCrudView(),
        AppRoutes.localizacaoPet: (context) => const Placeholder(), // Implement later
        AppRoutes.chat: (context) => const ChatView(),
        AppRoutes.blog: (context) => const BlogView(),
      },
    );
  }
}
