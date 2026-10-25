export type Faq = { q: string; a: string }

// the desktop and the phone design ask slightly different questions, so each
// keeps its own list rather than one being bent to fit the other
export const desktopFaq: Faq[] = [
  { q: 'Is moop private?', a: 'Yes. moop has no analytics or advertising. Your photos stay on your iPhone unless you turn on sync to your private iCloud.' },
  { q: 'Do I need an Apple account?', a: 'No. You can use moop without signing in. Continue with Apple and iCloud sync are optional.' },
  { q: 'What if a photo can\'t be read?', a: 'You can still save it without a mood. Mystery is a failed reading, not a feeling assigned to your day.' },
  { q: 'How do I save a backup?', a: 'Open Settings and choose Save Backup to Files. The ZIP is not encrypted, so keep it somewhere you trust.' },
  { q: 'Can I delete a moment?', a: 'Yes. Delete it from its day. Settings also lets you delete everything, including a choice about synced copies when iCloud is enabled.' },
  { q: 'Will my moments move to another iPhone?', a: 'If you enable iCloud sync, your moments can sync through your private iCloud. Local-only moments require a backup and restore.' },
]

export const mobileFaq = (email: string): Faq[] => [
  { q: 'Is moop private?', a: 'Yes. There are no ads or analytics, and your photos stay on your iPhone unless you choose private iCloud sync.' },
  { q: 'Can I use moop without signing in?', a: 'Yes. Local-only mode works without an account, and you can save a backup to Files.' },
  { q: 'What if a photo can\'t be read?', a: 'The photo can still be saved without a mood. The app won\'t invent a feeling.' },
  { q: 'Can I export my memories?', a: 'Yes. Use Save Backup to Files in Settings. The ZIP file isn\'t encrypted.' },
  { q: 'Can I delete everything?', a: 'Yes. Settings lets you delete data locally, with additional options if iCloud sync is enabled.' },
  { q: 'How can I get help?', a: `Contact: ${email}` },
]
