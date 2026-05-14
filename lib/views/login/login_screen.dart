import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../dashboard/dashboard_page.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

enum AuthMode {
  login,
  register,
}

class _LoginScreenState extends State<LoginScreen> {
  static const Color navy = Color(0xFF0D1B2A);
  static const Color orange = Color(0xFFE47B3E);
  static const Color softBg = Color(0xFFEFF3F6);

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  AuthMode authMode = AuthMode.login;

  bool isPasswordHidden = true;
  bool isConfirmPasswordHidden = true;
  bool isLoading = false;

  bool get isLogin => authMode == AuthMode.login;

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void switchMode() {
    setState(() {
      authMode = isLogin ? AuthMode.register : AuthMode.login;
      usernameController.clear();
      passwordController.clear();
      confirmPasswordController.clear();
      isPasswordHidden = true;
      isConfirmPasswordHidden = true;
    });
  }

  Future<void> registerUser() async {
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (username.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      showMessage('Gagal', 'Semua field harus diisi.');
      return;
    }

    if (username.length < 4) {
      showMessage('Gagal', 'Username minimal 4 karakter.');
      return;
    }

    if (password.length < 6) {
      showMessage('Gagal', 'Password minimal 6 karakter.');
      return;
    }

    if (password != confirmPassword) {
      showMessage('Gagal', 'Konfirmasi password tidak sama.');
      return;
    }

    setState(() => isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final savedUsername = prefs.getString('username');

    await Future.delayed(const Duration(milliseconds: 500));

    if (savedUsername == username) {
      setState(() => isLoading = false);
      showMessage('Gagal', 'Username sudah terdaftar.');
      return;
    }

    await prefs.setString('username', username);
    await prefs.setString('password', password);
    await prefs.setString('email', '');
    await prefs.setString('photoUrl', '');
    await prefs.setBool('isRegistered', true);
    await prefs.setBool('isGoogleLogin', false);

    setState(() {
      isLoading = false;
      authMode = AuthMode.login;
      usernameController.clear();
      passwordController.clear();
      confirmPasswordController.clear();
      isPasswordHidden = true;
      isConfirmPasswordHidden = true;
    });

    showMessage('Berhasil', 'Akun berhasil dibuat. Silakan login.');
  }

  Future<void> loginUser() async {
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      showMessage('Gagal', 'Username dan password harus diisi.');
      return;
    }

    setState(() => isLoading = true);

    final prefs = await SharedPreferences.getInstance();

    final savedUsername = prefs.getString('username');
    final savedPassword = prefs.getString('password');

    await Future.delayed(const Duration(milliseconds: 500));

    setState(() => isLoading = false);

    if (savedUsername == null || savedPassword == null) {
      showMessage('Belum Ada Akun', 'Silakan register terlebih dahulu.');
      return;
    }

    if (username == savedUsername && password == savedPassword) {
      await prefs.setBool('isLoggedIn', true);
      await prefs.setBool('isGoogleLogin', false);

      Get.offAll(() => const DashboardPage());
    } else {
      showMessage('Login Gagal', 'Username atau password salah.');
    }
  }

  Future<void> loginWithGoogle() async {
    try {
      setState(() => isLoading = true);

      UserCredential userCredential;

      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();

        googleProvider.addScope('email');
        googleProvider.addScope('profile');

        userCredential = await FirebaseAuth.instance.signInWithPopup(
          googleProvider,
        );
      } else {
        final GoogleSignInAccount googleUser =
            await GoogleSignIn.instance.authenticate();

        final GoogleSignInAuthentication googleAuth =
            googleUser.authentication;

        final OAuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );

        userCredential = await FirebaseAuth.instance.signInWithCredential(
          credential,
        );
      }

      final User? user = userCredential.user;

      if (user == null) {
        setState(() => isLoading = false);
        showMessage('Gagal', 'Login Google dibatalkan.');
        return;
      }

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(
        'username',
        user.displayName ?? user.email ?? 'Google User',
      );
      await prefs.setString('email', user.email ?? '');
      await prefs.setString('photoUrl', user.photoURL ?? '');
      await prefs.setString('password', '');
      await prefs.setBool('isLoggedIn', true);
      await prefs.setBool('isRegistered', true);
      await prefs.setBool('isGoogleLogin', true);

      setState(() => isLoading = false);

      Get.offAll(() => const DashboardPage());
    } on FirebaseAuthException catch (e) {
      setState(() => isLoading = false);

      showMessage(
        'Login Google Gagal',
        e.message ?? 'Terjadi kesalahan Firebase Auth.',
      );
    } catch (e) {
      setState(() => isLoading = false);

      showMessage(
        'Login Google Gagal',
        e.toString(),
      );
    }
  }

  Future<void> submitAuth() async {
    if (isLogin) {
      await loginUser();
    } else {
      await registerUser();
    }
  }

  void showMessage(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: navy,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 14,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(24, 34, 24, 24),
                    decoration: BoxDecoration(
                      color: softBg,
                      borderRadius: BorderRadius.circular(34),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: 35,
                          offset: const Offset(0, 18),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildLogo(),
                        const SizedBox(height: 24),
                        Text(
                          isLogin ? 'SmartFloorPlan' : 'Buat Akun Baru',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: Colors.black87,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          isLogin
                              ? 'Masuk untuk mulai membuat desain rumah AI'
                              : 'Daftar untuk menyimpan dan mengelola desain denah rumah Anda',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 15,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 36),
                        _buildTextField(
                          controller: usernameController,
                          hintText: 'Masukkan Username',
                          icon: Icons.person_rounded,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: passwordController,
                          hintText: 'Masukkan Password',
                          icon: Icons.lock_rounded,
                          isPassword: true,
                          isHidden: isPasswordHidden,
                          onToggleHidden: () {
                            setState(() {
                              isPasswordHidden = !isPasswordHidden;
                            });
                          },
                        ),
                        if (!isLogin) ...[
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: confirmPasswordController,
                            hintText: 'Konfirmasi Password',
                            icon: Icons.verified_user_rounded,
                            isPassword: true,
                            isHidden: isConfirmPasswordHidden,
                            onToggleHidden: () {
                              setState(() {
                                isConfirmPasswordHidden =
                                    !isConfirmPasswordHidden;
                              });
                            },
                          ),
                        ],
                        const SizedBox(height: 18),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: isLoading ? null : switchMode,
                            child: Text(
                              isLogin
                                  ? 'Belum punya akun? Register'
                                  : 'Sudah punya akun? Login',
                              style: const TextStyle(
                                color: navy,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildMainButton(),
                        const SizedBox(height: 28),
                        _buildDivider(),
                        const SizedBox(height: 24),
                        _buildGoogleButton(),
                        const SizedBox(height: 28),
                        Text(
                          isLogin
                              ? 'Dengan login Anda menyetujui syarat dan ketentuan aplikasi.'
                              : 'Data akun manual disimpan secara lokal untuk kebutuhan demo aplikasi.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: navy,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: navy.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(
            Icons.architecture_rounded,
            color: Colors.white,
            size: 38,
          ),
          Positioned(
            right: 15,
            bottom: 15,
            child: Container(
              width: 9,
              height: 9,
              decoration: const BoxDecoration(
                color: orange,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    bool isHidden = false,
    VoidCallback? onToggleHidden,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? isHidden : false,
      keyboardType: TextInputType.text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: Colors.grey.shade600,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(
          icon,
          color: Colors.grey.shade700,
        ),
        suffixIcon: isPassword
            ? IconButton(
                onPressed: onToggleHidden,
                icon: Icon(
                  isHidden
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: Colors.grey.shade600,
                ),
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(
            color: Colors.grey.shade200,
          ),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(22)),
          borderSide: BorderSide(
            color: orange,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildMainButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: isLoading ? null : submitAuth,
        style: ElevatedButton.styleFrom(
          backgroundColor: navy,
          disabledBackgroundColor: navy.withOpacity(0.5),
          elevation: 6,
          shadowColor: navy.withOpacity(0.25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.4,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isLogin ? 'Log In' : 'Register',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    isLogin
                        ? Icons.arrow_forward_rounded
                        : Icons.person_add_alt_1_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: Colors.grey.shade300,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'atau lanjut dengan',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: Colors.grey.shade300,
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: isLoading ? null : loginWithGoogle,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: BorderSide(
            color: Colors.grey.shade300,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'G',
              style: TextStyle(
                color: Colors.black,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(width: 18),
            Text(
              'Login dengan Google',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}