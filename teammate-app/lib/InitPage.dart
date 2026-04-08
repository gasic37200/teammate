import 'package:flutter/material.dart';
import 'package:teammate_app/RegisterPage.dart';
import 'package:teammate_app/LoginPage.dart';

class InitPage extends StatefulWidget {
  const InitPage({super.key});

  @override
  State<InitPage> createState() => _InitPageState();
}

class _InitPageState extends State<InitPage> {

  Route _createRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var tween = Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
            .chain(CurveTween(curve: Curves.ease));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }

  void loginClicked() {
    Navigator.push(context, _createRoute(const LoginPage()));
  }

  void registerClicked() {
    Navigator.push(context, _createRoute(const RegisterPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 60.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Container(
                  width: 200, height: 200,
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.rectangle,
                  ),
                  child: Image.asset(
                    "assets/images/logo.png",
                    fit: BoxFit.fill,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.hub, size: 50, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                "teammate_app",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4.0,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "AI 기반 전문가 역량 분석 플랫폼",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w300,
                  color: Colors.grey,
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: loginClicked,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  ),
                  child: const Text("로그인", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 56,
                child: OutlinedButton(
                  onPressed: registerClicked,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.black, width: 1.5),
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  ),
                  child: const Text("회원가입", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black, letterSpacing: 1.5)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}