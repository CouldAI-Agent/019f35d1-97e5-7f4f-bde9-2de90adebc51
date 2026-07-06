import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class GunGameScreen extends StatefulWidget {
  const GunGameScreen({super.key});

  @override
  State<GunGameScreen> createState() => _GunGameScreenState();
}

class _GunGameScreenState extends State<GunGameScreen> with TickerProviderStateMixin {
  int _score = 0;
  int _timeLeft = 30;
  bool _isPlaying = false;
  Timer? _gameTimer;
  Timer? _targetTimer;

  Offset _targetPosition = const Offset(100, 100);
  final double _targetSize = 60.0;
  final Random _random = Random();

  late AnimationController _recoilController;
  late Animation<double> _recoilAnimation;
  
  late AnimationController _flashController;
  late Animation<double> _flashAnimation;

  @override
  void initState() {
    super.initState();
    _recoilController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _recoilAnimation = Tween<double>(begin: 0, end: 20).animate(
      CurvedAnimation(parent: _recoilController, curve: Curves.easeOut),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _recoilController.reverse();
        }
      });

    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50),
    );
    _flashAnimation = Tween<double>(begin: 0, end: 1).animate(_flashController)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _flashController.reverse();
        }
      });
  }

  void _startGame() {
    setState(() {
      _score = 0;
      _timeLeft = 30;
      _isPlaying = true;
    });

    _moveTarget();

    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
      } else {
        _endGame();
      }
    });

    _targetTimer = Timer.periodic(const Duration(milliseconds: 1200), (timer) {
      if (_isPlaying) {
        _moveTarget();
      }
    });
  }

  void _endGame() {
    _gameTimer?.cancel();
    _targetTimer?.cancel();
    setState(() {
      _isPlaying = false;
    });
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Time\\'s Up!'),
        content: Text('Your final score: $_score'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startGame();
            },
            child: const Text('Play Again'),
          )
        ],
      ),
    );
  }

  void _moveTarget() {
    if (!mounted) return;
    
    final size = MediaQuery.of(context).size;
    // Keep target within safe screen bounds, avoiding top app bar area and bottom gun area
    final double maxX = size.width - _targetSize;
    final double maxY = size.height - _targetSize - 200; // 200 padding for gun

    if (maxX > 0 && maxY > 100) {
      setState(() {
        _targetPosition = Offset(
          _random.nextDouble() * maxX,
          100 + _random.nextDouble() * (maxY - 100),
        );
      });
    }
  }

  void _fireWeapon() {
    if (!_isPlaying) return;
    
    _recoilController.forward(from: 0);
    _flashController.forward(from: 0);
  }

  void _hitTarget() {
    if (!_isPlaying) return;
    
    _fireWeapon();
    setState(() {
      _score += 10;
    });
    _moveTarget();
    
    // Optional: Reset target timer so it doesn't jump immediately after hit
    _targetTimer?.cancel();
    _targetTimer = Timer.periodic(const Duration(milliseconds: 1200), (timer) {
      if (_isPlaying) {
        _moveTarget();
      }
    });
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _targetTimer?.cancel();
    _recoilController.dispose();
    _flashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Target Practice'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: GestureDetector(
        onTapDown: (_) => _fireWeapon(),
        child: Stack(
          children: [
            // Background
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.blueGrey.shade900, Colors.black],
                  ),
                ),
              ),
            ),
            
            // HUD
            Positioned(
              top: 20,
              left: 20,
              child: Text(
                'Score: $_score',
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            Positioned(
              top: 20,
              right: 20,
              child: Text(
                'Time: $_timeLeft',
                style: TextStyle(
                  color: _timeLeft <= 5 ? Colors.red : Colors.white, 
                  fontSize: 24, 
                  fontWeight: FontWeight.bold
                ),
              ),
            ),

            // Start Button overlay
            if (!_isPlaying)
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                    textStyle: const TextStyle(fontSize: 24),
                  ),
                  onPressed: _startGame,
                  child: const Text('Start Game'),
                ),
              ),

            // Target
            if (_isPlaying)
              Positioned(
                left: _targetPosition.dx,
                top: _targetPosition.dy,
                child: GestureDetector(
                  onTapDown: (_) => _hitTarget(),
                  child: Container(
                    width: _targetSize,
                    height: _targetSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.5),
                          blurRadius: 10,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: _targetSize * 0.5,
                        height: _targetSize * 0.5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: Colors.red, width: 4),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Gun and Muzzle Flash
            Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedBuilder(
                animation: _recoilAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _recoilAnimation.value),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Muzzle Flash
                        FadeTransition(
                          opacity: _flashAnimation,
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.orange,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.yellow,
                                  blurRadius: 20,
                                  spreadRadius: 10,
                                )
                              ]
                            ),
                          ),
                        ),
                        // Gun Graphic
                        Container(
                          width: 80,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade800,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(10),
                              topRight: Radius.circular(10),
                            ),
                            border: Border.all(color: Colors.grey.shade600, width: 2),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 20,
                                height: 40,
                                color: Colors.black,
                              ),
                              const Spacer(),
                              Container(
                                width: double.infinity,
                                height: 20,
                                color: Colors.grey.shade900,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
