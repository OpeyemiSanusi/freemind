import 'dart:async';
import 'dart:io';
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:firebase_storage/firebase_storage.dart';
//import 'package:flutter_native_admob/native_admob_controller.dart';
//import 'package:flutter_native_admob/native_admob_options.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:freemind/models/timeline.dart';
import 'package:native_admob_flutter/native_admob_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_advanced_segment/flutter_advanced_segment.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:freemind/models/user.dart';
import 'package:freemind/pages/create_account.dart';
import 'package:freemind/pages/settings.dart';
import 'package:freemind/pages/sound_player.dart';
import 'package:freemind/pages/sound_recorder.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:uuid/uuid.dart';
//import 'package:flutter_native_admob/flutter_native_admob.dart';
import 'package:permission_handler/permission_handler.dart';

final GoogleSignIn googleSignIn = GoogleSignIn();
final Reference storageRef = FirebaseStorage.instance.ref();

final usersRef = FirebaseFirestore.instance.collection('users');
final postRef = FirebaseFirestore.instance.collection('posts');
final timelineRef = FirebaseFirestore.instance.collection('timeline');
late User currentUser;
late Timeline currentTimeline;
int showadint = 0;
AppOpenAd appOpenAd = AppOpenAd();
NativeAdController nativeAd = NativeAdController();

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List timelinePostIdData = [];
  bool sendcancelactive = false;
  bool isrecording = false;
  bool isplaying = false;
  bool doneplayingrecord = true;
  bool adShownAlready = false;
  bool noMoreAudio = false;
  var _selectedSegment_0 = AdvancedSegmentController('0');
  String _selectedindex = '0';
  //final _selectedIndex = _selectedSegment_0.toString();
  static const maxseconds = 30;
  static const maxrecsecs = 30;
  int timelineSecondsLeft = 1; //needs to divide to get a double..for the prog
  int recordsecs = maxrecsecs;
  Timer? rectimer;
  Timer? playerTimer;
  Timer? playertimer;
  Timer? adTimer;
  final recorder = SoundRecorder(); //created an instance of SoundRecorder
  final player = SoundPlayer();
  bool isAuth = false;
  final timestamp = DateTime.now();
  late File audiofile;
  late String postId;
  late String timelineId;
  // final playerDurationgetter = AudioPlayer(); //from justAudio
  Duration? getduration;
  late String appDocPath;
  late int numberOfTimelineAudioAvailable;
  Random random = Random();
  late int randomNumber;
  int timelineAudioDuration = 1; //needs to divide to get a double..for the prog
  String pickedPostId = '';
  String timelineUsername = '';
  int audioDurationV2 = 0;
  bool isLoading = false;
  //static const _adUnitID = "ca-app-pub-3940256099942544/2247696110";
  //final _nativeAdController = NativeAdmobController();
  late dynamic
      currentUserId; //this would be equal to currentUser.id but not here because we have to wait for it to get that value
  late var now;
  late String timeformatter;

  login() {
    googleSignIn.signIn();
  }

  /*getAppsRootDir() async {
    //to get the root directory so we can use to find the audio file also get
    //..it to work on other os like iphone
    //form the package path provider
    final appDocDir = await getTemporaryDirectory();
    String appDocPath = appDocDir.path;
    print(appDocPath);
  } */

  @override
  void initState() {
    loadOpenAppAd();
    recorder
        .init(); //calling the init method of SoundRecorder() we created in our home's initstate
    player.init();
    _selectedSegment_0.addListener(() {
      //for the tab switching....selectedsegment.value gives a value of 0 or 1 as set in the tab design part....so i created a string variable _selectedindex to accept the value anytime it changes...also set it to 0 so it would represent the first page...to listen for change we used the callback listener .addlistener
      setState(() {
        //selectedsegment.alue become 1 when you click on talk
        //then i put the value in selected index to use to change the page
        _selectedindex = _selectedSegment_0.value.toString();
      });
      //print(_selectedindex);
    });

    googleSignIn.onCurrentUserChanged.listen((account) {
      handleSignin(account);
    }, onError: (err) {
      print('OPE there was an error: $err');
    });

    //reauthenticate user
    googleSignIn.signInSilently(suppressErrors: false).then((account) {
      handleSignin(account);
    }).catchError((err) {
      print('Error signing in: $err');
    });
  }

  handleSignin(account) async {
    if (account != null) {
      print('ope acct is not null');
      await createUserInFirestore();
      setState(() {
        isAuth = true;
      });
    } else {
      setState(() {
        isAuth = false;
      });
    }
  }

  createUserInFirestore() async {
    //check if user exists in users collection in database
    final user = googleSignIn.currentUser;

    DocumentSnapshot doc = await usersRef.doc(user!.id).get();
    print('the snapshot results: $doc');

    //if the user does not exist take them to 'create account page'
    if (!doc.exists) {
      //Navigator.push(
      // context, MaterialPageRoute(builder: (context) => CreateAccount()));
      final username = await Navigator.push(
          context, MaterialPageRoute(builder: (context) => CreateAccount()));

      //Use the username gotten from createact Navigator to create doc in user db
      usersRef.doc(user.id).set({
        "id": user.id,
        "username": username,
        "email": user.email,
        "timestamp": timestamp,
        "isAdmin": false,
      });

      //after creating the user try to get doc again
      //so you can pass it to the user model
      doc = await usersRef.doc(user.id).get();
    }

// comes from the user model
// we want to pass all the info from the variable 'doc' into it
    currentUser = User.fromDocument(doc);
    currentUserId = currentUser.id;
    print(currentUser.username);
    //Load the first audio that would play
    //since the play button should only play the audio not fetch a new one
    //could not put it in init becuase it depends on createUser being initialised
    getAudioInTimeline();
  }

  @override
  void dispose() {
    player.dispose();
    recorder.dispose();
    rectimer?.cancel();
    playerTimer?.cancel();
    playertimer?.cancel();
    adTimer?.cancel();

    // _nativeAdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //getAudioInTimeline();
    return Scaffold(
      backgroundColor: Colors.white,
      body: isAuth ? buildAuthScreen() : buildUnAuthScreen(),
    );
  }

  buildUnAuthScreen() {
    // currentUserStateListener();
    if (isLoading == true)
      return loadingPage();
    else
      _selectedSegment_0.value = '0'; //make sure it stats at listen page
    setState(() {});
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 650.w,
            height: 200.h,
            //color: Colors.black,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/logo.png'),
              ),
            ),
          ),
          SizedBox(
            height: 30.h,
          ),
          GestureDetector(
            onTap: () {
              login();
            },
            child: Container(
              width: 800.w,
              height: 200.h,
              // color: Colors.black,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/sign_in_button.png'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  buildAuthScreen() {
    //initState();
    //getAudioInTimeline(); //this is to load
    if (isLoading == true)
      return loadingPage();
    else
      return Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                  65.w, 45.h, 0, 110.h), //25, 15 = 40.h, 0, 40
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    height: 125.h, //52
                    width: 520.w, //230
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(
                          'assets/images/logo.png',
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      isAuth = await Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (c, a1, a2) =>
                              SettingsPage(), //for animation i don't understand it just copied and pasted :)
                          transitionsBuilder: (c, anim, a2, child) =>
                              FadeTransition(opacity: anim, child: child),
                          transitionDuration: Duration(milliseconds: 300),
                        ),
                        // MaterialPageRoute(builder: (context) => SettingsPage()),
                      );
                      if (isAuth == false) {
                        //put it back on the Listen page
                        //determines the
                        // _selectedSegment_0 = AdvancedSegmentController('0');
                        //_selectedindex = '0'; //determines the page being built
                        //make the record button default again or
                        //if someone recorded and did not post
                        //then logs ou and logs in with another account
                        //it would go straight to the talk page with
                        //the audio still there
                        //I still would like to take him to the listen page
                        //so i would change that later
                        resetRecordParameters();
                        //then refresh
                        setState(() {});
                      }
                    },
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(0, 0, 85.w, 0),
                      child: Icon(
                        Icons.settings,
                        size: 100.sp,
                      ),
                    ),
                  )
                ],
              ),
            ),
            Center(
              child: Padding(
                padding: EdgeInsets.fromLTRB(0, 0, 0, 95.h), //0, 0, 0, 35
                child: AdvancedSegment(
                  controller: _selectedSegment_0,
                  segments: {
                    '0': 'Listen',
                    '1': 'Talk',
                  },
                  activeStyle: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontSize: 70.sp, //25
                    fontWeight: FontWeight.w700,
                  ),
                  inactiveStyle: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontSize: 60.sp, //20
                      fontWeight: FontWeight.w700),
                  backgroundColor: Color(0xff246ee9),
                  sliderColor: Color(0xff001f53),
                  borderRadius: BorderRadius.all(
                    Radius.circular(25.0), // 7
                  ),
                  itemPadding:
                      EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                ),
              ),
            ),
            Center(
              child: int.parse(_selectedindex) == 0
                  ? buildlistensection()
                  : buildtalksection(),
            ),
          ],
        ),
      );
  }

  buildtalksection() {
    return Container(
      // color: Colors.black,
      width: 1000
          .w, //calculated this by turning it black to see the space it would take if not things inside can overflow
      height: 1300.h,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 170.h),
            child: Text(
              'SHARE A \nSECRET OR A THOUGHT',
              textAlign: TextAlign.center,
              style: TextStyle(
                height: 3.h,
                fontFamily: 'Poppins',
                fontSize: 70.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: -1.2,
                color: Color(0xff001f53),
              ),
            ),
          ),
          buildRecordCard(),
          // buildrecbutton()
          //buildplayandcancelbutton()
          if (isrecording == false && sendcancelactive == false)
            buildrecbutton()
          else if (isrecording == true && sendcancelactive == false)
            buildstopbutton()
          else
            buildpostandcancelbutton(),
        ],
      ),
    );
  }

  buildlistensection() {
    return Column(
      children: [
        noMoreAudio == true ? buildPlayerCardNoAudio() : buildPlayerCard(),
        buildNextButton(),
      ],
    );
  }

  buildpostandcancelbutton() {
    stopRecTimer();
    return Container(
      // color: Colors.black,
      height: 350.h,
      width: 1000.w,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                resetRecordParameters();
              });
            },
            child: Container(
              height: 350.h,
              width: 350.h,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(
                    'assets/images/cancel_button.png',
                  ),
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      content: Text('Are you sure you want to post this?'),
                      actions: [
                        TextButton(
                          style: TextButton.styleFrom(
                            textStyle: TextStyle(color: Colors.blue),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text('CANCEL'),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            textStyle: TextStyle(color: Colors.blue),
                          ),
                          onPressed: () async {
                            isLoading = true;
                            setState(() {});
                            Navigator.pop(context);
                            await getAudioFilePath();
                            postId = Uuid().v4();
                            var uploadTask = await storageRef
                                .child("post_$postId.aac")
                                .putFile(audiofile);
                            print('ope audiofile uploaded');
                            //get time

                            now = DateTime.now();
                            timeformatter = DateFormat('yMMMMd')
                                .add_jm()
                                .format(now); // 28/03/2020
                            //get upload url
                            String downloadUrl =
                                await uploadTask.ref.getDownloadURL();
                            // String downloadUrl2 = await storageRef.getDownloadURL();
                            print(downloadUrl);
                            //print(downloadUrl2);
                            await createPostInFirestore(
                              mediaUrl: downloadUrl,
                              postId: postId,
                              audioDuration: audioDurationV2.toString(),
                            );
                            //Navigator.pop(context);

                            showToast(
                                message: 'Posted Successfully!',
                                toastGravity: ToastGravity.BOTTOM);
                            resetRecordParameters();
                            isLoading = false;
                            setState(() {});
                          },
                          child: Text('POST'),
                        ),
                      ],
                    );
                  });
            },
            child: Container(
              height: 350.h,
              width: 350.h,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(
                    'assets/images/post_button.png',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  buildstopbutton() {
    return GestureDetector(
      onTap: () async {
        await recorder.stop(); //stop recording
        setState(() {
          sendcancelactive = true; //make so it can display the third button
          isrecording = recorder
              .isRecording; //so isrecording would now equal what the recorder's state is
          print("recorder is recording ${recorder.isRecording}");
        });
      },
      child: Container(
        height: 350.h,
        width: 350.h,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              'assets/images/record_stop_button.png',
            ),
          ),
        ),
      ),
    );
  }

  buildrecbutton() {
    //isrecording = recorder.isRecording; //get the state(T or F) from the class
    //isrecording = await recorder.isRecording; //get the state(T or F) from the class
    print("before tap: recorder is recording ${recorder.isRecording}");

    return GestureDetector(
      onTap: () async {
        stopRecTimer(); //first reset the timer incase of anything
        await recorder
            .toggleRecording(); //wait for the result before you setstate

        setState(() {
          startRecTimer(); //start the timer when recording starts so it can make the linear progress move

          isrecording = recorder
              .isRecording; //so isrecording would now equal what the recorder's state is

          print("recorder is recording ${recorder.isRecording}");
        });
      },
      child: Container(
        height: 350.h,
        width: 350.h,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              'assets/images/record_button.png',
            ),
          ),
        ),
      ),
    );
  }

  buildRecordCard() {
    return Padding(
      padding: EdgeInsets.only(bottom: 95.h), //prviously 35.0
      child: Container(
        //width: MediaQuery.of(context).size.width * 0.79,
        // height: MediaQuery.of(context).size.width * 0.79, //used width for heigth so it could be a square
        //color: Colors.black,
        width: ScreenUtil().setWidth(880),
        height: ScreenUtil().setHeight(300),
        child: Card(
          elevation: 10,
          margin: EdgeInsets.zero, //to remove defualt padding or margin
          color: Color(0xff246ee9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30), //5
          ),
          child: Column(
            //mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 35.h),
                child: Text(
                  currentUser.username,
                  style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontSize: 55.sp, //18
                      fontWeight: FontWeight.w200),
                ),
              ),
              SizedBox(height: 20.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 50.h),
                child: Row(
                  children: [
                    if (sendcancelactive == true)
                      GestureDetector(
                        onTap: () async {
                          setState(() {
                            doneplayingrecord = false;
                          });
                          //doneplayingrecord = false;
                          await player.togglePlayer(() {
                            setState(() {
                              //do when finished
                              //its a callback for when the player finishes
                              doneplayingrecord = true;
                              // print('I am done playing');
                            });
                          });
                        },
                        child: doneplayingrecord == true
                            ? Icon(
                                Icons.play_arrow,
                                size: 90.sp,
                                color: Colors.white,
                              )
                            : Icon(
                                Icons.pause,
                                size: 90.sp,
                                color: Colors.white,
                              ),
                      )
                    else
                      Icon(
                        Icons.circle,
                        size: 90.sp,
                        color: Colors.white,
                      ),
                    SizedBox(
                      width: 20.w,
                    ),
                    Container(
                      //color: Colors.black,
                      width: 650.w,
                      height: 20.h,
                      child: LinearProgressIndicator(
                        backgroundColor: Color(0xff6a9ef4),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xff001f53)),
                        value: 1 - recordsecs / maxrecsecs,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  getAudioFilePath() async {
    //to get the root directory so we can use to find the audio file also get
    //..it to work on other os like iphone
    //form the package path provider
    final appDocDir = await getTemporaryDirectory();
    appDocPath = appDocDir.path;

    audiofile = File('$appDocPath/audio_example.aac');
    /* if (await audiofile.exists()) {
      print('Ope file exist');
    } else
      print('Ope file does not exist'); */
  }

  buildPlayerCardNoAudio() {
    return Padding(
      padding: EdgeInsets.only(bottom: 95.h),
      child: Container(
        width: ScreenUtil().setWidth(880),
        height: ScreenUtil().setWidth(880),
        child: Card(
          elevation: 10,
          margin: EdgeInsets.zero, //to remove defualt padding or margin
          color: Color(0xff246ee9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(67), //5 or 67
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('No More Available Audio'),
                ElevatedButton(
                    onPressed: () {
                      _selectedSegment_0.value = '1';
                      setState(() {});
                    },
                    child: Text('Record Yours'))
              ],
            ),
          ),
        ),
      ),
    );
  }

  buildPlayerCard() {
    return Padding(
      padding: EdgeInsets.only(bottom: 95.h), //prviously 35.0
      child: Stack(
        children: [
          Container(
            //width: MediaQuery.of(context).size.width * 0.79,
            // height: MediaQuery.of(context).size.width * 0.79, //used width for heigth so it could be a square
            // color: Colors.black,
            width: ScreenUtil().setWidth(880),
            height: ScreenUtil().setWidth(880),
            child: Card(
              elevation: 10,
              margin: EdgeInsets.zero, //to remove defualt padding or margin
              color: Color(0xff246ee9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(67), //5 or 67
              ),
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 65.h), //25
                    child: Text(
                      timelineUsername,
                      style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Poppins',
                          fontSize: 55.sp, //18
                          fontWeight: FontWeight.w200),
                    ),
                  ),
                  SizedBox(height: 80.h),
                  buildProgressPlayPause()
                ],
              ),
            ),
          ),
          Visibility(
            //how many recording i want before ad shows
            visible: showadint >= 1 ? true : false,
            child: Container(
              //for advertisments
              width: ScreenUtil().setWidth(880),
              height: ScreenUtil().setWidth(880),

              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(240.w, 45.h, 0, 0),
                        child: Text(
                          'Advertisement',
                          style: TextStyle(
                              backgroundColor: Color(0xff246ee9),
                              color: Colors.white,
                              fontFamily: 'Poppins',
                              fontSize: 55.sp, //18
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(75.w, 40.h, 0, 0),
                        child: GestureDetector(
                          onTap: () {
                            adShownAlready =
                                true; //show it won't show after the first time
                            showadint = 0;
                            //_nativeAdController.dispose();

                            // _nativeAdController.reloadAd(
                            //    forceRefresh: true, numberAds: 1);
                            //startAdTimer();
                            setState(() {});
                          },
                          child: Icon(
                            Icons.close,
                            size: 90.sp,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: Divider(
                      color: Colors.white,
                      thickness: 1.5,
                    ),
                  ),
                  NativeAd(
                    buildLayout: mediumAdTemplateLayoutBuildercustom,
                    headline: AdTextView(
                      style: TextStyle(color: Colors.white),
                      maxLines: 1,
                    ),
                    body: AdTextView(
                      margin: EdgeInsets.only(bottom: -15),
                      style: TextStyle(color: Colors.white, fontSize: 40.sp),
                    ),
                    //media: AdMediaView(height: 140),
                    loading: Text('loading'),
                    error: Text('error'),
                    builder: (context, child) {
                      return Container(
                        color: Color(0xff246ee9),
                        //to resize the ad
                        margin: EdgeInsets.fromLTRB(60.sp, 0.sp, 60.sp,
                            0.sp), //75 0 75 0 without the white line
                        height: 700.h, //260

                        child: child,
                      );
                    },
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  buildProgressPlayPause() {
    return Container(
      //height: MediaQuery.of(context).size.width * 0.4,
      //width: MediaQuery.of(context).size.width * 0.4,
      height: ScreenUtil().setWidth(430),
      width: ScreenUtil().setWidth(430),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            //timelineSecondsLeft & timelineAudioDuration start at the same value
            //every 1 sec timelineSecondsLeft reduces by 1 with the fuction...
            //...startPlayerTimer()
            value: 1 - timelineSecondsLeft / timelineAudioDuration,
            strokeWidth: 45.h, //15
            valueColor: AlwaysStoppedAnimation(Color(0xff001F53)),
            backgroundColor: Color(0xff6a9ef4),
          ),
          Center(
            child: isplaying == false
                ? GestureDetector(
                    onTap: () {
                      isplaying = true;
                      setState(() {
                        //playPauseAudioInTimeline();
                        if (player.checkifAudioisPaused() == true) {
                          //check to see if its paused
                          //if it is paused, resume
                          player.resumeListenPage();
                          startPlayerTimer(); //continue the countdown
                        }
                        //fetch a new one
                        if (player.checkifAudioisPaused() == false) {
                          playAudioInTimeline();
                        }
                      });
                    },
                    child: Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 90,
                    ),
                  )
                : GestureDetector(
                    onTap: () {
                      isplaying = false;
                      setState(() {
                        playPauseAudioInTimeline();
                        //pause audio
                        //pause timer(circular progress)
                      });
                    },
                    child: Icon(
                      Icons.pause,
                      color: Colors.white,
                      size: 90,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  addOneToANumber() {}
  buildNextButton() {
    return GestureDetector(
      onTap: () async {
        /* timelineRef
            .where('username', isNotEqualTo: currentUser.username)
            .get()
            .then((snapshot) {
          snapshot.docs.forEach((doc) {
            var testmap = Timeline.fromDocument(doc);
            //print(testmap.played[currentUserId]);

            if (testmap.played[currentUserId] == null) {
              newdata.add(testmap.mediaUrl);
            }
            

          

            //FIGURE OUT HOW TO AWAIT SO IT DOESNT BRING NULL RESULT AT FIRST
            //TO DO - USE THE LENGTH OF NEWDATA TO SET AS MAX FOR RANDOM NUMBER GENERATION
            //TO DO - USE THE RANDOM NUMBER TO PICK THE NUMBER FROM THE LIST TO PLAY

            //print(doc.data());
            //if (doc['played'] == 'opeyemi') {
            //newdata.add(1);
            // }
          });
        });
        */
        timelinePostIdData = [];
        QuerySnapshot snapshot = await timelineRef
            .where('username', isNotEqualTo: currentUser.username)
            .get();

        snapshot.docs.forEach((doc) {
          var testmap = Timeline.fromDocument(doc);
          if (testmap.played[currentUserId] == null) {
            timelinePostIdData.add(testmap.mediaUrl);
          }
        });

        print(timelinePostIdData);

        /* stopPlayerTimer();
        //it's suppose to fecth the audio
        //then play the audio
        getAudioInTimeline();
        playAudioInTimeline();
        isplaying = true;
        print('isAuth: $isAuth');
        print(recorder.isRecorderInitialised);
        //recorder.toggleRecording();
        print(recorder.isRecording);

        //startPlayTimer(); //seconds / maxsdconds to get % and 1 - to flip the indicators direction
        //_selectedSegment_0.addListener(() {
        // _selectedSegment_0.value;
        // });
        // print(_selectedSegment_0.value);
        print(_selectedindex);
        */
      },
      child: Container(
        child: Center(
          child: Text(
            'NEXT',
            style: TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
                fontSize: 70.h, //25
                fontWeight: FontWeight.w700),
          ),
        ),
        width: 600.w, //MediaQuery.of(context).size.width * 0.5,
        height: 200.h, //MediaQuery.of(context).size.height * 0.1,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(
            Radius.circular(25), //5
          ),
          color: Color(0xff001f53),
        ),
      ),
    );
  }

  /* 
  //it was getting null so i made another version
  //"AudioDurationV2"
  getAudiofileDuration() async {
    //this is to get the duration the result is like
    // example - 0:00:29.930303 so we would extract just the 29
    getduration = await playerDurationgetter
        .setUrl('$appDocPath/audio_example.aac')
        .catchError((e) {
      print('ope this is $e');
    });
    print('1 Ope this is the duration V.1 $getduration');
    print('1 Ope this is the duration V.2 $audioDurationV2');
    //get it in seconds
    var audiodurationinsec = getduration?.inSeconds;
    /* for (audiodurationinsec = getduration?.inSeconds;
        audiodurationinsec == null;
        audiodurationinsec = getduration?.inSeconds)*/
    if (audiodurationinsec != null) {
      audiodurationinsec = audiodurationinsec + 1;
    } else {
      print('error fetching audio secs');
    }
    print('2 Ope this is the duration $audiodurationinsec');

    return audiodurationinsec;
  }

  getfinalAudioFileDuration()async{
     // getAppsRootDir();
        await getAudioFilePath();
        //upload file
        if (await audiofile.exists()) {
       //get the duration and convert it to string
         //we have to wait for it to to finish before converting it to string
       //or we would get an instance of Future
      var audioDurationn = await getAudiofileDuration();
       //sometimes it comes back null so let it try it again
        //replace with a for loop until it gets a result that's not null
        if (audioDurationn == null) {
         audioDurationn = await getAudiofileDuration();
         }

        String audioDuration = audioDurationn.toString();
         //to use in firestore model
         //I made the post id here because i want it to change everytime
         //if i make it a global variable it would only generate once
         //if a user should upload twice it would replace it
  }
  */

  createPostInFirestore(
      {String? mediaUrl, String? postId, String? audioDuration}) {
    //still gonna add time later
    //create post
    postRef.doc(currentUser.id).collection('usersPosts').doc(postId).set({
      'postId': postId,
      'ownerId': currentUser.id,
      'username': currentUser.username,
      'mediaUrl': mediaUrl,
      'audioDuration': audioDuration,
      'isApproved': false,
    });

    // timelineId = Uuid().v4();
    timelineRef.doc(postId).set({
      'postId': postId,
      'ownerId': currentUser.id,
      'username': currentUser.username,
      'mediaUrl': mediaUrl,
      'audioDuration': audioDuration,
      'isApproved': false,
      'played': {},
      'time': timeformatter,
    });
  }

  createAlertBox() {
    return AlertDialog(
      content: Text('Are you sure you want to post this?'),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            textStyle: TextStyle(color: Colors.blue),
          ),
          onPressed: () {},
          child: Text('CANCEL'),
        ),
      ],
    );
  }

  dynamic getAudioInTimeline() async {
    timelinePostIdData = [];
    QuerySnapshot snapshot = await timelineRef
        .where('username', isNotEqualTo: currentUser.username)
        .get();

    snapshot.docs.forEach((doc) {
      var testmap = Timeline.fromDocument(doc);
      if (testmap.played[currentUserId] == null) {
        timelinePostIdData.add(testmap.postId);
      }
    });

    print(timelinePostIdData);
    //First get all the documents that are not created by our username
    /* QuerySnapshot snapshot = await timelineRef
        .where('username', isNotEqualTo: currentUser.username)
        //.where('played.${currentUser.id}', isEqualTo: null)
        //.where('played.${currentUser.id}', isEqualTo: null)
        //.where('played.${currentUser.id}', isNotEqualTo: false)
        //.where('played.$currentUserId', isEqualTo: !true)
        //.where('played.$currentUserId', isNotEqualTo: true)
        //.where('played', isEqualTo: !currentUserId)
        .get();
        */
    //then the query we get - get it has document >> map
    //after making it a map request only the mediaUrl
    //convert it to list so that we can use a random number to call...
    //...a figure in the list like 'data[1]'

    /*List<dynamic> alldata = snapshot.docs.map((doc) => doc['postId']).toList();
    print('Ope Snapshot ${snapshot}');
    print('Ope Data ${alldata}');
    */

    //get the lenght of the list which is the lenght of all the document
    //we need it to set a limit for our random number
    numberOfTimelineAudioAvailable = timelinePostIdData.length;
    print('Ope length ${timelinePostIdData.length}');
    print(timelinePostIdData);
    //generate random number between 1 & numberOfTimelineAudio
    //to use to get a random number from the list of available document
    //so the document can be random everytime
    //random number from 0 to our available amount of document
    if (numberOfTimelineAudioAvailable > 0) {
      randomNumber = random.nextInt(numberOfTimelineAudioAvailable);
      print('Ope ${randomNumber}');
      //
      //print(alldata[randomNumber]);
      //await player.playListenPage(url: alldata[randomNumber]);
      pickedPostId = timelinePostIdData[randomNumber];
      DocumentSnapshot finalsnapshot =
          await timelineRef.doc(pickedPostId).get();

      print('Ope FinalSnapshot = $finalsnapshot');
      currentTimeline = Timeline.fromDocument(finalsnapshot);
      print(currentTimeline.mediaUrl);
      print(currentTimeline.postId);
    } else {
      noMoreAudio = true;
      setState(() {});
      //stopPlayerTimer();
      //if (isplaying == true) {
      //  await player.pauseListenPage();
      //}
      //there is a bug that make it replay the audio
      //so wuruwuru fix
    }
  }

  playAudioInTimeline() async {
    stopPlayerTimer(); //first reset Player timer
    //confirm if there is any audio left
    if (noMoreAudio == false) {
      //change the username in the playercard
      timelineUsername = currentTimeline.username;
      //play audio with info from getAudioInTimeline()
      await player.playListenPage(url: currentTimeline.mediaUrl);
      timelineAudioDuration = int.parse(currentTimeline.audioDuration);
      timelineSecondsLeft = int.parse(currentTimeline.audioDuration);
      //update the played map
      timelineRef
          .doc(currentTimeline.postId)
          .update({'played.$currentUserId': true});
      print(
          'Ope duration left V1 $timelineSecondsLeft and start duration $timelineAudioDuration');
      if (showadint < 5 && adShownAlready == false) {
        showadint++;
      }
      print(showadint);
      if (showadint == 5) {
        print('show ad int is 5'); //this is how wed make it show ad
        //_nativeAdController.reloadAd();
      }

      startPlayerTimer();
    }
  }

  pauseAudioInTimeline() async {
    stopPlayerTimer();
    player.pauseListenPage();
  }

  playPauseAudioInTimeline() {
    if (isplaying == true) {
      playAudioInTimeline();
    } else {
      pauseAudioInTimeline();
    }
  }

  resetRecordParameters() {
    isrecording = false; //so we can buildrec button again
    sendcancelactive = false; //so we can buildrec button again
    recordsecs = maxrecsecs; //reset timer to initiate start
  }

  void startPlayerTimer() async {
    //stopPlayerTimer();
    playerTimer = Timer.periodic(Duration(seconds: 1), (_) async {
      if (timelineSecondsLeft > 0) {
        timelineSecondsLeft--;
        setState(() {});
        print(
            'Ope duration left V2 $timelineSecondsLeft $timelineAudioDuration');
      } else if (timelineSecondsLeft == 0) {
        print('ope i got into this block of code');
        // recorder.stop();
        //when timer is done get & play another one
        //we are waiting for the timer because the timer is 1 sec or less...
        //...longer than the audio

        //TO DO MAKE SURE IT ONLY RUNS PLAY IF GET GETS ANYTHING
        //to do if get audio is timeline is null don't play...or it would play the audio again
        await getAudioInTimeline();
        //so it won't keep running every 1 sec because it's inside the periodic timer
        stopPlayerTimer();
        if (noMoreAudio == false) {
          playAudioInTimeline();
        }
      }
    });

    //look for how to make this run after timelinesecleft  gets to 0
  }

  void stopPlayerTimer() {
    playerTimer?.cancel();
  }

  void startRecTimer() {
    audioDurationV2 = 0;
    rectimer = Timer.periodic(Duration(seconds: 1), (_) {
      setState(() {
        audioDurationV2++;
        if (recordsecs > 0) {
          recordsecs--;
        }
        if (recordsecs == 0) {
          recorder.stop();
          sendcancelactive = true;
        }
      });
    });
  }

  void pauseRecTimer() {
    rectimer?.cancel();
  }

  void stopRecTimer() {
    rectimer?.cancel();
    audioDurationV2++; //after getting the duration of the new version of the
    //...record timer add 1 (created this becuase 'justaudio' lib gets null)
    recordsecs =
        maxrecsecs; //reset the timer or it would start from where you stopped
    //only needed when you want to record or when you press next
    //this should reset the timer to zero basically
    //it should get the amount of seconds for the next audio and reset the seconds value to it
  }

//the new one
  void loadNativeAd() {
    nativeAd.load(unitId: 'ca-app-pub-3940256099942544/2247696110');
  }

  void loadOpenAppAd() async {
    if (!appOpenAd.isAvailable) {
      await appOpenAd.load(unitId: 'ca-app-pub-3940256099942544/3419835294');
    }
    if (appOpenAd.isAvailable) {
      await appOpenAd.show();
    }
  }

  void startAdTimer() {
    adTimer = Timer.periodic(Duration(seconds: 5), (_) {
      //_nativeAdController.reloadAd();
      setState(() {
        print('ad reloaded');
      });
    });
  }

  AdLayoutBuilder get mediumAdTemplateLayoutBuildercustom {
    return (ratingBar, media, icon, headline, advertiser, body, price, store,
        attribution, button) {
      return AdLinearLayout(
        decoration: AdDecoration(backgroundColor: Color(0xff246ee9)),
        width: MATCH_PARENT,
        height: MATCH_PARENT,
        gravity: LayoutGravity.center_vertical,
        padding: EdgeInsets.all(8.0),
        children: [
          attribution,
          AdLinearLayout(
            padding: EdgeInsets.only(top: 6.0),
            height: WRAP_CONTENT,
            orientation: HORIZONTAL,
            children: [
              AdExpanded(
                flex: 2,
                child: AdLinearLayout(
                  width: WRAP_CONTENT,
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  children: [headline, body, advertiser],
                ),
              ),
            ],
          ),
          media,
        ],
      );
    };
  }
}

void showToast({required String message, required ToastGravity toastGravity}) {
  Fluttertoast.showToast(msg: message, gravity: toastGravity);
}

loadingPage() {
  return Container(
    color: Colors.white,
    child: Center(
      child: CircularProgressIndicator(
        strokeWidth: 15.h,
      ),
    ),
  );
}
