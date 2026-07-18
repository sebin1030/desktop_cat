import 'package:flutter_test/flutter_test.dart';

import 'package:desktop_cat_app/state_manager/pet_state.dart';

void main() {
  test('walking frames follow the facing direction', () {
    expect(PetPose.walk.frames().first, 'walk_r_01');
    expect(PetPose.walk.frames().last, 'walk_r_06');
    expect(PetPose.walk.frames(facingLeft: true).first, 'walk_l_01');
    expect(PetPose.walk.frames(facingLeft: true).last, 'walk_l_06');
  });
}
