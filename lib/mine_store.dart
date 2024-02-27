import 'package:flutter/material.dart';
import 'package:mine_sweeping/mine_sweeping_main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MineStore extends StatefulWidget {
  const MineStore({Key? key}) : super(key: key);

  @override
  State<MineStore> createState() => _MineStore();
}

class _MineStore extends State<MineStore> {
  final _formKey = GlobalKey<FormState>();
  String? size;
  List<List<String>> data = [];
  List<bool> flag = [];
  final int _storeNum = 3;

  bool _validateNumber(String value) {
    if (value.isEmpty) {
      return false;
    }
    final number = num.tryParse(value);
    return number != null && number > 0;
  }

  Future<void> initializeData() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> boardJsonList =
        prefs.getStringList('board') ?? List.filled(_storeNum, "");
    if (checkIsNull(boardJsonList)) {
      prefs.setStringList('board', List.filled(_storeNum, ""));
    }

    List<String> revealedJsonList =
        prefs.getStringList('revealed') ?? List.filled(_storeNum, "");
    if (checkIsNull(boardJsonList)) {
      prefs.setStringList('revealed', List.filled(_storeNum, ""));
    }
    List<String> flaggedJsonList =
        prefs.getStringList('flagged') ?? List.filled(_storeNum, "");
    if (checkIsNull(boardJsonList)) {
      prefs.setStringList('flagged', List.filled(_storeNum, ""));
    }
    List<String> playtimeList =
        prefs.getStringList('playTime') ?? List.filled(_storeNum, "");
    if (checkIsNull(boardJsonList)) {
      prefs.setStringList('playTime', List.filled(_storeNum, ""));
    }
    List<String> numMinesList =
        prefs.getStringList('numMines') ?? List.filled(_storeNum, "");
    if (checkIsNull(boardJsonList)) {
      prefs.setStringList('numMines', List.filled(_storeNum, ""));
    }

    for (int i = 0; i < _storeNum; i++) {
      data.add([
        boardJsonList[i],
        revealedJsonList[i],
        flaggedJsonList[i],
        playtimeList[i],
        numMinesList[i]
      ]);
      flag.add(boardJsonList[i] != "");
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: initializeData(),
        builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator(); // 显示一个加载指示器
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}'); // 显示错误信息
          } else {
            return Scaffold(
              appBar: AppBar(
                title: const Text('存档'),
                centerTitle: true,
              ),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_storeNum, (index) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.6,
                        height: MediaQuery.of(context).size.height * 0.2,
                        child: Card(
                          child: flag[index]
                              ? InkWell(
                                  onLongPress: () async {
                                    await showDialog(
                                        context: context,
                                        builder: (context) {
                                          return AlertDialog(
                                            title: const Text('提示'),
                                            content: Text('是否删除存档${index + 1}'),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  deleteIndex(index);
                                                  Navigator.of(context).pop();
                                                },
                                                child: const Text('确认'),
                                              ),
                                            ],
                                          );
                                        });
                                  },
                                  onTap: () async {
                                    // 传递data[index]给MineSweeping
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => MineSweeping(
                                            index: index, data: data[index]),
                                      ),
                                    );
                                  },
                                  child: Center(
                                    child: Text('存档 ${index + 1}',
                                        style: const TextStyle(fontSize: 24)),
                                  ),
                                )
                              : InkWell(
                                  onTap: () async {
                                    final TextEditingController controller =
                                        TextEditingController();
                                    await showDialog(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          title: const Text('请输入扫雷宽度'),
                                          content: Form(
                                            key: _formKey,
                                            child: TextFormField(
                                              controller: controller,
                                              keyboardType:
                                                  TextInputType.number,
                                              validator: (value) {
                                                if (!_validateNumber(value!)) {
                                                  return '请输入有效的数字';
                                                }
                                                return null;
                                              },
                                            ),
                                          ),
                                          actions: <Widget>[
                                            TextButton(
                                              child: const Text('确定'),
                                              onPressed: () async {
                                                if (_formKey.currentState!
                                                    .validate()) {
                                                  size = controller.text;
                                                  Navigator.of(context).pop();
                                                  final result =
                                                      await Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            MineSweeping(
                                                              size: size,
                                                              index: index,
                                                            )),
                                                  );
                                                  if (result != null &&
                                                      result) {
                                                    await initializeData();
                                                  }
                                                }
                                              },
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                  child: const Center(
                                    child: Icon(Icons.add, size: 50.0),
                                  ),
                                ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            );
          }
        });
  }

  bool checkIsNull(List<String> ls) {
    for (var item in ls) {
      if (item != "") {
        return false;
      }
    }
    return true;
  }

  void deleteIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? boardJsonList = prefs.getStringList('board');
    List<String>? revealedJsonList = prefs.getStringList('revealed');
    List<String>? flaggedJsonList = prefs.getStringList('flagged');
    List<String>? playtimeList = prefs.getStringList('playTime');
    List<String>? numMinesList = prefs.getStringList('numMines');

    if (boardJsonList != null && index < boardJsonList.length) {
      boardJsonList[index] = "";
    }

    if (revealedJsonList != null && index < revealedJsonList.length) {
      revealedJsonList[index] = "";
    }

    if (flaggedJsonList != null && index < flaggedJsonList.length) {
      flaggedJsonList[index] = "";
    }

    if (playtimeList != null && index < playtimeList.length) {
      playtimeList[index] = "";
    }

    if (numMinesList != null && index < numMinesList.length) {
      numMinesList[index] = "";
    }
    setState(() {
// 保存更新后的 List 到 SharedPreferences
      prefs.setStringList('board', boardJsonList!);
      prefs.setStringList('revealed', revealedJsonList!);
      prefs.setStringList('flagged', flaggedJsonList!);
      prefs.setStringList('playTime', playtimeList!);
      prefs.setStringList('numMines', numMinesList!);
      initializeData();
    });
  }
}
