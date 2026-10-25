import { useEffect, useRef, useState } from 'react'
import { EMAIL, Eyebrow, Footer, Header, Page, Panel } from '../components/Layout'
import { inShort, lastUpdated, sections } from '../content/privacy'

const ids = sections.map((s) => s.id)

// the section being read, so the list beside the page can follow along: the
// last one whose top has passed a line near the top of the window. the final
// sections can never get that high, so the bottom of the page counts too.
// a clicked item stays put until the reader scrolls for themselves, otherwise
// a link to one of the last sections would light up "Contact" instead.
function useActiveSection(ids: string[]) {
  const [active, setActive] = useState(ids[0])
  const pinned = useRef(false)
  useEffect(() => {
    const update = () => {
      if (pinned.current) return
      const atBottom = window.innerHeight + window.scrollY >= document.documentElement.scrollHeight - 4
      if (atBottom) return setActive(ids.at(-1)!)
      const passed = ids.filter((id) => (document.getElementById(id)?.getBoundingClientRect().top ?? Infinity) <= 100)
      setActive(passed.at(-1) ?? ids[0])
    }
    const release = () => { pinned.current = false }
    update()
    window.addEventListener('scroll', update, { passive: true })
    for (const e of ['wheel', 'touchmove', 'keydown']) window.addEventListener(e, release, { passive: true })
    return () => {
      window.removeEventListener('scroll', update)
      for (const e of ['wheel', 'touchmove', 'keydown']) window.removeEventListener(e, release)
    }
  }, [ids])
  const pin = (id: string) => { pinned.current = true; setActive(id) }
  return [active, pin] as const
}

export function Privacy() {
  const [active, pin] = useActiveSection(ids)

  return (
    <Page>
      <Header current="privacy" root="../" />

      <main>
        <section className="pt-16 lg:pt-[67px]">
          <Eyebrow className="lg:text-[14px] lg:leading-5">
            <span className="lg:hidden">Privacy isn't an extra</span>
            <span className="hidden lg:inline">The small print, made clear</span>
          </Eyebrow>
          <h1 className="mt-[21px] font-serif text-[52px] leading-[56px] lg:mt-[35px] lg:text-[89px] lg:leading-[93px]">
            Your moments.<br />Your privacy.
          </h1>
          <p className="mt-11 text-[14px] leading-[21px] font-medium text-violet lg:mt-[39px] lg:text-[16px] lg:leading-[23px]">
            <span className="lg:hidden">moop. Privacy Policy<br />Last updated: {lastUpdated}</span>
            <span className="hidden lg:inline">moop. Privacy Policy&nbsp;&nbsp;·&nbsp;&nbsp;Last updated: {lastUpdated}</span>
          </p>

          <Panel className="mt-[41px] rounded-2xl px-5 pt-6 pb-6 max-lg:min-h-[258px] lg:mt-[56px] lg:h-[238px] lg:rounded-[18px] lg:px-[35px] lg:pt-8">
            <p className="text-[12px] leading-[18px] font-bold uppercase text-citrus lg:text-[13px] lg:leading-[19px]">In short</p>
            <p className="mt-[23px] text-[16px] leading-6 lg:mt-6 lg:max-w-[1180px] lg:text-[24px] lg:leading-[35px]">{inShort}</p>
          </Panel>
        </section>

        <div className="mt-[56px] lg:mt-[75px] lg:flex lg:gap-[70px]">
          {/* on this page */}
          <aside className="hidden lg:block lg:w-[340px] lg:shrink-0">
            <nav aria-label="On this page" className="sticky top-8 pt-3">
              <p className="text-[13px] leading-[19px] font-bold text-violet">ON THIS PAGE</p>
              <ul className="mt-[20px]">
                {sections.map((s) => (
                  <li key={s.id} className="h-[42px]">
                    <a href={`#${s.id}`} onClick={() => pin(s.id)} aria-current={active === s.id ? 'true' : undefined}
                       className={`text-[14px] leading-[18px] ${active === s.id ? 'font-bold text-violet' : 'font-medium text-ink'}`}>
                      {s.title}
                    </a>
                  </li>
                ))}
              </ul>
              <p className="mt-[75px] max-w-[310px] text-[15px] leading-[22px] text-violet">
                You can revisit this policy anytime in moop Settings.
              </p>
            </nav>
          </aside>

          <div className="lg:w-[806px]">
            {sections.map((s, i) => (
              <section key={s.id} id={s.id}
                       className={`scroll-mt-6 pb-7 lg:pb-[34px] ${i === 0 ? '' : 'border-t border-veil pt-11 lg:pt-12'}`}>
                <h2 className="font-serif text-[31px] leading-9 lg:text-[32px] lg:leading-[38px]">{s.title}</h2>
                <div className="mt-[17px] flex flex-col gap-4 lg:mt-[18px]">
                  {s.blocks.map((b, j) =>
                    'p' in b ? (
                      <p key={j} className="text-[16px] leading-6 lg:text-[18px] lg:leading-7">{b.p}</p>
                    ) : (
                      <ul key={j} className="flex flex-col gap-4">
                        {b.bullets.map((t) => (
                          <li key={t} className="relative pl-[19px] text-[16px] leading-6 lg:pl-7 lg:text-[18px] lg:leading-7">
                            <span aria-hidden className="absolute top-[12px] left-0.5 size-[7px] rounded bg-violet lg:left-[8px] lg:top-[13px]" />
                            {t}
                          </li>
                        ))}
                      </ul>
                    ),
                  )}
                </div>
              </section>
            ))}
            <div className="border-t border-veil lg:pb-[133px]" />

            <div className="mt-[52px] rounded-[10px] bg-veil px-[18px] py-[14px] lg:hidden">
              <p className="text-[11px] leading-[17px] font-bold text-violet">QUESTIONS ABOUT PRIVACY?</p>
              <p className="mt-[7px] text-[14px] leading-[21px]">
                Contact: <a href={`mailto:${EMAIL}`} className="underline underline-offset-2">{EMAIL}</a>
              </p>
            </div>
          </div>
        </div>
      </main>

      <Footer
        root="../"
        privacyLabel="Privacy Policy"
        copyright={{ mobile: '© 2026 moop. Private by design.', desktop: '© 2026 moop   ·   Your moments belong to you.' }}
      />
    </Page>
  )
}
