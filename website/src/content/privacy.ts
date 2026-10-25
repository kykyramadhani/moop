import { EMAIL } from '../components/Layout'

export type Block = { p: string } | { bullets: string[] }
export type Section = { id: string; title: string; blocks: Block[] }

export const lastUpdated = '25 October 2026'

export const inShort =
  'moop has no servers and no analytics. Your photos are read on your iPhone. Nothing is uploaded unless you choose to turn on iCloud sync, and then it goes to your own private iCloud, not to us.'

// one source for the page and for the "on this page" list beside it
export const sections: Section[] = [
  {
    id: 'what-moop-is',
    title: 'What moop is',
    blocks: [{ p: 'moop is an iPhone app where you take one photo and get one mood and one short sentence. The reading is done on your iPhone with Apple Intelligence.' }],
  },
  {
    id: 'what-we-collect',
    title: 'What we collect',
    blocks: [{ p: 'Nothing. The developer of moop does not collect, receive, store or sell any personal data. moop has no backend, no advertising, no analytics and no tracking.' }],
  },
  {
    id: 'what-moop-keeps',
    title: 'What moop keeps on your iPhone',
    blocks: [{
      bullets: [
        'Your moments: the photo, its mood word, its sentence, the reason shown under "Why this word?", and the date. They are stored in the app\'s private storage on your iPhone.',
        'Your settings: your name (optional), theme, and reminder time.',
      ],
    }],
  },
  {
    id: 'camera-and-photos',
    title: 'Camera and photos',
    blocks: [{
      bullets: [
        'Camera: used only so you can take the photo moop reads. If you decline, you can still pick a photo from your library.',
        'Photo library: moop uses the system photo picker. It can only see the photos you choose, and nothing else in your library.',
      ],
    }],
  },
  {
    id: 'how-the-mood-is-read',
    title: 'How the mood is read',
    blocks: [{ p: 'The photo is read by Apple\'s on-device model through Apple Intelligence. The photo is not sent to us or to any other server by moop. If Apple Intelligence is unavailable, moop tells you and lets you keep the photo without a word.' }],
  },
  {
    id: 'notifications',
    title: 'Notifications',
    blocks: [{ p: 'If you turn on the evening reminder, moop schedules a notification on your iPhone. It is created locally and does not involve any server.' }],
  },
  {
    id: 'sign-in-with-apple',
    title: 'Sign in with Apple (optional)',
    blocks: [{ p: 'You can use moop without an account. If you choose Continue with Apple, moop does not ask for your name or email. It keeps Apple\'s app-specific user identifier in your iPhone\'s Keychain so it can check that your sign-in is still valid. This identifier is not sent to the developer.' }],
  },
  {
    id: 'icloud-sync',
    title: 'iCloud sync (optional)',
    blocks: [
      { p: 'If you turn on iCloud sync, your moments (photo, mood, sentence and date) are stored in your own private iCloud account using Apple\'s CloudKit. They count toward your iCloud storage and are handled under Apple\'s terms and privacy policy. The developer cannot see or access them.' },
      {
        bullets: [
          'Sync is off until you turn it on.',
          'Deleting a moment on one iPhone removes it on your other iPhones that sync.',
          'Stopping sync keeps a copy on this iPhone and leaves what is already in iCloud as it is.',
        ],
      },
    ],
  },
  {
    id: 'backups',
    title: 'Backups you save to Files',
    blocks: [{ p: '“Save Backup to Files” creates a zip file of your moments in a place you choose. moop does not encrypt this file. Anyone who has it may be able to see your moments, so keep it somewhere you trust. moop cannot delete backup files you have saved.' }],
  },
  {
    id: 'sharing',
    title: 'Sharing',
    blocks: [{ p: 'moop does not share your data with anyone. It includes open-source libraries (Lottie for animation and ZIPFoundation for backup files) that run inside the app and do not collect data.' }],
  },
  {
    id: 'your-choices',
    title: 'Your choices and deleting your data',
    blocks: [{
      bullets: [
        'Delete a single moment from its day.',
        'Use Settings, Delete everything to remove all moments from this iPhone. If iCloud sync is on, you can choose to delete everywhere or from this iPhone only.',
        'Deleting the app removes the moments stored on your iPhone. Copies in iCloud or in backup files you saved stay until you delete them.',
      ],
    }],
  },
  {
    id: 'children',
    title: 'Children',
    blocks: [{ p: 'moop is not directed at children and collects no personal data from anyone, including children.' }],
  },
  {
    id: 'changes',
    title: 'Changes',
    blocks: [{ p: 'If this policy changes, the new version will be published here with a new date.' }],
  },
  {
    id: 'contact',
    title: 'Contact',
    blocks: [{ p: `Questions about this policy: ${EMAIL}` }],
  },
]
