import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chan/API/api.dart';
import 'package:flutter_chan/Models/post.dart';
import 'package:flutter_chan/blocs/theme.dart';
import 'package:flutter_chan/blocs/thread_model.dart';
import 'package:flutter_chan/pages/media_page.dart';
import 'package:flutter_chan/pages/replies_row.dart';
import 'package:flutter_chan/pages/thread/thread_post_comment.dart';
import 'package:flutter_chan/pages/thread/thread_replies.dart';
import 'package:flutter_chan/services/string.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';

class ThreadPagePost extends StatefulWidget {
  const ThreadPagePost({
    Key? key,
    required this.board,
    required this.post,
    required this.thread,
    required this.allPosts,
    required this.onDismiss,
  }) : super(key: key);

  final String board;
  final int thread;
  final Post post;
  final List<Post> allPosts;
  final Function(String? index) onDismiss;

  static String formatBytes(int bytes, int decimals) {
    if (bytes <= 0) {
      return '0 B';
    }
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
    final i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  @override
  State<ThreadPagePost> createState() => _ThreadPagePostState();
}

class _ThreadPagePostState extends State<ThreadPagePost> {
  late Future<List<Post>> _fetchAllRepliesToPost;

  @override
  void initState() {
    super.initState();

    _fetchAllRepliesToPost = fetchAllRepliesToPost(
      widget.post.no ?? 0,
      widget.board,
      widget.thread,
      widget.allPosts,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeChanger>(context);
    final threadModel = Provider.of<ThreadProvider>(context);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: VisibilityDetector(
        key: Key(widget.post.no.toString()),
        onVisibilityChanged: (visibilityInfo) {
          if (visibilityInfo.visibleFraction == 1) {
            threadModel.addSeenPost(
              widget.thread,
              widget.board,
              widget.post.no ?? 0,
            );
          }
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: theme.getTheme() == ThemeData.dark()
                    ? CupertinoColors.systemGrey.withOpacity(0.5)
                    : const Color(0x1F000000),
                width: .25,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.post.filename != null)
                    SizedBox(
                      width: 125,
                      height: 125,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                        child: InkWell(
                          onTap: () => {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MediaPage(
                                  video: widget.post.tim.toString() +
                                      widget.post.ext.toString(),
                                  board: widget.board,
                                  allPosts: widget.allPosts,
                                  threadId: widget.thread,
                                ),
                              ),
                            ).then(
                              (value) => {
                                widget.onDismiss(value),
                              },
                            )
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              'https://i.4cdn.org/${widget.board}/${widget.post.tim}s.jpg',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.post.filename != null)
                          Text(
                            '${widget.post.ext} (${ThreadPagePost.formatBytes(
                              widget.post.fsize ?? 0,
                              0,
                            )})',
                            style: const TextStyle(
                              fontSize: 12,
                              color: CupertinoColors.activeBlue,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (widget.post.sub != null)
                          Text(
                            unescape(cleanTags(widget.post.sub ?? '')),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.getTheme() == ThemeData.dark()
                                  ? Colors.white
                                  : Colors.black,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        Text(
                          'No.${widget.post.no}',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.getTheme() == ThemeData.dark()
                                ? Colors.white
                                : Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          widget.post.name ?? 'Anonymous',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.getTheme() == ThemeData.dark()
                                ? Colors.white
                                : Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          DateFormat('kk:mm - dd.MM.y').format(
                            DateTime.fromMillisecondsSinceEpoch(
                              widget.post.time! * 1000,
                            ),
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.getTheme() == ThemeData.dark()
                                ? Colors.white
                                : Colors.black,
                          ),
                        )
                      ],
                    ),
                  ),
                  const Divider(
                    height: 20,
                  ),
                ],
              ),
              if (widget.post.com != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: ThreadPostComment(
                    com: widget.post.com ?? '',
                    board: widget.board,
                    thread: widget.thread,
                    allPosts: widget.allPosts,
                  ),
                ),
              FutureBuilder<List<Post>>(
                  future: _fetchAllRepliesToPost,
                  builder: (context, AsyncSnapshot<List<Post>> snapshot) {
                    if (snapshot.data != null && snapshot.data!.isNotEmpty)
                      return GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ThreadReplies(
                                replies: snapshot.data ?? [],
                                post: widget.post,
                                thread: widget.thread,
                                board: widget.board,
                                allPosts: widget.allPosts,
                              ),
                            ),
                          );
                        },
                        child: RepliesRow(
                          replies: snapshot.data!.length,
                          showImageReplies: false,
                        ),
                      );
                    else
                      return Container();
                  }),
              const Divider(
                height: 20,
                color: Colors.transparent,
              )
            ],
          ),
        ),
      ),
    );
  }
}
