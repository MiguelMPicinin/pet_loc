import 'package:flutter/material.dart';
import '../views/cadastro/login_view.dart';
import '../views/cadastro/cadastro_view.dart';
import '../views/home.dart';
import '../views/tela_splash.dart';
import '../views/pet/pet_view.dart';
import '../views/pet/pet_cadastro_view.dart';
import '../views/pet/pet_CRUD_view.dart';
import '../views/desaparecidos/desaparecido_view.dart';
import '../views/desaparecidos/desaparecido_CRUD.dart';
import '../views/loja/loja_view.dart';
import '../views/loja/loja_cadastro_view.dart';
import '../views/loja/loja_CRUD_view.dart';
import '../views/blog-chat/chat.dart';
import '../views/localizacao_pet_view.dart'; // Criar este arquivo

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
  static const String cadastrarProduto = '/cadastrar-produto';
  static const String atualizarProduto = '/atualizar-produto';
  static const String localizacaoPet = '/localizacao-pet';
  static const String chat = '/chat';

  static Map<String, WidgetBuilder> getRoutes(bool isAdmin) {
    Map<String, WidgetBuilder> routes = {
      splash: (context) => TelaSplash(),
      login: (context) => LoginScreen(),
      registro: (context) => CadastroUsuarioScreen(),
      home: (context) => Home(),
      pets: (context) => PetView(),
      cadastroPet: (context) => PetCadastroView(),
      editarPet: (context) => PetCRUDView(),
      desaparecidos: (context) => DesaparecidoView(),
      criarDesaparecido: (context) => DesaparecidoCRUD(),
      editarDesaparecido: (context) => DesaparecidoCRUD(),
      loja: (context) => LojaView(),
      cadastrarProduto: (context) => LojaCadastroView(),
      atualizarProduto: (context) => LojaCRUDView(),
      localizacaoPet: (context) => LocalizacaoPetView(),
      chat: (context) => Chat(),
    };

    // Remover rotas restritas se não for admin
    if (!isAdmin) {
      routes.remove(cadastrarProduto);
      routes.remove(atualizarProduto);
      routes.remove(editarDesaparecido); // Ajuste conforme necessidade
    }

    return routes;
  }
}
