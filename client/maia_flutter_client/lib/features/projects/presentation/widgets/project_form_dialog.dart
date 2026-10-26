import 'package:flutter/material.dart';
import '../../../../core/app_sizes.dart';
import '../../data/models/project.dart';
import '../projects_ui.dart';

/// Formularz projektu. [project] == null -> tworzenie, w przeciwnym razie edycja.
/// Zwraca [ProjectDraft] (albo `null` po anulowaniu).
class ProjectFormDialog extends StatefulWidget {
  final Project? project;

  const ProjectFormDialog({super.key, this.project});

  static Future<ProjectDraft?> show(BuildContext context, {Project? project}) {
    return showDialog<ProjectDraft>(
      context: context,
      builder: (_) => ProjectFormDialog(project: project),
    );
  }

  @override
  State<ProjectFormDialog> createState() => _ProjectFormDialogState();
}

class _ProjectFormDialogState extends State<ProjectFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late String _color;

  bool get _isEditing => widget.project != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project?.name);
    _descriptionController = TextEditingController(text: widget.project?.description);
    _color = widget.project?.color ?? ProjectsUi.defaultColor;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final description = _descriptionController.text.trim();
    Navigator.of(context).pop(ProjectDraft(
      name: _nameController.text.trim(),
      description: description.isEmpty ? null : description,
      color: _color,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.maxMobileWidth * 0.9),
        child: SingleChildScrollView(
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
                      _isEditing ? Icons.edit_note : Icons.create_new_folder_outlined,
                      color: Colors.deepPurple,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _isEditing ? "Edit Project" : "New Project",
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  autofocus: !_isEditing,
                  maxLength: 100,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: "Project name",
                    hintText: "e.g. Prepare for the IELTS exam",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Please enter a project name'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  minLines: 2,
                  maxLines: 4,
                  maxLength: 1000,
                  decoration: const InputDecoration(
                    labelText: "Description (optional)",
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                Text("Color", style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _ColorPalettePicker(
                  selected: _color,
                  onSelected: (color) => setState(() => _color = color),
                ),
                const SizedBox(height: 24),
                // OverflowBar: na wąskich ekranach przyciski przechodzą pod siebie zamiast się ucinać
                OverflowBar(
                  alignment: MainAxisAlignment.end,
                  overflowAlignment: OverflowBarAlignment.end,
                  spacing: 8,
                  overflowSpacing: 8,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text("CANCEL"),
                    ),
                    FilledButton(
                      onPressed: _submit,
                      child: Text(_isEditing ? "SAVE CHANGES" : "CREATE PROJECT"),
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

class _ColorPalettePicker extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const _ColorPalettePicker({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final hex in ProjectsUi.palette)
          Semantics(
            button: true,
            selected: hex == selected.toUpperCase(),
            label: 'Color $hex',
            child: InkWell(
              onTap: () => onSelected(hex),
              customBorder: const CircleBorder(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: ProjectsUi.parseHex(hex),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: hex == selected.toUpperCase() ? Colors.black87 : Colors.transparent,
                    width: 2.5,
                  ),
                ),
                child: hex == selected.toUpperCase()
                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                    : null,
              ),
            ),
          ),
      ],
    );
  }
}
