import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mine_sweeping/model/game_setting.dart';
import 'package:mine_sweeping/widget/block_container.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum BlockType {
  //数字
  figure,
  //雷
  mine,
  //标记
  label,
  //未标记（未被翻开）
  unlabeled,
}

class MineSweeping extends StatefulWidget {
  String? size;
  final int? index;
  final List<String>? data;
  MineSweeping({Key? key, this.size, this.index, this.data}) : super(key: key);

  @override
  State<MineSweeping> createState() => _MineSweepingState();
}

class _MineSweepingState extends State<MineSweeping> {
  static GameSetting gameSetting = GameSetting();
  late List<List<int>> board; // 棋盘
  late List<List<bool>> revealed; // 记录格子是否被翻开
  late List<List<bool>> flagged; // 记录格子是否被标记
  late bool gameOver; // 游戏是否结束
  late bool win; // 是否获胜
  late int numRows; // 行数
  late int numCols; // 列数
  int? numMines; // 雷数

  //游戏时间
  int? _playTime;

  String get playTime {
    int minutes = (_playTime! ~/ 60);
    int seconds = (_playTime! % 60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Timer? _timer;
  late final List<AlertDialog?> _dialog = List.filled(2, null);

  ///重置游戏
  void reset() {
    for (var d in _dialog) {
      if (d != null) {
        Navigator.of(context).pop();
        d = null; // 重置对话框对象
      }
    }

    setState(() {
      numRows = int.parse(widget.size!);
      numCols = int.parse(widget.size!);
      numMines = (numCols * numRows * 0.18).floor();
      // 初始化棋盘
      board = List.generate(numRows, (_) => List.filled(numCols, 0));
      // 初始化格子是否被翻开
      revealed = List.generate(numRows, (_) => List.filled(numCols, false));
      // 初始化格子是否被标记
      flagged = List.generate(numRows, (_) => List.filled(numCols, false));
      // 将游戏定义为未结束
      gameOver = false;
      // 将游戏定义为还未获胜
      win = false;

      //在棋盘上随机放置地雷，直到放置的地雷数量达到预定的 numMines
      int numMinesPlaced = 0;
      while (numMinesPlaced < numMines!) {
        //使用 Random().nextInt 方法生成两个随机数 i 和 j
        //分别用于表示棋盘中的行和列
        int i = Random().nextInt(numRows);
        int j = Random().nextInt(numCols);
        //通过 board[i][j] != -1 的判断语句，检查这个位置是否已经放置了地雷。如果没有
        //则将 board[i][j] 的值设置为 -1，表示在这个位置放置了地雷，并将 numMinesPlaced 的值加 1。
        if (board[i][j] != -1) {
          board[i][j] = -1;
          numMinesPlaced++;
        }
      }

      //计算每个非地雷格子周围的地雷数量
      //然后将计算得到的数量保存在对应的格子上。
      //通过两个嵌套的 for 循环遍历整个棋盘
      //内层的两个嵌套循环会计算这个格子周围的所有格子中地雷的数量
      //并将这个数量保存在 count 变量中
      for (int i = 0; i < numRows; i++) {
        for (int j = 0; j < numCols; j++) {
          //在每个单元格上，如果它不是地雷（值不为-1）
          //则内部嵌套两个循环遍历当前单元格周围的所有单元格
          //计算地雷数量并存储在当前单元格中。
          if (board[i][j] != -1) {
            int count = 0;
            //max(0, i - 1) 和 max(0, j - 1)
            //用于确保 i2 和 j2 不会小于 0，即不会越界到数组的负数索引。
            //min(numRows - 1, i + 1) 和 min(numCols - 1, j + 1) 用于确保 i2 和 j2 不会超出数组的边界
            // ·不会越界到数组的行列索引大于等于 numRows 和 numCols。
            for (int i2 = max(0, i - 1); i2 <= min(numRows - 1, i + 1); i2++) {
              for (int j2 = max(0, j - 1);
                  j2 <= min(numCols - 1, j + 1);
                  j2++) {
                if (board[i2][j2] == -1) {
                  count++;
                }
              }
            }
            board[i][j] = count;
          }
        }
      }
      //开始计时
      startTimer();
    });
  }

  void reveal(int i, int j) {
    if (gameOver) return;

    if (!revealed[i][j]) {
      setState(() {
        //将该格子设置为翻开
        revealed[i][j] = true;

        //如果翻开的是地雷
        if (board[i][j] == -1) {
          for (int i2 = 0; i2 < numRows; i2++) {
            for (int j2 = 0; j2 < numCols; j2++) {
              if (board[i2][j2] == -1) {
                revealed[i2][j2] = true;
              }
            }
          }
          //游戏结束
          gameOver = true;
          _timer?.cancel();
          _dialog[0] = AlertDialog(
            title: const Text('失败!'),
            content: const Text('踩到雷啦！'),
            actions: [
              TextButton(
                onPressed: reset,
                child: const Text('再玩一次'),
              ),
            ],
          );
          //结束动画
          showDialog(context: context, builder: (_) => _dialog[0] as Widget);
          return; // 如果翻开的是地雷，直接返回，不执行后面的代码
        }

        // 地雷跳跃：找到所有未翻开且未被标记为地雷的格子
        List<List<int>> availableCells = [];
        for (int i2 = 0; i2 < numRows; i2++) {
          for (int j2 = 0; j2 < numCols; j2++) {
            if (!revealed[i2][j2] && !flagged[i2][j2] && board[i2][j2] != -1) {
              availableCells.add([i2, j2]);
            }
          }
        }

        //如果有可用的格子，将地雷随机移动到一个可用的格子上
        if (availableCells.isNotEmpty) {
          int randomIndex = Random().nextInt(availableCells.length);
          List<int> newCell = availableCells[randomIndex];
          //  int randomMine = Random().nextInt((numRows*numRows/5.floor()) as int);
          //找到原来的地雷格子，将其变为非地雷
          d1:
          for (int i2 = 0; i2 < numRows; i2++) {
            for (int j2 = 0; j2 < numCols; j2++) {
              if (board[i2][j2] == -1 && !revealed[i2][j2]) {
                if (board[newCell[0]][newCell[1]] != -1 &&
                    !flagged[newCell[0]][newCell[1]]) {
                  board[i2][j2] = 0; //移除原来的地雷
                  board[newCell[0]][newCell[1]] = -1; //添加新的地雷
                  break d1;
                }
              }
            }
          }

          //重新计算所有格子的数字
          for (int i2 = 0; i2 < numRows; i2++) {
            for (int j2 = 0; j2 < numCols; j2++) {
              if (board[i2][j2] != -1) {
                int count = 0;
                for (int i3 = max(0, i2 - 1);
                    i3 <= min(numRows - 1, i2 + 1);
                    i3++) {
                  for (int j3 = max(0, j2 - 1);
                      j3 <= min(numCols - 1, j2 + 1);
                      j3++) {
                    if (board[i3][j3] == -1) {
                      count++;
                    }
                  }
                }
                board[i2][j2] = count;
              }
            }
          }
        }

        // 如果点击的格子周围都没有雷就自动翻开相邻的空格
        if (board[i][j] == 0) {
          for (int i2 = max(0, i - 1); i2 <= min(numRows - 1, i + 1); i2++) {
            for (int j2 = max(0, j - 1); j2 <= min(numCols - 1, j + 1); j2++) {
              if (!revealed[i2][j2]) {
                reveal(i2, j2);
              }
            }
          }
        }

        // 检查胜利条件
        if (checkWin()) {
          win = true;
          gameOver = true;
          _timer?.cancel();
          _dialog[1] = AlertDialog(
            title: const Text('成功！'),
            content: const Text('恭喜你!'),
            actions: [
              TextButton(
                onPressed: reset,
                child: const Text('再玩一次'),
              ),
            ],
          );
          //成功动画
          showDialog(context: context, builder: (_) => _dialog[1] as Widget);
        }
      });
    }
  }

  //这段代码是用来检查游戏是否获胜的。
  //具体来说，它会遍历整个棋盘，检查每一个未被翻开的格子是否都是地雷，
  //如果有任何一个未翻开的格子不是地雷，就说明游戏还没有获胜，返回false。
  //如果所有未翻开的格子都是地雷，就说明游戏已经获胜了，返回true。
  //
  //这个函数被用于在用户点击一个格子后检查游戏是否获胜，以及在重置游戏时重新初始化游戏状态。
  //通过这样的方式，可以实现自动检查游戏是否获胜的功能，并且让用户能够清楚地知道游戏是否已经结束。
  bool checkWin() {
    for (int i = 0; i < numRows; i++) {
      for (int j = 0; j < numCols; j++) {
        if (board[i][j] != -1 && !revealed[i][j]) {
          // reset();
          return false;
        }
      }
    }
    // reset();
    return true;
  }

  ///标记雷
  void toggleFlag(int i, int j) {
    if (revealed[i][j]) {
      return;
    }
    if (!gameOver) {
      setState(() {
        flagged[i][j] = !flagged[i][j];
        //     // 地雷跳跃：找到所有未翻开且未被标记为地雷的格子
        //     List<List<int>> availableCells = [];
        //     for (int i2 = 0; i2 < numRows; i2++) {
        //       for (int j2 = 0; j2 < numCols; j2++) {
        //         if (!revealed[i2][j2] && !flagged[i2][j2] && board[i2][j2] != -1) {
        //           availableCells.add([i2, j2]);
        //         }
        //       }
        //     }

        //     //如果有可用的格子，将地雷随机移动到一个可用的格子上
        //     if (availableCells.isNotEmpty) {
        //       int randomIndex = Random().nextInt(availableCells.length);
        //       List<int> newCell = availableCells[randomIndex];

        //       //找到原来的地雷格子，将其变为非地雷
        //       d1:
        //       for (int i2 = 0; i2 < numRows; i2++) {
        //         for (int j2 = 0; j2 < numCols; j2++) {
        //           if (board[i2][j2] == -1 &&
        //               !revealed[i2][j2] &&
        //               !flagged[i2][j2]) {
        //             if (board[newCell[0]][newCell[1]] != -1) {
        //               board[i2][j2] = 0; //移除原来的地雷
        //               board[newCell[0]][newCell[1]] = -1; //添加新的地雷
        //               break d1;
        //             }
        //           }
        //         }
        //       }

        //       //重新计算所有格子的数字
        //       for (int i2 = 0; i2 < numRows; i2++) {
        //         for (int j2 = 0; j2 < numCols; j2++) {
        //           if (board[i2][j2] != -1) {
        //             int count = 0;
        //             for (int i3 = max(0, i2 - 1);
        //                 i3 <= min(numRows - 1, i2 + 1);
        //                 i3++) {
        //               for (int j3 = max(0, j2 - 1);
        //                   j3 <= min(numCols - 1, j2 + 1);
        //                   j3++) {
        //                 if (board[i3][j3] == -1) {
        //                   count++;
        //                 }
        //               }
        //             }
        //             board[i2][j2] = count;
        //           }
        //         }
        //       }
        // }
      });
      if (!flagged[i][j]) {
        numMines = numMines! + 1;
      } else {
        numMines = numMines! - 1;
      }
    }
  }

  void changeDifficulty(int difficulty) {
    setState(() {
      gameSetting.difficulty = difficulty;
    });
    reset();
  }

  void changeThemeColor(Color color) {
    setState(() {
      gameSetting.themeColor = color;
    });
    // reset();
  }

  void setting() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('设置'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: const SizedBox(height: 24, child: Text('游戏主题颜色：')),
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => changeThemeColor(const Color(0xFF5ADFD0)),
                      child: const SizedBox(
                        width: 50,
                        height: 50,
                        child: ColoredBox(
                          color: Color(0xFF5ADFD0),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => changeThemeColor(const Color(0xFFA0BBFF)),
                      child: const SizedBox(
                        width: 50,
                        height: 50,
                        child: ColoredBox(
                          color: Color(0xFFA0BBFF),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                    height: 12), // Add spacing between buttons and content
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        store();
                      },
                      child: const Text('存档'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        reset();
                      },
                      child: const Text('重置'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  ///游戏计时器
  void startTimer() {
    //避免切换主题色导致计时跳动
    _timer?.cancel();
    const duration = Duration(seconds: 1);
    _playTime = 0;
    _timer = Timer.periodic(duration, (timer) {
      setState(() {
        _playTime = _playTime! + 1;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // 取消定时器
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.size == null) {
      reBuild();
    } else {
      reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("跳跳扫雷"),
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: IconButton(
            // 在这里添加自定义的按钮
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context, true);
            }),
        actions: [
          IconButton(
              onPressed: () => setting(), icon: const Icon(Icons.settings))
        ],
      ),
      backgroundColor: gameSetting.themeColor == const Color(0xFF5ADFD0)
          ? const Color(0xFF09484E)
          : const Color(0xFF1F2E7F),
      body: Column(
        children: <Widget>[
          SizedBox(
            height: 84,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                SizedBox(
                  height: 50,
                  child: Row(
                    children: [
                      Image.asset("assets/images/bomb.png"),
                      Text(
                        "${numMines ?? '0'}",
                        style:
                            const TextStyle(fontSize: 28, color: Colors.white),
                      )
                    ],
                  ),
                ),
                SizedBox(
                  height: 50,
                  child: Row(
                    children: [
                      Image.asset("assets/images/clock.png"),
                      Text(
                        playTime,
                        style:
                            const TextStyle(fontSize: 28, color: Colors.white),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: numCols,
                childAspectRatio: 1.0,
              ),
              itemBuilder: (BuildContext context, int index) {
                int i = index ~/ numCols;
                int j = index % numCols;
                BlockType blockType;
                //格子被翻开
                if (revealed[i][j]) {
                  //是地雷
                  if (board[i][j] == -1) {
                    blockType = BlockType.mine;
                  } else {
                    blockType = BlockType.figure;
                  }
                } else {
                  //被用户标记
                  if (flagged[i][j]) {
                    blockType = BlockType.label;
                  } else {
                    blockType = BlockType.unlabeled;
                  }
                }
                return GestureDetector(
                  onTap: () => reveal(i, j),
                  onLongPress: () => toggleFlag(i, j),
                  child: BlockContainer(
                    backColor: gameSetting.themeColor,
                    value: revealed[i][j] && board[i][j] != 0 ? board[i][j] : 0,
                    blockType: blockType,
                  ),
                );
              },
              itemCount: numRows * numCols,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> store() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? boardJsonList = prefs.getStringList('board');
    List<String>? revealedJsonList = prefs.getStringList('revealed');
    List<String>? flaggedJsonList = prefs.getStringList('flagged');
    List<String>? playtimeList = prefs.getStringList('playTime');
    List<String>? numMinesList = prefs.getStringList('numMines');
    setState(() {
      // 将二维列表转换为 Json 字符串
      String boardJson = json.encode(board);
      String revealedJson = json.encode(revealed);
      String flaggedJson = json.encode(flagged);

      boardJsonList?[widget.index!] = boardJson;
      revealedJsonList?[widget.index!] = revealedJson;
      flaggedJsonList?[widget.index!] = flaggedJson;
      playtimeList?[widget.index!] = _playTime.toString();
      numMinesList?[widget.index!] = numMines.toString();
      prefs.setStringList('board', boardJsonList!);
      prefs.setStringList('revealed', revealedJsonList!);
      prefs.setStringList('flagged', flaggedJsonList!);
      prefs.setStringList('playTime', playtimeList!);
      prefs.setStringList('numMines', numMinesList!);
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('存档成功'),
        content: Text('游戏存档已成功保存！'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }

  Future<void> reBuild() async {
    for (var d in _dialog) {
      if (d != null) {
        Navigator.of(context).pop();
        d = null; // 重置对话框对象
      }
    }
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      List<String>? boardJsonList = prefs.getStringList('board');
      List<String>? revealedJsonList = prefs.getStringList('revealed');
      List<String>? flaggedJsonList = prefs.getStringList('flagged');
      List<String>? playtimeList = prefs.getStringList('playTime');
      List<String>? numMinesList = prefs.getStringList('numMines');

      String boardJson = boardJsonList?[widget.index!] ?? "";
      String revealedJson = revealedJsonList?[widget.index!] ?? "";
      String flaggedJson = flaggedJsonList?[widget.index!] ?? "";
      int mines = int.parse(numMinesList![widget.index!]);
      int playtime = int.parse(playtimeList![widget.index!]);

      board = List<List<int>>.from(
          json.decode(boardJson).map((e) => List<int>.from(e)));
      revealed = List<List<bool>>.from(
          json.decode(revealedJson).map((e) => List<bool>.from(e)));
      flagged = List<List<bool>>.from(
          json.decode(flaggedJson).map((e) => List<bool>.from(e)));

      numRows = board.length;
      numCols = board[0].length;
      numMines = mines;
      gameOver = false;
      win = false;
      _playTime = playtime;
      widget.size = numCols.toString();

      startTimer();
    });
  }
}
