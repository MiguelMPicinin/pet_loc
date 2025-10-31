

import 'package:flutter/material.dart';
import 'package:pet_loc/views/Loja/loja_view.dart';
import 'package:pet_loc/views/blog-chat/blog_view.dart';
import 'package:pet_loc/views/blog-chat/chat_view.dart';
import 'package:pet_loc/views/cadastro/cadastro_view.dart';
import 'package:pet_loc/views/cadastro/login_view.dart';
import 'package:pet_loc/views/desaparecidos/desaparecido_cadastro_view.dart';
import 'package:pet_loc/views/desaparecidos/desaparecido_view.dart';
import 'package:pet_loc/views/home.dart';
import 'package:pet_loc/views/loja/loja_comprar.dart';
import 'package:pet_loc/views/pet/localizacao_pet_view.dart';
import 'package:pet_loc/views/pet/pet_CRUD_view.dart';
import 'package:pet_loc/views/pet/pet_cadastro_view.dart';
import 'package:pet_loc/views/pet/pet_view.dart';
import 'package:pet_loc/views/tela_splash.dart';

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
  static const String editarDesaparecido = '/editar-desaparecido';
  static const String loja = '/loja';
  static const String lojaComprar = '/loja-comprar';
  static const String localizacaoPet = '/localizacao-pet';
  static const String blog = '/blog';
  static const String chat = '/chat';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      splash: (context) => const TelaSplash(),
      login: (context) => const LoginScreen(),
      registro: (context) => CadastroUsuarioScreen(),
      home: (context) => const HomeView(),
      pets: (context) => const PetView(),
      cadastroPet: (context) => const PetCadastroView(),
      editarPet: (context) {
        final pet = ModalRoute.of(context)!.settings.arguments as dynamic;
        return PetCRUDView(pet: pet);
      },
      desaparecidos: (context) => const DesaparecidoScreen(),
      criarDesaparecido: (context) => const CriarDesaparecidoScreen(),
      editarDesaparecido: (context) {
        final desaparecidoData = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
        return CriarDesaparecidoScreen(desaparecidoData: desaparecidoData);
      },
      loja: (context) => LojaScreen(),
      lojaComprar: (context) {
        final produto = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
        return ComprarLojaScreen(produto: produto);
      },
      localizacaoPet: (context) => LocalizacaoPetView(),
      blog: (context) => const BlogView(),
      chat: (context) => const ChatView(),
    };
  }
}