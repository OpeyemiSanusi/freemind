import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
//import 'package:google_fonts/google_fonts.dart';
import 'package:introduction_screen/introduction_screen.dart';

class Onboarding extends StatefulWidget {
  @override
  _OnboardingState createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
//PAGE DECORATION
  final pageDecoration = PageDecoration(
      imagePadding: EdgeInsets.fromLTRB(0, 20, 0, 0),
      imageFlex: 1,
      titlePadding: EdgeInsets.fromLTRB(0, 33, 0, 0)
      //titleTextStyle: TextStyle(),
      //imageAlignment: Alignment.center,
      );

  //LIST OF PAGES
  List<PageViewModel> getPages() {
    return [
      PageViewModel(
        image: Image.asset(
          'assets/images/illustration_one.png',
          width: 560,
          alignment: Alignment.center,
          fit: BoxFit.contain,
        ),
        titleWidget: Text(
          'Share your secret\nanonymously without the\nfear of judgement',
          style: TextStyle(
            fontFamily: 'Poppins',
            color: Color(0xFF001F53),
            fontSize: 28,
          ),
          textAlign: TextAlign.center,
          // ),
        ),
        body: '',
        decoration: pageDecoration,
      ),
      PageViewModel(
        image: Image.asset(
          'assets/images/illustration_one.png',
          width: 560,
          alignment: Alignment.center,
          fit: BoxFit.contain,
        ),
        titleWidget: Text(
          'Share your secret\nanonymously without the\nfear of judgement',
          style: TextStyle(
            fontFamily: 'Poppins',
            color: Color(0xFF001F53),
            fontSize: 28,
          ),
          textAlign: TextAlign.center,
          // ),
        ),
        body: '',
        decoration: pageDecoration,
      ),
      PageViewModel(
        image: Image.asset(
          'assets/images/illustration_one.png',
          width: 560,
          alignment: Alignment.center,
          fit: BoxFit.contain,
        ),
        titleWidget: Text(
          'Share your secret\nanonymously without the\nfear of judgement',
          style: TextStyle(
            fontFamily: 'Poppins',
            color: Color(0xFF001F53),
            fontSize: 28,
          ),
          textAlign: TextAlign.center,
          // ),
        ),
        body: '',
        decoration: pageDecoration,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IntroductionScreen(
        //THE PLACE YOU PUT THE PAGES
        isTopSafeArea: true,
        /* globalHeader: Image.asset(
          'assets/images/logo.png',
          height: 35,
          alignment: Alignment.centerLeft,
          fit: BoxFit.fitHeight,
        ),*/
        globalBackgroundColor: Colors.white,
        pages: getPages(),
        done: Text('Done'),
        onDone: () {},
        showDoneButton: true,
        showNextButton: false,
        showSkipButton: false,
      ),
    );
  }
}
