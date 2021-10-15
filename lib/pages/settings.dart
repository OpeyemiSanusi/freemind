import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:freemind/models/timeline.dart';
import 'package:freemind/pages/home.dart';
import 'package:freemind/pages/my_recordings.dart';
import 'package:freemind/pages/sound_player.dart';
import 'package:freemind/pages/sound_recorder.dart';
import 'package:google_sign_in/google_sign_in.dart';

GoogleSignIn googlesignin = GoogleSignIn();
SoundPlayer _soundPlayer = SoundPlayer();
final timelineRef = FirebaseFirestore.instance.collection('timeline');
var isLoading = false;
final Reference storageDeleteRef = FirebaseStorage.instance.ref();

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    if (isLoading == true)
      return loadingPage();
    else
      return Scaffold(
        backgroundColor: Colors.white,
        body: Container(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                    65.w, 45.h, 0, 10.h), //25, 15 = 40.h, 0, 40
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
                      onTap: () {
                        Navigator.pop(context, true);
                      },
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(0, 0, 85.w, 0),
                        child: Icon(
                          Icons.cancel_rounded,
                          size: 100.sp,
                        ),
                      ),
                    )
                  ],
                ),
              ),
              buildprofileitems(),
            ],
          ),
        ),
      );
  }

  buildprofileitems() {
    return Center(
      child: Container(
        //color: Colors.black,
        height: MediaQuery.of(context).size.height * 0.9,
        width: 909.w,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(0, 0, 0, 100.w),
              child: Text(
                '@${currentUser.username}',
                style: TextStyle(
                    color: Colors.black,
                    fontFamily: 'Poppins',
                    fontSize: 65.sp, //18
                    fontWeight: FontWeight.w500),
              ),
            ),
            buildMyRecordingsButton(),
            SizedBox(
              height: 30.h,
            ),
            buildLogoutButton(),
            SizedBox(
              height: 30.h,
            ),
            buildDeleteAcctButton(),
          ],
        ),
      ),
    );
  }

  buildMyRecordingsButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => MyRecordings()));
      },
      child: Container(
        child: Center(
          child: Text(
            'My Recordings',
            style: TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
                fontSize: 60.h, //25
                fontWeight: FontWeight.w300),
          ),
        ),
        width: 900.w, //MediaQuery.of(context).size.width * 0.5,
        height: 190.h, //MediaQuery.of(context).size.height * 0.1,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(
            Radius.circular(5),
          ),
          color: Color(0xff246ee9),
        ),
      ),
    );
  }

  buildLogoutButton() {
    return GestureDetector(
      onTap: () async {
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                content: Text('Are you sure you want to logout?'),
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

                      //_soundPlayer.dispose();
                      //you have to do this or when it closes you won't be able to re login
                      await googleSignIn.disconnect();

                      await googlesignin.signOut();
                      showToast(
                          message: 'You are signed out!',
                          toastGravity: ToastGravity.BOTTOM);
                      /*Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Home(),
                      ));*/
                      isLoading = false;
                      Navigator.pop(context); //FIRST POP THE SHOWDIALOG
                      Navigator.pop(context, false); //isAuth
                    },
                    child: Text('LOGOUT'),
                  ),
                ],
              );
            });
      },
      child: Container(
        child: Center(
          child: Text(
            'Logout',
            style: TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
                fontSize: 60.h, //25
                fontWeight: FontWeight.w300),
          ),
        ),
        width: 900.w, //MediaQuery.of(context).size.width * 0.5,
        height: 190.h, //MediaQuery.of(context).size.height * 0.1,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(
            Radius.circular(5),
          ),
          color: Color(0xff246ee9),
        ),
      ),
    );
  }

  buildDeleteAcctButton() {
    return GestureDetector(
      onTap: () async {
        showDialog(
            context: context,
            builder: (BuildContext dialogcontext) {
              return AlertDialog(
                title: Text(
                  'Delete Account',
                  style: TextStyle(color: Colors.red),
                ),
                content: Text(
                    'Are you sure you want to delete your account? \n\nIf you delete your account, you will permanently lose your profile & recordings'),
                actions: [
                  TextButton(
                    style: TextButton.styleFrom(
                      primary: Colors.blue,
                    ),
                    onPressed: () {
                      Navigator.pop(dialogcontext);
                    },
                    child: Text('CANCEL'),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      primary: Colors.red,
                    ),
                    onPressed: () async {
                      Navigator.pop(dialogcontext); //FIRST POP THE SHOWDIALOG
                      isLoading = true;
                      setState(() {});

                      //delete user data
                      await usersRef.doc(currentUser.id).delete();

                      //delete all post created by user
                      var snapshot = await timelineRef
                          .where('username', isEqualTo: currentUser.username)
                          .get();
                      snapshot.docs.forEach((doc) {
                        // deletefile.postId delete doc file in timeline where username is current user
                        doc.reference.delete(); //use reference to delete

                        //delete all files created by the user
                        var deletefile = Timeline.fromDocument(doc);

                        storageDeleteRef
                            .child("post_${deletefile.postId}.aac")
                            .delete();
                      });

                      //logout because you are till signed in you just don't have a username or audio

                      //_soundPlayer.dispose();
                      //you have to do this or when it closes you won't be able to re login
                      await googleSignIn.disconnect();

                      await googlesignin.signOut();
                      isLoading = false;

                      Navigator.pop(context, false); //isAuth
                    },
                    child: Text('DELETE'),
                  ),
                ],
              );
            });
      },
      child: Container(
        child: Center(
          child: Text(
            'Delete Account',
            style: TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
                fontSize: 60.h, //25
                fontWeight: FontWeight.w300),
          ),
        ),
        width: 900.w, //MediaQuery.of(context).size.width * 0.5,
        height: 190.h, //MediaQuery.of(context).size.height * 0.1,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(
            Radius.circular(5),
          ),
          color: Color(0xFFE92430),
        ),
      ),
    );
  }
}
