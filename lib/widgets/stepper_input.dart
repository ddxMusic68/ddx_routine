import 'package:flutter/material.dart';

class StepperInput extends StatefulWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const StepperInput({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  State<StepperInput> createState() => _StepperInputState();
}

class _StepperInputState extends State<StepperInput> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toString());
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(StepperInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value &&
        !_focusNode.hasFocus &&
        _parse(_controller.text) != widget.value) {
      _controller.text = widget.value.toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  int? _parse(String text) => int.tryParse(text.trim());

  void _commit() {
    final parsed = _parse(_controller.text);
    if (parsed == null) {
      _controller.text = widget.value.toString();
      return;
    }
    final clamped = parsed.clamp(widget.min, widget.max).toInt();
    _controller.text = clamped.toString();
    if (clamped != widget.value) widget.onChanged(clamped);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(
          onPressed: widget.value > widget.min
              ? () => widget.onChanged(widget.value - 1)
              : null,
          constraints: const BoxConstraints.tightFor(
            width: 28,
            height: 28,
          ),
          padding: EdgeInsets.zero,
          iconSize: 16,
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.remove),
          tooltip: 'Decrease',
        ),
        SizedBox(
          width: 44,
          height: 36,
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            style: Theme.of(context).textTheme.titleMedium,
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _commit(),
            onEditingComplete: _commit,
            onTapOutside: (_) {
              _focusNode.unfocus();
              _commit();
            },
          ),
        ),
        IconButton.filledTonal(
          onPressed: widget.value < widget.max
              ? () => widget.onChanged(widget.value + 1)
              : null,
          constraints: const BoxConstraints.tightFor(
            width: 28,
            height: 28,
          ),
          padding: EdgeInsets.zero,
          iconSize: 16,
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.add),
          tooltip: 'Increase',
        ),
      ],
    );
  }
}
