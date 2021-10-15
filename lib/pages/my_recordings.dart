import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:freemind/pages/home.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freemind/models/timeline.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:freemind/pages/settings.dart';

final timelineRef = FirebaseFirestore.instance.collection('timeline');
List myRecListtime = [];
List myRecListPostid = [];

class MyRecordings extends StatefulWidget {
  @override
  _MyRecordingsState createState() => _MyRecordingsState();
}

class _MyRecordingsState extends State<MyRecordings> {
  @override
  void initState() {
    fetchMyRecordings();
  }

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
                  65.w, 45.h, 0, 10.h), //25, 15 = 40.h, 0, 40
              child: Column(
                children: [
                  Row(
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
                  Padding(
                    padding: EdgeInsets.only(top: 20.h),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(0, 0, 85.w, 0),
                      child: Container(
                        //color: Colors.green,
                        height: 1720.h,
                        width: MediaQuery.of(context).size.width * 0.9,
                        child: ListView.builder(
                          itemCount: myRecListtime.length,
                          itemBuilder: (context, index) {
                            //learn how to put all data in 1 list
                            final itemtime = myRecListtime[index];
                            final itemPostid = myRecListPostid[index];
                            //print('ope $itemtime');

                            return buildRecordingTile(
                                itemtime, itemPostid, index);
                            //return ListTile(title: Text('ope $itemtime'));
                          },
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  buildRecordingTile(itemtime, itemPostid, index) {
    return Card(
      elevation: 5,
      color: Color(0xff246ee9),
      child: ListTile(
        title: Text(itemtime),
        trailing: GestureDetector(
          onTap: () {
            deleteAlertBox(itemtime, itemPostid);
            //ask if the person is sure
            //delete storage file thats post_postid
            //delete timeline file
            //then either setstate to refresh or remove that index from list
          },
          child: Icon(
            Icons.delete,
            color: Color(0xffed2939),
          ),
        ),
      ),
    );
  }

  fetchMyRecordings() async {
    myRecListtime = [];
    myRecListPostid = [];
    //TO DO  - put when it isApproved == true
    QuerySnapshot snapshot = await timelineRef
        .where('username', isEqualTo: currentUser.username)
        .get();

    snapshot.docs.forEach((doc) {
      var myfetchedRec = Timeline.fromDocument(doc);
      myRecListtime.add(myfetchedRec.time);
      myRecListPostid.add(myfetchedRec.postId);
      setState(() {});
    });
    // print(myRecListtime);
  }

  deleteAlertBox(itemtime, itemPostid) {
    //this is like a constructor too //but you don't specify like that thing that asian woman taught you
    //but the order which you arrange them is important
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Are you sure you want to delete this?'),
            content: Text('This Recording would be permanently deleted.'),
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
                  timelineRef
                      .doc(itemPostid) // <-- Doc ID to be deleted.
                      .delete() // <-- Delete
                      .then((_) => print('Deleted'))
                      .catchError((error) => print('Delete failed: $error'));

                  //delete storage file created by the user
                  storageDeleteRef.child("post_$itemPostid.aac").delete();

                  Navigator.pop(context);

                  print('Ope Post id $itemPostid');

                  //print('Ope Rec time $itemtime');
                  //print('Ope Rec time $itemPostid');
                  fetchMyRecordings();

                  //Navigator.pop(context);
                  showToast(
                      message: 'Deleted Successfully!',
                      toastGravity: ToastGravity.BOTTOM);

                  setState(() {});
                },
                child: Text('DELETE'),
              ),
            ],
          );
        });
  }
}
