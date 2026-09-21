import 'package:flutter/material.dart';

/// Fixed icon sets used for generated lessons/units. Lessons and units only
/// ever get an icon by index into these lists, so persisting to Firestore
/// just means storing the index rather than serializing an IconData.
const lessonIcons = [
  Icons.data_object_rounded,
  Icons.calculate_rounded,
  Icons.alt_route_rounded,
  Icons.loop_rounded,
  Icons.functions_rounded,
  Icons.view_list_rounded,
  Icons.rocket_launch_rounded,
  Icons.code_rounded,
];

const unitIcons = [
  Icons.menu_book_rounded,
  Icons.widgets_rounded,
  Icons.auto_stories_rounded,
  Icons.school_rounded,
];

IconData lessonIconAt(int index) => lessonIcons[index % lessonIcons.length];

IconData unitIconAt(int index) => unitIcons[index % unitIcons.length];
