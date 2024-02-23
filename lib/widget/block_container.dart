import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mine_sweeping/mine_sweeping_main.dart';
import 'package:mine_sweeping/model/game_setting.dart';

class BlockContainer extends StatelessWidget {
  final Color backColor;
  final int value;
  final BlockType blockType;

  const BlockContainer({
    super.key,
    required this.backColor,
    required this.value,
    required this.blockType,
  });

  static GameSetting gameSetting = GameSetting();

  @override
  Widget build(BuildContext context) {
    late Widget container;
    double borderRadius = 4.0;
    if (blockType == BlockType.figure) {
      container = SizedBox(
        width: 40,
        height: 40,
        child: Container(
          alignment: Alignment.center,
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: backColor == const Color(0xFF5ADFD0)
                ? gameSetting.c_5ADFD0[0]
                : gameSetting.c_A0BBFF[0],
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: Text(
            "${value != 0 ? value : ''}",
          ),
        ),
      );
    } else if (blockType == BlockType.mine) {
      container = SizedBox(
        width: 40,
        height: 40,
        child: Container(
          alignment: Alignment.center,
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: backColor == const Color(0xFF5ADFD0)
                ? gameSetting.c_5ADFD0[1]
                : gameSetting.c_A0BBFF[1],
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: Image.asset("assets/images/flag.png"),
        ),
      );
    } else if (blockType == BlockType.label) {
      container = SizedBox(
        width: 40,
        height: 40,
        child: Container(
          alignment: Alignment.center,
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: backColor == const Color(0xFF5ADFD0)
                ? gameSetting.c_5ADFD0[2]
                : gameSetting.c_A0BBFF[2],
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: Image.asset("assets/images/flag.png"),
        ),
      );
    } else {
      container = SizedBox(
        width: 40,
        height: 40,
        child: Container(
          alignment: Alignment.center,
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: backColor,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      );
    }
    return container;
  }
}
