import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: EditorPage(),
    );
  }
}

class EditorPage extends StatefulWidget {
  const EditorPage({super.key});

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  final TextEditingController controlador = TextEditingController();

  Future<File> get arquivo async {
    final pasta = await getApplicationDocumentsDirectory();
    return File('${pasta.path}/organiza.md');
  }

  Future<void> carregarTexto() async {
    final arquivoMarkdown = await arquivo;
    final texto = await arquivoMarkdown.exists()
        ? await arquivoMarkdown.readAsString()
        : '';
    controlador.text = texto;
  }

  Future<void> salvarTexto() async {
    final arquivoMarkdown = await arquivo;
    await arquivoMarkdown.writeAsString(controlador.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Arquivo salvo')),
    );
  }

  Future<void> apagarArquivo() async {
    final arquivoMarkdown = await arquivo;
    if (await arquivoMarkdown.exists()) {
      await arquivoMarkdown.delete();
    }
    controlador.clear();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Arquivo apagado')),
    );
  }

  @override
  void initState() {
    super.initState();
    carregarTexto();
  }

  @override
  void dispose() {
    controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editor Markdown')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: TextField(
                controller: controlador,
                expands: true,
                maxLines: null,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  hintText: 'Escreva seu texto Markdown',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: salvarTexto,
              child: const Text('Salvar'),
            ),
            ElevatedButton(
              onPressed: apagarArquivo,
              child: const Text('Apagar'),
            ),
          ],
        ),
      ),
    );
  }
}
