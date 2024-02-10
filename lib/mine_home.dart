import 'package:flutter/material.dart';
import 'package:mine_sweeping/mine_store.dart';

class MineHome extends StatefulWidget {
  const MineHome({Key? key}) : super(key: key);

  @override
  State<MineHome> createState() => _MineHome();
}

class _MineHome extends State<MineHome> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('跳跳扫雷'),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(31, 246, 219, 17),
      ),
      body: Stack(fit: StackFit.expand, children: <Widget>[
        Image.asset('assets/images/home.jpg', fit: BoxFit.fill), // 添加背景图
        Center(
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const MineStore()), // 跳转到下一个Widget
              );
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.blue, // 按钮的文字颜色
            ),
            child: const Text('开始游戏'),
          ),
        ),
      ]),
    );
  }
}
