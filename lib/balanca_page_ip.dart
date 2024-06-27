import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

class BalancaPageIp extends StatefulWidget {
  const BalancaPageIp({super.key});

  @override
  State<BalancaPageIp> createState() => _BalancaPageIpState();
}

class _BalancaPageIpState extends State<BalancaPageIp> {
  Socket? socket;
  bool connected = false;
  bool pesagemRegistrada = false;
  int pesoRelativo = 10;
  String dados = '';
  String peso = '';
  String decimal = '';
  String pesoFinal = '';
  String pesoComparacao = '';
  bool estavel = false;
  int numeroCoparacao = 0;
  bool registrandoPesangem = false;
  final delimitador = Uint8List.fromList([13]);
  final inicioMensagem = Uint8List.fromList([43]);
  final buffer = BytesBuilder();

  String ipBalanca = '192.168.0.103';
  int portaBalanca = 4003;
  void iniciaLeitura() async {
    try {
      socket = await Socket.connect(
        ipBalanca,
        portaBalanca,
        timeout: const Duration(seconds: 1),
      );
      void handleData(Uint8List data) async {
        connected = true;
        // CONVERTE 7 BITS PARA 8 BITS
        List<int> convertedData = data.map((byte) => byte & 0x7F).toList();

        convertedData = Uint8List.fromList(
            convertedData.where((byte) => byte != 2).toList());

        buffer.add(Uint8List.fromList(convertedData));

        Uint8List bytes = buffer.toBytes();
        if (buffer.isNotEmpty) {
          if (bytes[0] != inicioMensagem[0] ||
              bytes[bytes.length - 1] == delimitador[0]) {
            buffer.clear();
          }
        }
        if (bytes.length == 16) {
          var bytesFormatados = bytes
              .where(
                  (element) => element != 13 && element != 10 && element != 32)
              .toList();

          String mensagemCompleta = String.fromCharCodes(bytesFormatados);
          peso = mensagemCompleta.substring(5, 8);
          decimal = mensagemCompleta.substring(8, 9);
          peso = int.parse(peso).toString();
          pesoFinal = '$peso,$decimal';
          if (pesoFinal == pesoComparacao) {
            numeroCoparacao += 1;
          } else {
            numeroCoparacao = 0;
          }
          if (numeroCoparacao >= 8 &&
              int.parse(peso) > pesoRelativo &&
              !pesagemRegistrada) {
            estavel = true;
          } else {
            estavel = false;
          }

          if (int.parse(peso) < pesoRelativo && pesagemRegistrada) {
            setState(() {
              pesagemRegistrada = false;
            });
          }
          pesoComparacao = pesoFinal;

          setState(() {});
        }

        if (bytes.length > 16) {
          buffer.clear();
        }
      }

      socket?.listen(
        handleData,
        onError: (error) {
          socket?.close();
          disconnect();
        },
        onDone: () {
          socket?.close();
          disconnect();
        },
        cancelOnError: false,
      );
    } on SocketException {
      disconnect();
    } on TimeoutException {
      disconnect();
    } catch (e) {
      disconnect();
    }
  }

  void gravaPeso() async {
    setState(() {
      registrandoPesangem = true;
    });
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      pesagemRegistrada = true;
      registrandoPesangem = false;
      estavel = false;
      numeroCoparacao = 0;
      pesoFinal = '0,0';
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Peso registrado com sucesso!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void disconnect() {
    setState(() {
      pesoFinal = '0,0';
      estavel = false;
      connected = false;
      numeroCoparacao = 0;
      registrandoPesangem = false;
    });
    if (socket != null) {
      socket?.close();
      socket?.destroy();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 15, 31, 251),
          centerTitle: true,
          title: const Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Módulo de Pesagem IP Toledo',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Versão: 5.1.1.50',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
          ),
          width: double.infinity,
          height: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                flex: 6,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      connected ? "Balança conectada" : "Balança desconectada",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: connected ? Colors.green : Colors.red,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Container(
                        height: 200,
                        width: MediaQuery.sizeOf(context).width,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: estavel
                                ? Colors.green.withOpacity(0.8)
                                : Colors.red.withOpacity(0.8),
                            width: 4,
                          ),
                          color: estavel
                              ? const Color.fromARGB(255, 11, 196, 17)
                              : const Color.fromARGB(255, 255, 32, 16),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Dados recebidos",
                                style: TextStyle(
                                  fontSize: 26,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "$pesoFinal kg",
                                style: const TextStyle(
                                  fontSize: 30,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              pesagemRegistrada
                                  ? SizedBox(
                                      width: MediaQuery.sizeOf(context).width,
                                      height: 50,
                                      child: const Center(
                                        child: Text(
                                          'Retire o peso da balança',
                                          style: TextStyle(
                                            fontSize: 20,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    )
                                  : Container(
                                      height: 50,
                                    ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                flex: 5,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50)),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: estavel
                                ? const Color.fromARGB(255, 11, 196, 17)
                                : const Color.fromARGB(255, 155, 154, 154),
                            padding: const EdgeInsets.all(8),
                          ),
                          onPressed: estavel &&
                                  !registrandoPesangem &&
                                  !pesagemRegistrada
                              ? () {
                                  gravaPeso();
                                }
                              : null,
                          child: const Text(
                            'Pesar',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      SizedBox(
                        width: MediaQuery.sizeOf(context).width,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 15, 31, 251),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.all(8),
                          ),
                          onPressed: !connected &&
                                  !registrandoPesangem &&
                                  !pesagemRegistrada
                              ? () {
                                  iniciaLeitura();
                                }
                              : null,
                          child: const Text(
                            'Iniciar leitura',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      SizedBox(
                        width: MediaQuery.sizeOf(context).width,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 255, 32, 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.all(8),
                          ),
                          onPressed: connected &&
                                  !registrandoPesangem &&
                                  !pesagemRegistrada
                              ? () {
                                  disconnect();
                                }
                              : null,
                          child: const Text(
                            'Parar leitura',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
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
    );
  }
}
