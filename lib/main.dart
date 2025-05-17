import 'package:flutter/material.dart';
import 'package:solana/solana.dart';
import 'package:borsh_annotation/borsh_annotation.dart';
part 'counter_account.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Solana Counter App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const CounterScreen(),
    );
  }
}

class CounterScreen extends StatefulWidget {
  const CounterScreen({super.key});
  @override
  State<CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends State<CounterScreen> {
  late final RpcClient client;
  final String programId = 'JC6C6UgodXUg3Zfm4WZXJq2mZMVwiJEMCrZVpZP4nhR7';
  late final Ed25519HDKeyPair counterAccountKeypair;
  String counterValue = 'Loading...';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    client = RpcClient('http://127.0.0.1:8899');
    _initializeKeypairAndFetchCounter();
  }

  Future<void> _initializeKeypairAndFetchCounter() async {
    setState(() => isLoading = true);
    try {
      counterAccountKeypair = await Ed25519HDKeyPair.random();
      await client.requestAirdrop(
        counterAccountKeypair.publicKey,
        1000000000,
        commitment: Commitment.confirmed,
      );
      final space = 8;
      final lamports = await client.getMinimumBalanceForRentExemption(space);
      final instruction = SystemInstruction.createAccount(
        fromPublicKey: counterAccountKeypair.publicKey,
        newAccountPublicKey: counterAccountKeypair.publicKey,
        lamports: lamports,
        space: space,
        programId: programId,
      );
      await client.sendTransaction(
        await client.signTransaction(
          Transaction(instructions: [instruction]),
          [counterAccountKeypair],
        ),
        commitment: Commitment.confirmed,
      );
      await _fetchCounterValue();
    } catch (e) {
      setState(() => counterValue = 'Error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchCounterValue() async {
    try {
      final account = await client.getAccountInfo(
        counterAccountKeypair.publicKey.toBase58(),
        encoding: Encoding.base64,
      );
      if (account == null || account.data.isEmpty) {
        setState(() => counterValue = 'Account not found');
        return;
      }
      final counterAccount = CounterAccount.fromBorsh(account.data);
      setState(() => counterValue = counterAccount.count.toString());
    } catch (e) {
      setState(() => counterValue = 'Error: $e');
    }
  }

  Future<void> _incrementCounter() async {
    setState(() => isLoading = true);
    try {
      final instruction = Instruction(
        programId: programId,
        accounts: [
          AccountMeta.writeable(
            counterAccountKeypair.publicKey.toBase58(),
            isSigner: false,
          ),
        ],
        data: [],
      );
      await client.sendTransaction(
        await client.signTransaction(
          Transaction(instructions: [instruction]),
          [counterAccountKeypair],
        ),
        commitment: Commitment.confirmed,
      );
      await _fetchCounterValue();
    } catch (e) {
      setState(() => counterValue = 'Error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Solana Counter')),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : Text(
                'Counter: $counterValue',
                style: const TextStyle(fontSize: 24),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        child: const Icon(Icons.add),
      ),
    );
  }
}
