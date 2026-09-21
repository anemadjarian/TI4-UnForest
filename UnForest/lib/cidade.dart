import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class ItemCidade {
  final UniqueKey id;
  Offset position; // Posição virtual normalizada (ex: 0 a 1920 em X, 0 a 1080 em Y)
  bool isBicycle;
  double speed;

  ItemCidade({
    required this.id,
    required this.position,
    this.isBicycle = false,
    this.speed = 2.0,
  });
}

class CidadePage extends StatefulWidget {
  const CidadePage({Key? key}) : super(key: key);

  @override
  State<CidadePage> createState() => _CidadePageState();
}

class _CidadePageState extends State<CidadePage> {
  // Resolução virtual fixa de referência (16:9)
  static const double gameWidth = 1920.0;
  static const double gameHeight = 1080.0;

  final List<ItemCidade> _itens = [];
  int _contadorBicicletas = 0;
  Timer? _timerSpawn;
  Timer? _timerGameLoop;
  final Random _random = Random();
  bool _showInstructions = true;
  bool _showVictory = false;
  bool _taskConcluida = false;

  @override
  void initState() {
    super.initState();
  }

  void _iniciarTask() {
    setState(() {
      _showInstructions = false;
    });

    _timerSpawn?.cancel();
    _timerSpawn = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (!mounted || _contadorBicicletas >= 10) {
        timer.cancel();
        return;
      }
      _gerarCarro();
    });

    _timerGameLoop?.cancel();
    _timerGameLoop = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!mounted) return;
      _atualizarPosicoes();
    });
  }

  void _gerarCarro() {
    if (_itens.length >= 6 || _taskConcluida) return;

    // Posição Y fixa baseada na resolução virtual de 1080p (ex: entre 650px e 800px da pista)
    double minHeight = gameHeight * 0.60;
    double maxHeight = gameHeight * 0.73;
    double posY = minHeight + _random.nextDouble() * (maxHeight - minHeight);

    double posX = -150.0;
    double velocidade = 3.0 + _random.nextDouble() * 3.0;

    setState(() {
      _itens.add(
        ItemCidade(
          id: UniqueKey(),
          position: Offset(posX, posY),
          speed: velocidade,
        ),
      );
    });
  }

  void _atualizarPosicoes() {
    setState(() {
      for (var item in _itens) {
        item.position = Offset(item.position.dx + item.speed, item.position.dy);
      }

      // Remove os itens ao saírem da largura virtual do jogo
      _itens.removeWhere((item) => item.position.dx > gameWidth + 150);
    });
  }

  void _transformarEmBicicleta(ItemCidade item) {
    if (item.isBicycle || _contadorBicicletas >= 10 || _showVictory) return;

    setState(() {
      item.isBicycle = true;
      _contadorBicicletas++;
    });

    if (_contadorBicicletas >= 10 && !_taskConcluida) {
      _concluirTask();
    }
  }

  void _concluirTask() {
    _timerSpawn?.cancel();

    setState(() {
      _taskConcluida = true;
    });

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showVictory = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _timerSpawn?.cancel();
    _timerGameLoop?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Cor de fundo nas sobras da tela
      body: Center(
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: gameWidth,
            height: gameHeight,
            child: Stack(
              children: [
                // 1. Fundo proporcional
                SizedBox.expand(
                  child: Image.asset(
                    _taskConcluida
                        ? 'assets/images/task-cidade/cidade_colorida.png'
                        : 'assets/images/task-cidade/fundo_cinza.png',
                    fit: BoxFit.cover,
                  ),
                ),

                // 2. Veículos em posições virtuais fixas
                if (!_showInstructions && !_showVictory)
                  ..._itens.map((item) {
                    return Positioned(
                      left: item.position.dx,
                      top: item.position.dy,
                      child: GestureDetector(
                        onTap: () => _transformarEmBicicleta(item),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Image.asset(
                            item.isBicycle
                                ? 'assets/images/task-cidade/bicicleta.png'
                                : 'assets/images/task-cidade/carro.png',
                            key: ValueKey(item.isBicycle),
                            width: 280,
                            height: 280,
                          ),
                        ),
                      ),
                    );
                  }).toList(),

                // 3. Indicador de Progresso
                if (!_showInstructions && !_showVictory)
                  Positioned(
                    top: 40,
                    left: 40,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/images/task-cidade/bicicleta.png',
                            width: 45,
                            height: 45,
                          ),
                          const SizedBox(width: 15),
                          Text(
                            '$_contadorBicicletas / 10',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // 4. Tela Inicial de Instruções
                if (_showInstructions)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/buttons/balão_cidade.png',
                          height: 300,
                        ),
                        const SizedBox(height: 30),
                        GestureDetector(
                          onTap: _iniciarTask,
                          child: Image.asset(
                            'assets/images/buttons/botao_check.png',
                            height: 100,
                          ),
                        ),
                      ],
                    ),
                  ),

                // 5. Tela de Vitória
                if (_showVictory)
                  Container(
                    color: Colors.black38,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/buttons/balão_task_concluida.png',
                            height: 250,
                          ),
                          const SizedBox(height: 30),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).pop();
                            },
                            child: Image.asset(
                              'assets/images/buttons/botao_saida.png',
                              height: 100,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}