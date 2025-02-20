import 'package:flutter/material.dart';
import 'package:instagram/pages/login_page.dart';
import 'package:instagram/widgets/onboarding.dart';
import 'package:shared_preferences/shared_preferences.dart';
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  int currentPage = 0;

  List<Map<String, String>> onboardingData = [
    {
      "image": "assets/images/onboard.jpg",
      "title": "Chào mừng đến với Instagram Clone",
      "description": "Chia sẻ khoảnh khắc đẹp với bạn bè và gia đình."
    },
    {
      "image": "assets/images/onboard1.jpg",
      "title": "Kết nối bạn bè",
      "description": "Tìm và kết bạn khắp thế giới dễ dàng."
    },
    {
      "image": "assets/images/onboard2.jpg",
      "title": "Chia sẻ hình ảnh",
      "description": "Đăng tải hình ảnh và video tuyệt đẹp của bạn."
    }
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:  Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: onboardingData.length,
              onPageChanged: (index) {
                setState(() {
                  currentPage = index;
                });
              },
              itemBuilder: (context, index) => Onboarding(
                image: onboardingData[index]["image"]!,
                title: onboardingData[index]["title"]!,
                description: onboardingData[index]["description"]!,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              onboardingData.length,
                  (index) => buildDot(index, context),
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              if (currentPage == onboardingData.length - 1) {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                prefs.setBool("onboarded", true);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              } else {
                _controller.nextPage(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.ease,
                );
              }
            },
            child: Text(currentPage == onboardingData.length - 1
                ? "Bắt đầu"
                : "Tiếp tục"),
          ),
          SizedBox(height: 40),
        ],
      ),
    );
  }
  Widget buildDot(int index, BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 5),
      width: currentPage == index ? 12 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: currentPage == index ? Colors.blue : Colors.grey,
        shape: BoxShape.circle,
      ),
    );
  }
}

