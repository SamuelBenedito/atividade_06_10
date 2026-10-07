import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
  final numeroController = TextEditingController();
  Map<String, String>? endereco;
  String mensagem = '';

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  Future<void> carregarDados() async {
    final prefs = await SharedPreferences.getInstance();
    final cep = prefs.getString('cep') ?? '';
    if (!mounted) return;

    cepController.text = cep;
    numeroController.text = prefs.getString('numero') ?? '';
    if (cep.isNotEmpty) {
      setState(() {
        endereco = {
          'logradouro': prefs.getString('rua') ?? '',
          'bairro': prefs.getString('bairro') ?? '',
          'localidade': prefs.getString('cidade') ?? '',
          'uf': prefs.getString('estado') ?? '',
        };
      });
    }
  }

  Future<void> consultarCep() async {
    final cep = cepController.text.replaceAll(RegExp(r'\D'), '');
    final numero = numeroController.text.trim();

    if (cep.length != 8) {
      setState(() {
        endereco = null;
        mensagem = 'Digite um CEP com 8 números.';
      });
      return;
    }
    if (numero.isEmpty) {
      setState(() => mensagem = 'Digite o número da casa.');
      return;
    }

    try {
      final resposta = await http.get(
        Uri.parse('https://viacep.com.br/ws/$cep/json/'),
      );
      if (resposta.statusCode != 200) {
        throw Exception('Falha na consulta');
      }
      final dados = jsonDecode(resposta.body) as Map<String, dynamic>;

      if (dados['erro'] == true) {
        setState(() {
          endereco = null;
          mensagem = 'CEP não encontrado.';
        });
        return;
      }

      final novoEndereco = <String, String>{
        'logradouro': dados['logradouro']?.toString() ?? '',
        'bairro': dados['bairro']?.toString() ?? '',
        'localidade': dados['localidade']?.toString() ?? '',
        'uf': dados['uf']?.toString() ?? '',
      };

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cep', cep);
      await prefs.setString('numero', numero);
      await prefs.setString('rua', novoEndereco['logradouro']!);
      await prefs.setString('bairro', novoEndereco['bairro']!);
      await prefs.setString('cidade', novoEndereco['localidade']!);
      await prefs.setString('estado', novoEndereco['uf']!);

      if (!mounted) return;
      setState(() {
        endereco = novoEndereco;
        mensagem = '';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        endereco = null;
        mensagem = 'Não foi possível consultar o CEP.';
      });
    }
  }

  Future<void> apagarDados() async {
    final prefs = await SharedPreferences.getInstance();
    for (final chave in [
      'cep',
      'numero',
      'rua',
      'bairro',
      'cidade',
      'estado'
    ]) {
      await prefs.remove(chave);
    }

    cepController.clear();
    numeroController.clear();
    setState(() {
      endereco = null;
      mensagem = '';
    });
  }

  @override
  void dispose() {
    cepController.dispose();
    numeroController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Consulta de CEP')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: cepController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(8),
              ],
              decoration: const InputDecoration(labelText: 'Digite o CEP'),
            ),
            TextField(
              controller: numeroController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Número da casa'),
            ),
            ElevatedButton(
              onPressed: consultarCep,
              child: const Text('Consultar e salvar'),
            ),
            Text(mensagem),
            if (endereco != null) ...[
              Text('Rua: ${endereco!['logradouro']}'),
              Text('Número: ${numeroController.text}'),
              Text('Bairro: ${endereco!['bairro']}'),
              Text('Cidade: ${endereco!['localidade']}'),
              Text('Estado: ${endereco!['uf']}'),
            ],
            ElevatedButton(
              onPressed: apagarDados,
              child: const Text('Apagar dados salvos'),
            ),
          ],
        ),
      ),
    );
  }
}
