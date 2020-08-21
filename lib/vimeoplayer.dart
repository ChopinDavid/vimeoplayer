library vimeoplayer;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import 'src/quality_links.dart';

class VimeoPlayer extends StatefulWidget {
  final String id;
  final Color overlayElementColor;
  final Color playedColor;
  final Color backgroundColor;
  final Color bufferedColor;
  final Color progressIndicatorColor;
  final bool fullscreenable;

  VimeoPlayer({
    @required this.id,
    this.overlayElementColor,
    this.playedColor = const Color(0xFF22A3D2),
    this.backgroundColor = const Color(0x5515162B),
    this.bufferedColor = const Color(0x5583D8F7),
    this.progressIndicatorColor = const Color(0xFF22A3D2),
    this.fullscreenable = true,
    Key key,
  }) : super(key: key);

  @override
  _VimeoPlayerState createState() => _VimeoPlayerState(id);
}

class _VimeoPlayerState extends State<VimeoPlayer> {
  String _id;
  bool autoPlay = false;
  bool _overlay = true;
  Duration _position;

  _VimeoPlayerState(this._id);

  VideoPlayerController _controller; //Custom controller
  Future<void> initFuture;

  QualityLinks _quality; // Quality Class
  Map _qualityValues;
  bool _seek = false;

  double videoHeight;
  double videoWidth;
  double videoMargin;

  @override
  void initState() {
    _quality = QualityLinks(_id); //Create class
    //Инициализация контроллеров видео при получении данных из Vimeo
    _quality.getQualitiesSync().then((value) {
      _qualityValues = value;
      _controller = VideoPlayerController.network(value[value.lastKey()]);
      _controller.setLooping(true);
      if (autoPlay) _controller.play();
      initFuture = _controller.initialize();

      //Обновление состояние приложения и перерисовка
      setState(() {});
    });

    //На странице видео преимущество за портретной ориентацией
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitDown, DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Stack(
      alignment: AlignmentDirectional.center,
      children: <Widget>[
        GestureDetector(
          child: FutureBuilder(
              future: initFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      double delta = constraints.maxWidth -
                          constraints.maxHeight * _controller.value.aspectRatio;
                      if (MediaQuery.of(context).orientation ==
                              Orientation.portrait ||
                          delta < 0) {
                        videoHeight = constraints.maxWidth /
                            _controller.value.aspectRatio;
                        videoWidth = constraints.maxWidth;
                        videoMargin = 0;
                      } else {
                        videoHeight = constraints.maxHeight - 36;
                        videoWidth =
                            videoHeight * _controller.value.aspectRatio;
                        videoMargin = (constraints.maxWidth - videoWidth) / 2;
                      }

                      if (_seek && _controller.value.duration.inSeconds > 2) {
                        _controller.seekTo(_position);
                        _seek = false;
                      }

                      //Отрисовка элементов плеера
                      return Stack(
                        children: <Widget>[
                          Container(
                            height: videoHeight,
                            width: videoWidth,
                            margin: EdgeInsets.only(left: videoMargin),
                            child: VideoPlayer(_controller),
                          ),
                          _videoOverlay(),
                        ],
                      );
                    },
                  );
                  //Управление шириной и высотой видео

                } else {
                  return Center(
                      heightFactor: 6,
                      child: CircularProgressIndicator(
                        strokeWidth: 4,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            widget.progressIndicatorColor),
                      ));
                }
              }),
          onTap: () {
            setState(() {
              _overlay = !_overlay;
            });
          },
        )
      ],
    ));
  }

  //================================ Quality ================================//
  void _settingModalBottomSheet(context) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          final children = <Widget>[];
          _qualityValues.forEach((elem, value) => (children.add(new ListTile(
              title: new Text(" ${elem.toString()} fps"),
              onTap: () => {
                    //Обновление состояние приложения и перерисовка
                    setState(() {
                      _controller.pause();
                      _controller = VideoPlayerController.network(value);
                      _controller.setLooping(true);
                      _seek = true;
                      initFuture = _controller.initialize();
                      _controller.play();
                    }),
                  }))));

          return Container(
            child: Wrap(
              children: children,
            ),
          );
        });
  }

  //================================ OVERLAY ================================//
  Widget _videoOverlay() {
    return _overlay
        ? Stack(
            children: <Widget>[
              GestureDetector(
                child: Center(
                  child: Container(
                    width: videoWidth,
                    height: videoHeight,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                        colors: [
                          const Color(0x662F2C47),
                          const Color(0x662F2C47)
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Center(
                child: IconButton(
                    padding: EdgeInsets.only(
                        top: videoHeight / 2 - 30,
                        bottom: videoHeight / 2 - 30),
                    icon: _controller.value.isPlaying
                        ? Icon(
                            Icons.pause,
                            size: 60.0,
                            color: widget.overlayElementColor != null
                                ? widget.overlayElementColor
                                : Theme.of(context).iconTheme.color,
                          )
                        : Icon(
                            Icons.play_arrow,
                            size: 60.0,
                            color: widget.overlayElementColor != null
                                ? widget.overlayElementColor
                                : Theme.of(context).iconTheme.color,
                          ),
                    onPressed: () {
                      setState(() {
                        _controller.value.isPlaying
                            ? _controller.pause()
                            : _controller.play();
                      });
                    }),
              ),
              if (widget.fullscreenable)
                Container(
                  margin: EdgeInsets.only(
                      top: videoHeight - 70,
                      left: videoWidth + videoMargin - 50),
                  child: IconButton(
                      alignment: AlignmentDirectional.center,
                      icon: Icon(
                        Icons.fullscreen,
                        size: 30.0,
                        color: widget.overlayElementColor != null
                            ? widget.overlayElementColor
                            : Theme.of(context).iconTheme.color,
                      ),
                      onPressed: () {
                        setState(() {
                          MediaQuery.of(context).orientation ==
                                  Orientation.landscape
                              ? SystemChrome.setPreferredOrientations([
                                  DeviceOrientation.portraitDown,
                                  DeviceOrientation.portraitUp
                                ])
                              : SystemChrome.setPreferredOrientations([
                                  DeviceOrientation.landscapeLeft,
                                  DeviceOrientation.landscapeRight
                                ]);
                        });
                      }),
                ),
              Container(
                margin: EdgeInsets.only(left: videoWidth + videoMargin - 48),
                child: IconButton(
                    icon: Icon(
                      Icons.settings,
                      size: 26.0,
                      color: widget.overlayElementColor != null
                          ? widget.overlayElementColor
                          : Theme.of(context).iconTheme.color,
                    ),
                    onPressed: () {
                      _position = _controller.value.position;
                      _seek = true;
                      _settingModalBottomSheet(context);
                      setState(() {});
                    }),
              ),
              Container(
                //===== Ползунок =====//
                margin: EdgeInsets.only(
                    top: videoHeight - 26, left: videoMargin), //CHECK IT
                child: _videoOverlaySlider(),
              )
            ],
          )
        : Center(
            child: Container(
              height: 5,
              width: videoWidth,
              margin: EdgeInsets.only(top: videoHeight - 5),
              child: VideoProgressIndicator(
                _controller,
                allowScrubbing: true,
                colors: VideoProgressColors(
                  playedColor: widget.playedColor,
                  backgroundColor: widget.backgroundColor,
                  bufferedColor: widget.bufferedColor,
                ),
                padding: EdgeInsets.only(top: 2),
              ),
            ),
          );
  }

  //=================== ПОЛЗУНОК ===================//
  Widget _videoOverlaySlider() {
    return ValueListenableBuilder(
      valueListenable: _controller,
      builder: (context, VideoPlayerValue value, child) {
        if (!value.hasError && value.initialized) {
          return Row(
            children: <Widget>[
              Container(
                width: 46,
                alignment: Alignment(0, 0),
                child: Text(
                    value.position.inMinutes.toString() +
                        ':' +
                        (value.position.inSeconds -
                                value.position.inMinutes * 60)
                            .toString()
                            .padLeft(2, '0'),
                    style: TextStyle(
                        color: widget.overlayElementColor != null
                            ? widget.overlayElementColor
                            : Theme.of(context).iconTheme.color)),
              ),
              Container(
                height: 20,
                width: videoWidth - 92,
                child: VideoProgressIndicator(
                  _controller,
                  allowScrubbing: true,
                  colors: VideoProgressColors(
                    playedColor: widget.playedColor,
                    backgroundColor: widget.backgroundColor,
                    bufferedColor: widget.bufferedColor,
                  ),
                  padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
                ),
              ),
              Container(
                width: 46,
                alignment: Alignment(0, 0),
                child: Text(
                    value.duration.inMinutes.toString() +
                        ':' +
                        (value.duration.inSeconds -
                                value.duration.inMinutes * 60)
                            .toString()
                            .padLeft(2, '0'),
                    style: TextStyle(
                        color: widget.overlayElementColor != null
                            ? widget.overlayElementColor
                            : Theme.of(context).iconTheme.color)),
              ),
            ],
          );
        } else {
          return Container();
        }
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
