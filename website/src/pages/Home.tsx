import moment from '../assets/moment.png'
import { Eyebrow, Footer, Header, Page, Panel } from '../components/Layout'

const features = [
  {
    n: '01', tone: 'bg-homey',
    title: { d: 'Snap something real.', m: 'Snap something real.' },
    body: { d: 'The camera takes one moment. No perfect angles required.', m: 'A photo is enough. No perfect day required.' },
  },
  {
    n: '02', tone: 'bg-calm',
    title: { d: 'Find a feeling.', m: 'Find a feeling.' },
    body: { d: 'Apple Intelligence suggests a mood and one gentle sentence, on your iPhone.', m: 'A short mood and a kind sentence, read on-device.' },
  },
  {
    n: '03', tone: 'bg-veil',
    title: { d: 'See your story.', m: 'Look back.' },
    body: { d: 'Look back through your weeks and months without scrolling forever.', m: 'See how your days felt across weeks and months.' },
  },
]

// copy that differs between the two designs is written once for each
const D = ({ children }: { children: React.ReactNode }) => <span className="hidden lg:inline">{children}</span>
const M = ({ children }: { children: React.ReactNode }) => <span className="lg:hidden">{children}</span>

const rule = <div className="h-px bg-veil" />
const cta = 'h-[54px] items-center rounded-[10px] bg-citrus px-[22px] text-[16px] font-bold'

export function Home() {
  return (
    <Page>
      <Header current="home" root="" />

      <main>
        {/* hero */}
        <section className="pt-[59px] lg:flex lg:items-start lg:justify-between lg:pt-[61px] lg:pb-[97px]">
          <div>
            <Eyebrow><M>A private photo journal</M><D>Your private photo journal</D></Eyebrow>
            <h1 className="mt-[21px] font-serif text-[53px] leading-[55px] lg:mt-[42px] lg:text-[90px] lg:leading-[96px]">
              <span className="lg:hidden">The small<br />moments are<br />the whole story.</span>
              <span className="hidden lg:inline">The small moments<br />are the whole story.</span>
            </h1>
            <p className="mt-[30px] max-w-[337px] text-[17px] leading-6 lg:mt-[66px] lg:ml-1 lg:max-w-[540px] lg:text-[22px] lg:leading-[29px]">
              <span className="lg:hidden">One photo. One feeling. A few kind words. A quieter way to remember an ordinary day.</span>
              <span className="hidden lg:inline">One photo. One feeling. A few kind words.<br />A quieter way to remember an ordinary day.</span>
            </p>

            <a href="#how" className={`${cta} mt-[68px] hidden w-[350px] lg:inline-flex`}>
              Discover how moop works&nbsp;&nbsp;↗
            </a>
            <p className="mt-7 hidden text-[14px] leading-[18px] font-medium text-violet lg:ml-1 lg:block">
              On your iPhone. On your terms.
            </p>
            <p className="mt-[47px] flex h-11 items-center rounded-lg bg-citrus px-4 text-[15px] font-bold lg:hidden">
              Made for the ordinary days.
            </p>
          </div>

          <div className="mt-[29px] lg:mt-[25px] lg:mr-[78px] lg:h-[471px] lg:w-[408px] lg:rounded-3xl lg:bg-veil lg:pt-7">
            <img src={moment} alt="A cosy evening window with a cat asleep on a purple sofa"
                 className="aspect-square w-full rounded-[18px] object-cover lg:mx-auto lg:size-[318px] lg:rounded-[20px]" />
            <p className="mt-[25px] font-serif text-[27px] leading-[38px] lg:hidden">Sometimes, homey is enough.</p>
            <p className="mt-3 hidden h-[49px] w-[196px] items-center rounded-lg bg-citrus pl-[25px] font-serif text-[23px] lg:flex">homey</p>
            <p className="mt-[26px] hidden px-[15px] text-[18px] leading-[23px] font-medium lg:block">
              Not every day has to be extraordinary.
            </p>
          </div>
        </section>

        <div className="mt-[85px] lg:mt-0">{rule}</div>

        {/* what it is */}
        <section id="how" className="scroll-mt-6 pt-12 lg:flex lg:justify-between lg:pt-[74px]">
          <h2 className="font-serif text-[48px] leading-[67px] lg:text-[62px] lg:leading-[81px]">
            <span className="lg:hidden">Not a journal.<br />Just your life.</span>
            <span className="hidden lg:inline">For the days that<br />would otherwise blur.</span>
          </h2>
          <p className="mt-[21px] hidden text-[20px] leading-[26px] lg:mr-20 lg:block lg:w-[528px]">
            School. Home. Homework. Repeat. moop makes room for small, honest moments without asking you to write a paragraph or share anything with anyone.
          </p>
        </section>

        <ul className="mt-[67px] grid gap-[22px] lg:mt-[92px] lg:grid-cols-3 lg:gap-[34px]">
          {features.map((f) => (
            <li key={f.n} className={`${f.tone} h-[217px] rounded-[14px] px-[21px] pt-5 lg:h-[350px] lg:rounded-[18px] lg:px-[30px] lg:pt-[25px]`}>
              <p className="text-[12px] leading-[17px] font-bold text-violet lg:text-[14px] lg:leading-[18px]">{f.n}</p>
              <h3 className="mt-[22px] font-serif text-[32px] leading-[45px] lg:mt-[42px] lg:text-[41px] lg:leading-[53px]">
                <M>{f.title.m}</M><D>{f.title.d}</D>
              </h3>
              <p className="mt-[22px] text-[16px] leading-[22px] lg:mt-[57px] lg:max-w-[336px] lg:text-[18px] lg:leading-[23px]">
                <M>{f.body.m}</M><D>{f.body.d}</D>
              </p>
            </li>
          ))}
        </ul>

        {/* privacy */}
        <Panel className="mt-[47px] min-h-[283px] rounded-[18px] px-[22px] pt-[30px] pb-6 lg:mt-20 lg:flex lg:h-[449px] lg:rounded-3xl lg:px-[46px] lg:pt-14 lg:pb-0">
          <div className="lg:w-[648px]">
            <p className="text-[12px] leading-[17px] font-bold uppercase text-citrus lg:text-[14px] lg:leading-[18px]">
              <M>Private by design</M><D>Your moments belong to you</D>
            </p>
            <h2 className="mt-[18px] font-serif text-[42px] leading-[59px] lg:mt-[31px] lg:text-[70px] lg:leading-[91px]">
              <span className="lg:hidden">Your moments<br />belong to you.</span>
              <span className="hidden lg:inline">Private by design.<br />Always.</span>
            </h2>
          </div>
          <div className="lg:mt-[75px] lg:w-[497px]">
            <p className="mt-[18px] text-[15px] leading-[21px] lg:mt-0 lg:text-[19px] lg:leading-[25px]">
              <M>No ads. No analytics. No feed. Private iCloud sync is optional.</M>
              <D>No ads. No analytics. No public feed. Photos stay on your iPhone unless you choose to use your private iCloud.</D>
            </p>
            <a href="./privacy/" className={`${cta} mt-[91px] hidden w-[361px] text-ink lg:inline-flex`}>
              Read our Privacy Policy&nbsp;&nbsp;↗
            </a>
          </div>
        </Panel>

        <section className="mt-[46px] hidden lg:mt-[109px] lg:block">
          <h2 className="font-serif text-[56px] leading-[73px]">A small space, just for you.</h2>
          <p className="mt-[9px] mb-[2px] text-[18px] leading-[23px] lg:ml-0.5">
            Available for iPhone. No account required to keep your moments locally.
          </p>
        </section>
      </main>

      <Footer
        root=""
        tagline="A little life, kept for you."
        privacyLabel="Privacy Policy"
        copyright={{ mobile: '© 2026 moop. Your moments belong to you.', desktop: '© 2026 moop · Made for iPhone' }}
      />
    </Page>
  )
}
