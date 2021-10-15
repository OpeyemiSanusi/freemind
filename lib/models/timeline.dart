import 'package:cloud_firestore/cloud_firestore.dart';

class Timeline {
  final String postId;
  final String mediaUrl;
  final String audioDuration;
  final String username;
  final dynamic played;
  final String time;

  Timeline({
    required this.postId,
    required this.mediaUrl,
    required this.audioDuration,
    required this.username,
    required this.played,
    required this.time,
  });

  factory Timeline.fromDocument(DocumentSnapshot doc) {
    return Timeline(
      postId: doc['postId'],
      mediaUrl: doc['mediaUrl'],
      audioDuration: doc['audioDuration'],
      username: doc['username'],
      played: doc['played'],
      time: doc['time'],
    );
  }
}
