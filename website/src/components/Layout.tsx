import type { ReactNode } from 'react'
import lens from '../assets/lens.svg'

export type PageName = 'home' | 'privacy' | 'support'

export const EMAIL = 'moopdeveloper@gmail.com'

// every page is its own html file, so links are relative to where this one
// lives. "" for the home page, "../" for the pages one folder down.
const path = (page: PageName, root: string) =>
  page === 'home' ? root || './' : `${root || './'}${page}/`

const names: Record<PageName, string> = { home: 'Home', privacy: 'Privacy', support: 'Support' }

export function Mark({ className = '' }: { className?: string }) {
  return <img src={lens} alt="" className={className} />
}

// the small caps line above a headline
export function Eyebrow({ children, className = '' }: { children: ReactNode; className?: string }) {
  return (
    <p className={`font-bold uppercase text-violet text-[12px] leading-[17px] lg:text-[13px] ${className}`}>
      {children}
    </p>
  )
}

export function Page({ children }: { children: ReactNode }) {
  return <div className="mx-auto w-full max-w-[1440px] px-6 lg:px-20">{children}</div>
}

export function Header({ current, root }: { current: PageName; root: string }) {
  const all: PageName[] = ['home', 'privacy', 'support']
  return (
    <header className="flex h-[76px] items-center justify-between border-b border-veil lg:h-24">
      <a href={path('home', root)} className="flex items-center gap-2.5 lg:gap-3.5" aria-label="moop home">
        <Mark className="size-[38px] lg:size-[45px]" />
        <span className="text-[24px] leading-9 font-bold lg:text-[30px]">moop.</span>
      </a>
      <nav aria-label="Main" className="text-[13px] font-medium lg:mr-[128px] lg:text-[15px]">
        {/* a phone has room for the two pages you are not on, a desktop shows all three */}
        <ul className="flex gap-[18px] lg:gap-[85px]">
          {all.map((page) => (
            <li key={page} className={page === current ? 'hidden lg:block' : ''}>
              <a
                href={path(page, root)}
                aria-current={page === current ? 'page' : undefined}
                className={page === current ? 'font-bold text-violet' : 'text-violet lg:text-ink'}
              >
                {names[page]}
              </a>
            </li>
          ))}
        </ul>
      </nav>
    </header>
  )
}

export function Footer({
  root,
  tagline,
  privacyLabel,
  copyright,
}: {
  root: string
  tagline?: string
  privacyLabel: string
  copyright: { mobile: string; desktop: string }
}) {
  const link = 'text-violet'
  return (
    <footer className="mt-11 border-t border-veil pt-[30px] pb-[18px] lg:mt-0 lg:pt-11 lg:pb-[26px]">
      <div className="flex flex-col gap-3 lg:flex-row lg:items-start lg:justify-between">
        <div>
          <p className="text-[25px] leading-[35px] font-bold lg:leading-[33px]">moop.</p>
          {tagline && <p className="mt-3 hidden font-serif text-[16px] leading-[21px] lg:block">{tagline}</p>}
        </div>
        <nav aria-label="Footer" className="text-[14px] font-medium lg:mt-[18px] lg:mr-3.5 lg:text-[15px]">
          <ul className="flex gap-[18px] lg:gap-[60px]">
            <li><a className={link} href={path('home', root)}>Home</a></li>
            <li><a className={link} href={path('privacy', root)}>
              <span className="lg:hidden">Privacy</span>
              <span className="hidden lg:inline">{privacyLabel}</span>
            </a></li>
            <li><a className={link} href={path('support', root)}>Support</a></li>
          </ul>
        </nav>
      </div>
      <p className="mt-[18px] text-[12px] leading-[18px] font-medium text-violet lg:mt-[30px] lg:text-[13px] lg:leading-[17px]">
        <span className="lg:hidden">{copyright.mobile}</span>
        <span className="hidden lg:inline">{copyright.desktop}</span>
      </p>
    </footer>
  )
}

// the dark panel that closes most sections
export function Panel({ children, className = '' }: { children: ReactNode; className?: string }) {
  return <div className={`bg-night text-highlight ${className}`}>{children}</div>
}
