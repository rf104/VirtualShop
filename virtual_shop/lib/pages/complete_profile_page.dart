import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:virtual_shop/pages/home_page.dart';
import 'package:virtual_shop/utils/loading_overlay.dart';
import 'package:virtual_shop/utils/supabase_service.dart';

class CompleteProfilePage extends StatefulWidget {
  final String email;
  const CompleteProfilePage({super.key, required this.email});

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _gender = '';
  String _userType = 'Normal User';
  String? _profile_image;
  DateTime? _selectedDate;
  bool _loading = false;
  String _error = '';
  String? _profileImageUrl;
  Uint8List? _pickedImageBytes;
  String? _pickedImageName;

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  Future<void> _prefill() async {
    final row = await SupabaseService.fetchUserProfile(widget.email);
    if (row != null) {
      setState(() {
        _nameCtrl.text = (row['name'] ?? '') as String;
        _phoneCtrl.text = (row['phone'] ?? '') as String;
        _gender = (row['gender'] ?? '') as String;
        _userType = (row['user_type'] ?? 'Normal User') as String;
        _profile_image = (row['profile_image'] ?? '') as String;
        final dobAny = row['dob'];
        if (dobAny != null) {
          final dobStr = dobAny.toString();
          _dobCtrl.text = dobStr.contains('T')
              ? dobStr.split('T').first
              : dobStr;
        }
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dobCtrl.text = picked.toIso8601String().split('T').first;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      // If a new image was picked, upload it first
      if (_pickedImageBytes != null && _pickedImageName != null) {
        final url = await SupabaseService.uploadProfileImageBytes(
          bytes: _pickedImageBytes!,
          filename: _pickedImageName!,
        );
        _profileImageUrl = url;
        await SupabaseService.setProfileImageUrlForUser(
          url,
          email: widget.email,
        );
      }

      await SupabaseService.updateUserProfile(
        email: widget.email,
        name: _nameCtrl.text.trim(),
        userType: _userType,
        gender: _gender,
        dobIso8601: _selectedDate?.toIso8601String() ?? _dobCtrl.text,
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        profileImageUrl: _profileImageUrl,
      );
      await SupabaseService.updateAuthMetadata({
        'name': _nameCtrl.text.trim(),
        'gender': _gender,
        'dob': _selectedDate?.toIso8601String() ?? _dobCtrl.text,
        'user_type': _userType,
        if (_profileImageUrl != null) 'avatar_url_custom': _profileImageUrl,
        if (_profileImageUrl != null) 'avatar_url': _profileImageUrl,
        if (_profileImageUrl != null) 'picture': _profileImageUrl,
        if (_phoneCtrl.text.trim().isNotEmpty) 'phone': _phoneCtrl.text.trim(),
      });
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete your profile')),
      body: LoadingOverlay(
        isLoading: _loading,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: _pickedImageBytes != null
                            ? MemoryImage(_pickedImageBytes!)
                            : (_profileImageUrl != null
                                  ? NetworkImage(_profileImageUrl!)
                                        as ImageProvider
                                  : const AssetImage(
                                      'assets/images/profile6.jpg',
                                    )),
                      ),
                      IconButton(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.camera_alt),
                        tooltip: 'Upload profile image',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Email: ${widget.email}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Full name*'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Please enter your name'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Mobile number*',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Please enter your mobile number'
                      : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _gender.isEmpty ? null : _gender,
                  items: const [
                    DropdownMenuItem(value: 'Male', child: Text('Male')),
                    DropdownMenuItem(value: 'Female', child: Text('Female')),
                  ],
                  onChanged: (v) => setState(() => _gender = v ?? ''),
                  decoration: const InputDecoration(labelText: 'Gender*'),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Please select gender' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _dobCtrl,
                  readOnly: true,
                  onTap: _pickDate,
                  decoration: const InputDecoration(
                    labelText: 'Date of Birth*',
                    hintText: 'Tap to select date',
                  ),
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Please pick your date of birth'
                      : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _userType,
                  items: const [
                    DropdownMenuItem(
                      value: 'Normal User',
                      child: Text('Normal User'),
                    ),
                    DropdownMenuItem(value: 'Seller', child: Text('Seller')),
                  ],
                  onChanged: (v) =>
                      setState(() => _userType = v ?? 'Normal User'),
                  decoration: const InputDecoration(labelText: 'User Type*'),
                ),
                const Spacer(),
                if (_error.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _error,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save,
                    child: const Text('Save & Continue'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(source: ImageSource.gallery);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      setState(() {
        _pickedImageBytes = bytes;
        _pickedImageName = file.name;
        _profileImageUrl = null; // will be replaced after upload
      });
    } catch (e) {
      setState(() => _error = 'Image pick failed: $e');
    }
  }
}
