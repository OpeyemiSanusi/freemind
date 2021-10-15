import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:freemind/models/user.dart';
import 'package:freemind/pages/home.dart';

class CreateAccount extends StatefulWidget {
  const CreateAccount({Key? key}) : super(key: key);

  @override
  _CreateAccountState createState() => _CreateAccountState();
}

class _CreateAccountState extends State<CreateAccount> {
  bool usernameExists = false;
  final _formkey = GlobalKey<FormState>();
  String? username; //doesn't read this until it's called the first time

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
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
                ],
              ),
            ),
            Container(
                //height: 950.h,
                //width: MediaQuery.of(context).size.height * 0.9,
                //color: Colors.black,
                child: Column(
              children: [
                Text(
                  'CREATE USERNAME',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 60.sp,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff001f53)),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: 50.h,
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 70.w),
                    child: Container(
                      child: Form(
                        key: _formkey,
                        child: TextFormField(
                          validator: (val) {
                            if (val!.trim().length < 3 || val.isEmpty) {
                              return "Username too short";
                            } else if (val.trim().length > 15) {
                              return "Username too long";
                            }
                            //else if (usernameExists == true) {
                            //return "Username already exists";
                            // }
                            else {
                              return null;
                            }
                          },
                          onSaved: (val) => username = val,
                          decoration: InputDecoration(
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Color(0xff001f53), width: 2.0),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Color(0xff001f53), width: 2.0),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    final form = _formkey.currentState;

                    if (form!.validate()) {
                      form.save();
                    }
                    print(username);
                    usernameExists = false;
                    var snapshot = await usersRef
                        .where('username', isEqualTo: username)
                        .get();
                    snapshot.docs.forEach((doc) {
                      var currentPerson = User.fromDocument(doc);

                      if (currentPerson.username == username) {
                        usernameExists = true;
                        setState(() {});

                        // usernameExists = true;
                        //setState(() {});
                      } else {
                        usernameExists = false;
                      }
                    });
                    if (usernameExists == true) {
                      showToast(
                          message: 'Username already exists',
                          toastGravity: ToastGravity.TOP);
                    } else {
                      Navigator.pop(context, username);
                    }
                    print(usernameExists);
                  },
                  child: Container(
                    child: Center(
                      child: Text(
                        'SIGN UP',
                        style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Poppins',
                            fontSize: 70.h, //25
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    width: 700.w, //MediaQuery.of(context).size.width * 0.5,
                    height: 190.h, //MediaQuery.of(context).size.height * 0.1,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(
                        Radius.circular(5),
                      ),
                      color: Color(0xff001f53),
                    ),
                  ),
                ),
              ],
            )),
          ],
        ),
      ),
    );
  }

  submit() {}
}
