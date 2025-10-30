import 'package:flutter/material.dart';

class LocalizacaoPetView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Localização do Pet'),
        backgroundColor: Colors.blue[900],
      ),
      body: Center(
        child: Text('Tela de Localização do Pet'),
      ),
    );
  }
}