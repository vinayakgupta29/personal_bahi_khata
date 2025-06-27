import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:personal_bahi_khata/data/database.dart';
import 'package:personal_bahi_khata/data/encryption.dart';

class BenchMarkPage extends StatefulWidget {
  const BenchMarkPage({super.key});

  @override
  State<BenchMarkPage> createState() => _BenchMarkPageState();
}

class _BenchMarkPageState extends State<BenchMarkPage> {
  List<int> benchmarkCount = [0, 1, 100, 500, 1000, 10000];
  List<Map> benchmarkResult = [];
  @override
  initState() {
    runBenchMark();
    super.initState();
  }

  void runBenchMark() async {
    for (int count in benchmarkCount) {
      var result = await encryptionBenchMark(count);

      setState(() {
        benchmarkResult.add(result);
      });
    }
  }

  dynamic compressionBenchMark(int count) async {
    var data = generateRandomData(count);
    var originallen = utf8.encode(jsonEncode(data)).lengthInBytes;
    var compressed = await zstd.compress(utf8.encode(jsonEncode(data)), 13);
    var compressedLen = compressed?.lengthInBytes ?? 0;
    return {
      "count": count,
      "originallen": originallen,
      "compressedLen": compressedLen,
    };
  }

  dynamic encryptionBenchMark(int count) async {
    var data = generateRandomData(count);
    var compressed = await zstd.compress(utf8.encode(jsonEncode(data)), 13);
    final stopwatch = clock.stopwatch()..start();
    final cipher = await EncryptionAES.encryptAESGCM(
      List<int>.from(compressed?.toList() ?? []),
      EncryptionAES.KEY,
    );
    var encTime = stopwatch.elapsedMilliseconds;
    stopwatch.reset();
    stopwatch.start();

    var decrypted = await EncryptionAES.decryptAESGCM(
      cipher,
      EncryptionAES.KEY,
    );
    var decTime = stopwatch.elapsedMilliseconds;
    return {"cout": count, "encTime": encTime, "decTime": decTime};
  }

  Future<Map> benchmarkFileIO(int count) async {
    var path = await getApplicationDocumentsDirectory();
    final filePath = '${path.path}test_$count.pbke';
    final file = File(filePath);
    var data = generateRandomData(count);
    var compressed = await zstd.compress(utf8.encode(jsonEncode(data)), 13);
    final cipher = await EncryptionAES.encryptAESGCM(
      List<int>.from(compressed?.toList() ?? []),
      EncryptionAES.KEY,
    );
    // Benchmark Write
    List<int> ouput = [
      ...utf8.encode(DataBase.SIGNATURE),
      ...getUnixTime(DateTime.now()),
      ...List.generate(13, (e) => 0),
      ...cipher,
    ];
    final stopwatch = clock.stopwatch()..start();
    await file.writeAsBytes(ouput);
    stopwatch.stop();
    print('File Write Time: ${stopwatch.elapsedMilliseconds} ms');
    var write = stopwatch.elapsedMilliseconds;
    // Benchmark Read
    stopwatch.reset();
    stopwatch.start();
    final contents = await file.readAsBytes();
    if (contents.isNotEmpty) {
      int headerSize = utf8.encode(DataBase.SIGNATURE).length + 4 + 13;
      List<int> metadata = contents.sublist(0, headerSize - 1);
      // SmsApi.lastDate = getDateTimeFromUnixTime(metadata);
      List<int> data = contents.sublist(headerSize);
      // contents.length - EncryptionAES.KEY_LENGTH);
    }
    stopwatch.stop();
    print('File Read Time: ${stopwatch.elapsedMilliseconds} ms');
    var read = stopwatch.elapsedMilliseconds;
    return {"count": count, "write": write, "read": read};
  }

  String getRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
    Random random = Random();
    return List.generate(
      length,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  List<Map<String, dynamic>> generateRandomData(int count) {
    Random random = Random();
    List<Map<String, dynamic>> dataList = [];

    for (int i = 0; i < count; i++) {
      int id =
          DateTime.now().millisecondsSinceEpoch +
          random.nextInt(1000); // Millisecond timestamp with a small offset
      String name = getRandomString(
        random.nextInt(46) + 5,
      ); // Length between 5 and 50
      double amount =
          random.nextDouble() * 1000; // Random amount between 0 and 1000
      bool isDebit = random.nextBool(); // Random boolean for debit
      int labelsCount =
          random.nextInt(5) + 1; // Random list length between 1 and 5
      List<String> labels = List.generate(
        labelsCount,
        (index) => getRandomString(random.nextInt(8) + 3),
      ); // Labels length between 3 and 10

      dataList.add(
        Expense(
          id: id.toString(),
          name: name,
          amount: amount.toString(),
          isDebit: isDebit,
          label: labels,
        ).toJson(),
      );
    }

    return dataList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("BenchMark")),
      body: ListView.builder(
        itemCount: benchmarkResult.length,
        itemBuilder: (context, index) {
          var result = benchmarkResult[index];
          return Container(
            decoration: BoxDecoration(border: Border.all(color: Colors.blue)),
            child: Padding(
              padding: const EdgeInsets.all(50.0),
              child: Text(result.toString()),
            ),
          );
        },
      ),
    );
  }
}
