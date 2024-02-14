import 'package:flutter/material.dart';
import 'package:mine_sweeping/mine_sweeping_main.dart';

class MineStore extends StatefulWidget {
  const MineStore({Key? key}) : super(key: key);

  @override
  State<MineStore> createState() => _MineStore();
}

class _MineStore extends State<MineStore> {
  final _formKey = GlobalKey<FormState>();
  String? size;

  bool _validateNumber(String value) {
    if (value.isEmpty) {
      return false;
    }
    final number = num.tryParse(value);
    return number != null && number > 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('存档'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.6,
                height: MediaQuery.of(context).size.height * 0.2,
                child: Card(
                  child: InkWell(
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
                                keyboardType: TextInputType.number,
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
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    size = controller.text;
                                    Navigator.of(context).pop();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              MineSweeping(size: size)),
                                    );
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
}
