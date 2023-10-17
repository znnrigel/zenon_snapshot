// zenon_snapshot.dart

import 'dart:async';
import 'dart:io';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

var ws = 'ws://127.0.0.1:35998';
var startingMomentum = 1;
var endingMomentum = 5000000;

final results = 'results.txt';
final f = new File(results);

List<String> addresses = [];

List extractMomentumData(DetailedMomentumList getDetailedMomentumsByHeight) {
  List messages = [];

  getDetailedMomentumsByHeight.list?.forEach((dm) {
    if (dm.momentum.content.isNotEmpty) {
      //print("${dm.momentum.height} has ${dm.momentum.content.length} transactions");
      dm.blocks.forEach((block) {
        addToList(block.address.toString());
      });
    }
  });
  return messages;
}

void addToList(String address) {
  bool found = false;
  if (!address.contains('z1qxemdedded')) {
    for (var a in addresses) {
      if (a == address) {
        found = true;
        break;
      }
    }
    if (!found) {
      addresses.add(address);
    }
  }
}

void writeToFile(List<String> list) {
  for (var a in list) {
    f.writeAsStringSync('$a\n', mode: FileMode.append);
  }
}

Future<void> main(List<String> args) async {
  final Zenon znnClient = Zenon();
  await znnClient.wsClient.initialize(ws, retry: false);

  int remaining = endingMomentum - startingMomentum;
  while (remaining > 0) {
    int querySize = remaining > rpcMaxPageSize ? rpcMaxPageSize : remaining;
    DetailedMomentumList getDetailedMomentumsByHeight = await znnClient.ledger
        .getDetailedMomentumsByHeight(endingMomentum - remaining, querySize);
    await extractMomentumData(getDetailedMomentumsByHeight);
    remaining -= querySize;
  }

  print("Writing to file");
  writeToFile(addresses);

  print("Done");
  znnClient.wsClient.stop();
}
