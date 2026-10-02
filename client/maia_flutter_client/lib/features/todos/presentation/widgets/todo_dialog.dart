import 'package:flutter/material.dart';
import '../../../../core/app_sizes.dart';

class TodoDialog extends StatefulWidget {
  final String? initialContent;
  
  // Jeśli initialContent jest null, to znaczy że TWORZYMY.
  // Jeśli ma wartość, to EDYTUJEMY.
  const TodoDialog({super.key, this.initialContent});

  @override
  State<TodoDialog> createState() => _TodoDialogState();
}

class _TodoDialogState extends State<TodoDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialContent);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop(_controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialContent != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.maxMobileWidth * 0.9),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isEditing ? Icons.edit_note : Icons.add_task, 
                      color: Colors.deepPurple,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isEditing ? "Edit Task" : "New Daily Task",
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                TextFormField(
                  controller: _controller,
                  minLines: 2,
                  maxLines: 5,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: const InputDecoration(
                    labelText: "Task description in English",
                    hintText: "e.g. Read 5 pages of an English book...",
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a task description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text("CANCEL"),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _submit,
                      child: Text(isEditing ? "SAVE CHANGES" : "ADD TASK"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}