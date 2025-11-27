import 'package:flutter/material.dart';
import 'package:pet_loc/views/Loja/cadastro_produto_view.dart';
import 'package:pet_loc/views/Loja/loja_view.dart';
import 'package:pet_loc/views/Loja/produto_CRUD_view.dart';
import 'package:pet_loc/views/blog-chat/community_view.dart';
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

class AppRoutes {
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
  static const String community = '/community';
  
  // Novas rotas para produtos
  static const String cadastroProduto = '/cadastro-produto';
  static const String produtoCrud = '/produto-crud';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
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
        final arguments = ModalRoute.of(context)!.settings.arguments;
        if (arguments != null && arguments is Map<String, dynamic>) {
          return ComprarLojaScreen(produto: arguments);
        } else {
          // Fallback para caso não receba argumentos válidos
          return Scaffold(
            appBar: AppBar(
              title: const Text('Erro'),
              backgroundColor: const Color(0xFF1A73E8),
            ),
            body: const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red),
                    SizedBox(height: 16),
                    Text(
                      'Produto não encontrado',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Não foi possível carregar as informações do produto.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: null,
                      child: Text('Voltar à Loja'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      },
      localizacaoPet: (context) => LocalizacaoPetView(),
      community: (context) => const CommunityView(),
      
      // Novas rotas para produtos
      cadastroProduto: (context) => const CadastroProdutoScreen(),
      produtoCrud: (context) => const ProdutoCrudScreen(),
    };
  }
}