import 'package:flutter_test/flutter_test.dart';
import 'package:formpocket/core/form/demo_seed.dart';
import 'package:formpocket/core/form/form_engine.dart';

void main() {
  test('shipping preview joins the personal fields', () {
    final book = DemoSeed.book();
    final personal = book.profiles.first;
    final shipping = book.templates.first;
    final lines = FormEngine.joinValues(
      FormEngine.included(personal, shipping.fieldIds),
    );
    expect(
      lines,
      'Alex Morgan\n12 Example Lane\nRiverton, CA 94107\nUnited States',
    );
  });

  test('sensitive values stay masked until shown', () {
    final work = DemoSeed.book().profiles[1];
    final phone = work.fields.firstWhere((field) => field.id == 'w-phone');
    expect(FormEngine.shown(phone, hidden: true), FormEngine.hiddenMark);
    expect(FormEngine.shown(phone, hidden: false), '4155550134');
    expect(work.fields.take(3).map((field) => field.id),
        ['w-name', 'w-company', 'w-email']);
  });

  test('labels and one line reuse the same fields', () {
    final work = DemoSeed.book().profiles[1];
    final fields = work.fields.take(2);
    expect(
      FormEngine.format(fields, CopyShape.labels),
      'Name: Alex Morgan\nCompany: North Studio',
    );
    expect(
      FormEngine.format(fields, CopyShape.line),
      'Alex Morgan · North Studio',
    );
    final raw = FormEngine.encodeClips(const [
      PocketClip(title: 'Work', text: 'Alex Morgan'),
    ]);
    expect(FormEngine.decodeClips(raw).single.title, 'Work');
  });

  test('book round-trips and keeps the free limits', () {
    final again = FormBook.decode(DemoSeed.book().encode());
    expect(again.profiles.map((profile) => profile.id),
        ['personal', 'work', 'family']);
    expect(again.templates.last.fieldIds, ['w-company', 'w-email', 'w-tax']);
    expect(FormEngine.freeProfiles, 3);
    expect(FormEngine.freeTemplates, 2);
  });
}
