import 'package:flutter/material.dart';

void main() => runApp(const CalculatorApp());

class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '手机计算器',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const CalculatorScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _output = "0";
  String _expression = "";
  double _num1 = 0;
  String _operation = "";

  void _buttonPressed(String buttonText) {
    setState(() {
      if (buttonText == "AC") {
        _output = "0";
        _expression = "";
        _num1 = 0;
        _operation = "";
      } else if (buttonText == "⌫") {
        if (_output.length > 1) {
          _output = _output.substring(0, _output.length - 1);
        } else {
          _output = "0";
        }
      } else if (buttonText == "%") {
        double value = double.parse(_output);
        _output = (value / 100).toStringAsFixed(2);
      } else if (["+", "-", "×", "÷"].contains(buttonText)) {
        _num1 = double.parse(_output);
        _operation = buttonText;
        _expression = "$_output $buttonText ";
        _output = "0";
      } else if (buttonText == "=") {
        if (_operation.isEmpty) return;

        double num2 = double.parse(_output);
        double result = 0;

        switch (_operation) {
          case "+":
            result = _num1 + num2;
            break;
          case "-":
            result = _num1 - num2;
            break;
          case "×":
            result = _num1 * num2;
            break;
          case "÷":
            result = num2 != 0 ? _num1 / num2 : double.infinity;
            break;
        }

        if (result.isInfinite) {
          _output = "错误";
        } else if (result % 1 == 0) {
          _output = result.toInt().toString();
        } else {
          _output = result.toStringAsFixed(4);
          _output = _output.replaceAll(RegExp(r'0+$'), '');
          if (_output.endsWith('.')) _output = _output.substring(0, _output.length - 1);
        }

        _expression = "";
        _operation = "";
      } else if (buttonText == ".") {
        if (!_output.contains(".")) {
          _output += ".";
        }
      } else {
        if (_output == "0" || _output == "错误") {
          _output = buttonText;
        } else {
          _output += buttonText;
        }
      }
    });
  }

  Widget _buildButton(String text, {Color? bgColor, Color textColor = Colors.white, bool big = false}) {
    return Expanded(
      flex: big ? 2 : 1,
      child: Container(
        margin: const EdgeInsets.all(4),
        child: ElevatedButton(
          onPressed: () => _buttonPressed(text),
          style: ElevatedButton.styleFrom(
            backgroundColor: bgColor ?? Colors.grey[800],
            foregroundColor: textColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(20),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: big ? 28 : 24,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // 显示区域
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                alignment: Alignment.bottomRight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // 表达式
                    Text(
                      _expression,
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 结果
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      reverse: true,
                      child: Text(
                        _output,
                        style: const TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.w300,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 按钮区域
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    // 第一行
                    Expanded(
                      child: Row(
                        children: [
                          _buildButton("AC", bgColor: Colors.grey[600]),
                          _buildButton("⌫", bgColor: Colors.grey[600]),
                          _buildButton("%", bgColor: Colors.grey[600]),
                          _buildButton("÷", bgColor: Colors.orange),
                        ],
                      ),
                    ),

                    // 第二行
                    Expanded(
                      child: Row(
                        children: [
                          _buildButton("7"),
                          _buildButton("8"),
                          _buildButton("9"),
                          _buildButton("×", bgColor: Colors.orange),
                        ],
                      ),
                    ),

                    // 第三行
                    Expanded(
                      child: Row(
                        children: [
                          _buildButton("4"),
                          _buildButton("5"),
                          _buildButton("6"),
                          _buildButton("-", bgColor: Colors.orange),
                        ],
                      ),
                    ),

                    // 第四行
                    Expanded(
                      child: Row(
                        children: [
                          _buildButton("1"),
                          _buildButton("2"),
                          _buildButton("3"),
                          _buildButton("+", bgColor: Colors.orange),
                        ],
                      ),
                    ),

                    // 第五行
                    Expanded(
                      child: Row(
                        children: [
                          _buildButton("0", big: true),
                          _buildButton("."),
                          _buildButton("=", bgColor: Colors.orange),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}