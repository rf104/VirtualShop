import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:virtual_shop/pages/home_page.dart';
import 'package:virtual_shop/widgets/terms_conditions_dialog.dart';
import 'package:virtual_shop/utils/loading_overlay.dart';
import 'package:virtual_shop/utils/supabase_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthPage extends StatefulWidget {
  final int initialPage; // 0 for login, 1 for signup

  const AuthPage({super.key, this.initialPage = 0});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with TickerProviderStateMixin {
  late PageController _pageController;

  int currentPage = 0;

  // Login controllers
  final _loginFormKey = GlobalKey<FormState>();
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  bool isLoginPasswordVisible = false;
  bool rememberMe = false;
  String loginErrorMessage = '';

  // Signup controllers
  final _signupFormKey = GlobalKey<FormState>();
  final _signupNameController = TextEditingController();
  final _signupEmailController = TextEditingController();
  final _signupPasswordController = TextEditingController();
  final _signupConfirmPasswordController = TextEditingController();
  final _dateOfBirthController = TextEditingController(); // Add this
  bool isSignupPasswordVisible = false;
  bool isConfirmPasswordVisible = false;
  bool agreeToTerms = false;
  String signupErrorMessage = '';
  bool _isLoading = false;

  // Add these new variables
  String selectedGender = '';
  String selectedUserType = 'Normal User';
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    currentPage = widget.initialPage;
    _pageController = PageController(initialPage: widget.initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _signupNameController.dispose();
    _signupEmailController.dispose();
    _signupPasswordController.dispose();
    _signupConfirmPasswordController.dispose();
    _dateOfBirthController.dispose(); // Add this
    super.dispose();
  }

  void _animateToPage(int page) {
    setState(() {
      currentPage = page;
    });
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  // Login with Supabase
  Future<void> login() async {
    try {
      setState(() {
        _isLoading = true;
        loginErrorMessage = '';
      });
      final email = _loginEmailController.text.trim();
      final password = _loginPasswordController.text;
      if (!EmailValidator.validate(email) || password.isEmpty) {
        setState(() => loginErrorMessage = 'Enter valid credentials');
        return;
      }
      final res = await SupabaseService.signInWithEmail(
        email: email,
        password: password,
      );
      if (res.session != null) {
        if (!mounted) return;
        // Let AuthGate handle profile creation and completeness redirect
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    } catch (e) {
      setState(() => loginErrorMessage = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Signup logic with Supabase + profile
  Future<void> register() async {
    try {
      setState(() {
        _isLoading = true;
        signupErrorMessage = '';
      });
      final name = _signupNameController.text.trim();
      final email = _signupEmailController.text.trim();
      final password = _signupPasswordController.text;

      if (name.isEmpty || email.isEmpty || password.isEmpty) {
        setState(() => signupErrorMessage = 'Please fill in all fields');
        return;
      }
      if (selectedGender.isEmpty) {
        setState(() => signupErrorMessage = 'Please select your gender');
        return;
      }
      if (_dateOfBirthController.text.isEmpty) {
        setState(() => signupErrorMessage = 'Please select your date of birth');
        return;
      }
      if (!EmailValidator.validate(email)) {
        setState(
          () => signupErrorMessage = 'Please enter a valid email address',
        );
        return;
      }

      final res = await SupabaseService.signUpWithEmail(
        email: email,
        password: password,
        metadata: {
          'name': name,
          'gender': selectedGender,
          'dob': selectedDate?.toIso8601String(),
          'user_type': selectedUserType,
        },
      );

      if (res.user != null) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Verify your email'),
            content: const Text(
              'A verification link has been sent to your email. Please verify before logging in.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _animateToPage(0);
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => signupErrorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> googleAuth() async {
    try {
      setState(() => _isLoading = true);
      final webClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'] ?? '';
      final iosClientId = dotenv.env['GOOGLE_IOS_CLIENT_ID'];
      final res = await SupabaseService.signInWithGoogle(
        webClientId: webClientId,
        iosClientId: iosClientId,
      );
      if (res.session != null) {
        if (!mounted) return false;
        // Let AuthGate handle profile creation and completeness redirect
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
        return true;
      }
      return false;
    } catch (e) {
      setState(() => loginErrorMessage = e.toString());
      return false;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Add this method for date selection
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          selectedDate ??
          DateTime.now().subtract(
            const Duration(days: 365 * 18),
          ), // Default to 18 years ago
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6D9379),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        _dateOfBirthController.text =
            "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  // Add methods for showing popup dialogs
  Future<void> _showGenderDialog() async {
    final result = await showDialog<String>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3), // Lighter barrier
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white, // Ensure white background
          surfaceTintColor: Colors.white, // Remove material 3 tint
          title: const Text(
            'Select Gender',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6D9379),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildGenderOption('Male'),
              const SizedBox(height: 12),
              _buildGenderOption('Female'),
            ],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: const EdgeInsets.all(20),
          elevation: 8,
          shadowColor: Colors.black.withOpacity(0.1),
        );
      },
    );

    if (result != null) {
      setState(() {
        selectedGender = result;
      });
    }
  }

  Widget _buildGenderOption(String gender) {
    final isSelected = selectedGender == gender;
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop(gender);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6D9379).withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF6D9379)
                : const Color(0xFFE5E5E5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? const Color(0xFF6D9379)
                    : const Color(0xFFBDBDBD),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              gender,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF6D9379)
                    : const Color(0xFF333333),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showUserTypeDialog() async {
    final result = await showDialog<String>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3), // Lighter barrier
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white, // Ensure white background
          surfaceTintColor: Colors.white, // Remove material 3 tint
          title: const Text(
            'Select User Type',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6D9379),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildUserTypeOption('Normal User'),
              const SizedBox(height: 12),
              _buildUserTypeOption('Seller'),
            ],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: const EdgeInsets.all(20),
          elevation: 8,
          shadowColor: Colors.black.withOpacity(0.1),
        );
      },
    );

    if (result != null) {
      setState(() {
        selectedUserType = result;
      });
    }
  }

  Widget _buildUserTypeOption(String userType) {
    final isSelected = selectedUserType == userType;
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop(userType);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6D9379).withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF6D9379)
                : const Color(0xFFE5E5E5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? const Color(0xFF6D9379)
                    : const Color(0xFFBDBDBD),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              userType,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF6D9379)
                    : const Color(0xFF333333),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C2C2E),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: SafeArea(
          child: Column(
            children: [
              // Top section with dynamic title
              Container(
                height: MediaQuery.of(context).size.height * 0.35,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF2C2C2E),
                      Color(0xFF1C1C1E),
                      Color(0xFF000000),
                    ],
                    stops: [0.0, 0.6, 1.0],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      // Back button
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Dynamic title text with smooth transition
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            transitionBuilder:
                                (Widget child, Animation<double> animation) {
                                  return SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0.3, 0),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    ),
                                  );
                                },
                            child: SingleChildScrollView(
                              child: Column(
                                key: ValueKey<int>(currentPage),
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    currentPage == 0
                                        ? 'Welcome back!\nSign in to continue'
                                        : 'Ready to dive in?\nCreate your account',
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    currentPage == 0
                                        ? 'Sign in to enjoy the best shopping experience'
                                        : 'Join us today and start your shopping journey',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white.withOpacity(0.7),
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // White bottom section
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // Animated tab selector
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F8F8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Stack(
                          children: [
                            // Animated indicator
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOutCubic,
                              left: currentPage == 0
                                  ? 4
                                  : MediaQuery.of(context).size.width * 0.5 -
                                        24,
                              top: 4,
                              bottom: 4,
                              width:
                                  MediaQuery.of(context).size.width * 0.5 - 24,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Tab buttons
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => _animateToPage(0),
                                    child: Container(
                                      height: 50,
                                      margin: const EdgeInsets.all(4),
                                      child: Center(
                                        child: AnimatedDefaultTextStyle(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: currentPage == 0
                                                ? FontWeight.w600
                                                : FontWeight.w500,
                                            color: currentPage == 0
                                                ? Colors.black
                                                : Colors.grey[600],
                                          ),
                                          child: const Text('Login'),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => _animateToPage(1),
                                    child: Container(
                                      height: 50,
                                      margin: const EdgeInsets.all(4),
                                      child: Center(
                                        child: AnimatedDefaultTextStyle(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: currentPage == 1
                                                ? FontWeight.w600
                                                : FontWeight.w500,
                                            color: currentPage == 1
                                                ? Colors.black
                                                : Colors.grey[600],
                                          ),
                                          child: const Text('Register'),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 25),

                      // PageView for smooth transitions
                      Expanded(
                        child: PageView(
                          controller: _pageController,
                          onPageChanged: (index) {
                            setState(() {
                              currentPage = index;
                            });
                          },
                          children: [_buildLoginPage(), _buildSignupPage()],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Form(
        key: _loginFormKey,
        child: Column(
          children: [
            // Email field
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFF8F8F8), width: 1),
              ),
              child: TextFormField(
                controller: _loginEmailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  labelStyle: TextStyle(color: Color(0xFF6D9379), fontSize: 14),
                  prefixIcon: Icon(
                    Icons.email_outlined,
                    color: Color(0xFF6D9379),
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.black87, fontSize: 16),
                // COMMENTED OUT - Form validation
                /*
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!EmailValidator.validate(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
                */
              ),
            ),

            const SizedBox(height: 14),

            // Password field
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF8F8F8), width: 1),
              ),
              child: TextFormField(
                controller: _loginPasswordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: const TextStyle(
                    color: Color(0xFF6D9379),
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: Color(0xFF6D9379),
                    size: 20,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      isLoginPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: const Color(0xFF6D9379),
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        isLoginPasswordVisible = !isLoginPasswordVisible;
                      });
                    },
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                obscureText: !isLoginPasswordVisible,
                style: const TextStyle(color: Colors.black87, fontSize: 16),
                // COMMENTED OUT - Form validation
                /*
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
                */
              ),
            ),

            const SizedBox(height: 16),

            // Remember me and Forgot password
            Row(
              children: [
                Transform.scale(
                  scale: 0.8,
                  child: Checkbox(
                    value: rememberMe,
                    onChanged: (value) {
                      setState(() {
                        rememberMe = value ?? false;
                      });
                    },
                    activeColor: const Color(0xFF6D9379),
                    checkColor: Colors.white,
                    fillColor: WidgetStateProperty.resolveWith<Color?>((
                      Set<WidgetState> states,
                    ) {
                      if (states.contains(WidgetState.disabled)) {
                        return null;
                      }
                      if (states.contains(WidgetState.selected)) {
                        return const Color(0xFF6D9379);
                      }
                      return Colors.white;
                    }),
                    side: const BorderSide(color: Color(0xFF6D9379), width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const Text(
                  'Remember me',
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    // Forgot password logic
                  },
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6D9379),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            // Login button - Modified to not require validation
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF6D9379),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ElevatedButton(
                onPressed: () {
                  // COMMENTED OUT - Form validation requirement
                  // if (_loginFormKey.currentState!.validate()) {
                  //   login();
                  // }

                  // Direct call to login function without validation
                  login();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Login',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Or login with
            Text(
              'Or login with',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),

            const SizedBox(height: 16),

            // Google login button
            Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE5E5E5)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextButton.icon(
                onPressed: () async {
                  bool isLoggedIn = await googleAuth();
                  if (isLoggedIn) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Google Login successful!')),
                    );
                  }
                },
                icon: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Image.asset(
                    'assets/images/Google.png', // Updated to use your Google logo
                    width: 20,
                    height: 20,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF4285F4), // Google Blue
                              Color(0xFF34A853), // Google Green
                              Color(0xFFFBBC05), // Google Yellow
                              Color(0xFFEA4335), // Google Red
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'G',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                label: const Text(
                  'Sign in with Google',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            loginErrorMessage.isNotEmpty
                ? Column(
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        loginErrorMessage,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSignupPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Form(
        key: _signupFormKey,
        child: Column(
          children: [
            // Name field
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E5E5), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextFormField(
                controller: _signupNameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  labelStyle: TextStyle(color: Color(0xFF6D9379), fontSize: 14),
                  prefixIcon: Icon(
                    Icons.person_outline,
                    color: Color(0xFF6D9379),
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                style: const TextStyle(color: Colors.black87, fontSize: 16),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
            ),

            const SizedBox(height: 14),

            // Email field
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E5E5), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextFormField(
                controller: _signupEmailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address *',
                  labelStyle: TextStyle(color: Color(0xFF6D9379), fontSize: 14),
                  prefixIcon: Icon(
                    Icons.email_outlined,
                    color: Color(0xFF6D9379),
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.black87, fontSize: 16),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!EmailValidator.validate(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
            ),

            const SizedBox(height: 14),

            // Gender Selection - Updated to show popup
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E5E5), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: InkWell(
                onTap: _showGenderDialog,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.person_pin,
                        color: Color(0xFF6D9379),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Gender *',
                              style: TextStyle(
                                color: Color(0xFF6D9379),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              selectedGender.isEmpty
                                  ? 'Tap to select gender'
                                  : selectedGender,
                              style: TextStyle(
                                fontSize: 16,
                                color: selectedGender.isEmpty
                                    ? Colors.grey[600]
                                    : Colors.black87,
                                fontWeight: selectedGender.isEmpty
                                    ? FontWeight.normal
                                    : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_drop_down,
                        color: Color(0xFF6D9379),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Date of Birth field
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E5E5), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextFormField(
                controller: _dateOfBirthController,
                decoration: const InputDecoration(
                  labelText: 'Date of Birth *',
                  hintText: 'Tap to select date',
                  labelStyle: TextStyle(color: Color(0xFF6D9379), fontSize: 14),
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  prefixIcon: Icon(
                    Icons.calendar_today_outlined,
                    color: Color(0xFF6D9379),
                    size: 20,
                  ),
                  suffixIcon: Icon(
                    Icons.arrow_drop_down,
                    color: Color(0xFF6D9379),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                style: const TextStyle(color: Colors.black87, fontSize: 16),
                readOnly: true,
                onTap: () => _selectDate(context),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select your date of birth';
                  }
                  return null;
                },
              ),
            ),

            const SizedBox(height: 14),

            // User Type Selection - Updated to show popup
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E5E5), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: InkWell(
                onTap: _showUserTypeDialog,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.work_outline,
                        color: Color(0xFF6D9379),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'User Type *',
                              style: TextStyle(
                                color: Color(0xFF6D9379),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              selectedUserType,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_drop_down,
                        color: Color(0xFF6D9379),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Password field
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E5E5), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextFormField(
                controller: _signupPasswordController,
                decoration: InputDecoration(
                  labelText: 'Password *',
                  labelStyle: const TextStyle(
                    color: Color(0xFF6D9379),
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: Color(0xFF6D9379),
                    size: 20,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      isSignupPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: const Color(0xFF6D9379),
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        isSignupPasswordVisible = !isSignupPasswordVisible;
                      });
                    },
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                obscureText: !isSignupPasswordVisible,
                style: const TextStyle(color: Colors.black87, fontSize: 16),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
            ),

            const SizedBox(height: 14),

            // Confirm Password field
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E5E5), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextFormField(
                controller: _signupConfirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Confirm Password *',
                  labelStyle: const TextStyle(
                    color: Color(0xFF6D9379),
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: Color(0xFF6D9379),
                    size: 20,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      isConfirmPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Color(0xFF6D9379),
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        isConfirmPasswordVisible = !isConfirmPasswordVisible;
                      });
                    },
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                obscureText: !isConfirmPasswordVisible,
                style: const TextStyle(color: Colors.black87, fontSize: 16),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (value != _signupPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
            ),

            const SizedBox(height: 16),

            // Terms and conditions
            Row(
              children: [
                Transform.scale(
                  scale: 0.8,
                  child: Checkbox(
                    value: agreeToTerms,
                    onChanged: (value) {
                      setState(() {
                        agreeToTerms = value ?? false;
                      });
                    },
                    activeColor: const Color(0xFF6D9379),
                    checkColor: Colors.white,
                    fillColor: WidgetStateProperty.resolveWith<Color?>((
                      Set<WidgetState> states,
                    ) {
                      if (states.contains(WidgetState.disabled)) {
                        return null;
                      }
                      if (states.contains(WidgetState.selected)) {
                        return const Color(0xFF6D9379);
                      }
                      return Colors.white;
                    }),
                    side: const BorderSide(color: Color(0xFF6D9379), width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final result = await showDialog<bool>(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => const TermsConditionsDialog(),
                      );

                      if (result == true) {
                        setState(() {
                          agreeToTerms = true;
                        });
                      }
                    },
                    child: Text.rich(
                      TextSpan(
                        text: 'I agree to the ',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                        children: [
                          TextSpan(
                            text: 'Terms & Conditions',
                            style: const TextStyle(
                              color: Color(0xFF6D9379),
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            // Sign Up button with proper validation
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF6D9379),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ElevatedButton(
                onPressed: agreeToTerms
                    ? () {
                        if (_signupFormKey.currentState!.validate() &&
                            selectedGender.isNotEmpty) {
                          register();
                        } else if (selectedGender.isEmpty) {
                          setState(() {
                            signupErrorMessage = 'Please select your gender';
                          });
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Sign Up',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Or sign up with
            Text(
              'Or sign up with',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),

            const SizedBox(height: 16),

            // Google sign up button
            Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE5E5E5)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextButton.icon(
                onPressed: () async {
                  bool isLoggedIn = await googleAuth();
                  if (isLoggedIn) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Google Sign Up successful!'),
                      ),
                    );
                  }
                },
                icon: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Image.asset(
                    'assets/images/Google.png',
                    width: 20,
                    height: 20,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF4285F4), // Google Blue
                              Color(0xFF34A853), // Google Green
                              Color(0xFFFBBC05), // Google Yellow
                              Color(0xFFEA4335), // Google Red
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'G',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                label: const Text(
                  'Sign up with Google',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            if (signupErrorMessage.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                signupErrorMessage,
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),
            ],

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
