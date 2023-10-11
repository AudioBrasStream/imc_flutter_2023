import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      appBar: AppBar(
        title: Text('Calculadora de IMC'),
      ),
      body: CalculadoraIMC(),
    ),
  ));
}

class IMCDatabaseHelper {
  static IMCDatabaseHelper? _instance;
  static Database? _database;

  IMCDatabaseHelper._privateConstructor();

  factory IMCDatabaseHelper() {
    if (_instance == null) {
      _instance = IMCDatabaseHelper._privateConstructor();
    }
    return _instance!;
  }

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await initializeDatabase();
    return _database!;
  }

  Future<Database> initializeDatabase() async {
    final path = await getDatabasesPath();
    final databasePath = join(path, 'imc_database.db');

    return await openDatabase(
      databasePath,
      version: 1,
      onCreate: (db, version) {
        db.execute('''
          CREATE TABLE imc_results (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            altura REAL,
            peso REAL,
            imc REAL
          )
        ''');
      },
    );
  }

  Future<void> insertIMCResult(IMCResult result) async {
    final db = await database;
    await db.insert('imc_results', result.toMap());
  }

  Future<List<IMCResult>> getIMCResults() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('imc_results');
    return List.generate(maps.length, (i) {
      return IMCResult(
        id: maps[i]['id'],
        altura: maps[i]['altura'],
        peso: maps[i]['peso'],
        imc: maps[i]['imc'],
      );
    });
  }
}

class IMCResult {
  final int? id;
  final double altura;
  final double peso;
  final double imc;

  IMCResult({
    this.id,
    required this.altura,
    required this.peso,
    required this.imc,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'altura': altura,
      'peso': peso,
      'imc': imc,
    };
  }
}

class CalculadoraIMC extends StatefulWidget {
  @override
  _CalculadoraIMCState createState() => _CalculadoraIMCState();
}

class _CalculadoraIMCState extends State<CalculadoraIMC> {
  final List<IMCResult> resultados = [];

  TextEditingController alturaController = TextEditingController();
  TextEditingController pesoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadIMCResults();
  }

  Future<void> loadIMCResults() async {
    final results = await IMCDatabaseHelper().getIMCResults();
    setState(() {
      resultados.addAll(results);
    });
  }

  String interpretarIMC(double imc) {
    if (imc < 16) {
      return 'Magreza grave';
    } else if (imc >= 16 && imc < 17) {
      return 'Magreza moderada';
    } else if (imc >= 17 && imc < 18.5) {
      return 'Magreza leve';
    } else if (imc >= 18.5 && imc < 25) {
      return 'Saudável';
    } else if (imc >= 25 && imc < 30) {
      return 'Sobrepeso';
    } else if (imc >= 30 && imc < 35) {
      return 'Obesidade Grau 1';
    } else if (imc >= 35 && imc < 40) {
      return 'Obesidade Grau 2';
    } else {
      return 'Obesidade Grau 3';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              TextField(
                keyboardType: TextInputType.number,
                controller: alturaController,
                decoration: InputDecoration(labelText: 'Altura (m)'),
              ),
              TextField(
                keyboardType: TextInputType.number,
                controller: pesoController,
                decoration: InputDecoration(labelText: 'Peso (kg)'),
              ),
              ElevatedButton(
                onPressed: () {
                  calcularIMC();
                },
                child: Text('Calcular'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: resultados.length,
            itemBuilder: (context, index) {
              final resultado = resultados[index];
              final interpretacao = interpretarIMC(resultado.imc);
              return ListTile(
                title: Text(
                  'Altura: ${resultado.altura.toStringAsFixed(2)} m, Peso: ${resultado.peso.toStringAsFixed(2)} kg',
                ),
                subtitle: Text('IMC: ${resultado.imc.toStringAsFixed(2)} - $interpretacao'),
              );
            },
          ),
        ),
      ],
    );
  }

  void calcularIMC() async {
    double altura = double.tryParse(alturaController.text) ?? 0.0;
    double peso = double.tryParse(pesoController.text) ?? 0.0;

   if (altura > 0 && peso > 0) {
      IMCResult resultado = IMCResult(altura: altura, peso: peso, imc: peso / (altura * altura));
      await IMCDatabaseHelper().insertIMCResult(resultado);

      setState(() {
        resultados.add(resultado);
        alturaController.clear();
        pesoController.clear();
      });
    }
  }
}