import 'form_engine.dart';

class DemoSeed {
  DemoSeed._();

  static FormBook book() {
    const personal = PocketProfile(
      id: 'personal',
      name: 'Personal',
      detail: 'Everyday details',
      initials: 'AM',
      tone: 0,
      fields: [
        PocketField(id: 'p-name', label: 'Full name', value: 'Alex Morgan'),
        PocketField(
            id: 'p-address', label: 'Address', value: '12 Example Lane'),
        PocketField(
          id: 'p-city',
          label: 'City, state, postal code',
          value: 'Riverton, CA 94107',
        ),
        PocketField(id: 'p-country', label: 'Country', value: 'United States'),
      ],
    );
    const work = PocketProfile(
      id: 'work',
      name: 'Work',
      detail: 'Professional details',
      initials: 'WN',
      tone: 1,
      fields: [
        PocketField(id: 'w-name', label: 'Name', value: 'Alex Morgan'),
        PocketField(id: 'w-company', label: 'Company', value: 'North Studio'),
        PocketField(
            id: 'w-email', label: 'Work email', value: 'alex@example.com'),
        PocketField(
          id: 'w-phone',
          label: 'Phone',
          value: '4155550134',
          sensitive: true,
        ),
        PocketField(
            id: 'w-title', label: 'Job title', value: 'Product Designer'),
        PocketField(
          id: 'w-address',
          label: 'Office address',
          value: '88 Creative Way\nRiverton, CA 94107',
        ),
        PocketField(
          id: 'w-tax',
          label: 'Tax ID',
          value: '12-3456789',
          sensitive: true,
        ),
      ],
    );
    const family = PocketProfile(
      id: 'family',
      name: 'Family',
      detail: 'Household details',
      initials: 'FL',
      tone: 1,
      fields: [
        PocketField(id: 'f-name', label: 'Name', value: 'Morgan household'),
        PocketField(
            id: 'f-address', label: 'Address', value: '12 Example Lane'),
        PocketField(
          id: 'f-phone',
          label: 'Phone',
          value: '4155550199',
          sensitive: true,
        ),
      ],
    );
    const shipping = PocketTemplate(
      id: 'shipping',
      name: 'Shipping details',
      blurb: 'A ready-to-copy set of details for online orders and deliveries.',
      profileId: 'personal',
      fieldIds: ['p-name', 'p-address', 'p-city', 'p-country'],
    );
    const company = PocketTemplate(
      id: 'company',
      name: 'Company info',
      blurb: 'Invoice details, ready to paste.',
      profileId: 'work',
      fieldIds: ['w-company', 'w-email', 'w-tax'],
    );
    return const FormBook(
      profiles: [personal, work, family],
      templates: [shipping, company],
    );
  }
}
