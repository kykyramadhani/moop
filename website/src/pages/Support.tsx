import { Eyebrow, EMAIL, Footer, Header, Mark, Page, Panel } from '../components/Layout'
import { desktopFaq, mobileFaq, type Faq } from '../content/faq'

// a question beside its answer on a desktop, one above the other on a phone
function FaqList({ items }: { items: Faq[] }) {
  return (
    <dl>
      {items.map((f, i) => (
        <div key={f.q}
             className={`border-b border-veil pt-[31px] pb-[26px] lg:grid lg:grid-cols-[498px_1fr] lg:gap-0 lg:pb-[44px] ${i === 0 ? 'lg:pt-[18px]' : ''}`}>
          <dt className="text-[20px] leading-[30px] font-bold lg:text-[22px] lg:leading-[31px]">{f.q}</dt>
          <dd className="mt-[12px] text-[16px] leading-6 lg:mt-0 lg:max-w-[726px] lg:text-[18px] lg:leading-[25px]">
            {f.a.startsWith('Contact: ')
              ? <>Contact: <a href={`mailto:${EMAIL}`} className="underline underline-offset-2">{EMAIL}</a></>
              : f.a}
          </dd>
        </div>
      ))}
    </dl>
  )
}

export function Support() {
  return (
    <Page>
      <Header current="support" root="../" />

      <main>
        <section className="pt-16 lg:flex lg:items-start lg:justify-between lg:pt-[93px] lg:pb-[78px]">
          <div className="lg:-mt-[18px]">
            <Eyebrow><span className="lg:hidden">Help when you need it</span><span className="hidden lg:inline">Help, without the hassle</span></Eyebrow>
            <h1 className="mt-[21px] font-serif text-[54px] leading-[57px] lg:mt-[38px] lg:text-[81px] lg:leading-[85px]">
              <span className="lg:hidden">A little help<br />goes a long way.</span>
              <span className="hidden lg:inline">A few answers.<br />A little peace of mind.</span>
            </h1>
            <p className="mt-11 max-w-[339px] text-[16px] leading-6 lg:mt-[48px] lg:ml-1 lg:max-w-[775px] lg:text-[20px] lg:leading-7">
              <span className="lg:hidden">Questions about your privacy, moments, backups, or iCloud? Start here.</span>
              <span className="hidden lg:inline">moop is meant to feel simple. Here are the things you might want to know before trusting it with your days.</span>
            </p>
          </div>
          <div className="hidden h-[376px] w-[385px] items-center justify-center rounded-[23px] bg-veil lg:mr-[5px] lg:flex" aria-hidden>
            <Mark className="size-[194px]" />
          </div>
        </section>

        <div className="hidden border-t border-veil lg:block" />

        <section className="mt-10 lg:mt-0 lg:pt-[61px]">
          <h2 className="hidden font-serif text-[47px] leading-[66px] lg:block">Frequently asked questions</h2>
          <div className="hidden lg:block"><FaqList items={desktopFaq} /></div>
          <div className="lg:hidden"><FaqList items={mobileFaq(EMAIL)} /></div>
        </section>

        <Panel className="mt-[54px] rounded-2xl px-[19px] pt-6 pb-8 max-lg:min-h-[213px] lg:mt-20 lg:h-[283px] lg:rounded-[22px] lg:px-[38px] lg:pt-[34px] lg:pb-0">
          <p className="text-[12px] leading-[18px] font-bold uppercase text-citrus lg:text-[13px]">
            <span className="lg:hidden">Take your time</span><span className="hidden lg:inline">Need something else?</span>
          </p>
          <p className="mt-[13px] font-serif text-[35px] leading-[39px] lg:mt-[21px] lg:text-[52px] lg:leading-[73px]">
            <span className="lg:hidden">Your moments<br />aren't going anywhere.</span>
            <span className="hidden lg:inline">We're here to help.</span>
          </p>
          <p className="mt-[6px] hidden text-[17px] leading-6 lg:block">
            Questions about privacy or moop? Contact: <a href={`mailto:${EMAIL}`} className="underline underline-offset-2">{EMAIL}</a>
          </p>
        </Panel>

        <div className="mt-[53px] lg:mt-[53px]" />
      </main>

      <Footer
        root="../"
        privacyLabel="Privacy"
        copyright={{ mobile: '© 2026 moop. Private by design.', desktop: '© 2026 moop. Your moments belong to you.' }}
      />
    </Page>
  )
}
