import 'package:flutter/material.dart';

class PasswordField extends StatefulWidget {
  final String label;
  final String initialValue;
  final ValueChanged<String>? onChanged;

  const PasswordField({
    Key? key,
    required this.label,
    required this.initialValue,
    this.onChanged,
  }) : super(key: key);

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  late TextEditingController _passwordController;
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscureText,
          onChanged: widget.onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureText ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _obscureText = !_obscureText;
                });
              },
            ),
          ),
        ),
      ],
    );
  }
}
