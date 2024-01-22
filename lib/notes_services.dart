import 'dart:convert';
import 'dart:io';

import 'package:dapp_notes/note.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/io.dart';

class NotesServices extends ChangeNotifier {
  List<Note> notes = [];
  final String RPC_URL = Platform.isAndroid
      ? dotenv.env['RPC_URL1'] ?? dotenv.env['RPC_URL2'] ?? 'default_rpc_url'
      : dotenv.env['RPC_URL2'] ?? 'default_rpc_url';

  final String WS_URL = Platform.isAndroid
      ? dotenv.env['WS_URL1'] ?? dotenv.env['WS_URL2'] ?? 'default_ws_url'
      : dotenv.env['WS_URL2'] ?? 'default_ws_url';
  final String PRIVATE_KEY = dotenv.env["PRIVATE_KEY"] ?? "default_private_key";
  bool isLoading = true;

  late Web3Client _web3client;
  late ContractAbi _abiCode;
  late EthereumAddress _contractAddress;
  NotesServices() {
    loadEnvVariables();
    init();
  }
  Future<void> loadEnvVariables() async {
    await dotenv.load();
  }

  Future<void> init() async {
    await _initializeWeb3Client();
    await getABI();
    await getCredentials();
    await getDeployedContract();
    await fetchNotes();
  }

  Future<void> _initializeWeb3Client() async {
    _web3client = Web3Client(
      RPC_URL,
      http.Client(),
      socketConnector: () {
        return IOWebSocketChannel.connect(WS_URL).cast<String>();
      },
    );
  }

  Future<void> getABI() async {
    String abiFile =
        await rootBundle.loadString('build/contracts/NotesContract.json');
    var jsonABI = jsonDecode(abiFile);
    _abiCode =
        ContractAbi.fromJson(jsonEncode(jsonABI['abi']), 'NotesContract');
    _contractAddress =
        EthereumAddress.fromHex(jsonABI["networks"]["5777"]["address"]);
    print('ABI: $_abiCode');
  }

  late EthPrivateKey _creds;
  Future<void> getCredentials() async {
    _creds = EthPrivateKey.fromHex(PRIVATE_KEY);
  }

  late DeployedContract _deployedContract;
  late ContractFunction _createNote;
  late ContractFunction _deleteNote;
  late ContractFunction _notes;
  late ContractFunction _noteCount;

  Future<void> getDeployedContract() async {
    _deployedContract = DeployedContract(_abiCode, _contractAddress);
    _createNote = _deployedContract.function('createNote');
    _deleteNote = _deployedContract.function('deleteNote');
    _notes = _deployedContract.function('notes');
    _noteCount = _deployedContract.function('noteCount');
    await fetchNotes();
  }

  Future<void> fetchNotes() async {
    List totalTaskList = await _web3client.call(
      contract: _deployedContract,
      function: _noteCount,
      params: [],
    );

    int totalTaskLen = totalTaskList[0].toInt();
    notes.clear();
    for (var i = 0; i < totalTaskLen; i++) {
      var temp = await _web3client.call(
          contract: _deployedContract,
          function: _notes,
          params: [BigInt.from(i)]);
      if (temp[1] != "") {
        notes.add(
          Note(
            id: (temp[0] as BigInt).toInt(),
            title: temp[1],
            description: temp[2],
          ),
        );
      }
    }
    isLoading = false;

    notifyListeners();
  }

  Future<void> addNote(String title, String description) async {
    await _web3client.sendTransaction(
      _creds,
      Transaction.callContract(
        contract: _deployedContract,
        function: _createNote,
        parameters: [title, description],
      ),
    );
    isLoading = true;
    fetchNotes();
  }

  Future<void> deleteNote(int id) async {
    await _web3client.sendTransaction(
      _creds,
      Transaction.callContract(
        contract: _deployedContract,
        function: _deleteNote,
        parameters: [BigInt.from(id)],
      ),
    );
    isLoading = true;
    notifyListeners();
    fetchNotes();
  }
}
