import 'package:mupdf_android/mupdf_android.dart' as mupdf;

typedef ExerciseCollection = (String, List<Exercise>);
typedef ExerciseBound = (int, double);

class Exercise {
  mupdf.PDFDocument document;
  ExerciseBound start;
  ExerciseBound? end;

  Exercise({required this.start, this.end, required this.document});

  Exercise copyWith() {
    return Exercise(start: start, end: end, document: document);
  }
}

class ExerciseMapper {
  RegExp titleRegex = RegExp(r"^.*\d{2}\.\d{2}\..*$");
  RegExp exerciseRegex = RegExp(r"^[1-9]\d*\.");
  double offsetStart = -20;
  double offsetEnd = -25;

  double _getPageBottom(mupdf.Page page) {
    return page.getBounds1().y1;
  }

  Exercise _offsetExercise(Exercise exercise,
      {bool first = false, bool last = false}) {
    exercise.start =
        (exercise.start.$1, exercise.start.$2 + (first ? 0 : offsetStart));
    ExerciseBound? end = exercise.end;
    if (end != null) {
      exercise.end = (end.$1, end.$2 + (last ? 0 : offsetEnd));
    }
    return exercise;
  }

  Future<List<Exercise>> _extractExercises(mupdf.PDFDocument document) async {
    List<Exercise> exercises = [];
    Exercise? prev;
    for (int i = 0; i < document.countPages(0); i++) {
      mupdf.PDFPage page = document.loadPage(i, i).castTo(mupdf.PDFPage.type);
      List<mupdf.StructuredText_TextLine> lines = page.lines
          .where((element) => exerciseRegex.hasMatch(element.text))
          .toList();
      bool isFirst = true;
      for (int j = 0; j < lines.length; j++) {
        mupdf.StructuredText_TextLine line = lines[j];
        if (prev != null) {
          prev.end = (i, line.bbox.y0);
          prev = _offsetExercise(prev, first: isFirst);
          isFirst = false;
          exercises.add(prev.copyWith());
        }
        prev = Exercise(document: document, start: (i, line.bbox.y0));
      }
      if (prev == null) {
        prev = Exercise(
            document: document, start: (i, 0), end: (i, _getPageBottom(page)));
        exercises.add(prev.copyWith());
      } else {
        prev.end = (i, _getPageBottom(page));
        if (i + 1 == document.pages.length) {
          prev = _offsetExercise(prev, last: true);
          exercises.add(prev.copyWith());
        }
      }
    }
    return exercises;
  }

  Future<List<Exercise>> documentToExercises(mupdf.PDFDocument document) async {
    return await _extractExercises(document);
  }
}
