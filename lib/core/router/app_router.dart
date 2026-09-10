import 'package:go_router/go_router.dart';

import '../../features/import/pages/import_capture_page.dart';
import '../../features/import/pages/import_login_page.dart';
import '../../features/settings/pages/settings_page.dart';
import '../../features/timetable/pages/course_detail_page.dart';
import '../../features/timetable/pages/course_form_page.dart';
import '../../features/timetable/pages/timetable_page.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const TimetablePage()),
    GoRoute(
      path: '/course/new',
      builder: (context, state) => const CourseFormPage(),
    ),
    GoRoute(
      path: '/course/:id',
      builder: (context, state) =>
          CourseDetailPage(courseId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/course/:id/edit',
      builder: (context, state) =>
          CourseFormPage(courseId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
    ),
    GoRoute(
      path: '/import/login',
      builder: (context, state) => const ImportLoginPage(),
    ),
    GoRoute(
      path: '/import/capture',
      builder: (context, state) => const ImportCapturePage(),
    ),
  ],
);
