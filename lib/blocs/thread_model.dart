import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

List<SeenThread> seenThreads = [];

class SeenThread {
  List<int> postIDs = [];
  int threadId = 0;
  String board = '';

  SeenThread({
    required this.postIDs,
    required this.threadId,
    required this.board,
  });

  factory SeenThread.fromJson(Map<String, dynamic> json) {
    return SeenThread(
      postIDs: List<int>.from(json['postIDs']),
      threadId: json['threadId'],
      board: json['board'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'postIDs': this.postIDs,
      'threadId': this.threadId,
      'board': this.board,
    };
  }
}

class ThreadProvider with ChangeNotifier {
  ThreadProvider() {
    loadPreferences();
  }

  Future<void> loadPreferences() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    if (prefs.getStringList('seenThreads') != null) {
      final List<String> seenThreadsPrefs = prefs.getStringList('seenThreads')!;
      seenThreads = seenThreadsPrefs
          .map((item) => SeenThread.fromJson(jsonDecode(item)))
          .toList();
    }
  }

  Future<void> addSeenPost(int threadID, String board, int postID) async {
    final seenThread = seenThreads.firstWhere(
        (element) => element.threadId == threadID,
        orElse: () => SeenThread(threadId: 0, board: '', postIDs: []));

    if (seenThread.threadId == 0) {
      seenThread.threadId = threadID;
      seenThread.board = board;
      seenThread.postIDs.add(postID);
      seenThreads.add(seenThread);
    } else {
      if (!seenThread.postIDs.contains(postID)) {
        seenThread.postIDs.add(postID);
        final index = seenThreads.indexWhere((element) =>
            element.threadId == threadID && element.board == board);
        seenThreads[index] = seenThread;
      }
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final seenThreadsJson =
        seenThreads.map((item) => jsonEncode(item.toJson())).toList();
    prefs.setStringList('seenThreads', seenThreadsJson);
  }

  bool isPostSeen(int thread, String board, int post) {
    final seenPost = seenThreads.firstWhere(
        (element) => element.threadId == thread && element.board == board,
        orElse: () => SeenThread(threadId: 0, board: '', postIDs: []));

    if (seenPost.threadId == 0) {
      return false;
    } else {
      return seenPost.postIDs.contains(post);
    }
  }

  SeenThread getSeenPostFromThread(int thread, String board) {
    return seenThreads.firstWhere(
        (element) => element.threadId == thread && element.board == board,
        orElse: () => SeenThread(threadId: 0, board: '', postIDs: []));
  }
}
