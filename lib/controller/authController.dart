import 'dart:async'; // ADICIONE ESTE IMPORT
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pet_loc/models/user_model.dart';

class AuthController with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;
  StreamSubscription<User?>? _authStateSubscription; // AGORA VAI FUNCIONAR

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;

  AuthController() {
    print('🔄 AuthController inicializado');
    _startAuthListener();
  }

  void _startAuthListener() {
    _authStateSubscription = _auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        print('👤 Usuário detectado no authStateChanges: ${user.uid}');
        await _loadUserData(user.uid);
      } else {
        print('👤 Nenhum usuário autenticado');
        _currentUser = null;
        notifyListeners();
      }
    }, onError: (error) {
      print('❌ Erro no authStateChanges: $error');
    });
  }

  Future<void> _loadUserData(String uid) async {
    try {
      print('📥 Carregando dados do usuário: $uid');
      final doc = await _firestore.collection('users').doc(uid).get();
      
      if (doc.exists) {
        _currentUser = UserModel.fromFirestore(doc);
        print('✅ Usuário carregado: ${_currentUser!.email}');
        print('✅ User ID: ${_currentUser!.id}');
        notifyListeners();
      } else {
        print('⚠️ Usuário não encontrado no Firestore, criando...');
        await _createUserInFirestore(uid);
      }
    } catch (e) {
      print('❌ Erro ao carregar dados do usuário: $e');
      _error = 'Erro ao carregar dados do usuário: $e';
      notifyListeners();
    }
  }

  Future<void> _createUserInFirestore(String uid) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userModel = UserModel(
          id: uid,
          nome: user.displayName ?? 'Usuário',
          email: user.email ?? 'email@exemplo.com',
          telefone: user.phoneNumber,
          criadoEm: DateTime.now(),
          atualizadoEm: DateTime.now(),
        );
        
        await _firestore.collection('users').doc(uid).set(userModel.toFirestore());
        _currentUser = userModel;
        print('✅ Usuário criado no Firestore: ${userModel.email}');
        notifyListeners();
      }
    } catch (e) {
      print('❌ Erro ao criar usuário no Firestore: $e');
    }
  }

  Future<bool> signUpWithEmailAndPassword({
    required String nome,
    required String email,
    required String senha,
  }) async {
    try {
      _setLoading(true);
      _error = null;

      print('📝 Criando usuário: $email');
      
      final UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: senha.trim(),
      );

      await cred.user?.updateDisplayName(nome.trim());
      await cred.user?.reload();

      print('✅ Usuário criado no Auth: ${cred.user!.uid}');

      final userModel = UserModel(
        id: cred.user!.uid,
        nome: nome,
        email: email,
        criadoEm: DateTime.now(),
        atualizadoEm: DateTime.now(),
      );

      await _firestore.collection('users').doc(cred.user!.uid).set(userModel.toFirestore());
      
      await _loadUserData(cred.user!.uid);

      _setLoading(false);
      print('✅ Cadastro completo: $email');
      return true;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return false;
    } catch (e) {
      print('❌ Erro inesperado: $e');
      _error = 'Erro inesperado: $e';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signInWithEmailAndPassword({
    required String email,
    required String senha,
  }) async {
    try {
      _setLoading(true);
      _error = null;

      print('🔐 Login: $email');
      
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: senha.trim(),
      );

      if (userCredential.user != null) {
        print('✅ Login bem-sucedido: ${userCredential.user!.uid}');
        await _loadUserData(userCredential.user!.uid);
        print('✅ Usuário carregado após login: ${_currentUser?.email}');
      }

      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return false;
    } catch (e) {
      print('❌ Erro inesperado: $e');
      _error = 'Erro inesperado: $e';
      _setLoading(false);
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      _setLoading(true);
      
      await _auth.signOut();
      
      _currentUser = null;
      _error = null;
      
      _setLoading(false);
      print('👋 Usuário deslogado');
      notifyListeners();
    } catch (e) {
      print('❌ Erro ao fazer logout: $e');
      _error = 'Erro ao fazer logout: $e';
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<bool> updateProfile({
    required String nome,
    String? telefone,
  }) async {
    try {
      if (_currentUser == null) return false;

      _setLoading(true);

      await _auth.currentUser?.updateDisplayName(nome);

      await _firestore.collection('users').doc(_currentUser!.id).update({
        'nome': nome,
        'telefone': telefone,
        'atualizadoEm': FieldValue.serverTimestamp(),
      });

      _currentUser = _currentUser!.copyWith(
        nome: nome,
        telefone: telefone,
        atualizadoEm: DateTime.now(),
      );
      
      _setLoading(false);
      notifyListeners();
      print('✅ Perfil atualizado');
      
      return true;
    } catch (e) {
      print('❌ Erro ao atualizar perfil: $e');
      _error = 'Erro ao atualizar perfil: $e';
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      _setLoading(true);
      await _auth.sendPasswordResetEmail(email: email.trim());
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return false;
    } catch (e) {
      print('❌ Erro inesperado: $e');
      _error = 'Erro inesperado: $e';
      _setLoading(false);
      return false;
    }
  }

  Future<void> forceReloadUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _loadUserData(user.uid);
    }
  }

  bool isUserAuthenticated() {
    return _auth.currentUser != null && _currentUser != null;
  }

  String? getCurrentUserId() {
    return _currentUser?.id;
  }

  void _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        _error = 'Este e-mail já está em uso.';
        break;
      case 'weak-password':
        _error = 'A senha precisa ter pelo menos 6 caracteres.';
        break;
      case 'invalid-email':
        _error = 'E-mail inválido.';
        break;
      case 'user-not-found':
        _error = 'Usuário não encontrado.';
        break;
      case 'wrong-password':
        _error = 'Senha incorreta.';
        break;
      case 'user-disabled':
        _error = 'Esta conta foi desativada.';
        break;
      case 'too-many-requests':
        _error = 'Muitas tentativas. Tente novamente mais tarde.';
        break;
      case 'operation-not-allowed':
        _error = 'Operação não permitida.';
        break;
      case 'network-request-failed':
        _error = 'Erro de conexão. Verifique sua internet.';
        break;
      default:
        _error = 'Erro: ${e.message ?? "Desconhecido"}';
    }
    
    print('❌ Erro de autenticação: $_error');
    _setLoading(false);
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
      final user = _auth.currentUser;
      if (user != null) {
        await _loadUserData(user.uid);
      }
    } catch (e) {
      print('❌ Erro ao recarregar usuário: $e');
    }
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
}