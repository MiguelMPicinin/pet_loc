import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pet_loc/models/user.dart';

class AuthController with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.standard();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;
  bool get isLojista => _currentUser?.isLojista ?? false;

  AuthController() {
    // Verificar se usuário já está logado ao inicializar
    _checkCurrentUser();
  }

  // Verificar usuário atual
  void _checkCurrentUser() {
    _auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        await _loadUserData(user.uid);
      } else {
        _currentUser = null;
        notifyListeners();
      }
    });
  }

  // Carregar dados do usuário do Firestore
  Future<void> _loadUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _currentUser = UserModel.fromFirestore(doc);
      } else {
        // Criar usuário no Firestore se não existir
        await _createUserInFirestore(uid);
      }
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao carregar dados do usuário: $e';
      notifyListeners();
    }
  }

  // Criar usuário no Firestore
  Future<void> _createUserInFirestore(String uid, {UserType tipo = UserType.normal}) async {
    final user = _auth.currentUser;
    if (user != null) {
      final userModel = UserModel(
        id: uid,
        nome: user.displayName ?? 'Usuário',
        email: user.email!,
        tipo: tipo,
      );
      
      await _firestore.collection('users').doc(uid).set(userModel.toFirestore());
      _currentUser = userModel;
    }
  }

  // Cadastro com email e senha
  Future<bool> signUpWithEmailAndPassword({
    required String nome,
    required String email,
    required String senha,
    required UserType tipo,
  }) async {
    try {
      _setLoading(true);
      _error = null;

      // Criar usuário no Authentication
      final UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: senha.trim(),
      );

      // Atualizar display name
      await cred.user?.updateDisplayName(nome.trim());
      await cred.user?.reload();

      // Criar usuário no Firestore
      final userModel = UserModel(
        id: cred.user!.uid,
        nome: nome,
        email: email,
        tipo: tipo,
      );

      await _firestore.collection('users').doc(cred.user!.uid).set(userModel.toFirestore());
      _currentUser = userModel;

      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return false;
    } catch (e) {
      _error = 'Erro inesperado: $e';
      _setLoading(false);
      return false;
    }
  }

  // Login com email e senha
  Future<bool> signInWithEmailAndPassword({
    required String email,
    required String senha,
  }) async {
    try {
      _setLoading(true);
      _error = null;

      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: senha.trim(),
      );

      // _loadUserData será chamado automaticamente pelo authStateChanges
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return false;
    } catch (e) {
      _error = 'Erro inesperado: $e';
      _setLoading(false);
      return false;
    }
  }

  // Login com Google
  Future<bool> signInWithGoogle() async {
    try {
      _setLoading(true);
      _error = null;

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _setLoading(false);
        return false;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      // Verificar se é primeiro login
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await _createUserInFirestore(userCredential.user!.uid);
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _error = 'Erro no login com Google: $e';
      _setLoading(false);
      return false;
    }
  }

  // Logout
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      _currentUser = null;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao fazer logout: $e';
      notifyListeners();
    }
  }

  // Atualizar tipo de usuário
  Future<void> updateUserType(UserType newType) async {
    try {
      if (_currentUser == null) return;

      await _firestore.collection('users').doc(_currentUser!.id).update({
        'tipo': newType.index,
        'atualizadoEm': FieldValue.serverTimestamp(),
      });

      _currentUser = _currentUser!.copyWith(tipo: newType);
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao atualizar tipo de usuário: $e';
      notifyListeners();
    }
  }

  // Esqueci a senha
  Future<bool> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return true;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return false;
    } catch (e) {
      _error = 'Erro inesperado: $e';
      return false;
    }
  }

  // Manipular erros de autenticação
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
      default:
        _error = 'Erro: ${e.message}';
    }
    _setLoading(false);
  }

  // Controlar estado de loading
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Limpar erros
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}