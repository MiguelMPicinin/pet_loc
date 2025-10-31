import 'package:flutter/material.dart';
import 'package:pet_loc/views/desaparecidos/desaparecido_cadastro_view.dart';
import '../views/cadastro/login_view.dart';
import '../views/cadastro/cadastro_view.dart';
import '../views/home.dart';
import '../views/tela_splash.dart';
import '../views/pet/pet_view.dart';
import '../views/pet/pet_cadastro_view.dart';
import '../views/pet/pet_CRUD_view.dart';
import '../views/desaparecidos/desaparecido_view.dart';
import '../views/loja/loja_view.dart';
import '../views/loja/loja_comprar.dart'; // Adicionado
import '../views/blog-chat/chat_view.dart';
import '../views/blog-chat/blog_view.dart';
import '../views/pet/localizacao_pet_view.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String registro = '/registro';
  static const String home = '/home';
  static const String pets = '/pets';
  static const String cadastroPet = '/cadastro-pet';
  static const String editarPet = '/editar-pet';
  static const String desaparecidos = '/desaparecidos';
  static const String criarDesaparecido = '/criar-desaparecido';
  static const String loja = '/loja';
  static const String lojaComprar = '/loja-comprar';
  static const String localizacaoPet = '/localizacao-pet';
  static const String blog = '/blog';
  static const String chat = '/chat';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      splash: (context) => const TelaSplash(),
      login: (context) => LoginScreen(),
      registro: (context) => CadastroUsuarioScreen(),
      home: (context) => const HomeView(),
      pets: (context) => const PetView(),
      cadastroPet: (context) => const PetCadastroView(),
      editarPet: (context) => const PetCRUDView(),
      desaparecidos: (context) => const DesaparecidoScreen(), // Corrigido
      criarDesaparecido: (context) => const CriarDesaparecidoScreen(), // Corrigido
      editarDesaparecido: (context) {
        final desaparecidoData = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
        return CriarDesaparecidoScreen(desaparecidoData: desaparecidoData);
      },
      loja: (context) => const LojaScreen(), // Corrigido
      lojaComprar: (context) {
        final produto = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
        return ComprarLojaScreen(produto: produto);
      },
      localizacaoPet: (context) => const LocalizacaoPetView(),
      blog: (context) => const BlogView(),
      chat: (context) => const ChatView(),
    };
  }
}