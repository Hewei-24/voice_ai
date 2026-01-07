import 'package:flutter/material.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _output = "0";
  String _expression = "";
  double _num1 = 0;
  double _num2 = 0;
  String _operand = "";

  void _buttonPressed(String buttonText) {
    setState(() {
      if (buttonText == "C") {
        _output = "0";
        _expression = "";
        _num1 = 0;
        _num2 = 0;
        _operand = "";
      } else if (buttonText == "+" || buttonText == "-" ||
          buttonText == "×" || buttonText == "÷") {
        _num1 = double.parse(_output);
        _operand = buttonText;
        _expression = "$_output $buttonText ";
        _output = "0";
      } else if (buttonText == "=") {
        _num2 = double.parse(_output);

        if (_operand == "+") {
          _output = (_num1 + _num2).toString();
        }
        if (_operand == "-") {
          _output = (_num1 - _num2).toString();
        }
        if (_operand == "×") {
          _output = (_num1 * _num2).toString();
        }
        if (_operand == "÷") {
          _output = (_num1 / _num2).toString();
        }

        // 移除小数点后多余的零
        if (_output.endsWith(".0")) {
          _output = _output.substring(0, _output.length - 2);
        }

        _expression = "";
        _num1 = 0;
        _num2 = 0;
        _operand = "";
      } else if (buttonText == ".") {
        if (!_output.contains(".")) {
          _output = "$_output.";
        }
      } else if (buttonText == "⌫") {
        if (_output.length > 1) {
          _output = _output.substring(0, _output.length - 1);
        } else {
          _output = "0";
        }
      } else {
        if (_output == "0") {
          _output = buttonText;
        } else {
          _output = _output + buttonText;
        }
      }
    });
  }

  Widget _buildButton(
      String buttonText, {
        Color? color,
        Color? textColor,
        double? fontSize,
      }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(4),
        child: ElevatedButton(
          onPressed: () => _buttonPressed(buttonText),
          style: ElevatedButton.styleFrom(
            backgroundColor: color ?? Colors.grey[200],
            foregroundColor: textColor ?? Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(20),
          ),
          child: Text(
            buttonText,
            style: TextStyle(
              fontSize: fontSize ?? 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter 计算器'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 显示区域
          Container(
            padding: const EdgeInsets.all(20),
            alignment: Alignment.centerRight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _expression,
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _output,
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // 按钮区域
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  // 第一行
                  Row(
                    children: [
                      _buildButton("C", color: Colors.red, textColor: Colors.white),
                      _buildButton("⌫", color: Colors.orange, textColor: Colors.white),
                      _buildButton("÷", color: Colors.orange, textColor: Colors.white),
                      _buildButton("×", color: Colors.orange, textColor: Colors.white),
                    ],
                  ),

                  // 第二行
                  Row(
                    children: [
                      _buildButton("7"),
                      _buildButton("8"),
                      _buildButton("9"),
                      _buildButton("-", color: Colors.orange, textColor: Colors.white),
                    ],
                  ),

                  // 第三行
                  Row(
                    children: [
                      _buildButton("4"),
                      _buildButton("5"),
                      _buildButton("6"),
                      _buildButton("+", color: Colors.orange, textColor: Colors.white),
                    ],
                  ),

                  // 第四行
                  Row(
                    children: [
                      _buildButton("1"),
                      _buildButton("2"),
                      _buildButton("3"),
                      _buildButton("=", color: Colors.orange, textColor: Colors.white),
                    ],
                  ),

                  // 第五行
                  Row(
                    children: [
                      _buildButton("0", fontSize: 28),
                      _buildButton("."),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}