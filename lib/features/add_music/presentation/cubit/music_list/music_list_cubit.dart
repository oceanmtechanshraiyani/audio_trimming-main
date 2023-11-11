// ignore_for_file: unused_local_variable

import 'dart:math';

import 'package:audio/features/add_music/data/models/music_category_data_list_model.dart';
import 'package:audio/features/add_music/domain/entities/entity/add_music_entity.dart';
import 'package:audio/features/add_music/domain/usecases/add_music_usecases.dart';
import 'package:audio/features/shared/domain/entities/app_error.dart';
import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';
import 'package:just_audio/just_audio.dart';
part 'music_list_state.dart';

class MusicListCubit extends Cubit<MusicListState> {
  final MusicListUseCase musicListUseCase;
  MusicListCubit({required this.musicListUseCase}) : super(MusicListLoadingState());

  AudioPlayer audioPlayer = AudioPlayer();
  List<int> bars = [];
  double startValue = 0;
  double endValue = 0;

  Future<void> loadMusicListData({required int id}) async {
    Either<AppError, List<MusicListEntity>> response = await musicListUseCase(id);

    response.fold(
      (l) {
        emit(MusicListErrorState(appErrorType: l.errorType, errorMessage: l.errorMessage));
      },
      (r) async {
        emit(
          MusicListLoadedState(
            cropDuration: false,
            musicList: r,
            random: Random().nextDouble(),
            totalDuration: 100,
          ),
        );
      },
    );
  }

  Future<void> changeIcon({required MusicListLoadedState state, required int index}) async {
    bars.clear();
    genrateList();
    Duration? totalDuration;
    if (state.musicList[index].isAudioPlay != true) {
      audioPlayer.stop();
      emit(state.copyWith(totalDuration: 0, random: Random().nextDouble()));
      for (var element in state.musicList) {
        element.isAudioPlay = false;
      }
      state.musicList[index].isAudioPlay = !state.musicList[index].isAudioPlay;

      if (state.musicList[index].path != null) {
        totalDuration = await audioPlayer.setFilePath(state.musicList[index].path!);
      } else {
        totalDuration = await audioPlayer.setUrl(state.musicList[index].musicFile);
        endValue = totalDuration!.inSeconds.toDouble();
      }
      emit(state.copyWith(
        musicList: state.musicList,
        totalDuration: totalDuration?.inSeconds.toDouble(),
        cropDuration: true,
        random: Random().nextDouble(),
      ));
      playMusic();
    } else {
      audioPlayer.stop();
      for (var element in state.musicList) {
        element.isAudioPlay = false;
      }
      emit(state.copyWith(
        musicList: state.musicList,
        totalDuration: 0,
        random: Random().nextDouble(),
      ));
    }
  }

  void genrateList() {
    List.generate(28, (index) {
      bars.add(Random().nextInt(50));
    });
  }

  Future<void> trimMusic({required MusicListLoadedState state}) async {
    emit(state.copyWith(cropDuration: false));

    audioPlayer
        .setClip(start: Duration(seconds: startValue.toInt()), end: Duration(seconds: endValue.toInt()))
        .then((value) {
      emit(state.copyWith(cropDuration: true));
      audioPlayer.play();
    });
  }

  Future<void> musicPicker({required MusicListLoadedState state}) async {
    audioPlayer.stop();
    Duration? totalDuration;
    FilePickerResult? filePicker = await FilePicker.platform.pickFiles(type: FileType.audio);

    String? filePath = filePicker!.files.first.path;

    List<MusicListEntity> musicList = state.musicList;
    for (var e in musicList) {
      if (e.isAudioPlay == true) {
        e.isAudioPlay = false;
        audioPlayer.stop();
      }
    }
    if (musicList[0].path == null) {
      musicList.insert(
        0,
        MusicListData(
          id: 0,
          homeCategoryId: "0",
          homeCategoryName: 'File',
          musicName: filePicker.files.first.name,
          musicFile: 'musicFile',
          isAudioPlay: true,
          audioDuration: Duration.zero,
          path: filePath,
        ),
      );
    } else {
      musicList[0] = MusicListData(
        id: 0,
        homeCategoryId: "0",
        homeCategoryName: 'File',
        musicName: filePicker.files.first.name,
        musicFile: 'musicFile',
        isAudioPlay: true,
        audioDuration: Duration.zero,
        path: filePath,
      );
    }
    genrateList();
    totalDuration = await audioPlayer.setFilePath(musicList[0].path!);
    emit(
      state.copyWith(
        musicList: musicList,
        random: Random().nextDouble(),
        totalDuration: totalDuration!.inSeconds.toDouble(),
      ),
    );
    playMusic();
  }

  Future<void> playMusic() async {
    await audioPlayer.play();
  }
}
