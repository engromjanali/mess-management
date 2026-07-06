import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/core/di/injection.dart';
import 'package:clean_boilerplate/core/network/api_client.dart';
import 'package:clean_boilerplate/core/widgets/home_back_button.dart';
import 'package:clean_boilerplate/features/membership/data/membership_api_service.dart';
import 'package:flutter/material.dart';

class EditMessScreen extends StatefulWidget {
  const EditMessScreen({super.key});

  @override
  State<EditMessScreen> createState() => _EditMessScreenState();
}

class _EditMessScreenState extends State<EditMessScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  late final MembershipApiService _service;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _service = MembershipApiService(getIt<ApiClient>());
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final mess = await _service.getMessDetails();
      _nameController.text = mess['name'] as String? ?? '';
      _addressController.text = mess['address'] as String? ?? '';
      _emailController.text = mess['email'] as String? ?? '';
      _phoneController.text = mess['phone'] as String? ?? '';
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not load mess details.')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false) || _saving) return;
    setState(() => _saving = true);
    try {
      await _service.updateMess(name: _nameController.text.trim(), address: _addressController.text.trim(), email: _emailController.text.trim(), phone: _phoneController.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mess details updated.')));
      Navigator.of(context).pop();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not update mess details.')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const HomeBackButton(), title: const Text('Edit mess')),
      body: _loading
          ? const Center(child: CircularProgressIndicator.adaptive())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 700),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Mess name'), validator: (value) => (value ?? '').trim().isEmpty ? 'Mess name is required.' : null),
                          const SizedBox(height: Dimensions.paddingSizeDefault),
                          TextFormField(controller: _addressController, decoration: const InputDecoration(labelText: 'Address'), maxLines: 3),
                          const SizedBox(height: Dimensions.paddingSizeDefault),
                          TextFormField(controller: _emailController, decoration: const InputDecoration(labelText: 'Mess email'), keyboardType: TextInputType.emailAddress),
                          const SizedBox(height: Dimensions.paddingSizeDefault),
                          TextFormField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Mess phone'), keyboardType: TextInputType.phone),
                          const SizedBox(height: Dimensions.spaceLarge),
                          FilledButton.icon(onPressed: _saving ? null : _save, icon: _saving ? const SizedBox(width: Dimensions.iconSizeSmall, height: Dimensions.iconSizeSmall, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined), label: const Text('Save changes')),
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
