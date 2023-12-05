import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chan/API/api.dart';
import 'package:flutter_chan/API/save_videos.dart';
import 'package:flutter_chan/Models/media.dart';
import 'package:flutter_chan/Models/post.dart';
import 'package:flutter_chan/blocs/gallery_model.dart';
import 'package:flutter_chan/blocs/saved_attachments_model.dart';
import 'package:flutter_chan/blocs/theme.dart';
import 'package:flutter_chan/blocs/thread_model.dart';
import 'package:flutter_chan/widgets/image_viewer.dart';
import 'package:flutter_chan/widgets/webm_player.dart';
import 'package:preload_page_view/preload_page_view.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

class MediaPage extends StatefulWidget {
  const MediaPage({
    Key? key,
    required this.video,
    this.board,
    required this.allPosts,
    this.isAsset = false,
    this.directory,
    this.threadId,
  }) : super(key: key);

  final String video;
  final String? board;
  final List<Post> allPosts;
  final bool isAsset;
  final Directory? directory;
  final int? threadId;

  @override
  State<MediaPage> createState() => _MediaPageState();
}

class _MediaPageState extends State<MediaPage> {
  late PreloadPageController controller;

  final String page = '0';
  late int index;
  String currentName = '';
  bool isSaved = false;

  List<Media> media = [];

  void onPageChanged(int i, String media, GalleryProvider gallery,
      ThreadProvider threadProvider) {
    gallery.setCurrentPage(i);
    gallery.setCurrentMedia(media);

    if (widget.threadId != null) {
      threadProvider.addSeenPost(
        widget.threadId ?? 0,
        widget.board ?? '',
        widget.allPosts[i].no ?? 0,
      );
    }

    setState(() {
      index = i;
    });
  }

  Future<void> setStartVideo(String video) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    prefs.setString('startVideo', video);
  }

  Widget getMediaWidget(int i) {
    if (widget.isAsset) {
      if (media[i].ext == '.webm') {
        return VLCPlayer(
          board: widget.board,
          video: media[i].videoName,
          fileName: media[i].fileName,
          isAsset: widget.isAsset,
          directory: widget.directory,
        );
      } else {
        return InteractiveViewer(
          minScale: 0.5,
          maxScale: 5,
          child: Image.asset(
            '${widget.directory!.path}/savedAttachments/${media[i].fileName}',
          ),
        );
      }
    } else {
      if (media[i].ext == '.webm') {
        return VLCPlayer(
          board: widget.board,
          video: media[i].videoName,
          fileName: media[i].fileName,
        );
      } else {
        return ImageViewer(
          url: 'https://i.4cdn.org/${widget.board}/${media[i].videoName}',
          interactiveViewer: true,
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();

    for (final Post post in widget.allPosts) {
      if (post.tim != null) {
        media.add(
          Media(
            videoId: post.tim ?? 0,
            videoName: post.tim.toString() + post.ext.toString(),
            fileName: post.filename ?? '',
            ext: post.ext ?? '',
          ),
        );
      }
    }

    index = media.indexWhere(
      (element) => element.videoName == widget.video,
    );

    if (index < 0) {
      Navigator.of(context).pop();
    }

    setStartVideo(media[index].videoId.toString());

    controller = PreloadPageController(
      initialPage: index,
      keepPage: false,
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeChanger>(context);
    final gallery = Provider.of<GalleryProvider>(context);
    final savedAttachments = Provider.of<SavedAttachmentsProvider>(context);
    final threadProvider = Provider.of<ThreadProvider>(context);

    isSaved = false;
    for (final element in savedAttachments.getSavedAttachments()) {
      if (element.fileName == media[index].videoName) {
        isSaved = true;
      }
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.getTheme() == ThemeData.light()
          ? CupertinoColors.systemGroupedBackground
          : CupertinoColors.black,
      extendBodyBehindAppBar: true,
      appBar: CupertinoNavigationBar(
        backgroundColor: theme.getTheme() == ThemeData.light()
            ? CupertinoColors.systemGroupedBackground.withOpacity(0.7)
            : CupertinoColors.black.withOpacity(0.7),
        border: Border.all(color: Colors.transparent),
        leading: MediaQuery(
          data: MediaQueryData(
            textScaleFactor: MediaQuery.textScaleFactorOf(context),
          ),
          child: Transform.translate(
            offset: const Offset(-16, 0),
            child: CupertinoNavigationBarBackButton(
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        middle: MediaQuery(
          data: MediaQueryData(
            textScaleFactor: MediaQuery.textScaleFactorOf(context),
          ),
          child: Column(
            children: [
              Text(
                '${media[index].fileName}${media[index].ext}',
                style: TextStyle(
                  color: theme.getTheme() == ThemeData.dark()
                      ? Colors.white
                      : Colors.black,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${index + 1}/${media.length}',
                style: TextStyle(
                  color: theme.getTheme() == ThemeData.dark()
                      ? Colors.white
                      : Colors.black,
                ),
              ),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isSaved)
              CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Icon(CupertinoIcons.bookmark),
                onPressed: () => {
                  savedAttachments.addSavedAttachments(
                    _scaffoldKey.currentContext ?? context,
                    widget.board ?? '',
                    media[index].videoName,
                  )
                },
              )
            else
              CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Icon(CupertinoIcons.bookmark_fill),
                onPressed: () => {
                  showCupertinoDialog(
                    barrierDismissible: true,
                    context: context,
                    builder: (context) {
                      return StatefulBuilder(
                        builder: (context, setState) {
                          return CupertinoAlertDialog(
                            title: const Text('Delete Attachment?'),
                            actions: [
                              CupertinoDialogAction(
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: CupertinoColors.activeBlue,
                                  ),
                                ),
                                onPressed: () => {
                                  Navigator.pop(context),
                                },
                              ),
                              CupertinoDialogAction(
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(
                                    color: CupertinoColors.activeBlue,
                                  ),
                                ),
                                onPressed: () => {
                                  savedAttachments
                                      .removeSavedAttachments(
                                          media[index].videoName)
                                      .then(
                                        (value) => {
                                          Navigator.pop(context),
                                        },
                                      ),
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                },
              ),
            SizedBox(
              width: 20,
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  showCupertinoModalPopup(
                    context: context,
                    builder: (BuildContext context) => CupertinoActionSheet(
                      actions: [
                        if (!isSaved)
                          CupertinoActionSheetAction(
                            child: const Text('Open in Browser'),
                            onPressed: () {
                              launchURL(
                                'https://i.4cdn.org/${widget.board}/${media[index].videoName}',
                              );
                              Navigator.pop(context);
                            },
                          ),
                        CupertinoActionSheetAction(
                          child: const Text('Share'),
                          onPressed: () {
                            shareMedia(
                              'https://i.4cdn.org/${widget.board}/${media[index].videoName}',
                              media[index].videoName,
                              _scaffoldKey.currentContext ?? context,
                              isSaved: isSaved,
                            );
                            Navigator.pop(context);
                          },
                        ),
                        CupertinoActionSheetAction(
                          child: const Text('Download'),
                          onPressed: () {
                            saveVideo(
                              'https://i.4cdn.org/${widget.board}/${media[index].videoName}',
                              media[index].videoName,
                              _scaffoldKey.currentContext ?? context,
                              showSnackBar: true,
                              isSaved: isSaved,
                            );
                            Navigator.pop(context);
                          },
                        ),
                      ],
                      cancelButton: CupertinoActionSheetAction(
                        child: const Text('Cancel'),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  );
                },
                child: const Icon(Icons.ios_share),
              ),
            ),
          ],
        ),
      ),
      body: PreloadPageView.custom(
        preloadPagesCount: 2,
        controller: controller,
        onPageChanged: (i) =>
            onPageChanged(i, media[i].videoName, gallery, threadProvider),
        childrenDelegate: SliverChildBuilderDelegate(
          (context, i) {
            return getMediaWidget(i);
          },
          childCount: media.length,
        ),
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
      ),
    );
  }
}
