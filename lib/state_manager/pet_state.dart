enum PetPose {
  sleep,
  stretch,
  sit,
  walk,
  yawn,
}

extension PetPoseAssetName on PetPose {
  List<String> frames({bool facingLeft = false}) {
    return switch (this) {
      PetPose.sleep => const ['sleep_01', 'sleep_02'],
      PetPose.stretch => const [
          'stretch_01',
          'stretch_02',
          'stretch_03',
          'stretch_04',
        ],
      // 별도의 앉기 이미지가 없으므로 편안한 수면 첫 프레임을 사용한다.
      PetPose.sit => const ['sleep_01'],
      PetPose.walk => facingLeft
          ? const [
              'walk_l_01',
              'walk_l_02',
              'walk_l_03',
              'walk_l_04',
              'walk_l_05',
              'walk_l_06',
            ]
          : const [
              'walk_r_01',
              'walk_r_02',
              'walk_r_03',
              'walk_r_04',
              'walk_r_05',
              'walk_r_06',
            ],
      PetPose.yawn => const ['yawn_01', 'yawn_02', 'yawn_03'],
    };
  }
}
