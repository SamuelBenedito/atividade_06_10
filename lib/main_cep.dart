import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MaterialApp(home: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final cepController = TextEditingController();
  Map<String, dynamic>? endereco;
  String mensagem = '';

  Future<void> consultarCep() async {
    final cep = cepController.text.replaceAll(RegExp(r'\D'), '');

    if (cep.length != 8) {
      setState(() {
        endereco = null;
        mensagem = 'Digite um CEP com 8 números.';
      });
      return;
    }

    try {
      final resposta = await http.get(
        Uri.parse('https://viacep.com.br/ws/$cep/json/'),
      );
      final dados = jsonDecode(resposta.body) as Map<String, dynamic>;

      setState(() {
        if (dados['erro'] == true) {
          endereco = null;
          mensagem = 'CEP não encontrado.';
        } else {
          endereco = dados;
          mensagem = '';
        }
      });
    } catch (_) {
      setState(() {
        endereco = null;
        mensagem = 'Não foi possível consultar o CEP.';
      });
    }
  }

  @override
  void dispose() {
    cepController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Consulta de CEP')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: cepController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Digite o CEP'),
            ),
            ElevatedButton(
              onPressed: consultarCep,
              child: const Text('Consultar'),
            ),
            Text(mensagem),
            if (endereco != null) ...[
              Text('Rua: ${endereco!['logradouro'] ?? ''}'),
              Text('Bairro: ${endereco!['bairro'] ?? ''}'),
              Text('Cidade: ${endereco!['localidade'] ?? ''}'),
              Text('Estado: ${endereco!['uf'] ?? ''}'),
            ],
          ],
        ),
      ),
    );
  }
}
