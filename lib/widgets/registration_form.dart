import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../providers/playground_provider.dart';
import '../services/persistence_service.dart';

class RegistrationView extends ConsumerStatefulWidget {
  const RegistrationView({super.key});

  @override
  ConsumerState<RegistrationView> createState() => _RegistrationViewState();
}

class _RegistrationViewState extends ConsumerState<RegistrationView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  int _selectedDuration = 60; // Default
  List<int> _durationOptions = [];

  @override
  void initState() {
    super.initState();
    _loadDurations();
  }
  
  void _loadDurations() {
    final custom = PersistenceService.getCustomDurations();
    setState(() {
      _durationOptions = custom.isNotEmpty ? custom : [30, 60, 90, 120];
      if (!_durationOptions.contains(_selectedDuration) && _selectionDuration != 0) {
        _selectedDuration = _durationOptions.first;
      }
    });
  }

  int get _selectionDuration => _selectedDuration; // Helper

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      ref.read(activeKidsProvider.notifier).addKid(
        _nameController.text.trim(),
        _phoneController.text.trim(),
        _selectedDuration,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registered ${_nameController.text}!')),
      );
      
      // Reset form
      _nameController.clear();
      _phoneController.clear();
      setState(() {
        _selectedDuration = _durationOptions.isNotEmpty ? _durationOptions.first : 60;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text("New Entry", style: Theme.of(context).textTheme.headlineSmall),
                    const Gap(24),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: "Kid's Name",
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                    ),
                    const Gap(16),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      maxLength: 10,
                      decoration: const InputDecoration(
                        labelText: "Parent Mobile Number",
                        prefixIcon: Icon(Icons.phone),
                        hintText: "05xxxxxxxx",
                        counterText: "", // Hide character counter
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        if (!RegExp(r'^05\d{8}$').hasMatch(value)) return 'Must start with 05 and be 10 digits';
                        return null;
                      },
                    ),
                    const Gap(24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Duration", style: Theme.of(context).textTheme.titleMedium),
                        IconButton(
                          icon: const Icon(Icons.refresh, size: 16), 
                          onPressed: _loadDurations,
                          tooltip: 'Reload from settings',
                        ),
                      ],
                    ),
                    const Gap(8),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: [
                        ..._durationOptions.map((minutes) {
                          return ChoiceChip(
                            label: Text('$minutes mins'),
                            selected: _selectedDuration == minutes,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedDuration = minutes);
                              }
                            },
                          );
                        }),
                        ChoiceChip(
                          label: const Text('Open'),
                          selected: _selectedDuration == 0,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedDuration = 0);
                            }
                          },
                          selectedColor: Colors.blue.shade100,
                          labelStyle: TextStyle(
                            color: _selectedDuration == 0 ? Colors.blue.shade900 : null,
                            fontWeight: _selectedDuration == 0 ? FontWeight.bold : null,
                          ),
                        ),
                      ],
                    ),
                    const Gap(32),
                    ElevatedButton(
                      onPressed: _submit,
                      child: const Text("Start Timer"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
